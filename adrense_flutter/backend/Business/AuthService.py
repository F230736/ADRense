import os
from datetime import datetime, timedelta, timezone
from dotenv import load_dotenv
from jose import jwt
from passlib.context import CryptContext
from sqlalchemy.exc import IntegrityError
from Models.User import User
from Models.Patient import Patient
from Models.ProfileData import ProfileData
from Business.EmailAuthService import state_for
from Models.AnalystApplication import AnalystApplication, AnalystDocument
from DTO.AnalystDTO import validate_document

load_dotenv()
SECRET_KEY = os.getenv("SECRET_KEY")
if not SECRET_KEY or len(SECRET_KEY) < 32:
    raise RuntimeError("Set a random SECRET_KEY of at least 32 characters in backend/.env")
ALGORITHM = "HS256"
EXPIRY = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "1440"))
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def register_user(db, data):
    email = str(data.email).strip().lower()
    if db.query(User).filter(User.email == email).first():
        return None, "Email already registered"
    user = User(name=data.name.strip(), email=email, password_hash=pwd_context.hash(data.password), role=data.role,
                status="pending" if data.role == "analyst" else "active",
                profession=data.profession, license_number=data.license_number, institution=data.institution)
    db.add(user)
    try:
        db.flush()
        if data.role == "patient":
            db.add(Patient(user_id=user.id, age_group=data.age_group, gender=data.gender,
                weight_range=data.weight_range, medical_conditions=",".join(data.medical_conditions or []),
                allergies=",".join(data.allergies or []), current_medications=",".join(data.current_medications or [])))
        if data.role == "patient":
            db.add(ProfileData(user_id=user.id, medical_conditions=data.medical_conditions, current_medications=data.current_medications, allergies=data.allergies, medication_doses=data.medication_doses))
        state_for(db, user)
        if data.role == "analyst":
            db.add(AnalystApplication(user_id=user.id, details=data.analyst_details.model_dump(mode="json")))
            for document in data.documents:
                filename, media_type, content = validate_document(document.filename, document.content_base64)
                db.add(AnalystDocument(user_id=user.id, kind=document.kind, filename=filename,
                                       media_type=media_type, size=len(content), content=content))
        db.commit()
        db.refresh(user)
    except IntegrityError:
        db.rollback()
        return None, "Email already registered"
    return user, None

def login_user(db, email, password):
    user = db.query(User).filter(User.email == str(email).strip().lower()).first()
    if not user or not pwd_context.verify(password, user.password_hash):
        return None, "Invalid email or password"
    if user.role == "admin" and user.email != "admin.adrense@gmail.com":
        return None, "Invalid administrator account"
    state = state_for(db, user)
    db.commit()
    if not state.is_verified:
        return None, "EMAIL_NOT_VERIFIED"
    if user.status != "active":
        return None, "Account is not active. Analyst accounts require administrator approval."
    token = access_token_for(user, state)
    return {"access_token": token, "token_type": "bearer", "role": user.role, "name": user.name, "id": user.id, "status": user.status}, None


def seed_demo_admin(db):
    """Create the one local demo administrator when ADR_ADMIN_PASSWORD is configured.

    Existing accounts are not modified; this never resets a password.
    """
    password = os.getenv('ADR_ADMIN_PASSWORD', '')
    if not password:
        return False
    email = 'admin.adrense@gmail.com'
    existing = db.query(User).filter(User.email == email).first()
    if existing:
        if existing.role != 'admin':
            raise RuntimeError('Reserved admin email belongs to a non-admin account; resolve manually.')
        return False
    admin = User(name='ADRense Administrator', email=email,
                 password_hash=pwd_context.hash(password), role='admin', status='active')
    db.add(admin)
    db.commit()
    return True


def access_token_for(user, state):
    return jwt.encode({"sub": str(user.id), "role": user.role, "ver": state.session_version, "exp": datetime.now(timezone.utc) + timedelta(minutes=EXPIRY)}, SECRET_KEY, algorithm=ALGORITHM)
