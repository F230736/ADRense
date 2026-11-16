import base64
import binascii
import io
import re
import warnings
from datetime import date, datetime
from pathlib import PurePosixPath
from typing import Literal
from PIL import Image
from pypdf import PdfReader
from pydantic import BaseModel, Field, EmailStr, model_validator, field_validator

MAX_DOCUMENT_BYTES = 5 * 1024 * 1024


def validate_document(filename, encoded):
    filename = PurePosixPath(filename.replace("\\", "/")).name
    if not filename or any(ord(c) < 32 for c in filename):
        raise ValueError("Invalid document filename")
    extension = filename.rsplit(".", 1)[-1].lower()
    if extension not in {"pdf", "jpg", "jpeg", "png"}:
        raise ValueError("Documents must be PDF, JPG, JPEG, or PNG")
    try:
        content = base64.b64decode(encoded, validate=True)
    except (binascii.Error, ValueError):
        raise ValueError("Invalid document encoding")
    if not content or len(content) > MAX_DOCUMENT_BYTES:
        raise ValueError("Each document must be nonempty and at most 5 MB")
    try:
        if extension == "pdf":
            if not content.startswith(b"%PDF-"):
                raise ValueError("Invalid PDF")
            reader = PdfReader(io.BytesIO(content), strict=True)
            if reader.is_encrypted or not len(reader.pages):
                raise ValueError("PDF must be readable and not password-protected")
            # Interactive actions and attachments are unnecessary for credential review.
            root = reader.trailer["/Root"]
            if any(key in root for key in ("/OpenAction", "/AA")):
                raise ValueError("Interactive PDF files are not accepted")
            names = root.get("/Names", {})
            if hasattr(names, "get_object"):
                names = names.get_object()
            if any(key in names for key in ("/JavaScript", "/EmbeddedFiles")):
                raise ValueError("PDF scripts and attachments are not accepted")
            for page in reader.pages:
                if page.get("/AA"):
                    raise ValueError("Upload a PDF without automatic actions")
            media_type = "application/pdf"
        else:
            with warnings.catch_warnings():
                warnings.simplefilter("error", Image.DecompressionBombWarning)
                with Image.open(io.BytesIO(content)) as image:
                    expected = "PNG" if extension == "png" else "JPEG"
                    if image.format != expected or image.width * image.height > 25_000_000:
                        raise ValueError("Image format does not match its extension or dimensions are too large")
                    image.verify()
            media_type = "image/png" if extension == "png" else "image/jpeg"
    except Exception as error:
        raise ValueError("Upload a valid, readable PDF, JPG, or PNG (no interactive or encrypted PDFs)") from error
    return filename, media_type, content


class AnalystDocumentDTO(BaseModel):
    kind: Literal["license", "degree", "id_card"]
    filename: str = Field(min_length=1, max_length=200)
    content_base64: str = Field(min_length=4, max_length=6990508)

    @model_validator(mode="after")
    def valid_document(self):
        validate_document(self.filename, self.content_base64)
        return self


class AnalystDetailsDTO(BaseModel):
    professional_email: EmailStr
    phone: str = Field(pattern=r"^\+[1-9][0-9]{6,14}$")
    country: str = Field(min_length=2, max_length=100)
    country_code: str = Field(pattern=r"^[A-Z]{2}$")
    professional_role: str = Field(min_length=2, max_length=100)
    qualification: str = Field(min_length=2, max_length=200)
    graduation_year: int = Field(ge=1950)
    issuing_authority: str = Field(min_length=3, max_length=200)
    license_expiry: date

    @field_validator("license_expiry", mode="before")
    @classmethod
    def parse_expiry(cls, value):
        if isinstance(value, str) and re.fullmatch(r"\d{2}/\d{2}/\d{4}", value):
            return datetime.strptime(value, "%m/%d/%Y").date()
        return value

    @model_validator(mode="after")
    def valid_dates(self):
        if self.license_expiry <= date.today():
            raise ValueError("The license must not be expired")
        if self.graduation_year > date.today().year:
            raise ValueError("Graduation year cannot be in the future")
        return self


class AnalystReviewDTO(BaseModel):
    decision: Literal["approve", "reject"]
    reason: str = Field(default="", max_length=1000)

    @model_validator(mode="after")
    def rejection_reason(self):
        if self.decision == "reject" and len(self.reason.strip()) < 3:
            raise ValueError("Enter a reason for rejection")
        return self
