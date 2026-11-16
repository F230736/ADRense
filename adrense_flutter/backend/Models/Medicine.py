from sqlalchemy import Column, Index, String, Text

from DAO.DatabaseConnection import Base


class Medicine(Base):
    __tablename__ = "medicines"
    __table_args__ = (Index("ix_medicines_name_order", "name_key", "id"),)

    id = Column(String(64), primary_key=True)
    name = Column(Text, nullable=False)
    name_key = Column(Text, nullable=False)
    search_text = Column(Text, nullable=False)
    source = Column(String(32), nullable=False)
    ingredients = Column(Text)
    therapeutic_class = Column(Text)
    action_class = Column(Text)
    chemical_class = Column(Text)
    uses = Column(Text)
    cas_number = Column(Text)
    source_status = Column(Text)
