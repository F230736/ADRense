from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from sqlalchemy.orm import Session

from Business.AccessControl import require_admin
from Business.DatasetService import import_catalog, list_imports, preview_catalog
from DAO.DatabaseConnection import get_db
from Models.DatasetImport import DatasetImport, DatasetImportPreview
from Models.User import User


router = APIRouter(
    prefix="/api/admin/datasets",
    tags=["Datasets"],
    dependencies=[Depends(require_admin)],
)

MAX_CSV_BYTES = 1024 * 1024


def read_csv(file: UploadFile) -> tuple[str, bytes]:
    filename = file.filename or ""
    if not filename.lower().endswith(".csv"):
        raise HTTPException(status_code=400, detail="Upload a .csv file.")

    content = file.file.read(MAX_CSV_BYTES + 1)
    if len(content) > MAX_CSV_BYTES:
        raise HTTPException(status_code=413, detail="CSV must be 1 MB or smaller.")

    return filename, content


@router.post("/preview")
def preview_dataset(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
):
    filename, content = read_csv(file)
    try:
        return {"filename": filename, **preview_catalog(db, content)}
    except ValueError as error:
        raise HTTPException(status_code=400, detail=str(error)) from error


@router.post("/import", status_code=201)
def confirm_import(
    file: UploadFile = File(...),
    admin: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    filename, content = read_csv(file)
    try:
        return import_catalog(db, content, filename, admin.id)
    except ValueError as error:
        raise HTTPException(status_code=400, detail=str(error)) from error


@router.get("/history")
def dataset_history(db: Session = Depends(get_db)):
    return {"imports": list_imports(db)}


@router.get("/{import_id}/preview")
def preview_import(import_id: int, db: Session = Depends(get_db)):
    record = db.get(DatasetImport, import_id)
    if record is None:
        raise HTTPException(404, "Dataset import not found.")
    preview = db.get(DatasetImportPreview, import_id)
    return {"rows": preview.rows if preview is not None else None, "added_rows": record.added_rows}