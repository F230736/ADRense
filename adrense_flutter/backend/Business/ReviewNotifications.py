import asyncio
import logging
from datetime import datetime, timedelta
from DAO.DatabaseConnection import SessionLocal
from Models.ReviewNotification import ReviewNotification
from Business.EmailService import send_review_result


def deliver_review_notification(notification_id):
    with SessionLocal() as db:
        job = db.query(ReviewNotification).filter_by(id=notification_id).with_for_update(skip_locked=True).first()
        if not job or job.sent_at or job.next_attempt_at > datetime.utcnow():
            return
        job.attempts += 1
        try:
            send_review_result(job.email, job.name, job.decision, job.reason)
            job.sent_at = datetime.utcnow()
        except Exception:
            job.next_attempt_at = datetime.utcnow() + timedelta(seconds=min(3600, 30 * 2 ** min(job.attempts, 7)))
            logging.getLogger(__name__).error("Analyst decision email delivery failed; queued for retry")
        db.commit()


def deliver_due_notifications():
    with SessionLocal() as db:
        ids = [row.id for row in db.query(ReviewNotification.id).filter(
            ReviewNotification.sent_at.is_(None), ReviewNotification.next_attempt_at <= datetime.utcnow()
        ).order_by(ReviewNotification.id).limit(20)]
    for notification_id in ids:
        deliver_review_notification(notification_id)


async def review_notification_worker():
    while True:
        try:
            await asyncio.to_thread(deliver_due_notifications)
        except Exception:
            logging.getLogger(__name__).error("Could not process pending analyst decision emails")
        await asyncio.sleep(30)
