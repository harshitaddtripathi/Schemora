import json
from pathlib import Path

json_path = Path(__file__).resolve().parent.parent.parent / "data" / "schemes" / "schemes.v1.json"

new_schemes = [
  {
    "scheme_id": "sch-central-pmkisan-004",
    "scheme_name": "Pradhan Mantri Kisan Samman Nidhi (PM-KISAN)",
    "scheme_version": "2026-08-01-v1",
    "short_description": "Income support scheme providing Rs 6,000 per year to eligible farmer families across India.",
    "description": "PM-KISAN is a Central Sector Scheme that provides financial support of Rs 6,000 per annum to landholding farmer families across India, transferred directly into their bank accounts in three equal installments of Rs 2,000 every four months.",
    "benefits": [
      {
        "benefit_id": "pmkisan-benefit-financial",
        "description": "Direct bank transfer of Rs 6,000 annually in 3 equal installments of Rs 2,000.",
        "amount": 6000,
        "currency": "INR",
        "frequency": "Annual",
        "verification_status": "Verified",
        "source_ids": ["src-pmkisan-official"]
      }
    ],
    "jurisdiction": "Central",
    "state": None,
    "department": "Ministry of Agriculture & Farmers Welfare",
    "scheme_category": "Agriculture",
    "eligibility_rules": {
      "rules_version": "v1",
      "root": {
        "rule_id": "pmkisan-g001",
        "type": "and",
        "description": "PM-KISAN eligibility criteria",
        "mandatory": True,
        "conditions": [
          {
            "rule_id": "pmkisan-r001-landholding",
            "type": "condition",
            "description": "Applicant family holds cultivable agricultural land.",
            "field": "landholding_status",
            "operator": "eq",
            "value": True,
            "mandatory": True,
            "missing_behavior": "Unresolved",
            "verification_status": "Verified"
          },
          {
            "rule_id": "pmkisan-r002-income-tax",
            "type": "condition",
            "description": "Applicant or family member did not pay income tax in the last assessment year.",
            "field": "is_income_tax_payer",
            "operator": "eq",
            "value": False,
            "mandatory": True,
            "missing_behavior": "Unresolved",
            "verification_status": "Verified"
          }
        ]
      }
    },
    "required_documents": [
      {
        "document_id": "doc-pmkisan-land",
        "document_type": "LandRecord",
        "name": "Cultivable Land Record / Khatauni",
        "required": True,
        "verification_status": "Verified"
      },
      {
        "document_id": "doc-pmkisan-aadhaar",
        "document_type": "AadhaarCard",
        "name": "Aadhaar Card linked with Bank Account",
        "required": True,
        "verification_status": "Verified"
      }
    ],
    "application_process": [
      {
        "step_number": 1,
        "description": "Register online at PM-KISAN portal (pmkisan.gov.in) or visit nearest Common Service Center (CSC).",
        "channel": "Online",
        "verification_status": "Verified"
      }
    ],
    "official_information_url": "https://pmkisan.gov.in/",
    "official_application_url": "https://pmkisan.gov.in/RegistrationForm.aspx",
    "status": "Active"
  },
  {
    "scheme_id": "sch-central-ayushman-005",
    "scheme_name": "Ayushman Bharat Pradhan Mantri Jan Arogya Yojana (PM-JAY)",
    "scheme_version": "2026-08-01-v1",
    "short_description": "Health coverage of up to Rs 5 lakh per family per year for secondary and tertiary care hospitalization.",
    "description": "Ayushman Bharat PM-JAY is the world's largest health insurance scheme fully financed by the government. It provides a cover of Rs 5 lakhs per family per year for secondary and tertiary care hospitalization across empanelled public and private hospitals in India.",
    "benefits": [
      {
        "benefit_id": "ayushman-benefit-health-cover",
        "description": "Cashless hospitalization coverage up to Rs 5,000,000 per family annually.",
        "amount": 500000,
        "currency": "INR",
        "frequency": "Annual",
        "verification_status": "Verified",
        "source_ids": ["src-pmjay-official"]
      }
    ],
    "jurisdiction": "Central",
    "state": None,
    "department": "National Health Authority, Ministry of Health and Family Welfare",
    "scheme_category": "Health",
    "eligibility_rules": {
      "rules_version": "v1",
      "root": {
        "rule_id": "ayushman-g001",
        "type": "and",
        "description": "Ayushman Bharat PM-JAY eligibility criteria",
        "mandatory": True,
        "conditions": [
          {
            "rule_id": "ayushman-r001-secc-deprivation",
            "type": "condition",
            "description": "Family is identified in SECC 2011 database or holds eligible ration card.",
            "field": "secc_eligible",
            "operator": "eq",
            "value": True,
            "mandatory": True,
            "missing_behavior": "Unresolved",
            "verification_status": "Verified"
          }
        ]
      }
    },
    "required_documents": [
      {
        "document_id": "doc-ayushman-aadhaar",
        "document_type": "AadhaarCard",
        "name": "Aadhaar Card or E-KYC Identity",
        "required": True,
        "verification_status": "Verified"
      },
      {
        "document_id": "doc-ayushman-ration",
        "document_type": "RationCard",
        "name": "Ration Card or Ayushman Card",
        "required": True,
        "verification_status": "Verified"
      }
    ],
    "application_process": [
      {
        "step_number": 1,
        "description": "Check eligibility at beneficiary.nha.gov.in or visit any empanelled hospital with Ayushman Mitra.",
        "channel": "Online",
        "verification_status": "Verified"
      }
    ],
    "official_information_url": "https://pmjay.gov.in/",
    "official_application_url": "https://beneficiary.nha.gov.in/",
    "status": "Active"
  },
  {
    "scheme_id": "sch-maharashtra-ladkibahin-006",
    "scheme_name": "Mukhyamantri Majhi Ladki Bahin Yojana",
    "scheme_version": "2026-08-01-v1",
    "short_description": "Financial assistance of Rs 1,500 per month for eligible women in Maharashtra aged 21 to 65 years.",
    "description": "A flagship Maharashtra state government initiative aimed at financial independence, health, and nutrition for women. Eligible women receive direct monthly financial transfers of Rs 1,500.",
    "benefits": [
      {
        "benefit_id": "ladkibahin-benefit-monthly",
        "description": "Monthly direct financial support of Rs 1,500 transferred to Aadhaar-linked bank account.",
        "amount": 1500,
        "currency": "INR",
        "frequency": "Monthly",
        "verification_status": "Verified",
        "source_ids": ["src-ladkibahin-official"]
      }
    ],
    "jurisdiction": "State",
    "state": "Maharashtra",
    "department": "Women and Child Development Department, Government of Maharashtra",
    "scheme_category": "WomenEmpowerment",
    "eligibility_rules": {
      "rules_version": "v1",
      "root": {
        "rule_id": "ladkibahin-g001",
        "type": "and",
        "description": "Majhi Ladki Bahin Yojana eligibility",
        "mandatory": True,
        "conditions": [
          {
            "rule_id": "ladkibahin-r001-state",
            "type": "condition",
            "description": "Applicant is a resident of Maharashtra.",
            "field": "state",
            "operator": "eq",
            "value": "Maharashtra",
            "mandatory": True,
            "missing_behavior": "Unresolved",
            "verification_status": "Verified"
          },
          {
            "rule_id": "ladkibahin-r002-gender",
            "type": "condition",
            "description": "Applicant is female.",
            "field": "gender",
            "operator": "eq",
            "value": "Female",
            "mandatory": True,
            "missing_behavior": "Unresolved",
            "verification_status": "Verified"
          },
          {
            "rule_id": "ladkibahin-r003-age-min",
            "type": "condition",
            "description": "Age is at least 21 years.",
            "field": "age",
            "operator": "gte",
            "value": 21,
            "mandatory": True,
            "missing_behavior": "Unresolved",
            "verification_status": "Verified"
          },
          {
            "rule_id": "ladkibahin-r004-age-max",
            "type": "condition",
            "description": "Age is no more than 65 years.",
            "field": "age",
            "operator": "lte",
            "value": 65,
            "mandatory": True,
            "missing_behavior": "Unresolved",
            "verification_status": "Verified"
          },
          {
            "rule_id": "ladkibahin-r005-income",
            "type": "condition",
            "description": "Annual family income does not exceed Rs 2.5 Lakhs.",
            "field": "annual_family_income",
            "operator": "lte",
            "value": 250000,
            "mandatory": True,
            "missing_behavior": "Unresolved",
            "verification_status": "Verified"
          }
        ]
      }
    },
    "required_documents": [
      {
        "document_id": "doc-ladkibahin-aadhaar",
        "document_type": "AadhaarCard",
        "name": "Aadhaar Card",
        "required": True,
        "verification_status": "Verified"
      },
      {
        "document_id": "doc-ladkibahin-domicile",
        "document_type": "DomicileCertificate",
        "name": "Maharashtra Domicile Certificate or 15-year old Ration Card",
        "required": True,
        "verification_status": "Verified"
      },
      {
        "document_id": "doc-ladkibahin-income",
        "document_type": "IncomeCertificate",
        "name": "Income Certificate (Family income <= 2.5 Lakhs) or Yellow/Orange Ration Card",
        "required": True,
        "verification_status": "Verified"
      }
    ],
    "application_process": [
      {
        "step_number": 1,
        "description": "Apply online through Nari Shakti Doot App or official MahaDBT portal.",
        "channel": "Online",
        "verification_status": "Verified"
      }
    ],
    "official_information_url": "https://ladkibahin.maharashtra.gov.in/",
    "official_application_url": "https://ladkibahin.maharashtra.gov.in/",
    "status": "Active"
  },
  {
    "scheme_id": "sch-central-pmsvanidhi-007",
    "scheme_name": "PM Street Vendor's AtmaNirbhar Nidhi (PM SVANidhi)",
    "scheme_version": "2026-08-01-v1",
    "short_description": "Collateral-free working capital loan of up to Rs 50,000 for street vendors.",
    "description": "PM SVANidhi is a micro-credit scheme providing street vendors with collateral-free working capital loans starting from Rs 10,000, with enhanced limits up to Rs 50,000 upon timely repayment, along with digital cashback incentives.",
    "benefits": [
      {
        "benefit_id": "svanidhi-benefit-loan",
        "description": "Collateral-free working capital loan up to Rs 50,000 with 7% interest subsidy.",
        "amount": 50000,
        "currency": "INR",
        "frequency": "OneTime",
        "verification_status": "Verified",
        "source_ids": ["src-pmsvanidhi-official"]
      }
    ],
    "jurisdiction": "Central",
    "state": None,
    "department": "Ministry of Housing and Urban Affairs",
    "scheme_category": "Microfinance",
    "eligibility_rules": {
      "rules_version": "v1",
      "root": {
        "rule_id": "svanidhi-g001",
        "type": "and",
        "description": "PM SVANidhi vendor eligibility",
        "mandatory": True,
        "conditions": [
          {
            "rule_id": "svanidhi-r001-vendor",
            "type": "condition",
            "description": "Applicant is an active street vendor in urban or peri-urban areas.",
            "field": "occupation",
            "operator": "eq",
            "value": "StreetVendor",
            "mandatory": True,
            "missing_behavior": "Unresolved",
            "verification_status": "Verified"
          }
        ]
      }
    },
    "required_documents": [
      {
        "document_id": "doc-svanidhi-cov",
        "document_type": "VendorCertificate",
        "name": "Certificate of Vending (CoV) or Identity Card issued by Urban Local Body",
        "required": True,
        "verification_status": "Verified"
      },
      {
        "document_id": "doc-svanidhi-aadhaar",
        "document_type": "AadhaarCard",
        "name": "Aadhaar Card",
        "required": True,
        "verification_status": "Verified"
      }
    ],
    "application_process": [
      {
        "step_number": 1,
        "description": "Apply online at pmsvanidhi.mohua.gov.in or through nearest CSC or lending bank branch.",
        "channel": "Online",
        "verification_status": "Verified"
      }
    ],
    "official_information_url": "https://pmsvanidhi.mohua.gov.in/",
    "official_application_url": "https://pmsvanidhi.mohua.gov.in/Schemepmsv",
    "status": "Active"
  },
  {
    "scheme_id": "sch-central-sukanya-008",
    "scheme_name": "Sukanya Samriddhi Yojana (SSY)",
    "scheme_version": "2026-08-01-v1",
    "short_description": "High-interest tax-exempt savings scheme for the education and marriage of girl children.",
    "description": "Part of the Beti Bachao Beti Padhao campaign, Sukanya Samriddhi Yojana offers attractive government-guaranteed interest rates and tax benefits under Section 80C for accounts opened for girl children up to 10 years of age.",
    "benefits": [
      {
        "benefit_id": "sukanya-benefit-interest",
        "description": "High government interest rate (approx 8.2% p.a.) compounded annually with tax exemption.",
        "amount": None,
        "currency": "INR",
        "frequency": "Variable",
        "verification_status": "Verified",
        "source_ids": ["src-ssy-official"]
      }
    ],
    "jurisdiction": "Central",
    "state": None,
    "department": "Ministry of Finance & Department of Posts",
    "scheme_category": "FinancialInclusion",
    "eligibility_rules": {
      "rules_version": "v1",
      "root": {
        "rule_id": "sukanya-g001",
        "type": "and",
        "description": "Sukanya Samriddhi Yojana eligibility",
        "mandatory": True,
        "conditions": [
          {
            "rule_id": "sukanya-r001-gender",
            "type": "condition",
            "description": "Account opened for a girl child.",
            "field": "gender",
            "operator": "eq",
            "value": "Female",
            "mandatory": True,
            "missing_behavior": "Unresolved",
            "verification_status": "Verified"
          },
          {
            "rule_id": "sukanya-r002-age",
            "type": "condition",
            "description": "Girl child age is below 10 years at account opening.",
            "field": "age",
            "operator": "lte",
            "value": 10,
            "mandatory": True,
            "missing_behavior": "Unresolved",
            "verification_status": "Verified"
          }
        ]
      }
    },
    "required_documents": [
      {
        "document_id": "doc-sukanya-birth-cert",
        "document_type": "BirthCertificate",
        "name": "Girl Child Birth Certificate",
        "required": True,
        "verification_status": "Verified"
      },
      {
        "document_id": "doc-sukanya-parent-id",
        "document_type": "IdentityProof",
        "name": "Identity & Address proof of Guardian",
        "required": True,
        "verification_status": "Verified"
      }
    ],
    "application_process": [
      {
        "step_number": 1,
        "description": "Visit any India Post Office or authorized commercial bank branch to open SSY account.",
        "channel": "Offline",
        "verification_status": "Verified"
      }
    ],
    "official_information_url": "https://www.indiapost.gov.in/Financial/Pages/Content/Post-Office-Saving-Schemes.aspx",
    "official_application_url": "https://www.indiapost.gov.in/",
    "status": "Active"
  }
]

with open(json_path, "r", encoding="utf-8") as f:
    data = json.load(f)

existing_ids = {s["scheme_id"] for s in data["schemes"]}
added = 0

for ns in new_schemes:
    if ns["scheme_id"] not in existing_ids:
        data["schemes"].append(ns)
        existing_ids.add(ns["scheme_id"])
        added += 1

with open(json_path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

print(f"Added {added} new high quality schemes to {json_path}. Total schemes in dataset: {len(data['schemes'])}")
