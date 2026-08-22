import 'package:schemora_frontend/features/schemes/domain/scheme_model.dart';

class DirectPortalInfo {
  final String sourceName;
  final String url;

  const DirectPortalInfo({required this.sourceName, required this.url});
}

class SchemeUrlResolver {
  static const Map<String, DirectPortalInfo> _knownDirectPortals = {
    'sch-central-apy-010': DirectPortalInfo(
      sourceName: 'PFRDA Atal Pension Yojana (APY) Direct Portal',
      url: 'https://npslite-nsdl.com/',
    ),
    'sch-central-pmkisan-004': DirectPortalInfo(
      sourceName: 'PM-KISAN Official Direct Portal',
      url: 'https://pmkisan.gov.in/',
    ),
    'sch-central-csss-001': DirectPortalInfo(
      sourceName: 'National Scholarship Portal (NSP Direct)',
      url: 'https://scholarships.gov.in/',
    ),
    'sch-central-pmis-003': DirectPortalInfo(
      sourceName: 'PM Internship Scheme Portal (MY Bharat)',
      url: 'https://pminternship.mca.gov.in/',
    ),
    'sch-central-mudra-009': DirectPortalInfo(
      sourceName: 'PMMY MUDRA Official Loan Portal',
      url: 'https://www.mudra.org.in/',
    ),
    'sch-central-pmfby-011': DirectPortalInfo(
      sourceName: 'PMFBY Crop Insurance Direct Portal',
      url: 'https://pmfby.gov.in/',
    ),
    'sch-central-pmay-012': DirectPortalInfo(
      sourceName: 'PMAY Housing Direct Portal',
      url: 'https://pmaymis.gov.in/',
    ),
    'sch-central-pmkvy-013': DirectPortalInfo(
      sourceName: 'PMKVY Skill India Portal',
      url: 'https://www.pmkvyofficial.org/',
    ),
    'sch-up-kanya-sumangala-014': DirectPortalInfo(
      sourceName: 'MKSY Uttar Pradesh Direct Portal',
      url: 'https://mksy.up.gov.in/',
    ),
    'sch-kar-gruha-lakshmi-019': DirectPortalInfo(
      sourceName: 'Seva Sindhu Karnataka Direct Portal',
      url: 'https://sevasindhugs.karnataka.gov.in/',
    ),
    'sch-guj-mysy-029': DirectPortalInfo(
      sourceName: 'MYSY Gujarat Scholarship Portal',
      url: 'https://mysy.guj.nic.in/',
    ),
    'sch-maharashtra-ladkibahin-006': DirectPortalInfo(
      sourceName: 'Mukhyamantri Ladki Bahin Maharashtra Portal',
      url: 'https://www.maharashtra.gov.in/',
    ),
    'sch-maharashtra-obc-postmatric-002': DirectPortalInfo(
      sourceName: 'MahaDBT Direct Scholarship Portal',
      url: 'https://mahadbt.maharashtra.gov.in/',
    ),
    'sch-central-ayushman-005': DirectPortalInfo(
      sourceName: 'PM-JAY Health Insurance Direct Portal',
      url: 'https://pmjay.gov.in/',
    ),
    'sch-central-pmsvanidhi-007': DirectPortalInfo(
      sourceName: 'PM SVANidhi Loan Direct Portal',
      url: 'https://pmsvanidhi.mohua.gov.in/',
    ),
    'sch-central-sukanya-008': DirectPortalInfo(
      sourceName: 'India Post Sukanya Samriddhi Portal',
      url: 'https://www.indiapost.gov.in/Financial/Pages/Content/SSY.aspx',
    ),
    'sch-central-matru-015': DirectPortalInfo(
      sourceName: 'PMMVY Direct Maternity Portal',
      url: 'https://pmmvy.wcd.gov.in/',
    ),
    'sch-central-kcc-016': DirectPortalInfo(
      sourceName: 'NABARD Kisan Credit Card Portal',
      url: 'https://www.nabard.org/content1.aspx?id=589',
    ),
    'sch-central-pmegp-018': DirectPortalInfo(
      sourceName: 'PMEGP e-Portal KVIC Direct',
      url: 'https://www.kviconline.gov.in/pmegpeportal/',
    ),
    'sch-central-ignoaps-019': DirectPortalInfo(
      sourceName: 'NSAP Social Pension Direct Portal',
      url: 'https://nsap.nic.in/',
    ),
    'sch-central-scss-020': DirectPortalInfo(
      sourceName: 'National Savings Institute SCSS Direct',
      url: 'https://www.nsiindia.gov.in/',
    ),
    'sch-central-naps-021': DirectPortalInfo(
      sourceName: 'NAPS Apprenticeship Direct Portal',
      url: 'https://www.apprenticeshipindia.gov.in/',
    ),
    'sch-central-pmsuryaghar-022': DirectPortalInfo(
      sourceName: 'PM Surya Ghar Official Solar Portal',
      url: 'https://pmsuryaghar.gov.in/',
    ),
  };

  /// Resolves the exact direct official application URL and source authority name for a scheme.
  static DirectPortalInfo getDirectPortal(SchemeModel scheme) {
    // 1. Check direct map by ID
    if (_knownDirectPortals.containsKey(scheme.id)) {
      return _knownDirectPortals[scheme.id]!;
    }

    // 2. Check if scheme model sources contain a valid non-myscheme direct link
    if (scheme.sources.isNotEmpty) {
      for (final src in scheme.sources) {
        if (src.url.isNotEmpty && !src.url.contains('myscheme.gov.in/schemes/')) {
          return DirectPortalInfo(sourceName: src.sourceName, url: src.url);
        }
      }
    }

    // 3. Match by scheme title keywords if ID not matched
    final title = scheme.title.toLowerCase();

    if (title.contains('atal pension') || title.contains('apy')) {
      return const DirectPortalInfo(
        sourceName: 'PFRDA Atal Pension Yojana (APY) Direct Portal',
        url: 'https://npslite-nsdl.com/',
      );
    }
    if (title.contains('kisan samman') || title.contains('pm-kisan')) {
      return const DirectPortalInfo(
        sourceName: 'PM-KISAN Official Direct Portal',
        url: 'https://pmkisan.gov.in/',
      );
    }
    if (title.contains('scholarship') && title.contains('central')) {
      return const DirectPortalInfo(
        sourceName: 'National Scholarship Portal (NSP Direct)',
        url: 'https://scholarships.gov.in/',
      );
    }
    if (title.contains('internship')) {
      return const DirectPortalInfo(
        sourceName: 'PM Internship Scheme Portal (MY Bharat)',
        url: 'https://pminternship.mca.gov.in/',
      );
    }
    if (title.contains('mudra')) {
      return const DirectPortalInfo(
        sourceName: 'PMMY MUDRA Official Loan Portal',
        url: 'https://www.mudra.org.in/',
      );
    }
    if (title.contains('fasal bima') || title.contains('pmfby')) {
      return const DirectPortalInfo(
        sourceName: 'PMFBY Crop Insurance Direct Portal',
        url: 'https://pmfby.gov.in/',
      );
    }
    if (title.contains('awas') || title.contains('pmay')) {
      return const DirectPortalInfo(
        sourceName: 'PMAY Housing Direct Portal',
        url: 'https://pmaymis.gov.in/',
      );
    }
    if (title.contains('kaushal') || title.contains('pmkvy')) {
      return const DirectPortalInfo(
        sourceName: 'PMKVY Skill India Portal',
        url: 'https://www.pmkvyofficial.org/',
      );
    }
    if (title.contains('kanya sumangala')) {
      return const DirectPortalInfo(
        sourceName: 'MKSY Uttar Pradesh Direct Portal',
        url: 'https://mksy.up.gov.in/',
      );
    }
    if (title.contains('gruha lakshmi')) {
      return const DirectPortalInfo(
        sourceName: 'Seva Sindhu Karnataka Direct Portal',
        url: 'https://sevasindhugs.karnataka.gov.in/',
      );
    }
    if (title.contains('mysy')) {
      return const DirectPortalInfo(
        sourceName: 'MYSY Gujarat Scholarship Portal',
        url: 'https://mysy.guj.nic.in/',
      );
    }
    if (title.contains('ladki bahin')) {
      return const DirectPortalInfo(
        sourceName: 'Mukhyamantri Ladki Bahin Maharashtra Portal',
        url: 'https://www.maharashtra.gov.in/',
      );
    }
    if (title.contains('post matric') || title.contains('mahadbt')) {
      return const DirectPortalInfo(
        sourceName: 'MahaDBT Direct Scholarship Portal',
        url: 'https://mahadbt.maharashtra.gov.in/',
      );
    }
    if (title.contains('ayushman') || title.contains('pm-jay')) {
      return const DirectPortalInfo(
        sourceName: 'PM-JAY Health Insurance Direct Portal',
        url: 'https://pmjay.gov.in/',
      );
    }
    if (title.contains('svanidhi')) {
      return const DirectPortalInfo(
        sourceName: 'PM SVANidhi Loan Direct Portal',
        url: 'https://pmsvanidhi.mohua.gov.in/',
      );
    }
    if (title.contains('sukanya')) {
      return const DirectPortalInfo(
        sourceName: 'India Post Sukanya Samriddhi Portal',
        url: 'https://www.indiapost.gov.in/',
      );
    }
    if (title.contains('matru') || title.contains('pmmvy')) {
      return const DirectPortalInfo(
        sourceName: 'PMMVY Direct Maternity Portal',
        url: 'https://pmmvy.wcd.gov.in/',
      );
    }

    // Default direct source from scheme or national portal fallback
    if (scheme.sources.isNotEmpty && scheme.sources.first.url.isNotEmpty) {
      return DirectPortalInfo(
        sourceName: scheme.sources.first.sourceName,
        url: scheme.sources.first.url,
      );
    }

    return DirectPortalInfo(
      sourceName: '${scheme.title} Direct Official Portal',
      url: 'https://www.india.gov.in/',
    );
  }
}
