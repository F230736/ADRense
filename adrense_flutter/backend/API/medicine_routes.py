import re
import unicodedata

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import case, func, select
from sqlalchemy.orm import Session

from Business.AccessControl import current_user
from DAO.DatabaseConnection import get_db
from Models.AdverseReaction import AdverseReaction
from Models.Drug import Drug
from Models.Medicine import Medicine

router = APIRouter(
    prefix="/api/medicines", tags=["Medicines"], dependencies=[Depends(current_user)]
)


@router.get("")
def search_medicines(
    q: str = Query("", max_length=150),
    limit: int = Query(25, ge=1, le=50),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db),
):
    query = " ".join(unicodedata.normalize("NFKC", q).casefold().split())
    statement = select(
        Medicine.id, Medicine.name, Medicine.source, Medicine.ingredients,
        Medicine.action_class, Medicine.therapeutic_class,
    )
    order = [Medicine.name_key, Medicine.id]
    if query:
        statement = statement.where(Medicine.search_text.contains(query, autoescape=True))
        order.insert(0, case(
            (Medicine.name_key == query, 0),
            (Medicine.name_key.startswith(query, autoescape=True), 1),
            else_=2,
        ))
    rows = db.execute(statement.order_by(*order).offset(offset).limit(limit + 1)).mappings().all()
    return {"medicines": [dict(row) for row in rows[:limit]], "has_more": len(rows) > limit}


@router.get("/general-adrs")
def general_adrs(
    name: str = Query("", max_length=150),
    medicine_id: str | None = Query(None, max_length=64),
    db: Session = Depends(get_db),
):
    if medicine_id is not None:
        medicine = db.get(Medicine, medicine_id)
        if medicine is None:
            raise HTTPException(404, "Medicine not found")
        name = medicine.name
        ingredients = (medicine.ingredients or "").split("+")
    else:
        ingredients = []

    # Match explicit names only, never arbitrary substrings of other drugs.
    names = {name.strip().lower()}
    for ingredient in ingredients:
        names.add(re.sub(r"\s*\(\s*\d[^()]*\)\s*$", "", ingredient).strip().lower())
    names.discard("")
    if not names:
        return {"reactions": []}

    rows = db.execute(
        select(Drug.name, AdverseReaction.reaction_name)
        .join(AdverseReaction, AdverseReaction.drug_id == Drug.id)
        .where(func.lower(Drug.name).in_(names))
        .order_by(func.lower(Drug.name), func.lower(AdverseReaction.reaction_name))
    )
    reactions = {}
    for drug_name, reaction in rows:
        reactions.setdefault(
            (drug_name.casefold(), reaction.casefold()),
            {"drug_name": drug_name, "reaction": reaction},
        )
    return {"reactions": list(reactions.values())}


@router.get("/{medicine_id}")
def medicine_details(medicine_id: str, db: Session = Depends(get_db)):
    medicine = db.get(Medicine, medicine_id)
    if medicine is None:
        raise HTTPException(404, "Medicine not found")
    fields = (
        "id", "name", "source", "ingredients", "therapeutic_class",
        "action_class", "chemical_class", "uses", "cas_number", "source_status",
    )
    return {field: getattr(medicine, field) for field in fields}
