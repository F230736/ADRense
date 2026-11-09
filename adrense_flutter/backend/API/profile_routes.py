import hashlib
import hmac
import secrets
from datetime import datetime,timedelta
from fastapi import APIRouter,Depends,HTTPException
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from DAO.DatabaseConnection import get_db
from Models.User import User
from Models.Patient import Patient
from Models.ProfileData import ProfileData,PendingEmailChange
from Models.AuthState import AuthState,EmailChallenge
from Business.AccessControl import require_patient
from Business.ProfileService import profile_data,serialize_user
from Business.AuthService import access_token_for
from Business.EmailAuthService import digest_code
from Business.EmailService import send_code
from Business.RateLimit import auth_rate_limit
from DTO.ProfileDTO import ProfileUpdateDTO,EmailChangeRequestDTO,EmailChangeConfirmDTO

router=APIRouter(prefix="/api/profile",tags=["Profile"])

@router.get("")
def get_profile(user:User=Depends(require_patient),db:Session=Depends(get_db)):
    return {"user":serialize_user(db,user)}

@router.patch("")
def update_profile(data:ProfileUpdateDTO,user:User=Depends(require_patient),db:Session=Depends(get_db)):
    user=db.query(User).filter_by(id=user.id).with_for_update().one()
    patient=db.query(Patient).filter_by(user_id=user.id).first()
    if patient is None:
        raise HTTPException(409,"This account does not have a patient profile")
    current=profile_data(db,user.id)
    details=db.get(ProfileData,user.id)
    if details is None:
        details=ProfileData(user_id=user.id,medical_conditions=current['medical_conditions'],current_medications=current['current_medications'],allergies=current['allergies'],medication_doses={})
        db.add(details)
    changes=data.model_dump(exclude_unset=True)
    if 'name' in changes:user.name=changes['name']
    for field in ['age_group','gender','weight_range']:
        if field in changes:setattr(patient,field,changes[field])
    for field in ['medical_conditions','current_medications','allergies']:
        if field in changes:
            setattr(details,field,changes[field])
            setattr(patient,field,','.join(changes[field]))
    doses=changes.get('medication_doses',details.medication_doses or {})
    medications=changes.get('current_medications',details.current_medications)
    if 'medication_doses' in changes and not set(doses).issubset(medications):
        raise HTTPException(422,"A dose must belong to a current medication")
    details.medication_doses={key:value for key,value in doses.items() if key in medications}
    db.commit()
    return {"message":"Profile saved","user":serialize_user(db,user)}

def change_key(user_id,email,version):
    return hashlib.sha256(f"email-change:{user_id}:{email}:{version}".encode()).hexdigest()

@router.post("/email-change/request",dependencies=[Depends(auth_rate_limit)])
def request_email_change(data:EmailChangeRequestDTO,user:User=Depends(require_patient),db:Session=Depends(get_db)):
    user=db.query(User).filter_by(id=user.id).with_for_update().one()
    email=str(data.email).strip().lower()
    if email==user.email:
        raise HTTPException(400,"Enter a different email address")
    if db.query(User.id).filter(User.email==email).first():
        raise HTTPException(409,"That email address cannot be used")
    now=datetime.utcnow()
    pending=db.get(PendingEmailChange,user.id)
    if pending and (now-pending.sent_at).total_seconds()<60:
        wait=max(1,60-int((now-pending.sent_at).total_seconds()))
        raise HTTPException(429,f"Please wait {wait} seconds before requesting another code",headers={"Retry-After":str(wait)})
    if pending and pending.attempts>=5 and pending.expires_at>now:
        raise HTTPException(429,"Too many incorrect codes. Wait for the current code to expire before trying again")
    state=db.get(AuthState,user.id)
    if pending is None:
        pending=PendingEmailChange(user_id=user.id)
        db.add(pending)
    code=f"{secrets.randbelow(1000000):06d}"
    pending.old_email=user.email;pending.email=email;pending.session_version=state.session_version
    pending.digest=digest_code(change_key(user.id,email,state.session_version),code)
    pending.sent_at=now;pending.expires_at=now+timedelta(minutes=10);pending.attempts=0
    try:
        send_code(email,code,"email-change")
        db.commit()
    except Exception:
        db.rollback()
        raise HTTPException(503,"We could not send the verification email. Your current email has not changed. Please try again.")
    return {"message":"Verification code sent to your new email. Your current email remains unchanged until verified.","email":email,"retry_after":60}

@router.post("/email-change/confirm",dependencies=[Depends(auth_rate_limit)])
def confirm_email_change(data:EmailChangeConfirmDTO,user:User=Depends(require_patient),db:Session=Depends(get_db)):
    user=db.query(User).filter_by(id=user.id).with_for_update().one()
    pending=db.get(PendingEmailChange,user.id)
    state=db.get(AuthState,user.id)
    email=str(data.email).strip().lower()
    if not pending or pending.expires_at<=datetime.utcnow() or pending.attempts>=5 or pending.email!=email or pending.old_email!=user.email or pending.session_version!=state.session_version:
        raise HTTPException(400,"Invalid or expired code. Request a new code if needed.")
    pending.attempts+=1
    key=change_key(user.id,email,state.session_version)
    if not hmac.compare_digest(pending.digest,digest_code(key,data.code)):
        db.commit()
        raise HTTPException(400,"Invalid or expired code. Request a new code if needed.")
    if db.query(User.id).filter(User.email==email,User.id!=user.id).first():
        raise HTTPException(409,"That email address is no longer available. Choose another address.")
    old_email=user.email
    user.email=email
    state.is_verified=True
    state.session_version+=1
    # Codes issued for a former email must not transfer to a future owner of that address.
    keys=[hashlib.sha256(f"{purpose}:{address}".encode()).hexdigest() for address in [old_email,email] for purpose in ['verify','reset']]
    db.query(EmailChallenge).filter(EmailChallenge.key.in_(keys)).update({EmailChallenge.consumed:True},synchronize_session=False)
    db.delete(pending)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(409,"That email address is no longer available. Choose another address.")
    return {"message":"Email verified and updated","user":serialize_user(db,user),"access_token":access_token_for(user,state),"token_type":"bearer"}
