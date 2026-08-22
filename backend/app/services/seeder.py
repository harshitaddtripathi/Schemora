import json
import re
from pathlib import Path
from typing import List, Dict, Any
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.models.scheme import Scheme, SchemeRule, SchemeSource


def slugify(text: str) -> str:
    text = text.lower()
    text = re.sub(r"[^\w\s-]", "", text)
    return re.sub(r"[-\s]+", "-", text).strip("-")


def extract_conditions(node: Dict[str, Any], rule_type_default: str = "mandatory") -> List[Dict[str, Any]]:
    conditions = []
    if not node:
        return conditions

    node_type = node.get("type", "")
    is_mandatory = node.get("mandatory", True)
    current_rule_type = "mandatory" if is_mandatory else "advisory"

    if node_type == "condition":
        conditions.append({
            "rule_id": node.get("rule_id", "r-unknown"),
            "field_name": node.get("field", "unknown"),
            "operator": node.get("operator", "eq"),
            "expected_value": json.dumps(node.get("value")),
            "rule_type": current_rule_type,
            "failure_reason": node.get("description", "Condition failed"),
        })
    elif node_type in ("and", "or"):
        for child in node.get("conditions", []):
            conditions.extend(extract_conditions(child, current_rule_type))

    return conditions


from app.services.rag_service import ingest_document


async def seed_scheme_dataset(db: AsyncSession, json_path: Path) -> int:
    with open(json_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    schemes_data = data.get("schemes", [])
    seeded_count = 0

    for s in schemes_data:
        scheme_id = s["scheme_id"]
        result = await db.execute(select(Scheme).where(Scheme.id == scheme_id))
        existing = result.scalar_one_or_none()

        if existing:
            continue

        title = s.get("scheme_name", "Untitled Scheme")
        slug = slugify(title)

        # Basic fields
        short_desc = s.get("short_description", "")
        detailed_desc = s.get("description", "")
        provider = s.get("department", "Government Provider")
        jurisdiction = s.get("jurisdiction", "Central")
        state = s.get("state")

        # Summary of benefits
        benefits = s.get("benefits", [])
        benefit_summary = benefits[0].get("description", "Financial Assistance") if benefits else "Scholarship Support"

        # Determine implementation status
        notes = s.get("scheme_version", "")
        impl_status = "Implemented" if "v1" in notes else "PlannedResearch"

        scheme = Scheme(
            id=scheme_id,
            slug=slug,
            title=title,
            short_description=short_desc,
            detailed_description=detailed_desc,
            provider=provider,
            jurisdiction=jurisdiction,
            state=state,
            gender_eligibility="All",
            social_categories="All",
            benefit_type="Financial",
            benefit_summary=benefit_summary,
            implementation_status=impl_status,
            is_published=True,
            application_deadline="2026-10-31",
        )

        db.add(scheme)
        await db.flush()

        # Seed rules
        root_rule = s.get("eligibility_rules", {}).get("root")
        if root_rule:
            extracted_rules = extract_conditions(root_rule)
            for r in extracted_rules:
                db_rule = SchemeRule(
                    scheme_id=scheme_id,
                    rule_id=r["rule_id"],
                    field_name=r["field_name"],
                    operator=r["operator"],
                    expected_value=r["expected_value"],
                    rule_type=r["rule_type"],
                    failure_reason=r["failure_reason"],
                )
                db.add(db_rule)

        # Seed default source with direct application link
        official_url = (
            s.get("official_application_url")
            or s.get("official_information_url")
            or f"https://www.india.gov.in/"
        )
        db_source = SchemeSource(
            scheme_id=scheme_id,
            source_name=f"{title} Official Application Portal",
            url=official_url,
            source_type="OfficialPortal",
            last_verified_at="2026-08-07",
        )
        db.add(db_source)

        # Ingest text document for RAG AI Retrieval
        rag_text = (
            f"Official Scheme: {title}\n"
            f"Provider: {provider} ({jurisdiction})\n"
            f"Summary: {short_desc}\n"
            f"Detailed Overview: {detailed_desc}\n"
            f"Benefits: {benefit_summary}\n"
            f"Official Application URL: {official_url}"
        )
        await ingest_document(
            db=db,
            title=f"Official Guideline: {title}",
            content=rag_text,
            scheme_id=scheme_id,
            source_url=official_url,
            doc_type="OfficialGuideline",
        )

        seeded_count += 1

    await db.commit()
    return seeded_count
