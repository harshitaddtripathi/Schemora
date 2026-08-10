import uuid
from datetime import datetime, timezone
from typing import Optional, List
from sqlalchemy import String, Float, Boolean, Text, DateTime, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.core.database import Base


class Scheme(Base):
    __tablename__ = "schemes"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)  # scheme_id e.g. SCH-CENT-0001
    slug: Mapped[str] = mapped_column(String(128), unique=True, index=True, nullable=False)
    title: Mapped[str] = mapped_column(String(256), nullable=False)
    short_description: Mapped[str] = mapped_column(Text, nullable=False)
    detailed_description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    provider: Mapped[str] = mapped_column(String(128), nullable=False)
    jurisdiction: Mapped[str] = mapped_column(String(32), nullable=False)  # Central, State
    state: Mapped[Optional[str]] = mapped_column(String(64), nullable=True)

    gender_eligibility: Mapped[str] = mapped_column(String(32), default="All", nullable=False)
    social_categories: Mapped[str] = mapped_column(String(128), default="All", nullable=False)  # CSV e.g. OBC,SC,ST
    min_age: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    max_age: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    max_family_income: Mapped[Optional[float]] = mapped_column(Float, nullable=True)

    benefit_type: Mapped[str] = mapped_column(String(64), default="Financial", nullable=False)
    benefit_amount: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    benefit_summary: Mapped[str] = mapped_column(Text, nullable=False)

    implementation_status: Mapped[str] = mapped_column(String(32), default="Implemented", nullable=False)  # Implemented, SearchOnly, PlannedResearch
    is_published: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    application_deadline: Mapped[Optional[str]] = mapped_column(String(64), nullable=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    rules: Mapped[List["SchemeRule"]] = relationship(
        "SchemeRule",
        back_populates="scheme",
        cascade="all, delete-orphan",
    )
    sources: Mapped[List["SchemeSource"]] = relationship(
        "SchemeSource",
        back_populates="scheme",
        cascade="all, delete-orphan",
    )


class SchemeRule(Base):
    __tablename__ = "scheme_rules"

    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=lambda: str(uuid.uuid4()))
    scheme_id: Mapped[str] = mapped_column(
        String(64),
        ForeignKey("schemes.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    rule_id: Mapped[str] = mapped_column(String(64), nullable=False)
    field_name: Mapped[str] = mapped_column(String(64), nullable=False)
    operator: Mapped[str] = mapped_column(String(32), nullable=False)  # eq, neq, gt, gte, lt, lte, in, not_in, contains, exists
    expected_value: Mapped[str] = mapped_column(Text, nullable=False)  # JSON string representation
    rule_type: Mapped[str] = mapped_column(String(32), default="mandatory", nullable=False)  # mandatory, advisory
    failure_reason: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    scheme: Mapped["Scheme"] = relationship("Scheme", back_populates="rules")


class SchemeSource(Base):
    __tablename__ = "scheme_sources"

    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=lambda: str(uuid.uuid4()))
    scheme_id: Mapped[str] = mapped_column(
        String(64),
        ForeignKey("schemes.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    source_name: Mapped[str] = mapped_column(String(256), nullable=False)
    url: Mapped[str] = mapped_column(Text, nullable=False)
    source_type: Mapped[str] = mapped_column(String(64), default="OfficialPortal", nullable=False)
    last_verified_at: Mapped[Optional[str]] = mapped_column(String(32), nullable=True)

    scheme: Mapped["Scheme"] = relationship("Scheme", back_populates="sources")
