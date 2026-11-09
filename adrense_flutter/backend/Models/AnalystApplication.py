from datetime import datetime
from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, JSON, LargeBinary, UniqueConstraint
from sqlalchemy.orm import deferred
from DAO.DatabaseConnection import Base


class AnalystApplication(Base):
    __tablename__ = "analyst_applications"
    user_id = Column(Integer, ForeignKey("users.id"), primary_key=True)
    details = Column(JSON, nullable=False)
    reviewed_by = Column(Integer, ForeignKey("users.id"), nullable=True)
    reviewed_at = Column(DateTime, nullable=True)
    review_reason = Column(String(1000), nullable=True)


class AnalystDocument(Base):
    __tablename__ = "analyst_documents"
    __table_args__ = (UniqueConstraint("user_id", "kind"),)
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"), index=True, nullable=False)
    kind = Column(String(20), nullable=False)
    filename = Column(String(200), nullable=False)
    media_type = Column(String(30), nullable=False)
    size = Column(Integer, nullable=False)
    # Document contents are not fetched when listing application metadata.
    content = deferred(Column(LargeBinary, nullable=False))
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
