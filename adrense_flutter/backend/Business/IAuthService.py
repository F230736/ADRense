from abc import ABC, abstractmethod
from sqlalchemy.orm import Session

class IAuthService(ABC):
    @abstractmethod
    def register_user(self, db: Session, name: str, email: str, password: str, role: str):
        pass

    @abstractmethod
    def login_user(self, db: Session, email: str, password: str):
        pass