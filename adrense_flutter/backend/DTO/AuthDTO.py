from pydantic import BaseModel, EmailStr, Field, field_validator, model_validator
from typing import Literal
import re
from DTO.ProfileDTO import clean_items, clean_doses
from DTO.AnalystDTO import AnalystDetailsDTO, AnalystDocumentDTO

class UserRegisterDTO(BaseModel):
    name: str = Field(min_length=3, max_length=120)
    email: EmailStr
    password: str
    role: Literal["patient", "analyst"] = "patient"
    age_group: str | None = None
    gender: str | None = None
    weight_range: str | None = None
    medical_conditions: list[str] = Field(default_factory=list)
    allergies: list[str] = Field(default_factory=list)
    current_medications: list[str] = Field(default_factory=list)
    medication_doses: dict[str,str] = Field(default_factory=dict)
    profession: str | None = None
    license_number: str | None = None
    institution: str | None = None
    analyst_details: AnalystDetailsDTO | None = None
    documents: list[AnalystDocumentDTO] = Field(default_factory=list, max_length=3)
    @field_validator("medical_conditions","current_medications","allergies")
    @classmethod
    def clean_lists(cls,value):
        return clean_items(value)
    @field_validator("medication_doses")
    @classmethod
    def check_doses(cls,value):
        return clean_doses(value)
    @field_validator("name")
    @classmethod
    def check_name(cls, value):
        if not re.fullmatch(r"[A-Za-z]+(?: +[A-Za-z]+)+", value.strip()):
            raise ValueError("Enter first and last name using letters only")
        return value.strip()
    @field_validator("password")
    @classmethod
    def check_password(cls, value):
        if len(value.encode("utf-8"))>72 or len(value)<8 or not re.search(r"[a-z]",value) or not re.search(r"[A-Z]",value) or not re.search(r"[^A-Za-z0-9\s]",value) or re.search(r"\s",value):
            raise ValueError("Password needs 8+ characters, uppercase, lowercase, special character and no spaces")
        return value
    @model_validator(mode="after")
    def required_profile(self):
        if not set(self.medication_doses).issubset(self.current_medications):
            raise ValueError("A dose must belong to a current medication")
        if self.role == "patient" and (not self.age_group or not self.gender):
            raise ValueError("Age group and biological sex are required")
        if self.role == "analyst" and (not self.profession or not self.license_number or not self.institution):
            raise ValueError("Professional credentials are required")
        if self.role == "analyst":
            if self.analyst_details is None:
                raise ValueError("Complete the analyst application details")
            kinds = [document.kind for document in self.documents]
            if len(kinds) != len(set(kinds)):
                raise ValueError("Only one document per category is allowed")
            if not {"license", "degree"}.issubset(kinds):
                raise ValueError("Professional license and degree documents are required")
        elif self.documents or self.analyst_details:
            raise ValueError("Professional documents are only accepted for analyst applications")
        return self
class UserLoginDTO(BaseModel):
    email: EmailStr
    password: str

class EmailRequestDTO(BaseModel):
    email: EmailStr = Field(max_length=254)

class EmailCodeDTO(EmailRequestDTO):
    code: str = Field(pattern=r"^[0-9]{6}$")

class ResetPasswordDTO(EmailCodeDTO):
    password: str
    confirm_password: str

    @field_validator("password")
    @classmethod
    def check_password(cls, value):
        return UserRegisterDTO.check_password(value)

    @model_validator(mode="after")
    def passwords_match(self):
        if self.password != self.confirm_password:
            raise ValueError("Passwords do not match")
        return self
