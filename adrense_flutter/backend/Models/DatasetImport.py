from datetime import datetime, timezone

from sqlalchemy import JSON, Column, DateTime, ForeignKey, Integer, String

from DAO.DatabaseConnection import Base


class DatasetImportPreview(Base):
    __tablename__ = "dataset_import_previews"

    import_id = Column(Integer, ForeignKey("dataset_imports.id", ondelete="CASCADE"), primary_key=True)
    rows = Column(JSON, nullable=False)


class DatasetImport(Base):
    __tablename__ = "dataset_imports"

    id = Column(Integer, primary_key=True)
    filename = Column(String, nullable=False)
    imported_by = Column(Integer, ForeignKey("users.id"), nullable=False)
    total_rows = Column(Integer, nullable=False)
    added_rows = Column(Integer, nullable=False)
    duplicate_rows = Column(Integer, nullable=False)
    invalid_rows = Column(Integer, nullable=False)
    created_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )