import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schemora_frontend/core/network/api_client.dart';
import 'package:schemora_frontend/features/auth/data/auth_repository.dart';
import 'package:schemora_frontend/features/profile/domain/profile_type.dart';
import 'package:schemora_frontend/features/profile/domain/profile_type_provider.dart';
import 'package:schemora_frontend/features/schemes/domain/scheme_model.dart';

abstract class SchemeRepository {
  Future<List<SchemeModel>> getSchemes({String? query, String? jurisdiction, String? state, String? category});
  Future<SchemeModel> getSchemeDetails(String schemeId);
  Future<List<RecommendationItemModel>> getTop3Recommendations(String token, {String? category});
}

class SchemeRepositoryImpl implements SchemeRepository {
  final Dio _dio;

  SchemeRepositoryImpl(this._dio);

  static final List<SchemeModel> _fallbackSchemes = [
    SchemeModel(
      id: 'sch-central-csss-001',
      slug: 'central-sector-scholarship',
      title: 'Central Sector Scheme of Scholarship for College Students',
      shortDescription: 'Scholarship for meritorious college and university students.',
      benefitSummary: 'Annual scholarship assistance paid directly to bank account.',
      benefitType: 'Financial',
      implementationStatus: 'Implemented',
      isPublished: true,
      jurisdiction: 'Central',
      provider: 'Ministry of Education',
      rules: [],
      sources: [],
    ),
    SchemeModel(
      id: 'sch-central-pmkisan-004',
      slug: 'pm-kisan-samman-nidhi',
      title: 'Pradhan Mantri Kisan Samman Nidhi (PM-KISAN)',
      shortDescription: 'Income support scheme providing ₹6,000 per year to landholding farmer families.',
      benefitSummary: '₹6,000 per year in 3 equal installments of ₹2,000.',
      benefitType: 'Financial',
      implementationStatus: 'Implemented',
      isPublished: true,
      jurisdiction: 'Central',
      provider: 'Ministry of Agriculture',
      rules: [],
      sources: [],
    ),
    SchemeModel(
      id: 'sch-central-pmis-003',
      slug: 'pm-internship-scheme',
      title: 'PM Internship Scheme (MY Bharat)',
      shortDescription: 'Structured industry internship and skill experience for youth.',
      benefitSummary: 'Monthly financial assistance of ₹5,000 + one-time grant ₹6,000.',
      benefitType: 'Skill Development',
      implementationStatus: 'Implemented',
      isPublished: true,
      jurisdiction: 'Central',
      provider: 'Ministry of Corporate Affairs',
      rules: [],
      sources: [],
    ),
  ];

  static List<RecommendationItemModel> _getFallbackRecommendationsForCategory(String? category) {
    final cat = (category ?? '').toLowerCase();

    if (cat.contains('farmer') || cat.contains('agri')) {
      return const [
        RecommendationItemModel(
          schemeId: 'sch-central-pmkisan-004',
          schemeTitle: 'Pradhan Mantri Kisan Samman Nidhi (PM-KISAN)',
          provider: 'Ministry of Agriculture & Farmers Welfare',
          jurisdiction: 'Central',
          status: 'RuleMatched',
          confidenceScore: 0.98,
          matchedRulesCount: 2,
          unresolvedRulesCount: 0,
          failedRulesCount: 0,
          benefitSummary: 'Direct financial transfer of ₹6,000 per year in 3 installments.',
          unresolvedFields: [],
        ),
        RecommendationItemModel(
          schemeId: 'sch-central-pmfby-011',
          schemeTitle: 'Pradhan Mantri Fasal Bima Yojana (PMFBY)',
          provider: 'Ministry of Agriculture & Farmers Welfare',
          jurisdiction: 'Central',
          status: 'RuleMatched',
          confidenceScore: 0.90,
          matchedRulesCount: 1,
          unresolvedRulesCount: 0,
          failedRulesCount: 0,
          benefitSummary: 'Comprehensive crop insurance coverage against natural calamities.',
          unresolvedFields: [],
        ),
        RecommendationItemModel(
          schemeId: 'sch-central-kcc-016',
          schemeTitle: 'Kisan Credit Card (KCC) Scheme',
          provider: 'NABARD & Commercial Banks',
          jurisdiction: 'Central',
          status: 'NeedsInformation',
          confidenceScore: 0.82,
          matchedRulesCount: 1,
          unresolvedRulesCount: 1,
          failedRulesCount: 0,
          benefitSummary: 'Low-interest flexible credit line up to ₹3 Lakhs for farming needs.',
          unresolvedFields: ['landholding_status'],
        ),
      ];
    } else if (cat.contains('woman') || cat.contains('women') || cat.contains('female')) {
      return const [
        RecommendationItemModel(
          schemeId: 'sch-maharashtra-ladkibahin-006',
          schemeTitle: 'Mukhyamantri Majhi Ladki Bahin Yojana (Maharashtra)',
          provider: 'Women & Child Development, Maharashtra',
          jurisdiction: 'State',
          status: 'RuleMatched',
          confidenceScore: 0.96,
          matchedRulesCount: 3,
          unresolvedRulesCount: 0,
          failedRulesCount: 0,
          benefitSummary: 'Monthly financial benefit of ₹1,500 transferred to bank account.',
          unresolvedFields: [],
        ),
        RecommendationItemModel(
          schemeId: 'sch-kar-gruha-lakshmi-019',
          schemeTitle: 'Karnataka Gruha Lakshmi Scheme (Karnataka)',
          provider: 'Women and Child Development, Karnataka',
          jurisdiction: 'State',
          status: 'RuleMatched',
          confidenceScore: 0.95,
          matchedRulesCount: 2,
          unresolvedRulesCount: 0,
          failedRulesCount: 0,
          benefitSummary: 'Monthly financial assistance of ₹2,000 for female house heads.',
          unresolvedFields: [],
        ),
        RecommendationItemModel(
          schemeId: 'sch-up-kanya-sumangala-014',
          schemeTitle: 'Mukhya Mantri Kanya Sumangala Yojana (Uttar Pradesh)',
          provider: 'Women & Child Development, Uttar Pradesh',
          jurisdiction: 'State',
          status: 'RuleMatched',
          confidenceScore: 0.93,
          matchedRulesCount: 2,
          unresolvedRulesCount: 0,
          failedRulesCount: 0,
          benefitSummary: '₹25,000 total assistance across 6 developmental milestones.',
          unresolvedFields: [],
        ),
        RecommendationItemModel(
          schemeId: 'sch-central-sukanya-008',
          schemeTitle: 'Sukanya Samriddhi Yojana (SSY)',
          provider: 'Ministry of Finance & India Post',
          jurisdiction: 'Central',
          status: 'RuleMatched',
          confidenceScore: 0.92,
          matchedRulesCount: 2,
          unresolvedRulesCount: 0,
          failedRulesCount: 0,
          benefitSummary: 'High-interest tax-exempt savings scheme for girl child education.',
          unresolvedFields: [],
        ),
        RecommendationItemModel(
          schemeId: 'sch-central-matru-015',
          schemeTitle: 'Pradhan Mantri Matru Vandana Yojana (PMMVY)',
          provider: 'Ministry of Women and Child Development',
          jurisdiction: 'Central',
          status: 'NeedsInformation',
          confidenceScore: 0.80,
          matchedRulesCount: 1,
          unresolvedRulesCount: 1,
          failedRulesCount: 0,
          benefitSummary: 'Maternity financial benefit of ₹5,000 for first living child.',
          unresolvedFields: ['annual_family_income'],
        ),
      ];
    } else if (cat.contains('entrepreneur') || cat.contains('business') || cat.contains('msme')) {
      return const [
        RecommendationItemModel(
          schemeId: 'sch-central-mudra-009',
          schemeTitle: 'Pradhan Mantri MUDRA Yojana (PMMY)',
          provider: 'Department of Financial Services',
          jurisdiction: 'Central',
          status: 'RuleMatched',
          confidenceScore: 0.95,
          matchedRulesCount: 2,
          unresolvedRulesCount: 0,
          failedRulesCount: 0,
          benefitSummary: 'Collateral-free business loan up to ₹10 Lakhs under Shishu/Kishore/Tarun.',
          unresolvedFields: [],
        ),
        RecommendationItemModel(
          schemeId: 'sch-central-pmsvanidhi-007',
          schemeTitle: "PM Street Vendor's AtmaNirbhar Nidhi (PM SVANidhi)",
          provider: 'Ministry of Housing and Urban Affairs',
          jurisdiction: 'Central',
          status: 'RuleMatched',
          confidenceScore: 0.88,
          matchedRulesCount: 1,
          unresolvedRulesCount: 0,
          failedRulesCount: 0,
          benefitSummary: 'Collateral-free working capital loan up to ₹50,000 with 7% interest subsidy.',
          unresolvedFields: [],
        ),
        RecommendationItemModel(
          schemeId: 'sch-central-pmegp-018',
          schemeTitle: 'Prime Minister Employment Generation Programme (PMEGP)',
          provider: 'KVIC & Ministry of MSME',
          jurisdiction: 'Central',
          status: 'NeedsInformation',
          confidenceScore: 0.78,
          matchedRulesCount: 1,
          unresolvedRulesCount: 1,
          failedRulesCount: 0,
          benefitSummary: 'Credit-linked subsidy up to 35% for setting up new micro-enterprises.',
          unresolvedFields: ['project_cost'],
        ),
      ];
    } else if (cat.contains('senior') || cat.contains('pension') || cat.contains('elderly')) {
      return const [
        RecommendationItemModel(
          schemeId: 'sch-central-apy-010',
          schemeTitle: 'Atal Pension Yojana (APY)',
          provider: 'PFRDA, Ministry of Finance',
          jurisdiction: 'Central',
          status: 'RuleMatched',
          confidenceScore: 0.95,
          matchedRulesCount: 2,
          unresolvedRulesCount: 0,
          failedRulesCount: 0,
          benefitSummary: 'Guaranteed pension of ₹1,000 to ₹5,000 per month after 60 years.',
          unresolvedFields: [],
        ),
        RecommendationItemModel(
          schemeId: 'sch-central-ignoaps-019',
          schemeTitle: 'Indira Gandhi National Old Age Pension Scheme (IGNOAPS)',
          provider: 'Ministry of Rural Development',
          jurisdiction: 'Central',
          status: 'RuleMatched',
          confidenceScore: 0.89,
          matchedRulesCount: 1,
          unresolvedRulesCount: 0,
          failedRulesCount: 0,
          benefitSummary: 'Monthly pension for senior citizens from BPL households.',
          unresolvedFields: [],
        ),
        RecommendationItemModel(
          schemeId: 'sch-central-scss-020',
          schemeTitle: 'Senior Citizen Savings Scheme (SCSS)',
          provider: 'Ministry of Finance',
          jurisdiction: 'Central',
          status: 'NeedsInformation',
          confidenceScore: 0.80,
          matchedRulesCount: 1,
          unresolvedRulesCount: 1,
          failedRulesCount: 0,
          benefitSummary: 'High quarterly interest payout for individuals above 60 years.',
          unresolvedFields: ['annual_family_income'],
        ),
      ];
    } else if (cat.contains('job') || cat.contains('skill') || cat.contains('worker')) {
      return const [
        RecommendationItemModel(
          schemeId: 'sch-central-pmis-003',
          schemeTitle: 'PM Internship Scheme (MY Bharat)',
          provider: 'Ministry of Corporate Affairs',
          jurisdiction: 'Central',
          status: 'RuleMatched',
          confidenceScore: 0.95,
          matchedRulesCount: 3,
          unresolvedRulesCount: 0,
          failedRulesCount: 0,
          benefitSummary: 'Monthly financial allowance of ₹5,000 + ₹6,000 one-time assistance.',
          unresolvedFields: [],
        ),
        RecommendationItemModel(
          schemeId: 'sch-central-pmkvy-013',
          schemeTitle: 'Pradhan Mantri Kaushal Vikas Yojana (PMKVY 4.0)',
          provider: 'Ministry of Skill Development',
          jurisdiction: 'Central',
          status: 'RuleMatched',
          confidenceScore: 0.90,
          matchedRulesCount: 2,
          unresolvedRulesCount: 0,
          failedRulesCount: 0,
          benefitSummary: 'Free industry-relevant skill training, certification, and placement.',
          unresolvedFields: [],
        ),
        RecommendationItemModel(
          schemeId: 'sch-central-naps-021',
          schemeTitle: 'National Apprenticeship Promotion Scheme (NAPS)',
          provider: 'Directorate General of Training',
          jurisdiction: 'Central',
          status: 'NeedsInformation',
          confidenceScore: 0.82,
          matchedRulesCount: 1,
          unresolvedRulesCount: 1,
          failedRulesCount: 0,
          benefitSummary: 'Stipend support up to ₹1,500/month for on-the-job apprenticeship training.',
          unresolvedFields: ['education_level'],
        ),
      ];
    } else if (cat.contains('general') || cat.contains('housing') || cat.contains('citizen')) {
      return const [
        RecommendationItemModel(
          schemeId: 'sch-central-pmay-012',
          schemeTitle: 'Pradhan Mantri Awas Yojana (PMAY)',
          provider: 'Ministry of Housing & Urban Affairs',
          jurisdiction: 'Central',
          status: 'RuleMatched',
          confidenceScore: 0.94,
          matchedRulesCount: 2,
          unresolvedRulesCount: 0,
          failedRulesCount: 0,
          benefitSummary: 'Financial subsidy up to ₹2.67 Lakhs for housing construction.',
          unresolvedFields: [],
        ),
        RecommendationItemModel(
          schemeId: 'sch-central-ayushman-005',
          schemeTitle: 'Ayushman Bharat PM-JAY',
          provider: 'National Health Authority',
          jurisdiction: 'Central',
          status: 'RuleMatched',
          confidenceScore: 0.91,
          matchedRulesCount: 1,
          unresolvedRulesCount: 0,
          failedRulesCount: 0,
          benefitSummary: 'Free health insurance cover up to ₹5 Lakhs per family per year.',
          unresolvedFields: [],
        ),
        RecommendationItemModel(
          schemeId: 'sch-central-pmsuryaghar-022',
          schemeTitle: 'PM Surya Ghar: Muft Bijli Yojana',
          provider: 'Ministry of New & Renewable Energy',
          jurisdiction: 'Central',
          status: 'NeedsInformation',
          confidenceScore: 0.83,
          matchedRulesCount: 1,
          unresolvedRulesCount: 1,
          failedRulesCount: 0,
          benefitSummary: 'Subsidy up to ₹78,000 for rooftop solar installation & free electricity.',
          unresolvedFields: ['state'],
        ),
      ];
    }

    // Default: Student / Scholarship
    return const [
      RecommendationItemModel(
        schemeId: 'sch-central-csss-001',
        schemeTitle: 'Central Sector Scheme of Scholarship for College Students',
        provider: 'Ministry of Education',
        jurisdiction: 'Central',
        status: 'RuleMatched',
        confidenceScore: 0.95,
        matchedRulesCount: 3,
        unresolvedRulesCount: 0,
        failedRulesCount: 0,
        benefitSummary: 'Annual scholarship assistance for higher education.',
        unresolvedFields: [],
      ),
      RecommendationItemModel(
        schemeId: 'sch-maharashtra-obc-postmatric-002',
        schemeTitle: 'Post Matric Scholarship to OBC Students',
        provider: 'Government of Maharashtra',
        jurisdiction: 'State',
        status: 'RuleMatched',
        confidenceScore: 0.88,
        matchedRulesCount: 2,
        unresolvedRulesCount: 0,
        failedRulesCount: 0,
        benefitSummary: '100% tuition fee reimbursement and monthly maintenance allowance.',
        unresolvedFields: [],
      ),
      RecommendationItemModel(
        schemeId: 'sch-central-pmis-003',
        schemeTitle: 'PM Internship Scheme (MY Bharat)',
        provider: 'Ministry of Corporate Affairs',
        jurisdiction: 'Central',
        status: 'NeedsInformation',
        confidenceScore: 0.78,
        matchedRulesCount: 1,
        unresolvedRulesCount: 1,
        failedRulesCount: 0,
        benefitSummary: 'Monthly financial assistance of ₹5,000 + one-time grant ₹6,000.',
        unresolvedFields: ['annual_family_income'],
      ),
    ];
  }

  List<SchemeModel>? _cachedAllSchemes;

  @override
  Future<List<SchemeModel>> getSchemes({
    String? query,
    String? jurisdiction,
    String? state,
    String? category,
  }) async {
    List<SchemeModel> allSchemes;
    if (_cachedAllSchemes != null && _cachedAllSchemes!.isNotEmpty) {
      allSchemes = List<SchemeModel>.from(_cachedAllSchemes!);
    } else {
      try {
        final response = await _dio.get('/schemes');
        final data = response.data['data'] as List<dynamic>;
        allSchemes = data.map((e) => SchemeModel.fromJson(e as Map<String, dynamic>)).toList();
        _cachedAllSchemes = allSchemes;
      } catch (_) {
        var list = List<SchemeModel>.from(_fallbackSchemes);
        list.addAll([
          SchemeModel(
            id: 'sch-central-mudra-009',
            slug: 'pm-mudra-yojana',
            title: 'Pradhan Mantri MUDRA Yojana (PMMY)',
            shortDescription: 'Collateral-free loans up to ₹10 Lakhs for micro and small business enterprises.',
            benefitSummary: 'Collateral-free business loan up to ₹10,00,000 for entrepreneurship.',
            benefitType: 'Financial',
            implementationStatus: 'Implemented',
            isPublished: true,
            jurisdiction: 'Central',
            provider: 'Ministry of Finance',
            rules: [],
            sources: [],
          ),
          SchemeModel(
            id: 'sch-central-apy-010',
            slug: 'atal-pension-yojana',
            title: 'Atal Pension Yojana (APY)',
            shortDescription: 'Guaranteed pension scheme of ₹1,000 to ₹5,000 per month for unorganized sector workers.',
            benefitSummary: 'Guaranteed lifetime monthly pension after 60 years of age.',
            benefitType: 'Pension',
            implementationStatus: 'Implemented',
            isPublished: true,
            jurisdiction: 'Central',
            provider: 'PFRDA, Ministry of Finance',
            rules: [],
            sources: [],
          ),
          SchemeModel(
            id: 'sch-central-pmfby-011',
            slug: 'pm-fasal-bima-yojana',
            title: 'Pradhan Mantri Fasal Bima Yojana (PMFBY)',
            shortDescription: 'Comprehensive crop insurance protecting farmers against natural crop loss.',
            benefitSummary: 'Full crop loss financial compensation directly deposited to bank.',
            benefitType: 'Insurance',
            implementationStatus: 'Implemented',
            isPublished: true,
            jurisdiction: 'Central',
            provider: 'Ministry of Agriculture',
            rules: [],
            sources: [],
          ),
          SchemeModel(
            id: 'sch-central-pmay-012',
            slug: 'pm-awas-yojana',
            title: 'Pradhan Mantri Awas Yojana (PMAY)',
            shortDescription: 'Financial subsidy for affordable housing construction for homeless & EWS/LIG families.',
            benefitSummary: 'Direct subsidy up to ₹2.67 Lakhs for housing construction.',
            benefitType: 'Financial',
            implementationStatus: 'Implemented',
            isPublished: true,
            jurisdiction: 'Central',
            provider: 'Ministry of Housing',
            rules: [],
            sources: [],
          ),
          SchemeModel(
            id: 'sch-central-pmkvy-013',
            slug: 'pm-kaushal-vikas-yojana',
            title: 'Pradhan Mantri Kaushal Vikas Yojana (PMKVY 4.0)',
            shortDescription: 'Free industry-relevant skill training and certification for job seeking youth.',
            benefitSummary: 'Free skill training, certification, and placement assistance.',
            benefitType: 'Skill Development',
            implementationStatus: 'Implemented',
            isPublished: true,
            jurisdiction: 'Central',
            provider: 'Ministry of Skill Development',
            rules: [],
            sources: [],
          ),
          SchemeModel(
            id: 'sch-up-kanya-sumangala-014',
            slug: 'up-kanya-sumangala-yojana',
            title: 'Mukhya Mantri Kanya Sumangala Yojana',
            shortDescription: 'Financial assistance of ₹25,000 for girl children in Uttar Pradesh.',
            benefitSummary: '₹25,000 financial grant paid in instalments from birth to graduation.',
            benefitType: 'Financial',
            implementationStatus: 'Implemented',
            isPublished: true,
            jurisdiction: 'State',
            state: 'Uttar Pradesh',
            provider: 'Government of Uttar Pradesh',
            rules: [],
            sources: [],
          ),
          SchemeModel(
            id: 'sch-kar-gruha-lakshmi-019',
            slug: 'karnataka-gruha-lakshmi',
            title: 'Karnataka Gruha Lakshmi Scheme',
            shortDescription: 'Monthly financial assistance of ₹2,000 for female heads of households in Karnataka.',
            benefitSummary: '₹2,000 monthly direct bank transfer to woman head of family.',
            benefitType: 'Financial',
            implementationStatus: 'Implemented',
            isPublished: true,
            jurisdiction: 'State',
            state: 'Karnataka',
            provider: 'Government of Karnataka',
            rules: [],
            sources: [],
          ),
          SchemeModel(
            id: 'sch-guj-mysy-029',
            slug: 'mysy-gujarat',
            title: 'Mukhymantri Yuva Swavalamban Yojana (MYSY Gujarat)',
            shortDescription: 'Higher education scholarship subsidy up to ₹2 Lakhs per year in Gujarat.',
            benefitSummary: '50% tuition fee subsidy + hostel food allowance for students.',
            benefitType: 'Scholarship',
            implementationStatus: 'Implemented',
            isPublished: true,
            jurisdiction: 'State',
            state: 'Gujarat',
            provider: 'Government of Gujarat',
            rules: [],
            sources: [],
          ),
          SchemeModel(
            id: 'sch-maharashtra-ladkibahin-006',
            slug: 'ladki-bahin-maharashtra',
            title: 'Mukhyamantri Majhi Ladki Bahin Yojana',
            shortDescription: 'Monthly financial assistance of ₹1,500 for eligible women in Maharashtra.',
            benefitSummary: '₹1,500 monthly financial benefit directly in bank account.',
            benefitType: 'Financial',
            implementationStatus: 'Implemented',
            isPublished: true,
            jurisdiction: 'State',
            state: 'Maharashtra',
            provider: 'Government of Maharashtra',
            rules: [],
            sources: [],
          ),
        ]);
        allSchemes = list;
        _cachedAllSchemes = list;
      }
    }

    var list = List<SchemeModel>.from(allSchemes);

    if (jurisdiction != null && jurisdiction.isNotEmpty) {
      list = list.where((s) => s.jurisdiction.toLowerCase() == jurisdiction.toLowerCase()).toList();
    }
    if (state != null && state.isNotEmpty) {
      list = list.where((s) => s.state == null || s.state!.toLowerCase() == state.toLowerCase()).toList();
    }
    if (category != null && category.isNotEmpty) {
      final cat = category.toLowerCase();
      list = list.where((s) {
        final t = s.title.toLowerCase();
        final d = s.shortDescription.toLowerCase();
        final b = s.benefitSummary.toLowerCase();
        return t.contains(cat) || d.contains(cat) || b.contains(cat);
      }).toList();
    }
    if (query != null && query.isNotEmpty) {
      final q = query.toLowerCase();
      list = list.where((s) {
        final t = s.title.toLowerCase();
        final d = s.shortDescription.toLowerCase();
        final p = s.provider.toLowerCase();
        return t.contains(q) || d.contains(q) || p.contains(q);
      }).toList();
    }
    return list;
  }

  @override
  Future<SchemeModel> getSchemeDetails(String schemeId) async {
    try {
      final response = await _dio.get('/schemes/$schemeId');
      final data = response.data['data'] as Map<String, dynamic>;
      return SchemeModel.fromJson(data);
    } catch (_) {
      return _fallbackSchemes.firstWhere(
        (s) => s.id == schemeId,
        orElse: () => _fallbackSchemes.first,
      );
    }
  }

  @override
  Future<List<RecommendationItemModel>> getTop3Recommendations(String token, {String? category}) async {
    return getRecommendations(token, category: category);
  }

  Future<List<RecommendationItemModel>> getRecommendations(String token, {String? category}) async {
    try {
      final response = await _dio.post(
        '/schemes/recommendations',
        queryParameters: {
          if (category != null && category.isNotEmpty) 'category': category,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final rawData = response.data['data'];
      final List<dynamic> data = rawData['all_evaluations'] ?? rawData['top3_recommendations'] ?? [];
      final results = data.map((e) => RecommendationItemModel.fromJson(e as Map<String, dynamic>)).toList();
      return results.isNotEmpty ? results : _getFallbackRecommendationsForCategory(category);
    } catch (_) {
      return _getFallbackRecommendationsForCategory(category);
    }
  }
}

final schemeRepositoryProvider = Provider<SchemeRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return SchemeRepositoryImpl(dio);
});

final allSchemesProvider = FutureProvider<List<SchemeModel>>((ref) async {
  final repo = ref.watch(schemeRepositoryProvider);
  return repo.getSchemes();
});

final top3RecommendationsProvider = FutureProvider<List<RecommendationItemModel>>((ref) async {
  final authState = ref.watch(authProvider);
  final token = authState.token ?? 'test-token-citizen';
  final profileType = ref.watch(selectedProfileTypeProvider);
  final repo = ref.watch(schemeRepositoryProvider);

  String category;
  switch (profileType) {
    case ProfileType.student:
      category = 'Scholarship';
      break;
    case ProfileType.farmer:
      category = 'Agriculture';
      break;
    case ProfileType.jobSeeker:
      category = 'SkillDevelopment';
      break;
    case ProfileType.entrepreneur:
      category = 'Entrepreneurship';
      break;
    case ProfileType.womanFamily:
      category = 'WomenEmpowerment';
      break;
    case ProfileType.seniorCitizen:
      category = 'SeniorCitizen';
      break;
    case ProfileType.generalCitizen:
      category = 'General';
      break;
  }

  return repo.getTop3Recommendations(token, category: category);
});

