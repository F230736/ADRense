import hashlib
import hmac
import secrets
from datetime import datetime, timedelta
from Models.User import User
from Models.AuthState import AuthState, EmailChallenge
from Business.EmailService import send_code

GENERIC = "If an account exists with this email, a code has been sent. Check your inbox and spam folder."

def state_for(db, user):
    state = db.get(AuthState, user.id)
    if state is None:
        state = AuthState(user_id=user.id, is_verified=user.role == "admin", session_version=0)
        db.add(state)
        db.flush()
    return state

def digest_code(key, code):
    from Business.AuthService import SECRET_KEY
    return hmac.new(SECRET_KEY.encode(), f"{key}:{code}".encode(), hashlib.sha256).hexdigest()

def request_code(db, email, purpose):
    email = str(email).strip().lower()
    # A row for every address gives unknown addresses the same persistent cooldown.
    key = hashlib.sha256(f"{purpose}:{email}".encode()).hexdigest()
    row = db.query(EmailChallenge).filter_by(key=key).with_for_update().first()
    now = datetime.utcnow()
    if row and (now-row.sent_at).total_seconds() < 60:
        db.commit()
        return
    # Failed attempts remain locked until the original challenge expires.
    if row and row.attempts >= 5 and row.expires_at > now:
        db.commit()
        return
    code = f"{secrets.randbelow(1000000):06d}"
    if row is None:
        row = EmailChallenge(key=key)
        db.add(row)
    row.digest = digest_code(key, code)
    row.sent_at = now
    row.expires_at = now + timedelta(minutes=10)
    row.attempts = 0
    row.consumed = False
    user = db.query(User).filter_by(email=email).first()
    eligible = user is not None and (purpose == "reset" or not state_for(db, user).is_verified)
    if eligible:
        send_code(email, code, purpose)
    db.commit()

def consume_code(db, email, code, purpose, password=None):
    from Business.AuthService import pwd_context
    email = str(email).strip().lower()
    key = hashlib.sha256(f"{purpose}:{email}".encode()).hexdigest()
    row = db.query(EmailChallenge).filter_by(key=key).with_for_update().first()
    if not row or row.consumed or row.expires_at <= datetime.utcnow() or row.attempts >= 5:
        db.rollback()
        return False
    row.attempts += 1
    if not hmac.compare_digest(row.digest, digest_code(key, code)):
        db.commit()
        return False
    user = db.query(User).filter_by(email=email).with_for_update().first()
    if not user:
        db.commit()
        return False
    state = state_for(db, user)
    if purpose == "verify":
        state.is_verified = True
    else:
        user.password_hash = pwd_context.hash(password)
        state.session_version += 1
    row.consumed = True
    db.commit()
    return True
