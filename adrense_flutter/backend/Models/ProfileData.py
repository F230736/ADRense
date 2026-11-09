from sqlalchemy import Column, Integer, String, JSON, DateTime, ForeignKey
from DAO.DatabaseConnection import Base

class ProfileData(Base):
    __tablename__ = "patient_profile_data"
    user_id = Column(Integer, ForeignKey("users.id"), primary_key=True)
    medical_conditions = Column(JSON, nullable=False, default=list)
    current_medications = Column(JSON, nullable=False, default=list)
    allergies = Column(JSON, nullable=False, default=list)
    medication_doses = Column(JSON, nullable=False, default=dict)

class PendingEmailChange(Base):
    __tablename__ = "pending_email_changes"
    user_id = Column(Integer, ForeignKey("users.id"), primary_key=True)
    old_email = Column(String, nullable=False)
    email = Column(String, nullable=False)
    digest = Column(String, nullable=False)
    session_version = Column(Integer, nullable=False)
    sent_at = Column(DateTime, nullable=False)
    expires_at = Column(DateTime, nullable=False)
    attempts = Column(Integer, nullable=False, default=0)
