from Models.Patient import Patient
from Models.AnalystApplication import AnalystApplication
from Models.ProfileData import MedicationCondition, ProfileData

def split_legacy(value):
    return [part.strip() for part in (value or "").split(",") if part.strip()]

def profile_data(db,user_id):
    patient=db.query(Patient).filter_by(user_id=user_id).first()
    details=db.get(ProfileData,user_id)
    if not patient:return None
    medication_conditions = db.get(MedicationCondition, user_id)
    return {"age_group":patient.age_group,"gender":patient.gender,"weight_range":patient.weight_range,
        "medical_conditions":details.medical_conditions if details else split_legacy(patient.medical_conditions),
        "current_medications":details.current_medications if details else split_legacy(patient.current_medications),
        "allergies":details.allergies if details else split_legacy(patient.allergies),
        "medication_doses":details.medication_doses if details else {},
        "medication_conditions": medication_conditions.conditions if medication_conditions else {}}

def serialize_user(db,user):
    application = db.get(AnalystApplication, user.id) if user.role == "analyst" else None
    analyst = {
        **(application.details or {} if application else {}),
        "profession": user.profession,
        "license_number": user.license_number,
        "institution": user.institution,
    } if user.role == "analyst" else None
    return {"id":user.id,"name":user.name,"email":user.email,"role":user.role,"status":user.status,
        "created_at":user.created_at.isoformat() if user.created_at else None,
        "profile":profile_data(db,user.id) if user.role=="patient" else None,
        **({"analyst_profile": analyst} if analyst is not None else {})}
