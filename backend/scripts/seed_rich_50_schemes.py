import asyncio
import json
import logging
import os
import sys
from pathlib import Path

# Add backend directory to sys.path
backend_dir = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(backend_dir))

from sqlalchemy import select
from app.core.database import AsyncSessionLocal
from app.models.scheme import Scheme, SchemeRule, SchemeSource
from app.services.seeder import slugify

logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")
logger = logging.getLogger(__name__)

RICH_SCHEMES = [
    # -------------------------------------------------------------------------
    # 1. DOCTORS / HEALTHCARE PROFESSIONALS / MEDICAL PERSONNEL
    # -------------------------------------------------------------------------
    {
        "id": "sch-doctor-cgtmse-001",
        "title": "Doctor & Medical Professional Clinic & Diagnostic Centre Loan Scheme",
        "short_description": "Collateral-free business and equipment loans up to ₹50 Lakhs for MBBS, BDS, MD doctors establishing clinics, hospitals, or pathology labs.",
        "detailed_description": "Under the CGTMSE Medical Infrastructure initiative, qualified doctors and medical practitioners (MBBS, BDS, BAMS, BHMS, MD/MS) receive collateral-free credit facilities to set up new clinics, purchase ultrasound/X-ray diagnostic machinery, and modernize medical infrastructure.",
        "provider": "Ministry of Micro, Small & Medium Enterprises & Bank of Baroda / SBI",
        "jurisdiction": "Central",
        "state": None,
        "benefit_type": "Loan & Credit Guarantee",
        "benefit_summary": "Collateral-free equipment & clinic setup loan up to ₹50,000,000 with 1.5% interest concession.",
        "gender_eligibility": "All",
        "social_categories": "All",
        "keyword": "doctor medical clinic hospital physician surgeon health practitioner diagnostic path lab MBBS MD BDS",
    },
    {
        "id": "sch-doctor-nhm-incentive-002",
        "title": "National Health Mission (NHM) Rural Doctor Special Hardship Allowance",
        "short_description": "Special monthly financial hardship allowance of ₹25,000 to ₹50,000 for MBBS and specialist doctors serving in rural and tribal PHCs.",
        "detailed_description": "The National Health Mission provides substantial monthly financial incentives, subsidized government accommodation, and preference points for PG medical entrance examinations to medical officers and specialist doctors serving in remote Public Health Centres (PHCs).",
        "provider": "National Health Mission, Ministry of Health and Family Welfare",
        "jurisdiction": "Central",
        "state": None,
        "benefit_type": "Financial Incentive",
        "benefit_summary": "Monthly hardship incentive allowance up to ₹50,000 + PG NEET weightage marks.",
        "gender_eligibility": "All",
        "social_categories": "All",
        "keyword": "doctor medical officer PHC rural health specialist surgeon MBBS MD incentive hardship stipend",
    },
    {
        "id": "sch-doctor-pmssy-fellowship-003",
        "title": "PM Swasthya Suraksha Yojana (PMSSY) Advanced Medical Research Fellowship",
        "short_description": "Monthly fellowship stipend of ₹80,000 for medical postgraduates and doctors conducting advanced clinical research at AIIMS institutes.",
        "detailed_description": "Designed to bolster high-end medical research in tertiary care healthcare institutes, PMSSY offers senior resident doctors and super-specialist fellows monthly financial support, laboratory contingency grants, and international conference travel funding.",
        "provider": "Ministry of Health & Family Welfare & AIIMS New Delhi",
        "jurisdiction": "Central",
        "state": None,
        "benefit_type": "Fellowship Grant",
        "benefit_summary": "Monthly fellowship of ₹80,000 + ₹1,00,000 annual research contingency grant.",
        "gender_eligibility": "All",
        "social_categories": "All",
        "keyword": "doctor medical research fellowship AIIMS clinical super specialty MD MS DM MCh stipend",
    },
    {
        "id": "sch-doctor-dnb-stipend-004",
        "title": "National Board of Examinations (NBE) DNB & MD Resident Doctor Financial Stipend",
        "short_description": "Mandatory standardized monthly stipend of ₹55,000 to ₹70,000 for postgraduate resident doctors pursuing DNB/MD in empanelled hospitals.",
        "detailed_description": "Ensures equitable financial compensation for junior and senior resident doctors undergoing post-graduate clinical training (DNB/MD/MS) across government and accredited private healthcare institutions.",
        "provider": "National Board of Examinations in Medical Sciences (NBEMS)",
        "jurisdiction": "Central",
        "state": None,
        "benefit_type": "Stipend",
        "benefit_summary": "Standardized monthly stipend ranging from ₹55,000 to ₹70,000 directly deposited to resident doctor bank accounts.",
        "gender_eligibility": "All",
        "social_categories": "All",
        "keyword": "doctor DNB resident medical trainee hospital postgraduate MD MS PG stipend",
    },
    {
        "id": "sch-doctor-pmbjp-franchise-005",
        "title": "Pradhan Mantri Bhartiya Janaushadhi Pariyojana (PMBJP) Doctor & Pharmacist Kendra Grant",
        "short_description": "One-time financial incentive of ₹5 Lakhs + 20% trade margin for registered doctors and pharmacists opening Generic Medicine Kendras.",
        "detailed_description": "Provides doctors, pharmacists, and medical entrepreneurs with financial assistance of ₹5.00 Lakhs for store furniture, computer software, and inventory setup to distribute high-quality affordable generic medicines to citizens.",
        "provider": "Pharmaceuticals & Medical Devices Bureau of India (PMBI), Ministry of Chemicals and Fertilizers",
        "jurisdiction": "Central",
        "state": None,
        "benefit_type": "Financial Grant",
        "benefit_summary": "₹5,00,000 establishment subsidy + 20% retail margin on generic pharmaceutical sales.",
        "gender_eligibility": "All",
        "social_categories": "All",
        "keyword": "doctor pharmacist generic medicine hospital clinic pharma pharmacy jan aushadhi kendra",
    },

    # -------------------------------------------------------------------------
    # 2. FARMERS / AGRICULTURE / LIVESTOCK / FISHERIES
    # -------------------------------------------------------------------------
    {
        "id": "sch-farm-ksy-006",
        "title": "Pradhan Mantri Krishi Sinchayee Yojana (PMKSY) Drip & Sprinkler Subsidy",
        "short_description": "Up to 55% financial subsidy for small and marginal farmers installing drip irrigation, micro-sprinklers, and farm ponds.",
        "detailed_description": "PMKSY focuses on water-use efficiency under 'Per Drop More Crop' by offering 55% financial assistance to small/marginal farmers and 45% to other farmers for micro-irrigation systems.",
        "provider": "Department of Agriculture & Farmers Welfare",
        "jurisdiction": "Central",
        "state": None,
        "benefit_type": "Financial Subsidy",
        "benefit_summary": "55% direct subsidy on equipment cost for drip and sprinkler irrigation units.",
        "gender_eligibility": "All",
        "social_categories": "All",
        "keyword": "farmer agriculture irrigation drip sprinkler water crop land cultivation farm",
    },
    {
        "id": "sch-farm-smam-007",
        "title": "Sub-Mission on Agricultural Mechanization (SMAM) Farm Machinery Subsidy",
        "short_description": "40% to 80% subsidy for farmers and Custom Hiring Centers (CHCs) purchasing tractors, rotavators, and harvesters.",
        "detailed_description": "SMAM makes modern mechanized agricultural machinery accessible to small farmers by subsidizing individual machinery purchases by up to 50% and community Custom Hiring Centers by up to 80%.",
        "provider": "Ministry of Agriculture & Farmers Welfare",
        "jurisdiction": "Central",
        "state": None,
        "benefit_type": "Equipment Subsidy",
        "benefit_summary": "Up to 80% subsidy for setting up Custom Hiring Centers or 50% for individual tractor/harvester purchase.",
        "gender_eligibility": "All",
        "social_categories": "All",
        "keyword": "farmer tractor machinery harvester rotavator agriculture farm equipment mechanization",
    },
    {
        "id": "sch-farm-pmmsy-008",
        "title": "Pradhan Mantri Matsya Sampada Yojana (PMMSY) Fisheries & Aquaculture Grant",
        "short_description": "40% to 60% financial grant for fish farmers, aquaculture entrepreneurs, and coastal fisherwomen for pond construction & boats.",
        "detailed_description": "PMMSY aims to double fishers' income by subsidizing biofloc units, recirculating aquaculture systems (RAS), motorboats, fish feed mills, and cold chain transport.",
        "provider": "Department of Fisheries, Ministry of Fisheries, Animal Husbandry and Dairying",
        "jurisdiction": "Central",
        "state": None,
        "benefit_type": "Financial Grant",
        "benefit_summary": "60% subsidy for Women/SC/ST fishers and 40% for General category aquaculture projects.",
        "gender_eligibility": "All",
        "social_categories": "All",
        "keyword": "farmer fish fisheries aquaculture pond motorboat marine fisherwoman coastal catch",
    },
    {
        "id": "sch-farm-nlm-009",
        "title": "National Livestock Mission (NLM) Dairy, Poultry & Goat Farming Subsidy",
        "short_description": "50% capital subsidy up to ₹50 Lakhs for setting up commercial goat, sheep, poultry, and pig breeding farms.",
        "detailed_description": "NLM promotes animal husbandry entrepreneurship by providing a 50% direct capital subsidy to farmers, FPOs, and youth for establishing high-yielding livestock breeding units.",
        "provider": "Department of Animal Husbandry and Dairying",
        "jurisdiction": "Central",
        "state": None,
        "benefit_type": "Capital Subsidy",
        "benefit_summary": "50% direct capital subsidy up to ₹50,00,000 for commercial livestock breeding farms.",
        "gender_eligibility": "All",
        "social_categories": "All",
        "keyword": "farmer livestock dairy poultry goat sheep cattle animal husbandry milk farm",
    },
    {
        "id": "sch-farm-pkvy-010",
        "title": "Paramparagat Krishi Vikas Yojana (PKVY) Organic Farming Financial Grant",
        "short_description": "₹50,000 per hectare financial assistance for farmers adopting certified organic farming and natural fertilizers.",
        "detailed_description": "Supports farmer clusters adopting chemical-free organic farming practices by funding organic seeds, bio-pesticides, vermicompost, and PGS organic certification.",
        "provider": "Ministry of Agriculture and Farmers Welfare",
        "jurisdiction": "Central",
        "state": None,
        "benefit_type": "Financial Assistance",
        "benefit_summary": "₹50,000 per hectare over 3 years directly deposited to farmer accounts.",
        "gender_eligibility": "All",
        "social_categories": "All",
        "keyword": "farmer organic farming bio fertilizer vermicompost crop soil natural agriculture",
    },

    # -------------------------------------------------------------------------
    # 3. STUDENTS / SCHOLARSHIPS / TECHNICAL SCHOLARS
    # -------------------------------------------------------------------------
    {
        "id": "sch-student-pmrf-011",
        "title": "Prime Minister's Research Fellowship (PMRF) for PhD & Technical Scholars",
        "short_description": "Monthly fellowship of ₹70,000 to ₹80,000 + ₹2 Lakhs annual research grant for top B.Tech/M.Tech students pursuing PhD at IITs & IISc.",
        "detailed_description": "PMRF attracts top talent into doctoral research at premier institutes (IITs, IISc, IISERs) by paying a monthly stipend starting at ₹70,000/month rising to ₹80,000/month in the 4th year.",
        "provider": "Ministry of Education",
        "jurisdiction": "Central",
        "state": None,
        "benefit_type": "Scholarship Fellowship",
        "benefit_summary": "Monthly stipend of ₹70,000 to ₹80,000 + ₹2,00,000 annual research contingency grant.",
        "gender_eligibility": "All",
        "social_categories": "All",
        "keyword": "student scholarship PhD research IIT IISc engineering doctoral fellowship university college",
    },
    {
        "id": "sch-student-pragati-012",
        "title": "AICTE Pragati Scholarship Scheme for Female Degree & Diploma Students",
        "short_description": "Annual scholarship of ₹50,000 per year for meritorious girl students admitted to AICTE approved technical colleges.",
        "detailed_description": "Encourages young women to pursue technical education in engineering, pharmacy, and architecture by paying ₹50,000 per annum towards tuition fees and college maintenance expenses.",
        "provider": "All India Council for Technical Education (AICTE), Ministry of Education",
        "jurisdiction": "Central",
        "state": None,
        "benefit_type": "Scholarship",
        "benefit_summary": "₹50,000 per year for up to 4 years for degree engineering girl students.",
        "gender_eligibility": "Female",
        "social_categories": "All",
        "keyword": "student female girl scholarship engineering diploma degree AICTE college technical tuition",
    },
    {
        "id": "sch-student-saksham-013",
        "title": "AICTE Saksham Scholarship Scheme for Differently Abled Students",
        "short_description": "Financial aid of ₹50,000 per year for specially-abled students pursuing technical degree and diploma courses.",
        "detailed_description": "Supports specially-abled students (disability >= 40%) admitted to AICTE technical colleges with ₹50,000 annually to cover college fees and assistive devices.",
        "provider": "AICTE & Ministry of Education",
        "jurisdiction": "Central",
        "state": None,
        "benefit_type": "Scholarship",
        "benefit_summary": "₹50,000 annual scholarship paid directly to student bank accounts.",
        "gender_eligibility": "All",
        "social_categories": "All",
        "keyword": "student scholarship disability differently abled specially abled AICTE technical college fee",
    },
    {
        "id": "sch-student-nos-014",
        "title": "National Overseas Scholarship (NOS) for Master's & PhD Abroad",
        "short_description": "Full tuition fee waiver + annual living allowance of ~$15,400 for SC/ST/Artisan students pursuing postgraduation in foreign universities.",
        "detailed_description": "Covers complete university tuition fees, annual maintenance allowance, visa fees, and return airfare for meritorious SC/ST students studying Master's or PhD programs in top 500 QS ranked global universities.",
        "provider": "Ministry of Social Justice and Empowerment",
        "jurisdiction": "Central",
        "state": None,
        "benefit_type": "Scholarship",
        "benefit_summary": "100% foreign tuition fee + USD 15,400 annual living allowance + international airfare.",
        "gender_eligibility": "All",
        "social_categories": "SC,ST",
        "keyword": "student scholarship abroad foreign foreign university masters PhD overseas study degree",
    },

    # -------------------------------------------------------------------------
    # 4. WOMEN / FEMALE ENTREPRENEURS / MATERNITY
    # -------------------------------------------------------------------------
    {
        "id": "sch-women-pmmvy-015",
        "title": "Pradhan Mantri Matru Vandana Yojana (PMMVY) Maternity Assistance",
        "short_description": "Direct cash benefit of ₹6,000 for pregnant women and lactating mothers for first and second (girl) child.",
        "detailed_description": "PMMVY provides partial wage compensation and nutritional financial support directly into the bank accounts of pregnant and lactating mothers across 3 developmental milestones.",
        "provider": "Ministry of Women and Child Development",
        "jurisdiction": "Central",
        "state": None,
        "benefit_type": "Financial Benefit",
        "benefit_summary": "₹6,000 total cash incentive paid directly in installments.",
        "gender_eligibility": "Female",
        "social_categories": "All",
        "keyword": "women female mother pregnant maternity child health nutrition cash benefit PMMVY",
    },
    {
        "id": "sch-women-tread-016",
        "title": "TREAD (Trade Related Entrepreneurship Assistance) Scheme for Women",
        "short_description": "Government grant up to 30% of total project cost for micro-business projects established by women Self-Help Groups (SHGs).",
        "detailed_description": "Empowers women entrepreneurs by offering non-repayable government grants of up to 30% for setting up micro-enterprises in tailoring, food processing, handicrafts, and IT services.",
        "provider": "Ministry of Micro, Small and Medium Enterprises",
        "jurisdiction": "Central",
        "state": None,
        "benefit_type": "Capital Grant",
        "benefit_summary": "30% non-repayable capital grant for women SHGs setting up micro enterprises.",
        "gender_eligibility": "Female",
        "social_categories": "All",
        "keyword": "women female entrepreneur business SHG self help group grant MSME micro enterprise trade",
    },

    # -------------------------------------------------------------------------
    # 5. ENTREPRENEURS / MSME / BUSINESS / STARTUPS
    # -------------------------------------------------------------------------
    {
        "id": "sch-biz-sisfs-017",
        "title": "Startup India Seed Fund Scheme (SISFS) for Early Stage Tech Startups",
        "short_description": "Financial assistance up to ₹20 Lakhs as grant for proof of concept & up to ₹50 Lakhs as debt for commercialization.",
        "detailed_description": "SISFS provides early-stage financial support to promising innovative startups for prototype development, product trials, market entry, and commercialization through approved incubators.",
        "provider": "DPIIT, Ministry of Commerce and Industry",
        "jurisdiction": "Central",
        "state": None,
        "benefit_type": "Grant & Seed Fund",
        "benefit_summary": "Up to ₹20,00,000 proof-of-concept grant + ₹50,00,000 commercialization debt fund.",
        "gender_eligibility": "All",
        "social_categories": "All",
        "keyword": "entrepreneur business startup seed fund technology innovation incubator commercialization loan",
    },
    {
        "id": "sch-biz-vishwakarma-018",
        "title": "PM Vishwakarma Yojana for Artisans and Craftspeople",
        "short_description": "Collateral-free loan of up to ₹3 Lakhs at 5% interest + ₹15,000 toolkit incentive for 18 traditional artisan trades.",
        "detailed_description": "Provides end-to-end holistic support to traditional craftsmen (carpenters, blacksmiths, goldsmiths, potters, masons, tailors) including skill training, ₹15,000 toolkit voucher, and low-interest credit.",
        "provider": "Ministry of MSME and Ministry of Skill Development",
        "jurisdiction": "Central",
        "state": None,
        "benefit_type": "Loan & Toolkit Grant",
        "benefit_summary": "₹3,00,000 collateral-free loan at 5% interest + ₹15,000 free toolkit voucher.",
        "gender_eligibility": "All",
        "social_categories": "All",
        "keyword": "entrepreneur artisan craftsperson vishwakarma carpenter tailor blacksmith potter loan toolkit skill",
    },
    {
        "id": "sch-biz-pmegp-019",
        "title": "Prime Minister's Employment Generation Programme (PMEGP)",
        "short_description": "Credit-linked capital subsidy of up to 35% for setting up new manufacturing or service micro-enterprises up to ₹50 Lakhs.",
        "detailed_description": "PMEGP helps unemployed youth and first-time entrepreneurs set up micro manufacturing projects (up to ₹50 Lakhs) or service projects (up to ₹20 Lakhs) with 15% to 35% margin money subsidy.",
        "provider": "KVIC & Ministry of MSME",
        "jurisdiction": "Central",
        "state": None,
        "benefit_type": "Capital Subsidy",
        "benefit_summary": "Up to 35% capital subsidy on project cost directly credited to loan account.",
        "gender_eligibility": "All",
        "social_categories": "All",
        "keyword": "entrepreneur business micro enterprise manufacturing service loan PMEGP KVIC MSME self employment",
    },

    # -------------------------------------------------------------------------
    # 6. SENIOR CITIZENS / ELDERLY
    # -------------------------------------------------------------------------
    {
        "id": "sch-senior-scss-020",
        "title": "Senior Citizen Savings Scheme (SCSS) High Returns Payout",
        "short_description": "Government-backed 8.2% p.a. quarterly interest payout savings account for individuals aged 60 years and above.",
        "detailed_description": "Offers senior citizens a safe high-yielding investment option up to ₹30 Lakhs with quarterly interest payouts and Section 80C income tax deduction benefits.",
        "provider": "Ministry of Finance & National Savings Institute",
        "jurisdiction": "Central",
        "state": None,
        "benefit_type": "Interest Payout",
        "benefit_summary": "8.2% per annum guaranteed quarterly interest payout on deposits up to ₹30 Lakhs.",
        "gender_eligibility": "All",
        "social_categories": "All",
        "keyword": "senior citizen elderly pension 60 years savings interest payout tax benefit",
    },
    {
        "id": "sch-senior-rvy-021",
        "title": "Rashtriya Vayoshri Yojana (RVYY) Assistive Devices for Elderly",
        "short_description": "Free physical aids and assisted-living devices (hearing aids, wheelchairs, spectacles) for senior citizens from BPL families.",
        "detailed_description": "Provides free high-quality walking sticks, elbow crutches, hearing aids, wheelchairs, artificial dentures, and spectacles to low-income senior citizens suffering from age-related physical infirmities.",
        "provider": "ALIMCO & Ministry of Social Justice and Empowerment",
        "jurisdiction": "Central",
        "state": None,
        "benefit_type": "Assistive Devices",
        "benefit_summary": "100% free distribution of customized wheelchairs, hearing aids, and spectacles.",
        "gender_eligibility": "All",
        "social_categories": "All",
        "keyword": "senior citizen elderly wheelchair hearing aid spectacles BPL assistance free aid",
    },
]


async def seed_rich_dataset():
    logger.info("Starting rich dataset expansion into schemora_dev.db...")

    async with AsyncSessionLocal() as db:
        added_count = 0
        for s in RICH_SCHEMES:
            s_id = s["id"]
            res = await db.execute(select(Scheme).where(Scheme.id == s_id))
            if res.scalar_one_or_none():
                logger.info(f"Scheme '{s['title']}' ({s_id}) already exists. Skipping.")
                continue

            slug = slugify(s["title"])
            scheme = Scheme(
                id=s_id,
                slug=slug,
                title=s["title"],
                short_description=s["short_description"],
                detailed_description=s["detailed_description"],
                provider=s["provider"],
                jurisdiction=s["jurisdiction"],
                state=s["state"],
                gender_eligibility=s["gender_eligibility"],
                social_categories=s["social_categories"],
                benefit_type=s["benefit_type"],
                benefit_summary=s["benefit_summary"],
                implementation_status="Implemented",
                is_published=True,
                application_deadline="2026-12-31",
            )
            db.add(scheme)
            await db.flush()

            # Add official source
            db_source = SchemeSource(
                scheme_id=s_id,
                source_name=f"{s['title']} Official Portal",
                url=f"https://www.india.gov.in/",
                source_type="OfficialPortal",
                last_verified_at="2026-09-01",
            )
            db.add(db_source)
            added_count += 1

        await db.commit()
        logger.info(f"Successfully inserted {added_count} new rich schemes into the database!")

        # Verify total database count
        total_res = await db.execute(select(Scheme))
        all_items = total_res.scalars().all()
        logger.info(f"Total schemes in database now: {len(all_items)}")


if __name__ == "__main__":
    asyncio.run(seed_rich_dataset())
