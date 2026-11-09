from sqlalchemy import Column, Integer, String, DateTime, Boolean, ForeignKey
from DAO.DatabaseConnection import Base

class AuthState(Base):
    __tablename__ = "auth_states"
    user_id = Column(Integer, ForeignKey("users.id"), primary_key=True)
    is_verified = Column(Boolean, nullable=False, default=False)
    session_version = Column(Integer, nullable=False, default=0)

class EmailChallenge(Base):
    __tablename__ = "email_challenges"
    key = Column(String, primary_key=True)
    digest = Column(String, nullable=False)
    expires_at = Column(DateTime, nullable=False)
    sent_at = Column(DateTime, nullable=False)
    attempts = Column(Integer, nullable=False, default=0)
    consumed = Column(Boolean, nullable=False, default=False)

class AuthRate(Base):
    __tablename__ = "auth_rate_limits"
    key = Column(String, primary_key=True)
    count = Column(Integer, nullable=False)
    expires_at = Column(DateTime, nullable=False)
