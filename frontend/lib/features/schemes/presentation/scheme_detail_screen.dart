import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:schemora_frontend/core/theme/app_theme.dart';
import 'package:schemora_frontend/core/utils/scheme_url_resolver.dart';
import 'package:schemora_frontend/core/utils/url_launcher_helper.dart';
import 'package:schemora_frontend/core/widgets/common_states.dart';
import 'package:schemora_frontend/core/widgets/dashboard_button.dart';
import 'package:schemora_frontend/features/profile/domain/profile_type.dart';
import 'package:schemora_frontend/features/profile/domain/profile_type_provider.dart';
import 'package:schemora_frontend/features/saved_schemes/data/saved_scheme_repository.dart';
import 'package:schemora_frontend/features/schemes/data/scheme_repository.dart';
import 'package:schemora_frontend/features/schemes/domain/scheme_model.dart';

class SchemeDetailScreen extends ConsumerStatefulWidget {
  final String schemeId;

  const SchemeDetailScreen({super.key, required this.schemeId});

  @override
  ConsumerState<SchemeDetailScreen> createState() => _SchemeDetailScreenState();
}

class _SchemeDetailScreenState extends ConsumerState<SchemeDetailScreen> {
  bool _isAutoFilledApplied = true;
  late Future<SchemeModel> _schemeDetailsFuture;

  @override
  void initState() {
    super.initState();
    _schemeDetailsFuture = ref.read(schemeRepositoryProvider).getSchemeDetails(widget.schemeId);
  }

  ProfileType _detectSchemeProfileType(SchemeModel scheme) {
    final text = '${scheme.title} ${scheme.shortDescription} ${scheme.benefitSummary}'.toLowerCase();

    if (text.contains('kisan') ||
        text.contains('fasal') ||
        text.contains('bima') ||
        text.contains('raitha') ||
        text.contains('crop') ||
        text.contains('farm') ||
        text.contains('agri')) {
      return ProfileType.farmer;
    }
    if (text.contains('mudra') ||
        text.contains('svanidhi') ||
        text.contains('pmegp') ||
        text.contains('business') ||
        text.contains('enterprise') ||
        text.contains('msme') ||
        text.contains('loan') ||
        text.contains('doctor') ||
        text.contains('clinic')) {
      return ProfileType.entrepreneur;
    }
    if (text.contains('scholarship') ||
        text.contains('mysy') ||
        text.contains('vidya') ||
        text.contains('student') ||
        text.contains('college') ||
        text.contains('post matric') ||
        text.contains('internship') ||
        text.contains('phd') ||
        text.contains('fellowship')) {
      return ProfileType.student;
    }
    if (text.contains('pudhumai') ||
        text.contains('ladki') ||
        text.contains('bahin') ||
        text.contains('gruha') ||
        text.contains('lakshmi') ||
        text.contains('sumangala') ||
        text.contains('sukanya') ||
        text.contains('matru') ||
        text.contains('women') ||
        text.contains('female') ||
        text.contains('girl')) {
      return ProfileType.womanFamily;
    }
    if (text.contains('pension') ||
        text.contains('apy') ||
        text.contains('ignoaps') ||
        text.contains('senior') ||
        text.contains('scss') ||
        text.contains('old age')) {
      return ProfileType.seniorCitizen;
    }
    if (text.contains('kaushal') ||
        text.contains('pmkvy') ||
        text.contains('naps') ||
        text.contains('skill') ||
        text.contains('apprentice') ||
        text.contains('worker') ||
        text.contains('job')) {
      return ProfileType.jobSeeker;
    }
    return ProfileType.generalCitizen;
  }

  Map<String, String> _getMockDataForSchemeType(ProfileType type, SchemeModel scheme) {
    switch (type) {
      case ProfileType.student:
        return {
          'Full Name': 'Aarav Sharma',
          'Age & DOB': '20 Years (2004-06-15)',
          'Gender': 'Male',
          'State': scheme.state ?? 'Maharashtra',
          'Category': 'OBC',
          'Family Income': '₹2,50,000 / Year',
          'Education Stage': 'Undergraduate',
          'Course': 'B.Tech Computer Science',
          'Institution': 'COEP Technological University',
        };
      case ProfileType.farmer:
        return {
          'Full Name': 'Ramesh Chandra Patil',
          'Age & DOB': '46 Years (1978-04-12)',
          'Gender': 'Male',
          'State': scheme.state ?? 'Maharashtra',
          'Category': 'General',
          'Family Income': '₹1,80,000 / Year',
          'Farming Type': 'Sugarcane & Rice Cultivation',
          'Landholding': 'Small & Marginal Farmer (Own Land)',
        };
      case ProfileType.entrepreneur:
        return {
          'Full Name': 'Vikramaditya Joshi',
          'Age & DOB': '32 Years (1992-11-05)',
          'Gender': 'Male',
          'State': scheme.state ?? 'Gujarat',
          'Category': 'General',
          'Family Income': '₹4,50,000 / Year',
          'Enterprise': 'Micro Non-Farm Enterprise',
          'Sector': 'Retail Tech & Agri-Trading',
        };
      case ProfileType.womanFamily:
        return {
          'Full Name': 'Sunita Devi',
          'Age & DOB': '38 Years (1986-08-25)',
          'Gender': 'Female',
          'State': scheme.state ?? 'Maharashtra',
          'Category': 'OBC',
          'Family Income': '₹1,20,000 / Year',
          'Marital Status': 'Married',
          'Bank Direct Transfer': 'Active Aadhaar Linked Account',
        };
      case ProfileType.seniorCitizen:
        return {
          'Full Name': 'Harishchandra Kulkarni',
          'Age & DOB': '66 Years (1958-03-10)',
          'Gender': 'Male',
          'State': scheme.state ?? 'Karnataka',
          'Category': 'General',
          'Family Income': '₹1,60,000 / Year',
          'Employment': 'Retired Unorganized Sector',
        };
      case ProfileType.jobSeeker:
        return {
          'Full Name': 'Priya Verma',
          'Age & DOB': '23 Years (2001-09-20)',
          'Gender': 'Female',
          'State': scheme.state ?? 'Uttar Pradesh',
          'Category': 'SC',
          'Family Income': '₹1,50,000 / Year',
          'Education': 'Undergraduate / ITI Graduate',
        };
      case ProfileType.generalCitizen:
        return {
          'Full Name': 'Rajesh Kumar Singh',
          'Age & DOB': '39 Years (1985-01-18)',
          'Gender': 'Male',
          'State': scheme.state ?? 'Central',
          'Category': 'General',
          'Family Income': '₹3,00,000 / Year',
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final savedIds = ref.watch(savedSchemeIdsProvider).value ?? {};
    final isSaved = savedIds.contains(widget.schemeId);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          tooltip: 'Go Back',
          onPressed: () => context.canPop() ? context.pop() : context.go('/dashboard'),
        ),
        title: const Text(
          'Scheme Guidelines',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: isSaved ? AppTheme.saffronGold : Colors.white,
            ),
            tooltip: isSaved ? 'Remove Bookmark' : 'Save Scheme',
            onPressed: () async {
              try {
                final nowSaved = await ref
                    .read(savedSchemeIdsProvider.notifier)
                    .toggleSave(widget.schemeId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        nowSaved ? 'Scheme saved to My Saved Schemes!' : 'Scheme removed from Saved Schemes.',
                      ),
                      action: SnackBarAction(
                        label: 'View All',
                        onPressed: () => context.push('/saved-schemes'),
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update bookmark: $e')),
                  );
                }
              }
            },
          ),
          const DashboardButton(),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<SchemeModel>(
          future: _schemeDetailsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingStateWidget(message: 'Loading scheme details...');
            }
            if (snapshot.hasError) {
              return ErrorStateWidget(
                message: 'Failed to load scheme details: ${snapshot.error}',
                onRetry: () => setState(() {}),
              );
            }

            final scheme = snapshot.data!;
            final userProfileType = ref.watch(selectedProfileTypeProvider);
            final schemeProfileType = _detectSchemeProfileType(scheme);
            final isProfileMismatch =
                (userProfileType != schemeProfileType && schemeProfileType != ProfileType.generalCitizen);
            final mismatchReason =
                isProfileMismatch ? userProfileType.getIneligibilityReason(schemeProfileType) : '';
            final activeProfileForForm = isProfileMismatch ? userProfileType : schemeProfileType;
            final mockData = _getMockDataForSchemeType(activeProfileForForm, scheme);
            final directPortal = SchemeUrlResolver.getDirectPortal(scheme);
            final officialUrl = directPortal.url;
            final sourceName = directPortal.sourceName;

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── 1. Premium Hero Header Banner ────────────────────────
                        _buildHeroHeader(scheme),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // ── 2. Key Metrics Card Grid ─────────────────────
                              _buildMetricsGrid(scheme),

                              const SizedBox(height: 20),

                              // ── 3. Official Government Portal Banner ──────────
                              _buildPortalBanner(context, sourceName, officialUrl),

                              const SizedBox(height: 20),

                              // ── 4. Eligibility & Profile Evaluation Card ─────
                              _buildEligibilityCard(
                                userProfileType: userProfileType,
                                isProfileMismatch: isProfileMismatch,
                                mismatchReason: mismatchReason,
                                activeProfile: activeProfileForForm,
                                mockData: mockData,
                              ),

                              const SizedBox(height: 20),

                              // ── 5. Financial Benefits & DBT Card ─────────────
                              _buildBenefitsCard(scheme),

                              const SizedBox(height: 20),

                              // ── 6. Step-by-Step Application Roadmap ──────────
                              _buildApplicationRoadmap(scheme, isProfileMismatch, mismatchReason),

                              const SizedBox(height: 20),

                              // ── 7. Detailed Scheme Overview ──────────────────
                              _buildOverviewCard(scheme),

                              const SizedBox(height: 20),

                              // ── 8. Scheme Rules & Conditions ─────────────────
                              _buildRulesCard(scheme, mockData),

                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── 9. Sticky Action Bar Dock ──────────────────────────────────
                _buildStickyBottomDock(context, scheme, officialUrl, isSaved),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Hero Header ────────────────────────────────────────────────────────────
  Widget _buildHeroHeader(SchemeModel scheme) {
    final isState = scheme.jurisdiction.toLowerCase() == 'state' || scheme.state != null;
    final tagColor = isState ? AppTheme.saffronGold : AppTheme.royalAzure;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryNavy, Color(0xFF1E293B)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: tagColor.withAlpha(50),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: tagColor.withAlpha(140)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isState ? Icons.location_city_rounded : Icons.account_balance_rounded,
                        size: 13, color: tagColor),
                    const SizedBox(width: 5),
                    Text(
                      isState ? '${scheme.state ?? "State"} Scheme' : 'Central Scheme',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: tagColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.vibrantEmerald.withAlpha(40),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.vibrantEmerald.withAlpha(120)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded, size: 13, color: AppTheme.vibrantEmerald),
                    SizedBox(width: 4),
                    Text(
                      'Verified Government Portal',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.vibrantEmerald),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            scheme.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.account_balance_outlined, size: 14, color: Color(0xFF94A3B8)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  scheme.provider,
                  style: const TextStyle(fontSize: 13, color: Color(0xFFCBD5E1), fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Metrics Grid ───────────────────────────────────────────────────────────
  Widget _buildMetricsGrid(SchemeModel scheme) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            icon: Icons.currency_rupee_rounded,
            iconColor: AppTheme.vibrantEmerald,
            label: 'Benefit Type',
            value: scheme.benefitType,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricTile(
            icon: Icons.people_alt_rounded,
            iconColor: AppTheme.royalAzure,
            label: 'Jurisdiction',
            value: scheme.jurisdiction,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricTile(
            icon: Icons.event_available_rounded,
            iconColor: AppTheme.saffronGold,
            label: 'Status',
            value: 'Active 2026',
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── Official Portal Banner ──────────────────────────────────────────────────
  Widget _buildPortalBanner(BuildContext context, String sourceName, String officialUrl) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.royalAzure.withAlpha(15),
            AppTheme.royalAzure.withAlpha(30),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.royalAzure.withAlpha(80)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: AppTheme.royalAzure, shape: BoxShape.circle),
                child: const Icon(Icons.language_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Text(
                          'Official Application Portal',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryNavy),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.verified_rounded, color: AppTheme.vibrantEmerald, size: 15),
                      ],
                    ),
                    Text(
                      sourceName,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Text(
              officialUrl,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.royalAzure,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => UrlLauncherHelper.openUrl(context, officialUrl),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.royalAzure,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text(
                'Open Official Government Website',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Eligibility Card ───────────────────────────────────────────────────────
  Widget _buildEligibilityCard({
    required ProfileType userProfileType,
    required bool isProfileMismatch,
    required String mismatchReason,
    required ProfileType activeProfile,
    required Map<String, String> mockData,
  }) {
    final statusColor = isProfileMismatch ? const Color(0xFFDC2626) : AppTheme.vibrantEmerald;
    final statusBg = isProfileMismatch ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4);
    final statusBorder = isProfileMismatch ? const Color(0xFFFCA5A5) : const Color(0xFFBBF7D0);

    return Container(
      decoration: BoxDecoration(
        color: statusBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusBorder, width: 1.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                child: Icon(
                  isProfileMismatch ? Icons.cancel_rounded : Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isProfileMismatch ? 'Eligibility Status: Ineligible' : 'Eligibility Status: 100% Eligible',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: statusColor),
                    ),
                    Text(
                      isProfileMismatch
                          ? 'Evaluated against profile: ${userProfileType.displayName}'
                          : 'Profile matches all mandatory eligibility rules',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isAutoFilledApplied,
                activeColor: statusColor,
                onChanged: (val) => setState(() => _isAutoFilledApplied = val),
              ),
            ],
          ),
          if (isProfileMismatch) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Text(
                'Reason: $mismatchReason',
                style: const TextStyle(fontSize: 12, color: Color(0xFF991B1B), height: 1.3),
              ),
            ),
          ],
          if (_isAutoFilledApplied) ...[
            const Divider(height: 20),
            const Text(
              'Verified Applicant Profile Data:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
            ),
            const SizedBox(height: 10),
            ...mockData.entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      Text(
                        entry.value,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  // ── Benefits Card ──────────────────────────────────────────────────────────
  Widget _buildBenefitsCard(SchemeModel scheme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.card_giftcard_rounded, color: AppTheme.vibrantEmerald, size: 20),
              SizedBox(width: 8),
              Text(
                'Scheme Benefits & Financial Support',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
              ),
            ],
          ),
          const Divider(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Text(
              scheme.benefitSummary,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF14532D), height: 1.4),
            ),
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Icon(Icons.verified_user_rounded, size: 14, color: AppTheme.vibrantEmerald),
              SizedBox(width: 6),
              Text(
                'Disbursement Mode: Direct Bank Transfer (DBT) via Aadhaar Link',
                style: TextStyle(fontSize: 11, color: Color(0xFF15803D), fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Application Roadmap ────────────────────────────────────────────────────
  Widget _buildApplicationRoadmap(SchemeModel scheme, bool isMismatch, String mismatchReason) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.alt_route_rounded, color: AppTheme.royalAzure, size: 20),
              SizedBox(width: 8),
              Text(
                'Step-by-Step Application Workflow',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
              ),
            ],
          ),
          const Divider(height: 20),
          _buildRoadmapStep(
            stepNum: '1',
            title: 'Verify Eligibility',
            desc: isMismatch ? 'Ineligible: $mismatchReason' : 'Check age, state domicile, and income criteria.',
            isDone: !isMismatch,
          ),
          _buildRoadmapStep(
            stepNum: '2',
            title: 'Gather Key Documents',
            desc: 'Aadhaar Card, Income Certificate, Bank Passbook & Educational Marksheets.',
            isDone: true,
          ),
          _buildRoadmapStep(
            stepNum: '3',
            title: 'Register on Official Portal',
            desc: 'Visit official website link and create applicant profile.',
            isDone: false,
          ),
          _buildRoadmapStep(
            stepNum: '4',
            title: 'Submit & Track Status',
            desc: 'Upload documents, submit form, and receive application tracking ID.',
            isDone: false,
          ),
        ],
      ),
    );
  }

  Widget _buildRoadmapStep({
    required String stepNum,
    required String title,
    required String desc,
    required bool isDone,
  }) {
    final color = isDone ? AppTheme.vibrantEmerald : AppTheme.royalAzure;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Center(
              child: Text(
                stepNum,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryNavy)),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Overview Card ──────────────────────────────────────────────────────────
  Widget _buildOverviewCard(SchemeModel scheme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detailed Overview',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
          ),
          const SizedBox(height: 8),
          Text(
            scheme.detailedDescription ?? scheme.shortDescription,
            style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.5),
          ),
        ],
      ),
    );
  }

  // ── Rules Card ─────────────────────────────────────────────────────────────
  Widget _buildRulesCard(SchemeModel scheme, Map<String, String> mockData) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Eligibility Rule Criteria (${scheme.rules.isNotEmpty ? scheme.rules.length : "Verified"})',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
          ),
          const SizedBox(height: 10),
          if (scheme.rules.isEmpty) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.check_circle_rounded, color: AppTheme.vibrantEmerald),
              title: const Text('Mandatory Domicile & Income Eligibility', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              subtitle: Text('Evaluated against: ${mockData["State"] ?? "All India"}', style: const TextStyle(fontSize: 11)),
            ),
          ] else ...[
            ...scheme.rules.map(
              (r) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  r.ruleType == 'mandatory' ? Icons.check_circle_rounded : Icons.info_rounded,
                  color: r.ruleType == 'mandatory' ? AppTheme.vibrantEmerald : AppTheme.saffronGold,
                  size: 20,
                ),
                title: Text('${r.fieldName} ${r.operator} ${r.expectedValue}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: Text(r.failureReason ?? 'Condition verified', style: const TextStyle(fontSize: 11)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Sticky Bottom Bar Dock ─────────────────────────────────────────────────
  Widget _buildStickyBottomDock(BuildContext context, SchemeModel scheme, String officialUrl, bool isSaved) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 10, offset: const Offset(0, -3)),
        ],
      ),
      child: Row(
        children: [
          IconButton.outlined(
            onPressed: () async {
              try {
                final nowSaved =
                    await ref.read(savedSchemeIdsProvider.notifier).toggleSave(widget.schemeId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        nowSaved ? 'Scheme saved!' : 'Scheme removed.',
                      ),
                    ),
                  );
                }
              } catch (_) {}
            },
            icon: Icon(
              isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: isSaved ? AppTheme.saffronGold : AppTheme.primaryNavy,
            ),
            tooltip: 'Bookmark Scheme',
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => UrlLauncherHelper.openUrl(context, officialUrl),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.royalAzure,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              icon: const Icon(Icons.open_in_browser_rounded, size: 18),
              label: const Text(
                'Apply on Official Portal',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
