import os
import ssl
import smtplib
from pathlib import Path
from dotenv import load_dotenv
load_dotenv(Path(__file__).resolve().parent / '.env', override=True)
try:
    with smtplib.SMTP(os.environ['SMTP_HOST'], int(os.environ['SMTP_PORT']), timeout=20) as smtp:
        smtp.ehlo()
        smtp.starttls(context=ssl.create_default_context())
        smtp.ehlo()
        smtp.login(os.environ['SMTP_USERNAME'], os.environ['SMTP_PASSWORD'])
        print('SMTP STARTTLS and authentication succeeded.')
except smtplib.SMTPResponseException as error:
    print('SMTP authentication failed. Status:', error.smtp_code)
except Exception as error:
    print('SMTP connection failed:', type(error).__name__)
