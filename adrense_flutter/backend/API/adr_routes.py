from fastapi import APIRouter, Depends
from pydantic import BaseModel, ConfigDict, Field
from sqlalchemy.orm import Session

from Business.AccessControl import require_patient
from DAO.DatabaseConnection import get_db
from Models.AdverseReaction import ADRReport
from Models.User import User


router = APIRouter(prefix="/api/adr", tags=["ADR reports"])


class ADRSubmission(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True)
    raw_text: str = Field(min_length=10, max_length=10000)


@router.post("/submit", status_code=201)
def submit_report(
    data: ADRSubmission,
    db: Session = Depends(get_db),
    patient: User = Depends(require_patient),
):
    report = ADRReport(user_id=patient.id, raw_text=data.raw_text, status="pending")
    db.add(report)
    db.flush()
    result = {"report_id": report.id, "status": report.status}
    db.commit()
    return result
