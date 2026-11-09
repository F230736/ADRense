import re
from pydantic import BaseModel, ConfigDict, Field, EmailStr, field_validator, model_validator

def clean_items(values):
    if len(values)>100:
        raise ValueError("Use at most 100 items in each list")
    result=[]
    seen=set()
    for value in values:
        value=value.strip()
        if not value or len(value)>120 or any(ord(c)<32 for c in value):
            raise ValueError("Each item must contain 1–120 readable characters")
        if value.casefold() not in seen:
            result.append(value);seen.add(value.casefold())
    return result

def clean_doses(values):
    if len(values)>100:
        raise ValueError("Use at most 100 medication doses")
    result={}
    for key,value in values.items():
        key=key.strip();value=value.strip()
        if not key or len(key)>120 or len(value)>120 or any(ord(c)<32 for c in key+value):
            raise ValueError("Medication names and doses must be at most 120 readable characters")
        if value:result[key]=value
    return result

class ProfileUpdateDTO(BaseModel):
    model_config=ConfigDict(extra="forbid")
    name: str | None = Field(default=None,min_length=3,max_length=120)
    age_group: str | None = None
    gender: str | None = None
    weight_range: str | None = None
    medical_conditions: list[str] | None = None
    current_medications: list[str] | None = None
    allergies: list[str] | None = None
    medication_doses: dict[str,str] | None = None
    @field_validator("name")
    @classmethod
    def valid_name(cls,value):
        if value is None or not re.fullmatch(r"[A-Za-z]+(?: +[A-Za-z]+)+",value.strip()):
            raise ValueError("Enter first and last name using letters only")
        return value.strip()
    @field_validator("age_group","weight_range")
    @classmethod
    def valid_ranges(cls,value,info):
        if value is None and info.field_name=="weight_range":return None
        normalized=(value or "").replace(" ","").replace("-","–")
        allowed=["18–25","26–35","36–50","51–65","65+"] if info.field_name=="age_group" else ["<50kg","50–70kg","70–90kg","90–110kg",">110kg"]
        if normalized not in allowed:raise ValueError("Select a valid "+info.field_name.replace("_"," "))
        return normalized
    @field_validator("gender")
    @classmethod
    def valid_gender(cls,value):
        if value not in ["Male","Female","Other"]:raise ValueError("Select Male, Female, or Other")
        return value
    @field_validator("medical_conditions","current_medications","allergies")
    @classmethod
    def valid_items(cls,value):
        if value is None:raise ValueError("Use an empty list to remove all items")
        return clean_items(value)
    @field_validator("medication_doses")
    @classmethod
    def valid_doses(cls,value):
        if value is None:raise ValueError("Use an empty object to remove all doses")
        return clean_doses(value)
    @model_validator(mode="after")
    def nonempty(self):
        if not self.model_fields_set:raise ValueError("Provide at least one profile field")
        return self

class EmailChangeRequestDTO(BaseModel):
    model_config=ConfigDict(extra="forbid")
    email: EmailStr

class EmailChangeConfirmDTO(EmailChangeRequestDTO):
    code: str=Field(pattern=r"^[0-9]{6}$")
