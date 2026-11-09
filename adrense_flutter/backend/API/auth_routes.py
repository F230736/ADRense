from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from jose import jwt, JWTError
from DAO.DatabaseConnection import get_db, SessionLocal
from DTO.AuthDTO import UserRegisterDTO, UserLoginDTO, EmailRequestDTO, EmailCodeDTO, ResetPasswordDTO
from Business.EmailAuthService import request_code, consume_code, state_for, GENERIC
import logging
from Business.RateLimit import auth_rate_limit
from Business.AuthService import register_user, login_user, SECRET_KEY, ALGORITHM
from Models.User import User
from Models.Patient import Patient
from Business.ProfileService import serialize_user

router = APIRouter(prefix="/api/auth", tags=["Authentication"])
security = HTTPBearer()

@router.post("/register", status_code=201, dependencies=[Depends(auth_rate_limit)])
def register(data: UserRegisterDTO, background_tasks: BackgroundTasks, db: Session = Depends(get_db)):
    user, error = register_user(db, data)
    if error:
        raise HTTPException(409, error)
    background_tasks.add_task(deliver_code, user.email, "verify")
    return {"message": "Account created. Verify your email before signing in.", "user_id": user.id, "status": user.status, "requires_verification": True}

@router.post("/login", dependencies=[Depends(auth_rate_limit)])
def login(data: UserLoginDTO, db: Session = Depends(get_db)):
    result, error = login_user(db, data.email, data.password)
    if error:
        raise HTTPException(401, error)
    return result

@router.get("/me")
def me(credentials: HTTPAuthorizationCredentials = Depends(security), db: Session = Depends(get_db)):
    try:
        payload = jwt.decode(credentials.credentials, SECRET_KEY, algorithms=[ALGORITHM])
        user_id = int(payload["sub"])
    except (JWTError, ValueError, KeyError):
        raise HTTPException(401, "Invalid or expired token")
    user = db.query(User).filter(User.id == user_id).first()
    if not user or user.status != "active":
        raise HTTPException(401, "Account is not active")
    state = state_for(db, user)
    if not state.is_verified or payload.get("ver") != state.session_version:
        raise HTTPException(401, "Session expired. Please sign in again.")
    return serialize_user(db, user)


def deliver_code(email, purpose):
    # Independent DB session: responses do not wait for SMTP or reveal account existence through delivery latency.
    with SessionLocal() as db:
        try:
            request_code(db, email, purpose)
        except Exception:
            db.rollback()
            logging.getLogger(__name__).error("Authentication email delivery failed; check SMTP configuration and service availability")

@router.post("/forgot-password", dependencies=[Depends(auth_rate_limit)])
def forgot_password(data: EmailRequestDTO, background_tasks: BackgroundTasks):
    background_tasks.add_task(deliver_code, data.email, "reset")
    return {"message": GENERIC, "retry_after": 60}

@router.post("/resend-verification", dependencies=[Depends(auth_rate_limit)])
def resend_verification(data: EmailRequestDTO, background_tasks: BackgroundTasks):
    background_tasks.add_task(deliver_code, data.email, "verify")
    return {"message": GENERIC, "retry_after": 60}

@router.post("/verify-email", dependencies=[Depends(auth_rate_limit)])
def verify_email(data: EmailCodeDTO, db: Session = Depends(get_db)):
    if not consume_code(db, data.email, data.code, "verify"):
        raise HTTPException(400, "Invalid or expired code. Request a new code if needed.")
    return {"message": "Email verified. Sign in to continue. Analyst accounts still require administrator approval."}

@router.post("/reset-password", dependencies=[Depends(auth_rate_limit)])
def reset_password(data: ResetPasswordDTO, db: Session = Depends(get_db)):
    if not consume_code(db, data.email, data.code, "reset", data.password):
        raise HTTPException(400, "Invalid or expired code. Request a new code if needed.")
    return {"message": "Password updated. All previous sessions have been revoked. Please sign in."}
