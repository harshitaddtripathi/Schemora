import json
from pathlib import Path

DATASET_PATH = Path(__file__).resolve().parent.parent.parent / "data" / "schemes" / "schemes.v1.json"

NEW_SCHEMES = [
  {
    "scheme_id": "sch-central-mudra-009",
    "scheme_name": "Pradhan Mantri MUDRA Yojana (PMMY)",
    "scheme_version": "2026-08-01-v1",
    "short_description": "Collateral-free loans up to Rs 10 Lakhs for micro and small non-corporate enterprises.",
    "description": "Pradhan Mantri MUDRA Yojana provides micro-loans up to Rs 10 Lakhs under Shishu (up to 50k), Kishore (50k-5L), and Tarun (5L-10L) categories to non-farm micro/small enterprises and entrepreneurs.",
    "benefits": [
      {
        "benefit_id": "mudra-benefit-loan",
        "description": "Collateral-free business loan up to Rs 10,000,000 for entrepreneurship.",
        "amount": 1000000,
        "currency": "INR",
        "frequency": "OneTime",
        "verification_status": "Verified"
      }
    ],
    "jurisdiction": "Central",
    "state": None,
    "department": "Department of Financial Services, Ministry of Finance",
    "scheme_category": "Entrepreneurship",
    "eligibility_rules": {
      "rules_version": "v1",
      "root": {
        "rule_id": "mudra-g001",
        "type": "and",
        "description": "PMMY Entrepreneur eligibility",
        "mandatory": True,
        "conditions": [
          {
            "rule_id": "mudra-r001-age",
            "type": "condition",
            "description": "Applicant is at least 18 years old.",
            "field": "age",
            "operator": "gte",
            "value": 18,
            "mandatory": True,
            "missing_behavior": "Unresolved",
            "verification_status": "Verified"
          }
        ]
      }
    },
    "required_documents": [
      {
        "document_id": "doc-mudra-id",
        "document_type": "IdentityProof",
        "name": "Aadhaar Card / Voter ID / PAN Card",
        "required": True,
        "verification_status": "Verified"
      },
      {
        "document_id": "doc-mudra-business-plan",
        "document_type": "BusinessPlan",
        "name": "Business Plan / Project Report",
        "required": True,
        "verification_status": "Verified"
      }
    ],
    "application_process": [
      {
        "step_number": 1,
        "description": "Apply online at udyamimitra.in or submit loan application to any commercial bank, MFI, or RRB branch.",
        "channel": "Online",
        "verification_status": "Verified"
      }
    ],
    "official_information_url": "https://www.mudra.org.in/",
    "official_application_url": "https://www.udyamimitra.in/",
    "status": "Active"
  },
  {
    "scheme_id": "sch-central-apy-010",
    "scheme_name": "Atal Pension Yojana (APY)",
    "scheme_version": "2026-08-01-v1",
    "short_description": "Guaranteed pension scheme of Rs 1,000 to Rs 5,000 per month for unorganized sector workers.",
    "description": "Atal Pension Yojana (APY) provides a guaranteed minimum monthly pension ranging from Rs 1,000 to Rs 5,000 per month after reaching 60 years of age, depending on contributions.",
    "benefits": [
      {
        "benefit_id": "apy-benefit-pension",
        "description": "Guaranteed lifetime monthly pension of Rs 1,000 to Rs 5,000 after 60 years of age.",
        "amount": 5000,
        "currency": "INR",
        "frequency": "Monthly",
        "verification_status": "Verified"
      }
    ],
    "jurisdiction": "Central",
    "state": None,
    "department": "PFRDA, Ministry of Finance",
    "scheme_category": "SeniorCitizen",
    "eligibility_rules": {
      "rules_version": "v1",
      "root": {
        "rule_id": "apy-g001",
        "type": "and",
        "description": "APY subscriber eligibility",
        "mandatory": True,
        "conditions": [
          {
            "rule_id": "apy-r001-age-min",
            "type": "condition",
            "description": "Age is at least 18 years at entry.",
            "field": "age",
            "operator": "gte",
            "value": 18,
            "mandatory": True,
            "missing_behavior": "Unresolved",
            "verification_status": "Verified"
          },
          {
            "rule_id": "apy-r002-age-max",
            "type": "condition",
            "description": "Age is no more than 40 years at entry.",
            "field": "age",
            "operator": "lte",
            "value": 40,
            "mandatory": True,
            "missing_behavior": "Unresolved",
            "verification_status": "Verified"
          }
        ]
      }
    },
    "required_documents": [
      {
        "document_id": "doc-apy-aadhaar",
        "document_type": "AadhaarCard",
        "name": "Aadhaar Card linked to Savings Account",
        "required": True,
        "verification_status": "Verified"
      }
    ],
    "application_process": [
      {
        "step_number": 1,
        "description": "Subscribe through net banking or visit your bank post office branch.",
        "channel": "Online",
        "verification_status": "Verified"
      }
    ],
    "official_information_url": "https://www.npscra.nsdl.co.in/scheme-details.php",
    "official_application_url": "https://enps.nsdl.com/",
    "status": "Active"
  },
  {
    "scheme_id": "sch-central-pmfby-011",
    "scheme_name": "Pradhan Mantri Fasal Bima Yojana (PMFBY)",
    "scheme_version": "2026-08-01-v1",
    "short_description": "Comprehensive crop insurance scheme protecting farmers against crop loss due to natural calamities.",
    "description": "PMFBY provides financial support and insurance coverage to farmers in the event of failure of any notified crop as a result of natural calamities, pests, and diseases.",
    "benefits": [
      {
        "benefit_id": "pmfby-benefit-claim",
        "description": "Full crop loss financial compensation directly deposited into farmer bank accounts.",
        "amount": None,
        "currency": "INR",
        "frequency": "Seasonal",
        "verification_status": "Verified"
      }
    ],
    "jurisdiction": "Central",
    "state": None,
    "department": "Ministry of Agriculture & Farmers Welfare",
    "scheme_category": "Agriculture",
    "eligibility_rules": {
      "rules_version": "v1",
      "root": {
        "rule_id": "pmfby-g001",
        "type": "and",
        "description": "Crop insurance farmer eligibility",
        "mandatory": True,
        "conditions": [
          {
            "rule_id": "pmfby-r001-farmer",
            "type": "condition",
            "description": "Applicant is a farmer growing notified crops.",
            "field": "landholding_status",
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
        "document_id": "doc-pmfby-land",
        "document_type": "LandRecord",
        "name": "Land ownership paper or tenancy agreement",
        "required": True,
        "verification_status": "Verified"
      }
    ],
    "application_process": [
      {
        "step_number": 1,
        "description": "Enroll through PMFBY portal (pmfby.gov.in), bank branch, or insurance intermediary before cutoff date.",
        "channel": "Online",
        "verification_status": "Verified"
      }
    ],
    "official_information_url": "https://pmfby.gov.in/",
    "official_application_url": "https://pmfby.gov.in/",
    "status": "Active"
  },
  {
    "scheme_id": "sch-central-pmay-012",
    "scheme_name": "Pradhan Mantri Awas Yojana (PMAY)",
    "scheme_version": "2026-08-01-v1",
    "short_description": "Financial subsidy for affordable housing construction and home loans for homeless and EWS/LIG families.",
    "description": "Pradhan Mantri Awas Yojana provides pucca houses with basic amenities to all eligible urban and rural homeless and EWS/LIG families across India.",
    "benefits": [
      {
        "benefit_id": "pmay-benefit-subsidy",
        "description": "Direct financial assistance of up to Rs 2.67 Lakhs as interest subsidy or construction grant.",
        "amount": 267000,
        "currency": "INR",
        "frequency": "OneTime",
        "verification_status": "Verified"
      }
    ],
    "jurisdiction": "Central",
    "state": None,
    "department": "Ministry of Housing and Urban Affairs",
    "scheme_category": "General",
    "eligibility_rules": {
      "rules_version": "v1",
      "root": {
        "rule_id": "pmay-g001",
        "type": "and",
        "description": "PMAY housing eligibility",
        "mandatory": True,
        "conditions": [
          {
            "rule_id": "pmay-r001-pucca-house",
            "type": "condition",
            "description": "Applicant family does not own a pucca house anywhere in India.",
            "field": "owns_pucca_house",
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
        "document_id": "doc-pmay-aadhaar",
        "document_type": "AadhaarCard",
        "name": "Aadhaar Card of all family members",
        "required": True,
        "verification_status": "Verified"
      },
      {
        "document_id": "doc-pmay-income",
        "document_type": "IncomeCertificate",
        "name": "Income Proof / Self-Declaration",
        "required": True,
        "verification_status": "Verified"
      }
    ],
    "application_process": [
      {
        "step_number": 1,
        "description": "Apply online at pmaymis.gov.in or visit local municipal office/CSC center.",
        "channel": "Online",
        "verification_status": "Verified"
      }
    ],
    "official_information_url": "https://pmaymis.gov.in/",
    "official_application_url": "https://pmaymis.gov.in/",
    "status": "Active"
  },
  {
    "scheme_id": "sch-central-pmkvy-013",
    "scheme_name": "Pradhan Mantri Kaushal Vikas Yojana (PMKVY 4.0)",
    "scheme_version": "2026-08-01-v1",
    "short_description": "Free industry-relevant skill training and certification for youth seeking jobs and self-employment.",
    "description": "PMKVY 4.0 is the flagship skill training scheme enabling Indian youth to take up industry-relevant skill training that helps them in securing a better livelihood.",
    "benefits": [
      {
        "benefit_id": "pmkvy-benefit-training",
        "description": "Free skill training, government certification, assessment fees, and placement assistance.",
        "amount": None,
        "currency": "INR",
        "frequency": "OneTime",
        "verification_status": "Verified"
      }
    ],
    "jurisdiction": "Central",
    "state": None,
    "department": "Ministry of Skill Development and Entrepreneurship",
    "scheme_category": "SkillDevelopment",
    "eligibility_rules": {
      "rules_version": "v1",
      "root": {
        "rule_id": "pmkvy-g001",
        "type": "and",
        "description": "PMKVY skill candidate eligibility",
        "mandatory": True,
        "conditions": [
          {
            "rule_id": "pmkvy-r001-age",
            "type": "condition",
            "description": "Age is between 15 and 45 years.",
            "field": "age",
            "operator": "gte",
            "value": 15,
            "mandatory": True,
            "missing_behavior": "Unresolved",
            "verification_status": "Verified"
          }
        ]
      }
    },
    "required_documents": [
      {
        "document_id": "doc-pmkvy-aadhaar",
        "document_type": "AadhaarCard",
        "name": "Aadhaar Card and Bank Details",
        "required": True,
        "verification_status": "Verified"
      }
    ],
    "application_process": [
      {
        "step_number": 1,
        "description": "Register on Skill India Digital portal (skillindiadigital.gov.in) and choose desired training course.",
        "channel": "Online",
        "verification_status": "Verified"
      }
    ],
    "official_information_url": "https://www.pmkvyofficial.org/",
    "official_application_url": "https://www.skillindiadigital.gov.in/",
    "status": "Active"
  },
  {
    "scheme_id": "sch-up-kanya-sumangala-014",
    "scheme_name": "Mukhya Mantri Kanya Sumangala Yojana",
    "scheme_version": "2026-08-01-v1",
    "short_description": "Financial assistance of Rs 25,000 for girl children in Uttar Pradesh across 6 key developmental milestones.",
    "description": "A Uttar Pradesh state government initiative providing conditional cash transfers totaling Rs 25,000 to girl children from birth through higher education.",
    "benefits": [
      {
        "benefit_id": "up-kanya-benefit-grant",
        "description": "Rs 25,000 total financial assistance paid in instalments from birth to graduation.",
        "amount": 25000,
        "currency": "INR",
        "frequency": "Milestone",
        "verification_status": "Verified"
      }
    ],
    "jurisdiction": "State",
    "state": "Uttar Pradesh",
    "department": "Women and Child Development Department, Government of Uttar Pradesh",
    "scheme_category": "WomenEmpowerment",
    "eligibility_rules": {
      "rules_version": "v1",
      "root": {
        "rule_id": "up-kanya-g001",
        "type": "and",
        "description": "Kanya Sumangala UP eligibility",
        "mandatory": True,
        "conditions": [
          {
            "rule_id": "up-kanya-r001-state",
            "type": "condition",
            "description": "Applicant is a resident of Uttar Pradesh.",
            "field": "state",
            "operator": "eq",
            "value": "Uttar Pradesh",
            "mandatory": True,
            "missing_behavior": "Unresolved",
            "verification_status": "Verified"
          },
          {
            "rule_id": "up-kanya-r002-income",
            "type": "condition",
            "description": "Annual family income does not exceed Rs 3 Lakhs.",
            "field": "annual_family_income",
            "operator": "lte",
            "value": 300000,
            "mandatory": True,
            "missing_behavior": "Unresolved",
            "verification_status": "Verified"
          }
        ]
      }
    },
    "required_documents": [
      {
        "document_id": "doc-up-kanya-domicile",
        "document_type": "DomicileCertificate",
        "name": "UP Domicile Certificate",
        "required": True,
        "verification_status": "Verified"
      }
    ],
    "application_process": [
      {
        "step_number": 1,
        "description": "Apply online on the official portal mksy.up.gov.in.",
        "channel": "Online",
        "verification_status": "Verified"
      }
    ],
    "official_information_url": "https://mksy.up.gov.in/",
    "official_application_url": "https://mksy.up.gov.in/",
    "status": "Active"
  },
  {
    "scheme_id": "sch-tn-pudhumai-penn-017",
    "scheme_name": "Pudhumai Penn Scheme (Moovalur Ramamirtham Ammal Scheme)",
    "scheme_version": "2026-08-01-v1",
    "short_description": "Monthly financial assistance of Rs 1,000 for female students in Tamil Nadu pursuing higher education.",
    "description": "Tamil Nadu state scheme granting Rs 1,000 per month to female students who studied in government schools from Classes 6 to 12 and enrolled in degree or diploma courses.",
    "benefits": [
      {
        "benefit_id": "tn-pudhumai-benefit-monthly",
        "description": "Rs 1,000 monthly financial assistance directly deposited into student bank accounts.",
        "amount": 1000,
        "currency": "INR",
        "frequency": "Monthly",
        "verification_status": "Verified"
      }
    ],
    "jurisdiction": "State",
    "state": "Tamil Nadu",
    "department": "Social Welfare and Women Empowerment Department, Government of Tamil Nadu",
    "scheme_category": "Scholarship",
    "eligibility_rules": {
      "rules_version": "v1",
      "root": {
        "rule_id": "tn-pudhumai-g001",
        "type": "and",
        "description": "Pudhumai Penn eligibility",
        "mandatory": True,
        "conditions": [
          {
            "rule_id": "tn-pudhumai-r001-state",
            "type": "condition",
            "description": "Applicant is a resident of Tamil Nadu.",
            "field": "state",
            "operator": "eq",
            "value": "Tamil Nadu",
            "mandatory": True,
            "missing_behavior": "Unresolved",
            "verification_status": "Verified"
          },
          {
            "rule_id": "tn-pudhumai-r002-gender",
            "type": "condition",
            "description": "Applicant is female.",
            "field": "gender",
            "operator": "eq",
            "value": "Female",
            "mandatory": True,
            "missing_behavior": "Unresolved",
            "verification_status": "Verified"
          }
        ]
      }
    },
    "required_documents": [
      {
        "document_id": "doc-tn-pudhumai-school-cert",
        "document_type": "SchoolCertificate",
        "name": "Government School Transfer / Schooling Certificate (Class 6-12)",
        "required": True,
        "verification_status": "Verified"
      }
    ],
    "application_process": [
      {
        "step_number": 1,
        "description": "Register on penkalvi.tn.gov.in through college nodal officer.",
        "channel": "Online",
        "verification_status": "Verified"
      }
    ],
    "official_information_url": "https://penkalvi.tn.gov.in/",
    "official_application_url": "https://penkalvi.tn.gov.in/",
    "status": "Active"
  },
  {
    "scheme_id": "sch-kar-gruha-lakshmi-019",
    "scheme_name": "Karnataka Gruha Lakshmi Scheme",
    "scheme_version": "2026-08-01-v1",
    "short_description": "Monthly financial assistance of Rs 2,000 for female heads of households in Karnataka.",
    "description": "Karnataka state scheme providing Rs 2,000 every month directly to female house heads (APL/BPL/Antyodaya ration card holders).",
    "benefits": [
      {
        "benefit_id": "kar-gruha-benefit-monthly",
        "description": "Rs 2,000 per month direct bank benefit to woman house head.",
        "amount": 2000,
        "currency": "INR",
        "frequency": "Monthly",
        "verification_status": "Verified"
      }
    ],
    "jurisdiction": "State",
    "state": "Karnataka",
    "department": "Women and Child Development Department, Government of Karnataka",
    "scheme_category": "WomenEmpowerment",
    "eligibility_rules": {
      "rules_version": "v1",
      "root": {
        "rule_id": "kar-gruha-g001",
        "type": "and",
        "description": "Gruha Lakshmi eligibility",
        "mandatory": True,
        "conditions": [
          {
            "rule_id": "kar-gruha-r001-state",
            "type": "condition",
            "description": "Applicant is a resident of Karnataka.",
            "field": "state",
            "operator": "eq",
            "value": "Karnataka",
            "mandatory": True,
            "missing_behavior": "Unresolved",
            "verification_status": "Verified"
          },
          {
            "rule_id": "kar-gruha-r002-gender",
            "type": "condition",
            "description": "Applicant is female.",
            "field": "gender",
            "operator": "eq",
            "value": "Female",
            "mandatory": True,
            "missing_behavior": "Unresolved",
            "verification_status": "Verified"
          }
        ]
      }
    },
    "required_documents": [
      {
        "document_id": "doc-kar-gruha-ration",
        "document_type": "RationCard",
        "name": "BPL / APL Ration Card listing applicant as head of family",
        "required": True,
        "verification_status": "Verified"
      }
    ],
    "application_process": [
      {
        "step_number": 1,
        "description": "Apply online at sevasindhugs.karnataka.gov.in or visit Grama One / Karnataka One centers.",
        "channel": "Online",
        "verification_status": "Verified"
      }
    ],
    "official_information_url": "https://sevasindhugs.karnataka.gov.in/",
    "official_application_url": "https://sevasindhugs.karnataka.gov.in/",
    "status": "Active"
  },
  {
    "scheme_id": "sch-kar-raitha-vidya-020",
    "scheme_name": "Karnataka Raitha Vidya Nidhi Scheme",
    "scheme_version": "2026-08-01-v1",
    "short_description": "Scholarship assistance of Rs 2,500 to Rs 11,000 per year for children of farmers pursuing higher education.",
    "description": "Scholarship granted by Karnataka state government to students whose parents are farmers, encouraging higher education among agricultural families.",
    "benefits": [
      {
        "benefit_id": "kar-raitha-benefit-scholarship",
        "description": "Annual scholarship of Rs 2,500 to Rs 11,000 depending on course stage.",
        "amount": 11000,
        "currency": "INR",
        "frequency": "Annual",
        "verification_status": "Verified"
      }
    ],
    "jurisdiction": "State",
    "state": "Karnataka",
    "department": "Agriculture Department, Government of Karnataka",
    "scheme_category": "Scholarship",
    "eligibility_rules": {
      "rules_version": "v1",
      "root": {
        "rule_id": "kar-raitha-g001",
        "type": "and",
        "description": "Raitha Vidya Nidhi eligibility",
        "mandatory": True,
        "conditions": [
          {
            "rule_id": "kar-raitha-r001-state",
            "type": "condition",
            "description": "Applicant is a resident of Karnataka.",
            "field": "state",
            "operator": "eq",
            "value": "Karnataka",
            "mandatory": True,
            "missing_behavior": "Unresolved",
            "verification_status": "Verified"
          }
        ]
      }
    },
    "required_documents": [
      {
        "document_id": "doc-kar-raitha-fid",
        "document_type": "FarmerID",
        "name": "Farmer Identification (FID) or Land Record of Parent",
        "required": True,
        "verification_status": "Verified"
      }
    ],
    "application_process": [
      {
        "step_number": 1,
        "description": "Apply on State Scholarship Portal (SSP Karnataka) at ssp.postmatric.karnataka.gov.in.",
        "channel": "Online",
        "verification_status": "Verified"
      }
    ],
    "official_information_url": "https://ssp.postmatric.karnataka.gov.in/",
    "official_application_url": "https://ssp.postmatric.karnataka.gov.in/",
    "status": "Active"
  },
  {
    "scheme_id": "sch-wb-kanyashree-023",
    "scheme_name": "West Bengal Kanyashree Prakalpa",
    "scheme_version": "2026-08-01-v1",
    "short_description": "Annual scholarship of Rs 1,000 and one-time grant of Rs 25,000 for unmarried female students in West Bengal.",
    "description": "A globally recognized West Bengal conditional cash transfer scheme empowering adolescent girls and preventing child marriage.",
    "benefits": [
      {
        "benefit_id": "wb-kanya-benefit-grant",
        "description": "Annual stipend K1 (Rs 1,000) and one-time K2 grant (Rs 25,000) at age 18.",
        "amount": 25000,
        "currency": "INR",
        "frequency": "OneTime",
        "verification_status": "Verified"
      }
    ],
    "jurisdiction": "State",
    "state": "West Bengal",
    "department": "Department of Women & Child Development and Social Welfare, West Bengal",
    "scheme_category": "Scholarship",
    "eligibility_rules": {
      "rules_version": "v1",
      "root": {
        "rule_id": "wb-kanya-g001",
        "type": "and",
        "description": "Kanyashree WB eligibility",
        "mandatory": True,
        "conditions": [
          {
            "rule_id": "wb-kanya-r001-state",
            "type": "condition",
            "description": "Applicant is a resident of West Bengal.",
            "field": "state",
            "operator": "eq",
            "value": "West Bengal",
            "mandatory": True,
            "missing_behavior": "Unresolved",
            "verification_status": "Verified"
          },
          {
            "rule_id": "wb-kanya-r002-gender",
            "type": "condition",
            "description": "Applicant is female.",
            "field": "gender",
            "operator": "eq",
            "value": "Female",
            "mandatory": True,
            "missing_behavior": "Unresolved",
            "verification_status": "Verified"
          }
        ]
      }
    },
    "required_documents": [
      {
        "document_id": "doc-wb-kanya-institution",
        "document_type": "StudentCertificate",
        "name": "Unmarried Certificate and School/College Enrollment Proof",
        "required": True,
        "verification_status": "Verified"
      }
    ],
    "application_process": [
      {
        "step_number": 1,
        "description": "Apply through school/educational institution portal at wbkanyashree.gov.in.",
        "channel": "Online",
        "verification_status": "Verified"
      }
    ],
    "official_information_url": "https://wbkanyashree.gov.in/",
    "official_application_url": "https://wbkanyashree.gov.in/",
    "status": "Active"
  },
  {
    "scheme_id": "sch-guj-mysy-029",
    "scheme_name": "Mukhymantri Yuva Swavalamban Yojana (MYSY Gujarat)",
    "scheme_version": "2026-08-01-v1",
    "short_description": "Higher education scholarship subsidy up to Rs 2 Lakhs per year for diploma, degree, and medical students in Gujarat.",
    "description": "Gujarat state scholarship providing up to 50% tuition fee assistance and hostel food allowance to meritorious students with family income <= Rs 6 Lakhs.",
    "benefits": [
      {
        "benefit_id": "guj-mysy-benefit-fee",
        "description": "50% tuition fee subsidy (up to Rs 2,000,000/yr for medical/engineering) + hostel allowance.",
        "amount": 200000,
        "currency": "INR",
        "frequency": "Annual",
        "verification_status": "Verified"
      }
    ],
    "jurisdiction": "State",
    "state": "Gujarat",
    "department": "Education Department, Government of Gujarat",
    "scheme_category": "Scholarship",
    "eligibility_rules": {
      "rules_version": "v1",
      "root": {
        "rule_id": "guj-mysy-g001",
        "type": "and",
        "description": "MYSY Gujarat eligibility",
        "mandatory": True,
        "conditions": [
          {
            "rule_id": "guj-mysy-r001-state",
            "type": "condition",
            "description": "Applicant is a resident of Gujarat.",
            "field": "state",
            "operator": "eq",
            "value": "Gujarat",
            "mandatory": True,
            "missing_behavior": "Unresolved",
            "verification_status": "Verified"
          },
          {
            "rule_id": "guj-mysy-r002-income",
            "type": "condition",
            "description": "Annual family income is no more than Rs 6 Lakhs.",
            "field": "annual_family_income",
            "operator": "lte",
            "value": 600000,
            "mandatory": True,
            "missing_behavior": "Unresolved",
            "verification_status": "Verified"
          }
        ]
      }
    },
    "required_documents": [
      {
        "document_id": "doc-guj-mysy-income",
        "document_type": "IncomeCertificate",
        "name": "Gujarat Income Certificate & Class 10/12 Marksheet (>= 80 percentile)",
        "required": True,
        "verification_status": "Verified"
      }
    ],
    "application_process": [
      {
        "step_number": 1,
        "description": "Apply online at mysy.guj.nic.in.",
        "channel": "Online",
        "verification_status": "Verified"
      }
    ],
    "official_information_url": "https://mysy.guj.nic.in/",
    "official_application_url": "https://mysy.guj.nic.in/",
    "status": "Active"
  }
]

def main():
    with open(DATASET_PATH, "r", encoding="utf-8") as f:
        data = json.load(f)

    existing_ids = {s["scheme_id"] for s in data.get("schemes", [])}

    added = 0
    for s in NEW_SCHEMES:
        if s["scheme_id"] not in existing_ids:
            data["schemes"].append(s)
            added += 1

    with open(DATASET_PATH, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

    print(f"Added {added} new schemes. Total schemes in dataset: {len(data['schemes'])}")

if __name__ == "__main__":
    main()
