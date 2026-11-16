from datetime import datetime, date, timedelta
from zoneinfo import ZoneInfo
from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks, Query
from sqlalchemy import func, case
from fastapi.responses import Response
from sqlalchemy.orm import Session
from DAO.DatabaseConnection import get_db
from Models.User import User
from Models.AuthState import AuthState
from Models.AnalystApplication import AnalystApplication, AnalystDocument
from Business.AccessControl import require_admin
from DTO.AnalystDTO import AnalystReviewDTO
from Models.ReviewNotification import ReviewNotification
from Business.ReviewNotifications import deliver_review_notification
from pydantic import BaseModel
from typing import Literal

router = APIRouter(prefix="/api/admin", tags=["Analyst verification"])


@router.get("/analysts")
def analysts(admin: User = Depends(require_admin), db: Session = Depends(get_db)):
    users = db.query(User).filter(User.role == "analyst").order_by(User.created_at.desc()).all()
    applications = {a.user_id: a for a in db.query(AnalystApplication).all()}
    states = {s.user_id: s.is_verified for s in db.query(AuthState).all()}
    documents = {}
    for document in db.query(AnalystDocument).all():
        documents.setdefault(document.user_id, []).append({"id": document.id, "kind": document.kind,
            "filename": document.filename, "media_type": document.media_type, "size": document.size})
    return {"applications": [{"id": user.id, "name": user.name, "email": user.email,
        "profession": user.profession or "", "license_number": user.license_number or "",
        "institution": user.institution or "", "status": user.status,
        "email_verified": states.get(user.id, False), "created_at": user.created_at.isoformat(),
        "details": applications[user.id].details if user.id in applications else {},
        "review_reason": applications[user.id].review_reason if user.id in applications else None,
        "documents": documents.get(user.id, [])} for user in users]}


@router.get("/documents/{document_id}")
def document_content(document_id: int, admin: User = Depends(require_admin), db: Session = Depends(get_db)):
    document = db.get(AnalystDocument, document_id)
    if document is None:
        raise HTTPException(404, "Document not found")
    return Response(content=document.content, media_type=document.media_type, headers={
        "Cache-Control": "no-store", "X-Content-Type-Options": "nosniff",
        "Content-Disposition": "attachment"})


@router.post("/analysts/{user_id}/review")
def review_analyst(user_id: int, data: AnalystReviewDTO, background_tasks: BackgroundTasks, admin: User = Depends(require_admin), db: Session = Depends(get_db)):
    user = db.query(User).filter_by(id=user_id, role="analyst").with_for_update().first()
    application = db.get(AnalystApplication, user_id)
    if not user or not application:
        raise HTTPException(404, "Analyst application not found")
    if user.status != "pending":
        raise HTTPException(409, "This application has already been reviewed. Refresh the list.")
    if data.decision == "approve":
        kinds = {d.kind for d in db.query(AnalystDocument).filter_by(user_id=user_id)}
        if not {"license", "degree"}.issubset(kinds):
            raise HTTPException(400, "License and degree documents are required before approval")
        if date.fromisoformat(application.details["license_expiry"]) <= date.today():
            raise HTTPException(400, "The professional license has expired")
    user.status = "active" if data.decision == "approve" else "rejected"
    state = db.get(AuthState, user_id)
    if state:
        state.session_version += 1
    application.reviewed_by = admin.id
    application.reviewed_at = datetime.utcnow()
    application.review_reason = data.reason.strip()
    notification = ReviewNotification(user_id=user.id, email=user.email, name=user.name,
                                      decision=data.decision, reason=data.reason.strip())
    db.add(notification)
    db.commit()
    background_tasks.add_task(deliver_review_notification, notification.id)
    return {"message": "Application approved" if data.decision == "approve" else "Application rejected", "status": user.status}


def user_metadata(user, verified):
    return {"id": user.id, "name": user.name, "email": user.email, "role": user.role,
            "status": user.status, "email_verified": bool(verified), "created_at": user.created_at.isoformat()}


@router.get("/users")
def list_users(admin: User = Depends(require_admin), db: Session = Depends(get_db)):
    # Deliberately select account metadata only, never the health profile or password hash.
    rows = db.query(User.id, User.name, User.email, User.role, User.status, User.created_at, AuthState.is_verified).outerjoin(
        AuthState, AuthState.user_id == User.id).filter(User.role.in_(["patient", "analyst"])).order_by(User.created_at.desc(), User.id.desc()).all()
    return {"users": [user_metadata(row, row.is_verified) for row in rows]}


@router.get("/registrations")
def registrations(days: int = Query(default=30), admin: User = Depends(require_admin), db: Session = Depends(get_db)):
    if days not in (7, 30, 90, 365):
        raise HTTPException(422, "Choose 7, 30, 90, or 365 days")
    local_now = datetime.now(ZoneInfo("Asia/Karachi"))
    today = local_now.date()
    start = today - timedelta(days=days-1)
    start_utc = datetime.combine(start, datetime.min.time()) - timedelta(hours=5)
    end_utc = datetime.combine(today+timedelta(days=1), datetime.min.time()) - timedelta(hours=5)
    rows = db.query(User.role, User.created_at).filter(User.role.in_(["patient", "analyst"]),
        User.created_at >= start_utc, User.created_at < end_utc).all()
    # Daily buckets for 7/30 days, weekly for 90 days, monthly for the year view.
    def bucket(day):
        if days == 365:
            return max(start, day.replace(day=1))
        if days == 90:
            return start + timedelta(days=((day-start).days//7)*7)
        return day
    series = {}
    for offset in range(days):
        key = bucket(start+timedelta(days=offset))
        series.setdefault(key, {"date": key.isoformat(), "general_users": 0, "analysts": 0})
    for role, created_at in rows:
        key = bucket((created_at+timedelta(hours=5)).date())
        series[key]["general_users" if role == "patient" else "analysts"] += 1
    summary = db.query(
        func.count(User.id).label("total"),
        func.sum(case((User.role == "patient", 1), else_=0)).label("general_users"),
        func.sum(case((User.role == "analyst", 1), else_=0)).label("analysts"),
        func.sum(case(((User.status == "active") & (AuthState.is_verified.is_(True)), 1), else_=0)).label("active"),
    ).outerjoin(AuthState, AuthState.user_id == User.id).filter(User.role.in_(["patient", "analyst"])).one()
    return {"days": days, "timezone": "Asia/Karachi", "buckets": list(series.values()),
            "summary": {key: int(getattr(summary, key) or 0) for key in ("total", "general_users", "analysts", "active")}}


class UserStatusDTO(BaseModel):
    action: Literal["restrict", "restore"]


@router.post("/users/{user_id}/status")
def change_user_status(user_id: int, data: UserStatusDTO, admin: User = Depends(require_admin), db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id, User.role.in_(["patient", "analyst"])).with_for_update().first()
    if not user:
        raise HTTPException(404, "User not found")
    expected = "active" if data.action == "restrict" else "restricted"
    if user.status != expected:
        raise HTTPException(409, "This status change is not available. Refresh the account list.")
    user.status = "restricted" if data.action == "restrict" else "active"
    state = db.get(AuthState, user_id)
    if state:
        state.session_version += 1
    db.commit()
    return {"message": "Account restricted" if data.action == "restrict" else "Account restored", "status": user.status}
