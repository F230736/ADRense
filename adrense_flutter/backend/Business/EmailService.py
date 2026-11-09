"""SMTP delivery with an inline ADRense logo; never log credentials or codes."""
import os
import ssl
import smtplib
from email.message import EmailMessage
from pathlib import Path
from html import escape

def send_code(email, code, purpose):
    host = os.getenv("SMTP_HOST")
    sender = os.getenv("SMTP_FROM")
    if not host or not sender:
        raise RuntimeError("Configure SMTP_HOST and SMTP_FROM to deliver authentication emails")
    title = {"verify":"Verify your email address", "reset":"Reset your password", "email-change":"Verify your new email address"}[purpose]
    msg = EmailMessage()
    msg["Subject"] = f"ADRense — {title}"
    msg["From"] = sender
    msg["To"] = email
    msg.set_content(f"{title}\nYour ADRense code is {code}. It expires in 10 minutes and can only be used once. "
                    "Enter it in the ADRense app. If you did not request this, ignore this email.")
    msg.add_alternative(f"""<html><body style="margin:0;background:#f3f6f8;font-family:Arial,sans-serif;color:#172638">
      <div style="max-width:520px;margin:32px auto;padding:32px;background:white;border-radius:16px">
      <img src="cid:adrense-logo" width="64" height="64" alt="ADRense logo"><h2>ADRense</h2>
      <h1 style="font-size:24px">{escape(title)}</h1><p>Enter this one-time code in the ADRense app:</p>
      <div style="background:#e4f8f5;padding:20px;font-size:32px;letter-spacing:8px;font-weight:bold">{code}</div>
      <p>This code expires in <b>10 minutes</b>. Never share it with anyone.</p>
      <p style="color:#637184">If you did not request this email, you can safely ignore it.</p></div></body></html>""", subtype="html")
    logo = Path(__file__).resolve().parents[2] / "assets" / "native_splash.png"
    msg.get_payload()[-1].add_related(logo.read_bytes(), maintype="image", subtype="png", cid="<adrense-logo>")
    deliver_message(msg)


def send_review_result(email, name, decision, reason=""):
    approved = decision == "approve"
    title = "Your analyst account has been approved" if approved else "Your analyst application was not approved"
    explanation = ("An ADRense administrator has approved your professional credentials. You can now sign in as an analyst. "
                   "If you have not verified your email yet, please complete email verification first.") if approved else (
                   "An ADRense administrator has reviewed and rejected your analyst application. Analyst access has not been activated.")
    msg = EmailMessage()
    msg["Subject"] = f"ADRense — {'Account approved' if approved else 'Application rejected'}"
    msg["From"] = os.environ["SMTP_FROM"]
    msg["To"] = email
    notes = f"\nAdministrator notes: {reason}" if reason else ""
    msg.set_content(f"Hello {name},\n\n{title}\n\n{explanation}{notes}\n\nThe ADRense team")
    color = "#007d77" if approved else "#b42346"
    notes_html = f'<div style="padding:16px;background:#f3f6f8;border-radius:10px"><b>Administrator notes</b><p>{escape(reason).replace(chr(10), "<br>")}</p></div>' if reason else ""
    msg.add_alternative(f'''<html><body style="margin:0;background:#f3f6f8;font-family:Arial,sans-serif;color:#172638">
      <div style="max-width:520px;margin:32px auto;padding:32px;background:white;border-radius:16px">
      <img src="cid:adrense-logo" width="64" height="64" alt="ADRense logo"><h2>ADRense</h2>
      <p>Hello {escape(name)},</p><h1 style="font-size:24px;color:{color}">{title}</h1>
      <p style="line-height:1.7">{explanation}</p>{notes_html}<p>The ADRense team</p></div></body></html>''', subtype="html")
    logo = Path(__file__).resolve().parents[2] / "assets" / "native_splash.png"
    msg.get_payload()[-1].add_related(logo.read_bytes(), maintype="image", subtype="png", cid="<adrense-logo>")
    deliver_message(msg)


def deliver_message(msg):
    host = os.getenv("SMTP_HOST")
    if not host or not os.getenv("SMTP_FROM"):
        raise RuntimeError("SMTP_HOST and SMTP_FROM must be configured")
    use_ssl = os.getenv("SMTP_SSL", "false").lower() == "true"
    client = smtplib.SMTP_SSL if use_ssl else smtplib.SMTP
    with client(host, int(os.getenv("SMTP_PORT", "465" if use_ssl else "587")), timeout=15) as smtp:
        if not use_ssl and os.getenv("SMTP_STARTTLS", "true").lower() == "true":
            smtp.starttls(context=ssl.create_default_context())
        if os.getenv("SMTP_USERNAME"):
            smtp.login(os.environ["SMTP_USERNAME"], os.environ["SMTP_PASSWORD"])
        smtp.send_message(msg)
