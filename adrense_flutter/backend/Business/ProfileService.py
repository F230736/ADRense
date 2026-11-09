from Models.Patient import Patient
from Models.ProfileData import ProfileData

def split_legacy(value):
    return [part.strip() for part in (value or "").split(",") if part.strip()]

def profile_data(db,user_id):
    patient=db.query(Patient).filter_by(user_id=user_id).first()
    details=db.get(ProfileData,user_id)
    if not patient:return None
    return {"age_group":patient.age_group,"gender":patient.gender,"weight_range":patient.weight_range,
        "medical_conditions":details.medical_conditions if details else split_legacy(patient.medical_conditions),
        "current_medications":details.current_medications if details else split_legacy(patient.current_medications),
        "allergies":details.allergies if details else split_legacy(patient.allergies),
        "medication_doses":details.medication_doses if details else {}}

def serialize_user(db,user):
    return {"id":user.id,"name":user.name,"email":user.email,"role":user.role,"status":user.status,
        "created_at":user.created_at.isoformat() if user.created_at else None,
        "profile":profile_data(db,user.id) if user.role=="patient" else None}
