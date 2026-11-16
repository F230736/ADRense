from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from jose import jwt, JWTError
from DAO.DatabaseConnection import get_db, SessionLocal
from Business.AccessControl import current_user
from Models.AuthState import AuthState
from Business.AuthService import pwd_context
from DTO.AuthDTO import ChangePasswordDTO, UserRegisterDTO, UserLoginDTO, EmailRequestDTO, EmailCodeDTO, ResetPasswordDTO
from email_validator import EmailNotValidError, validate_email
from Business.EmailAuthService import PasswordReuseError, request_code, consume_code, state_for, GENERIC
import logging
from Business.RateLimit import auth_rate_limit
from Business.AuthService import register_user, login_user, SECRET_KEY, ALGORITHM
from Models.User import User
from Models.Patient import Patient
from Business.ProfileService import serialize_user

router = APIRouter(prefix="/api/auth", tags=["Authentication"])
security = HTTPBearer()

@router.post("/check-registration-email", dependencies=[Depends(auth_rate_limit)])
def check_registration_email(data: EmailRequestDTO):
    domain = str(data.email).rsplit("@", 1)[1].lower()
    suggestions = {"gmale.com": "gmail.com", "gmai.com": "gmail.com", "gmial.com": "gmail.com", "hotnail.com": "hotmail.com", "yaho.com": "yahoo.com"}
    if domain in suggestions:
        raise HTTPException(422, f"Check the email domain. Did you mean {suggestions[domain]}?")
    try:
        validate_email(str(data.email), check_deliverability=True, timeout=3)
    except EmailNotValidError as error:
        raise HTTPException(422, "Check the email address. Its domain cannot receive email.") from error
    return {"valid": True}


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
    try:
        accepted = consume_code(db, data.email, data.code, "reset", data.password)
    except PasswordReuseError:
        raise HTTPException(400, "Choose a password different from your current password.") from None
    if not accepted:
        raise HTTPException(400, "Invalid or expired code. Request a new code if needed.")
    return {"message": "Password updated. All previous sessions have been revoked. Please sign in."}


@router.post("/change-password", dependencies=[Depends(auth_rate_limit)])
def change_password(data: ChangePasswordDTO, user: User = Depends(current_user), db: Session = Depends(get_db)):
    state = db.get(AuthState, user.id)
    version = state.session_version
    db.refresh(user, with_for_update=True)
    db.refresh(state)
    if user.status != "active" or not state.is_verified or version != state.session_version:
        raise HTTPException(401, "Session expired. Please sign in again.")
    if not pwd_context.verify(data.current_password, user.password_hash):
        raise HTTPException(400, "Current password is incorrect.")
    if pwd_context.verify(data.password, user.password_hash):
        raise HTTPException(400, "Choose a password different from your current password.")
    user.password_hash = pwd_context.hash(data.password)
    state.session_version += 1
    db.commit()
    return {"message": "Password changed. Please sign in again."}
