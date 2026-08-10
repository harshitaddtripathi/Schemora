import uuid
from datetime import datetime, date, timezone
from typing import Optional
from sqlalchemy import String, Float, Boolean, Date, DateTime, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.core.database import Base


class StudentProfile(Base):
    __tablename__ = "student_profiles"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("users.id", ondelete="CASCADE"),
        unique=True,
        nullable=False,
        index=True,
    )

    full_name: Mapped[str] = mapped_column(String(128), nullable=False)
    date_of_birth: Mapped[date] = mapped_column(Date, nullable=False)
    gender: Mapped[str] = mapped_column(String(32), nullable=False)  # Male, Female, Transgender, Other
    state: Mapped[str] = mapped_column(String(64), nullable=False)
    education_level: Mapped[str] = mapped_column(String(64), nullable=False)  # Class10, Class12, Diploma, ITI, Undergraduate, Postgraduate, PhD
    course_name: Mapped[Optional[str]] = mapped_column(String(128), nullable=True)
    institution_name: Mapped[Optional[str]] = mapped_column(String(256), nullable=True)
    institution_type: Mapped[str] = mapped_column(String(64), default="Regular", nullable=False)  # Regular, Distance, Correspondence

    social_category: Mapped[str] = mapped_column(String(32), nullable=False)  # General, OBC, SC, ST, EWS
    annual_family_income: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    is_full_time_student: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    employment_status: Mapped[str] = mapped_column(String(64), default="Unemployed", nullable=False)  # Unemployed, PartTime, FullTime, SelfEmployed
    citizenship: Mapped[str] = mapped_column(String(32), default="Indian", nullable=False)

    class12_percentile: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    attendance_percentage: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    education_gap_years: Mapped[int] = mapped_column(Float, default=0, nullable=False)
    course_type: Mapped[Optional[str]] = mapped_column(String(64), nullable=True)  # Professional, NonProfessional
    admission_through_cap: Mapped[Optional[bool]] = mapped_column(Boolean, nullable=True)
    family_male_beneficiaries_count: Mapped[int] = mapped_column(Float, default=0, nullable=False)
    receiving_other_scholarship: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    pmis_exclusion_clearance: Mapped[Optional[bool]] = mapped_column(Boolean, nullable=True)

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

    user: Mapped["User"] = relationship("User", back_populates="profile")
