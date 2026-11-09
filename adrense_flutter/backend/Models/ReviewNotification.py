from datetime import datetime
from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from DAO.DatabaseConnection import Base


class ReviewNotification(Base):
    __tablename__ = "review_notifications"
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True, nullable=False)
    email = Column(String, nullable=False)
    name = Column(String, nullable=False)
    decision = Column(String, nullable=False)
    reason = Column(String(1000), nullable=False, default="")
    attempts = Column(Integer, nullable=False, default=0)
    next_attempt_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    sent_at = Column(DateTime, nullable=True)
