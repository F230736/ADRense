import argparse
import csv
import hashlib
import io
import re
import shutil
import sys
import tempfile
import unicodedata
import zipfile
from pathlib import Path
from xml.etree import ElementTree as ET

PROJECT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(PROJECT / "backend"))

from sqlalchemy import delete, insert, text
from DAO.DatabaseConnection import SessionLocal, engine
from Models.Medicine import Medicine


FIELDS = (
    "ingredients", "therapeutic_class", "action_class", "chemical_class",
    "uses", "cas_number", "source_status",
)
MID_FIELDS = {
    "NAME": "name", "CONTAINS": "ingredients", "USES": "uses",
    "CHEMICAL_CLASS": "chemical_class", "THERAPEUTIC_CLASS": "therapeutic_class",
    "ACTION_CLASS": "action_class",
}
XML = "{http://schemas.openxmlformats.org/spreadsheetml/2006/main}"
BATCH_SIZE = 2000


def clean(value):
    value = " ".join(unicodedata.normalize("NFKC", value or "").split())
    return None if value.casefold() in {"", "-", "nan", "n/a", "na", "none", "null", "not available"} else value


def medicine(source, name, identity=None, **details):
    name = clean(name)
    if not name:
        return None
    fields = {key: clean(details.get(key)) for key in FIELDS}
    name_key = name.casefold()
    identifier = hashlib.sha256(
        "\0".join((source, name_key, (clean(identity) or "").casefold())).encode()
    ).hexdigest()
    search_text = " ".join(
        value.casefold() for value in (name, *(fields[key] for key in FIELDS[:4])) if value
    )
    return dict(id=identifier, name=name, name_key=name_key, source=source, search_text=search_text, **fields)


def mid_records(path):
    with zipfile.ZipFile(path) as source, tempfile.TemporaryFile() as workbook:
        with source.open("MID Medicines Information Dataset/MID.xlsx") as compressed:
            shutil.copyfileobj(compressed, workbook)
        with zipfile.ZipFile(workbook) as xlsx, xlsx.open("xl/worksheets/sheet1.xml") as sheet:
            columns = None
            sheet_data = None
            for event, element in ET.iterparse(sheet, events=("start", "end")):
                if event == "start" and element.tag == XML + "sheetData":
                    sheet_data = element
                if event != "end" or element.tag != XML + "row":
                    continue
                values = {
                    cell.attrib["r"].rstrip("0123456789"):
                    "".join(node.text or "" for node in cell.iter(XML + "t"))
                    for cell in element
                }
                if columns is None:
                    columns = {key: MID_FIELDS[value] for key, value in values.items() if value in MID_FIELDS}
                    if set(columns.values()) != set(MID_FIELDS.values()):
                        raise ValueError("MID workbook headers do not match the expected medicine columns")
                else:
                    row = {field: values.get(column) for column, field in columns.items()}
                    yield medicine("MID", identity=row["ingredients"], **row)
                sheet_data.remove(element)
            if columns is None:
                raise ValueError("MID workbook has no data rows")


def sdf_records(path):
    properties = {}
    field = None
    with path.open(encoding="utf-8-sig", errors="replace") as source:
        for line in source:
            line = line.strip()
            if line == "$$$$":
                yield medicine(
                    "e-Drug3D", properties.get("name"), identity=properties.get("cas"),
                    cas_number=properties.get("cas"), source_status=properties.get("status"),
                )
                properties.clear()
                field = None
            elif match := re.match(r"^>\s*<([^>]+)>", line):
                field = match.group(1)
            elif field and line:
                properties[field] = line
                field = None


def review_records(path):
    with zipfile.ZipFile(path) as source:
        for file, name_column in (
            ("Database/clean_drugs_data.csv", "drug_name"),
            ("Database/drugsComTrain_raw.csv", "drugName"),
        ):
            with source.open(file) as data:
                rows = csv.DictReader(io.TextIOWrapper(data, encoding="utf-8-sig", newline=""))
                if name_column not in (rows.fieldnames or ()):
                    raise ValueError(f"Missing {name_column} in {file}")
                for row in rows:
                    drug_class = clean(row.get("drug_class"))
                    yield medicine(
                        "Drug Reviews", row[name_column],
                        therapeutic_class=drug_class if drug_class and drug_class.casefold() != "general" else None,
                    )


def import_catalog(sources):
    Medicine.__table__.create(engine, checkfirst=True)
    with SessionLocal.begin() as db:
        db.execute(text("SELECT pg_advisory_xact_lock(823729431)"))
        db.execute(delete(Medicine))
        for name, records in sources:
            batch = []
            seen = set()
            for row in records:
                if row is None or row["id"] in seen:
                    continue
                seen.add(row["id"])
                batch.append(row)
                if len(batch) == BATCH_SIZE:
                    db.execute(insert(Medicine), batch)
                    batch.clear()
            if batch:
                db.execute(insert(Medicine), batch)
            if not seen:
                raise ValueError(f"No medicines found in {name}")
            print(f"{name}: {len(seen):,} catalog entries", flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--mid", type=Path, required=True)
    parser.add_argument("--sdf", type=Path, required=True)
    parser.add_argument("--reviews", type=Path, required=True)
    args = parser.parse_args()
    import_catalog([
        ("MID", mid_records(args.mid)),
        ("e-Drug3D", sdf_records(args.sdf)),
        ("Drug Reviews", review_records(args.reviews)),
    ])


if __name__ == "__main__":
    main()
