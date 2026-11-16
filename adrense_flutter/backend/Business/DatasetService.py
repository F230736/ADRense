import csv
from io import StringIO

from sqlalchemy import select, text
from sqlalchemy.orm import Session

from Models.AdverseReaction import AdverseReaction
from Models.DatasetImport import DatasetImport, DatasetImportPreview
from Models.Drug import Drug


CATALOG_COLUMNS = {"drug_name", "drug_class", "adverse_reaction"}


def inspect_catalog(db: Session, content: bytes) -> tuple[dict, list]:
    try:
        csv_text = content.decode("utf-8-sig")
    except UnicodeDecodeError as error:
        raise ValueError("Save the file as a UTF-8 CSV and upload it again.") from error

    reader = csv.DictReader(StringIO(csv_text, newline=""), strict=True)

    try:
        headers = reader.fieldnames or []
        if len(headers) != len(CATALOG_COLUMNS) or set(headers) != CATALOG_COLUMNS:
            raise ValueError(
                "CSV must have these columns: drug_name, drug_class, adverse_reaction."
            )

        existing_rows = db.execute(
            select(Drug.name, AdverseReaction.reaction_name).join(
                AdverseReaction, AdverseReaction.drug_id == Drug.id
            )
        )
        seen = {
            (name.strip().casefold(), reaction.strip().casefold())
            for name, reaction in existing_rows
        }

        total_rows = 0
        duplicate_rows = 0
        invalid_rows = 0
        errors = []
        new_entries = []

        for row in reader:
            total_rows += 1
            name = (row.get("drug_name") or "").strip()
            drug_class = (row.get("drug_class") or "").strip()
            reaction = (row.get("adverse_reaction") or "").strip()

            if (
                None in row
                or any(row[column] is None for column in CATALOG_COLUMNS)
                or not name
                or not reaction
            ):
                invalid_rows += 1
                if len(errors) < 10:
                    errors.append({
                        "line": reader.line_num,
                        "message": (
                            "Use three columns and fill in drug_name "
                            "and adverse_reaction."
                        ),
                    })
                continue

            key = (name.casefold(), reaction.casefold())
            if key in seen:
                duplicate_rows += 1
                continue

            seen.add(key)
            new_entries.append((name, drug_class, reaction))

        if total_rows == 0:
            raise ValueError("The CSV has a header but no data rows.")

    except csv.Error as error:
        raise ValueError(f"Invalid CSV format near line {reader.line_num}.") from error

    return {
        "total_rows": total_rows,
        "new_rows": len(new_entries),
        "duplicate_rows": duplicate_rows,
        "invalid_rows": invalid_rows,
        "errors": errors,
    }, new_entries


def preview_catalog(db: Session, content: bytes) -> dict:
    summary, _ = inspect_catalog(db, content)
    return summary


def import_catalog(
    db: Session, content: bytes, filename: str, admin_id: int
) -> dict:
    # Serialize catalog writes so two imports cannot add the same pair.
    if db.get_bind().dialect.name == "postgresql":
        db.execute(text(
            "LOCK TABLE drugs, adverse_reactions IN SHARE ROW EXCLUSIVE MODE"
        ))

    summary, new_entries = inspect_catalog(db, content)
    if summary["invalid_rows"] == summary["total_rows"]:
        raise ValueError("The CSV has no valid data rows.")

    drugs = {}
    for drug in db.scalars(select(Drug).order_by(Drug.id)):
        drugs.setdefault(drug.name.strip().casefold(), drug)

    for name, drug_class, reaction in new_entries:
        key = name.casefold()
        drug = drugs.get(key)

        if drug is None:
            drug = Drug(name=name, drug_class=drug_class or None)
            db.add(drug)
            db.flush()
            drugs[key] = drug

        db.add(AdverseReaction(drug_id=drug.id, reaction_name=reaction))

    record = DatasetImport(
        filename=filename,
        imported_by=admin_id,
        total_rows=summary["total_rows"],
        added_rows=summary["new_rows"],
        duplicate_rows=summary["duplicate_rows"],
        invalid_rows=summary["invalid_rows"],
    )
    db.add(record)
    db.flush()
    db.add(DatasetImportPreview(import_id=record.id, rows=[
        {"drug_name": name, "drug_class": drug_class, "adverse_reaction": reaction}
        for name, drug_class, reaction in new_entries[:25]
    ]))
    result = {"import_id": record.id, "filename": filename, **summary}
    db.commit()
    return result


def list_imports(db: Session) -> list[dict]:
    records = db.scalars(
        select(DatasetImport).order_by(DatasetImport.id.desc())
    )
    return [
        {
            "id": record.id,
            "filename": record.filename,
            "imported_by": record.imported_by,
            "total_rows": record.total_rows,
            "added_rows": record.added_rows,
            "duplicate_rows": record.duplicate_rows,
            "invalid_rows": record.invalid_rows,
            "created_at": record.created_at.isoformat(),
        }
        for record in records
    ]