from sqlalchemy import Column, Integer, String, ForeignKey
from sqlalchemy.orm import relationship
from DAO.DatabaseConnection import Base

class Patient(Base):
    __tablename__ = "patients"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True, nullable=False)
    age_group = Column(String, nullable=True)
    gender = Column(String, nullable=True)
    weight_range = Column(String, nullable=True)
    medical_conditions = Column(String, nullable=True) # Comma separated string
    allergies = Column(String, nullable=True)          # Comma separated string
    current_medications = Column(String, nullable=True) # Comma separated string
    
    user = relationship("User")