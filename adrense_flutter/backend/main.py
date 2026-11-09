from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from DAO.DatabaseConnection import Base, engine, SessionLocal
from Models.User import User
from Models.Patient import Patient
from Models.AuthState import AuthState, EmailChallenge
from API.auth_routes import router as auth_router
from Business.AuthService import seed_demo_admin
from API.admin_routes import router as admin_router
from API.profile_routes import router as profile_router
from Models.AnalystApplication import AnalystApplication, AnalystDocument
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException
import asyncio
from contextlib import suppress
from Business.ReviewNotifications import review_notification_worker


class RegistrationBodyLimit:
    def __init__(self, app):
        self.app = app

    async def __call__(self, scope, receive, send):
        if scope["type"] != "http" or scope.get("path") != "/api/auth/register":
            return await self.app(scope, receive, send)
        limit = 22 * 1024 * 1024
        headers = dict(scope.get("headers", []))
        try:
            declared = int(headers.get(b"content-length", b"0"))
        except ValueError:
            declared = limit + 1
        if declared > limit:
            return await JSONResponse({"detail": "Registration exceeds the document upload limit"}, status_code=413)(scope, receive, send)
        total = 0

        async def limited_receive():
            nonlocal total
            message = await receive()
            total += len(message.get("body", b""))
            if total > limit:
                raise HTTPException(413, "Registration exceeds the document upload limit")
            return message

        return await self.app(scope, limited_receive, send)

app = FastAPI(title="ADRense Authentication API", version="1.0")
app.add_middleware(RegistrationBodyLimit)
app.add_middleware(CORSMiddleware, allow_origins=[], allow_origin_regex=r"https?://(localhost|127\.0\.0\.1)(:\d+)?", allow_credentials=False, allow_methods=["GET", "POST", "PATCH", "OPTIONS"], allow_headers=["Authorization", "Content-Type"])
@app.on_event("startup")
async def create_tables():
    Base.metadata.create_all(bind=engine)
    with SessionLocal() as db:
        seed_demo_admin(db)
    app.state.review_mail_worker = asyncio.create_task(review_notification_worker())


@app.on_event("shutdown")
async def stop_review_mail_worker():
    task = getattr(app.state, "review_mail_worker", None)
    if task:
        task.cancel()
        with suppress(asyncio.CancelledError):
            await task
app.include_router(auth_router)
app.include_router(admin_router)
app.include_router(profile_router)


@app.exception_handler(RequestValidationError)
async def validation_error(request, error):
    # Never echo passwords or base64 documents in validation responses.
    return JSONResponse(status_code=422, content={"detail": [
        {"loc": list(e["loc"]), "msg": e["msg"], "type": e["type"]} for e in error.errors()]})
@app.get("/health")
def health():
    return {"status": "ok"}
