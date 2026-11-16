from sqlalchemy import Column, Integer, String, ForeignKey, DateTime
from sqlalchemy.orm import relationship
from datetime import datetime
from DAO.DatabaseConnection import Base

class AdverseReaction(Base):
    __tablename__ = "adverse_reactions"

    id = Column(Integer, primary_key=True, index=True)
    drug_id = Column(Integer, ForeignKey("drugs.id"), nullable=False)
    reaction_name = Column(String, nullable=False) # e.g., Nausea, Headache

    # Relationship to Drug
    drug = relationship("Drug", back_populates="adverse_reactions")


# ADRReport class BAHAR hai (AdverseReaction ke andar nahi)
class ADRReport(Base):
    __tablename__ = "adr_reports"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    raw_text = Column(String, nullable=False)
    extracted_drug = Column(String, nullable=True)
    extracted_adr = Column(String, nullable=True)
    confidence_score = Column(String, nullable=True)
    status = Column(String, default="pending") # pending, reviewed
    created_at = Column(DateTime, default=datetime.utcnow)