from sqlalchemy import Column, Integer, String
from sqlalchemy.orm import relationship
from DAO.DatabaseConnection import Base

class Drug(Base):
    __tablename__ = "drugs"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, unique=True, index=True, nullable=False)
    drug_class = Column(String, nullable=True)
    
    # Relationship to ADRs
    adverse_reactions = relationship("AdverseReaction", back_populates="drug")