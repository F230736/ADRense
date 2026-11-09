from abc import ABC, abstractmethod
from sqlalchemy.orm import Session
from Models.User import User

class IUserDAO(ABC):
    @abstractmethod
    def get_user_by_email(self, db: Session, email: str): pass

    @abstractmethod
    def create_user(self, db: Session, name: str, email: str, password_hash: str, role: str, status: str, profession: str = None, license_number: str = None, institution: str = None): pass