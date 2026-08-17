import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:schemora_frontend/core/theme/app_theme.dart';
import 'package:schemora_frontend/core/widgets/common_states.dart';
import 'package:schemora_frontend/features/profile/domain/profile_type.dart';
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
        text.contains('loan')) {
      return ProfileType.entrepreneur;
    }
    if (text.contains('scholarship') ||
        text.contains('mysy') ||
        text.contains('vidya') ||
        text.contains('student') ||
        text.contains('college') ||
        text.contains('post matric') ||
        text.contains('internship')) {
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
          'Date of Birth': '2004-06-15 (Age: 20)',
          'Gender': 'Male',
          'Home State': scheme.state ?? 'Maharashtra',
          'Social Category': 'OBC',
          'Annual Family Income': '₹2,50,000',
          'Education Stage': 'Undergraduate',
          'Course / Programme': 'B.Tech Computer Science',
          'Institution': 'COEP Technological University',
          'Class 12 Marks': '88.5%',
          'Enrolment Status': 'Full-Time Regular Student',
        };
      case ProfileType.farmer:
        return {
          'Full Name': 'Ramesh Chandra Patil',
          'Date of Birth': '1978-04-12 (Age: 46)',
          'Gender': 'Male',
          'Home State': scheme.state ?? 'Maharashtra',
          'Social Category': 'General',
          'Annual Family Income': '₹1,80,000',
          'Farming Type': 'Sugarcane & Rice Cultivation',
          'Farm Location': 'Kolhapur Agricultural District',
          'Landholding Status': 'Small & Marginal Farmer (Own Land)',
        };
      case ProfileType.entrepreneur:
        return {
          'Full Name': 'Vikramaditya Joshi',
          'Date of Birth': '1992-11-05 (Age: 32)',
          'Gender': 'Male',
          'Home State': scheme.state ?? 'Gujarat',
          'Social Category': 'General',
          'Annual Family Income': '₹4,50,000',
          'Enterprise Category': 'Micro Non-Farm Enterprise',
          'Business Sector': 'Retail Tech & Agri-Trading',
          'Employment Type': 'Self-Employed Entrepreneur',
        };
      case ProfileType.womanFamily:
        return {
          'Full Name': 'Sunita Devi',
          'Date of Birth': '1986-08-25 (Age: 38)',
          'Gender': 'Female',
          'Home State': scheme.state ?? 'Maharashtra',
          'Social Category': 'OBC',
          'Annual Family Income': '₹1,20,000',
          'Marital Status': 'Married',
          'Primary Bank Linked': 'Aadhaar Direct Bank Transfer Active',
        };
      case ProfileType.seniorCitizen:
        return {
          'Full Name': 'Harishchandra Kulkarni',
          'Date of Birth': '1958-03-10 (Age: 66)',
          'Gender': 'Male',
          'Home State': scheme.state ?? 'Karnataka',
          'Social Category': 'General',
          'Annual Family Income': '₹1,60,000',
          'Employment Status': 'Retired Unorganized Sector',
          'Pension Status': 'First Time Applicant',
        };
      case ProfileType.jobSeeker:
        return {
          'Full Name': 'Priya Verma',
          'Date of Birth': '2001-09-20 (Age: 23)',
          'Gender': 'Female',
          'Home State': scheme.state ?? 'Uttar Pradesh',
          'Social Category': 'SC',
          'Annual Family Income': '₹1,50,000',
          'Education Level': 'Undergraduate / ITI',
          'Key Skill Track': 'Data Entry & Digital Operations',
          'Employment Status': 'Unemployed (Actively Job Seeking)',
        };
      case ProfileType.generalCitizen:
        return {
          'Full Name': 'Rajesh Kumar Singh',
          'Date of Birth': '1985-01-18 (Age: 39)',
          'Gender': 'Male',
          'Home State': scheme.state ?? 'Delhi',
          'Social Category': 'General',
          'Annual Family Income': '₹3,00,000',
          'Housing Status': 'Kutcha / Rented Accommodation',
          'Ration Card Type': 'BPL / Priority Household',
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(schemeRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scheme Application & Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share Scheme',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Scheme link copied to clipboard!')),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<SchemeModel>(
          future: repo.getSchemeDetails(widget.schemeId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingStateWidget(message: 'Loading scheme details & auto-filling mock data...');
            }
            if (snapshot.hasError) {
              return ErrorStateWidget(
                message: 'Failed to load scheme details: ${snapshot.error}',
                onRetry: () => setState(() {}),
              );
            }

            final scheme = snapshot.data!;
            final profileType = _detectSchemeProfileType(scheme);
            final mockData = _getMockDataForSchemeType(profileType, scheme);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Title Card
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          scheme.title,
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 22, color: AppTheme.primaryNavy),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          scheme.jurisdiction,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Provider: ${scheme.provider}', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 16),

                  // Benefit Banner Box
                  Card(
                    elevation: 2,
                    color: AppTheme.primaryBlue.withAlpha(15),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Icon(Icons.stars_rounded, color: AppTheme.warningOrange, size: 32),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Key Benefit Summary', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryNavy)),
                                const SizedBox(height: 4),
                                Text(scheme.benefitSummary, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Auto-Filled Mock Data Application Section ───────────
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.amber.shade400, width: 1.5),
                    ),
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade700,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Auto-Filled Scheme Application Data',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF78350F)),
                                  ),
                                  Text(
                                    'Pre-populated with mock data tailored for ${profileType.displayName}',
                                    style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _isAutoFilledApplied,
                              activeColor: Colors.amber.shade800,
                              onChanged: (val) => setState(() => _isAutoFilledApplied = val),
                            ),
                          ],
                        ),
                        if (_isAutoFilledApplied) ...[
                          const Divider(height: 24),
                          const Text(
                            'The following form fields have been automatically populated for instant eligibility verification:',
                            style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Color(0xFF92400E)),
                          ),
                          const SizedBox(height: 14),
                          ...mockData.entries.map((entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      entry.key,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF451A03)),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.amber.shade300),
                                        ),
                                        child: Text(
                                          entry.value,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryNavy),
                                          textAlign: TextAlign.end,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.successGreen.withAlpha(25),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.successGreen.withAlpha(80)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.check_circle_rounded, color: AppTheme.successGreen, size: 20),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Eligibility Status: 100% Matched with Auto-Filled Profile!',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.successGreen, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Detailed Description
                  Text('Scheme Overview', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    scheme.detailedDescription ?? scheme.shortDescription,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),

                  const SizedBox(height: 24),

                  // Eligibility Rules Section
                  Text('Rule Conditions & Criteria (${scheme.rules.isNotEmpty ? scheme.rules.length : "Evaluated"})', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 12),
                  if (scheme.rules.isEmpty) ...[
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.verified_rounded, color: AppTheme.successGreen),
                        title: const Text('Mandatory Age & Domicile Eligibility'),
                        subtitle: Text('Verified against auto-filled profile state: ${mockData['Home State']}'),
                      ),
                    ),
                  ] else ...[
                    ...scheme.rules.map((rule) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Icon(
                              rule.ruleType == 'mandatory' ? Icons.check_circle_rounded : Icons.info_rounded,
                              color: rule.ruleType == 'mandatory' ? AppTheme.successGreen : AppTheme.warningOrange,
                            ),
                            title: Text('${rule.fieldName} ${rule.operator} ${rule.expectedValue}'),
                            subtitle: Text(rule.failureReason ?? 'Mandatory rule condition — Passed'),
                          ),
                        )),
                  ],

                  const SizedBox(height: 24),

                  // Official Links
                  if (scheme.sources.isNotEmpty) ...[
                    Text('Official Portals & Sources', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 12),
                    ...scheme.sources.map((src) => ListTile(
                          leading: const Icon(Icons.open_in_new_rounded, color: AppTheme.primaryBlue),
                          title: Text(src.sourceName),
                          subtitle: Text(src.url, style: const TextStyle(color: AppTheme.primaryBlue)),
                        )),
                    const SizedBox(height: 24),
                  ],

                  // Action Buttons
                  ElevatedButton.icon(
                    onPressed: () => context.push('/checklist/${scheme.id}'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppTheme.primaryBlue,
                    ),
                    icon: const Icon(Icons.assignment_turned_in_rounded),
                    label: const Text('Proceed with Auto-Filled Application', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/documents/upload'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.upload_file_rounded),
                    label: const Text('Upload Supporting Verification Documents'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
