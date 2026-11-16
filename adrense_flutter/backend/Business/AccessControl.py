from fastapi import Depends, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import jwt, JWTError
from sqlalchemy.orm import Session
from DAO.DatabaseConnection import get_db
from Models.User import User
from Models.AuthState import AuthState
from Business.AuthService import SECRET_KEY, ALGORITHM

bearer = HTTPBearer()


def current_user(credentials: HTTPAuthorizationCredentials = Depends(bearer), db: Session = Depends(get_db)):
    try:
        payload = jwt.decode(credentials.credentials, SECRET_KEY, algorithms=[ALGORITHM])
        user_id = int(payload["sub"])
    except (JWTError, ValueError, KeyError, TypeError):
        raise HTTPException(401, "Invalid or expired session")
    user = db.get(User, user_id)
    state = db.get(AuthState, user_id)
    if not user or user.status != "active" or not state or not state.is_verified or payload.get("ver") != state.session_version:
        raise HTTPException(401, "Session expired. Please sign in again.")
    return user


def require_patient(user: User = Depends(current_user)):
    if user.role != "patient":
        raise HTTPException(403, "A general-user account is required")
    return user


def require_admin(user: User = Depends(current_user)):
    if user.role != "admin" or user.email != "admin.adrense@gmail.com":
        raise HTTPException(403, "Administrator access required")
    return user
