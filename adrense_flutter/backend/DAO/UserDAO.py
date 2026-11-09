from DAO.IUserDAO import IUserDAO
from Models.User import User

class UserDAO(IUserDAO):
    def get_user_by_email(self, db, email):
        return db.query(User).filter(User.email == email).first()

    def create_user(self, db, name, email, password_hash, role, status, profession=None, license_number=None, institution=None):
        new_user = User(
            name=name, email=email, password_hash=password_hash, 
            role=role, status=status, profession=profession, 
            license_number=license_number, institution=institution
        )
        db.add(new_user)
        db.commit()
        db.refresh(new_user)
        return new_user