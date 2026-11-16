import hashlib
from datetime import datetime, timedelta
from fastapi import Request, HTTPException, Depends
from sqlalchemy import update, case
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.dialects.sqlite import insert as sqlite_insert
from sqlalchemy.orm import Session
from DAO.DatabaseConnection import get_db
from Models.AuthState import AuthRate

def auth_rate_limit(request: Request, db: Session = Depends(get_db)):
    # Use the actual peer address; configure trusted proxy handling at the server.
    peer = request.client.host if request.client else "unknown"
    key = hashlib.sha256(f"{peer}:{request.url.path}".encode()).hexdigest()
    now = datetime.utcnow()
    insert = sqlite_insert if db.bind.dialect.name == "sqlite" else pg_insert
    stmt = insert(AuthRate).values(key=key, count=1, expires_at=now+timedelta(hours=1))
    expired = AuthRate.expires_at <= now
    stmt = stmt.on_conflict_do_update(index_elements=[AuthRate.key], set_={
        "count": case((expired, 1), else_=AuthRate.count+1),
        "expires_at": case((expired, now+timedelta(hours=1)), else_=AuthRate.expires_at),
    }).returning(AuthRate.count)
    count = db.execute(stmt).scalar_one()
    db.commit()
    if count > 30:
        raise HTTPException(429, "Too many requests. Please try again later.", headers={"Retry-After":"3600"})
