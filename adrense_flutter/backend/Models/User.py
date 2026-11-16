from sqlalchemy import Column, Integer, String, DateTime
from datetime import datetime
from DAO.DatabaseConnection import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    email = Column(String, unique=True, index=True, nullable=False)
    password_hash = Column(String, nullable=False)
    role = Column(String, default="patient")
    status = Column(String, default="active") 
    
    # Analyst specific fields
    profession = Column(String, nullable=True)
    license_number = Column(String, nullable=True)
    institution = Column(String, nullable=True)
    
    created_at = Column(DateTime, default=datetime.utcnow)