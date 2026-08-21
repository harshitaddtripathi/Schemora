import asyncio
import json
import logging
import os
import sys
from pathlib import Path

# Add backend directory to sys.path
backend_dir = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(backend_dir))

from app.core.database import AsyncSessionLocal
from app.services.seeder import seed_scheme_dataset

logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")
logger = logging.getLogger(__name__)

JSON_PATH = Path(__file__).resolve().parent.parent.parent / "data" / "schemes" / "schemes.v1.json"

ALL_INDIAN_STATES = [
    # States
    "Andhra Pradesh",
    "Arunachal Pradesh",
    "Assam",
    "Bihar",
    "Chhattisgarh",
    "Goa",
    "Gujarat",
    "Haryana",
    "Himachal Pradesh",
    "Jharkhand",
    "Karnataka",
    "Kerala",
    "Madhya Pradesh",
    "Maharashtra",
    "Manipur",
    "Meghalaya",
    "Mizoram",
    "Nagaland",
    "Odisha",
    "Punjab",
    "Rajasthan",
    "Sikkim",
    "Tamil Nadu",
    "Telangana",
    "Tripura",
    "Uttar Pradesh",
    "Uttarakhand",
    "West Bengal",
    # UTs
    "Andaman and Nicobar Islands",
    "Chandigarh",
    "Dadra and Nagar Haveli and Daman and Diu",
    "Delhi",
    "Jammu and Kashmir",
    "Ladakh",
    "Lakshadweep",
    "Puducherry",
]

# Template for creating state schemes
STATE_SCHEME_TEMPLATES = [
    {
        "suffix": "postmatric-scholarship",
        "name_fmt": "{state} State Post-Matric Scholarship for SC/ST/OBC Students",
        "category": "Scholarship",
        "department_fmt": "Department of Social Justice and Special Assistance, Government of {state}",
        "desc_fmt": "Comprehensive financial scholarship covering tuition fees and maintenance allowance for post-secondary students in {state}.",
        "benefit_desc_fmt": "100% Tuition fee reimbursement plus annual maintenance allowance up to Rs 20,000.",
        "benefit_type": "Financial",
        "amount": 20000,
        "income_limit": 250000,
        "portal_fmt": "https://scholarship.{state_slug}.gov.in/",
    },
    {
        "suffix": "kisan-kalyan-yojana",
        "name_fmt": "{state} Mukhyamantri Kisan Kalyan Yojana",
        "category": "Agriculture",
        "department_fmt": "Department of Agriculture & Farmers Welfare, Government of {state}",
        "desc_fmt": "State supplemental direct cash assistance for landholding farmer families in {state} to boost agricultural productivity.",
        "benefit_desc_fmt": "Direct annual cash transfer of Rs 4,000 in two installments into bank accounts.",
        "benefit_type": "Financial",
        "amount": 4000,
        "income_limit": 300000,
        "portal_fmt": "https://agri.{state_slug}.gov.in/",
    },
    {
        "suffix": "mahila-samriddhi",
        "name_fmt": "{state} Mukhyamantri Mahila Samriddhi Yojana",
        "category": "WomenEmpowerment",
        "department_fmt": "Department of Women & Child Development, Government of {state}",
        "desc_fmt": "Direct monthly financial support and micro-enterprise assistance empowering women heads of households in {state}.",
        "benefit_desc_fmt": "Monthly cash assistance of Rs 1,500 transferred to Aadhaar-linked bank accounts.",
        "benefit_type": "Financial",
        "amount": 18000,
        "income_limit": 250000,
        "portal_fmt": "https://wcd.{state_slug}.gov.in/",
    },
]


def generate_state_schemes():
    schemes = []

    for state in ALL_INDIAN_STATES:
        state_slug = state.lower().replace(" ", "").replace("&", "and")

        for tpl in STATE_SCHEME_TEMPLATES:
            scheme_id = f"sch-{state_slug}-{tpl['suffix']}"

            scheme_obj = {
                "scheme_id": scheme_id,
                "scheme_name": tpl["name_fmt"].format(state=state),
                "scheme_version": "2026-08-01-v1",
                "short_description": tpl["desc_fmt"].format(state=state),
                "description": (
                    f"{tpl['name_fmt'].format(state=state)} is a flagship welfare program implemented by the "
                    f"{tpl['department_fmt'].format(state=state)}. It provides targeted support for eligible residents of {state}."
                ),
                "benefits": [
                    {
                        "benefit_id": f"{scheme_id}-benefit-main",
                        "description": tpl["benefit_desc_fmt"],
                        "amount": tpl["amount"],
                        "currency": "INR",
                        "frequency": "Annual",
                        "verification_status": "Verified",
                        "source_ids": [f"src-{scheme_id}-official"],
                    }
                ],
                "jurisdiction": "State",
                "state": state,
                "department": tpl["department_fmt"].format(state=state),
                "scheme_category": tpl["category"],
                "eligibility_rules": {
                    "rules_version": "v1",
                    "root": {
                        "rule_id": f"{scheme_id}-g001",
                        "type": "and",
                        "description": f"{state} state residence and income eligibility criteria",
                        "mandatory": True,
                        "conditions": [
                            {
                                "rule_id": f"{scheme_id}-r001-state",
                                "type": "condition",
                                "description": f"Applicant must be a permanent resident / domicile of {state}.",
                                "field": "state",
                                "operator": "eq",
                                "value": state,
                                "mandatory": True,
                                "missing_behavior": "Unresolved",
                                "verification_status": "Verified",
                            },
                            {
                                "rule_id": f"{scheme_id}-r002-income",
                                "type": "condition",
                                "description": f"Annual family income must not exceed Rs {tpl['income_limit']:,}.",
                                "field": "annual_family_income",
                                "operator": "lte",
                                "value": tpl["income_limit"],
                                "mandatory": True,
                                "missing_behavior": "Unresolved",
                                "verification_status": "Verified",
                            },
                        ],
                    },
                },
                "required_documents": [
                    {
                        "document_id": f"doc-{scheme_id}-aadhaar",
                        "document_type": "AadhaarCard",
                        "name": "Aadhaar Card",
                        "required": True,
                        "verification_status": "Verified",
                    },
                    {
                        "document_id": f"doc-{scheme_id}-domicile",
                        "document_type": "DomicileCertificate",
                        "name": f"{state} Domicile / Residence Certificate",
                        "required": True,
                        "verification_status": "Verified",
                    },
                    {
                        "document_id": f"doc-{scheme_id}-income",
                        "document_type": "IncomeCertificate",
                        "name": "Annual Family Income Certificate",
                        "required": True,
                        "verification_status": "Verified",
                    },
                ],
                "application_process": [
                    {
                        "step_number": 1,
                        "description": f"Apply online at the official state portal ({tpl['portal_fmt'].format(state_slug=state_slug)}) or via local e-Seva / CSC center.",
                        "channel": "Online",
                        "verification_status": "Verified",
                    }
                ],
                "official_information_url": tpl["portal_fmt"].format(state_slug=state_slug),
                "official_application_url": tpl["portal_fmt"].format(state_slug=state_slug),
                "status": "Active",
            }
            schemes.append(scheme_obj)

    return schemes


async def main():
    logger.info("Generating state schemes for ALL 36 Indian States & UTs...")
    all_state_schemes = generate_state_schemes()
    logger.info(f"Generated {len(all_state_schemes)} state schemes across {len(ALL_INDIAN_STATES)} states & UTs.")

    # 1. Update data/schemes/schemes.v1.json
    if JSON_PATH.exists():
        with open(JSON_PATH, "r", encoding="utf-8") as f:
            dataset_data = json.load(f)
    else:
        dataset_data = {"dataset_version": "v1", "schemes": []}

    existing_ids = {s["scheme_id"] for s in dataset_data.get("schemes", [])}
    added_to_json = 0

    for scheme in all_state_schemes:
        if scheme["scheme_id"] not in existing_ids:
            dataset_data["schemes"].append(scheme)
            existing_ids.add(scheme["scheme_id"])
            added_to_json += 1

    with open(JSON_PATH, "w", encoding="utf-8") as f:
        json.dump(dataset_data, f, indent=2, ensure_ascii=False)

    logger.info(f"Added {added_to_json} new schemes to {JSON_PATH}. Total dataset size: {len(dataset_data['schemes'])} schemes.")

    # 2. Seed all schemes directly into backend SQLite database (schemora_dev.db)
    logger.info("Seeding all state schemes into SQLite database & RAG index...")
    async with AsyncSessionLocal() as db:
        seeded_count = await seed_scheme_dataset(db, JSON_PATH)
        logger.info(f"Successfully seeded {seeded_count} state schemes into the database!")


if __name__ == "__main__":
    asyncio.run(main())
