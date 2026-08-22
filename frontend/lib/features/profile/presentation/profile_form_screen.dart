import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:schemora_frontend/core/theme/app_theme.dart';
import 'package:schemora_frontend/core/widgets/common_states.dart';
import 'package:schemora_frontend/core/widgets/dashboard_button.dart';
import 'package:schemora_frontend/features/auth/data/auth_repository.dart';
import 'package:schemora_frontend/features/profile/data/profile_repository.dart';
import 'package:schemora_frontend/features/profile/domain/profile_model.dart';
import 'package:schemora_frontend/features/profile/domain/profile_type.dart';
import 'package:schemora_frontend/features/profile/domain/profile_type_provider.dart';

class ProfileFormScreen extends ConsumerStatefulWidget {
  const ProfileFormScreen({super.key});

  @override
  ConsumerState<ProfileFormScreen> createState() => _ProfileFormScreenState();
}

class _ProfileFormScreenState extends ConsumerState<ProfileFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Common controllers
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _incomeController = TextEditingController();

  // Type-specific controllers (reuse backend fields contextually)
  final _courseController = TextEditingController();   // course_name
  final _institutionController = TextEditingController(); // institution_name
  final _percentileController = TextEditingController();
  final _attendanceController = TextEditingController();

  String _gender = 'Male';
  String _state = 'Maharashtra';
  String _socialCategory = 'General';
  String _educationLevel = 'Undergraduate';
  String _employmentStatus = 'Unemployed';
  String _institutionType = 'Regular';
  bool _isFullTimeStudent = true;
  bool _hasDisability = false;

  // Privacy: "prefer not to say" sentinel
  bool _incomePreferNotToSay = false;
  bool _categoryPreferNotToSay = false;

  bool _isSubmitting = false;
  bool _isNavigating = false;

  @override
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final type = ref.read(selectedProfileTypeProvider);
      final profileAsync = ref.read(currentProfileProvider);

      profileAsync.whenData((profile) {
        if (profile != null && mounted && profile.fullName.isNotEmpty) {
          // If profile exists, check if user changed profile type card
          _loadFromProfile(profile);
        } else if (mounted) {
          _applyMockDataForType(type);
        }
      });

      // Always apply card-specific mock data defaults if form is blank
      if (_nameController.text.isEmpty && mounted) {
        _applyMockDataForType(type);
      }
    });
  }

  void _loadFromProfile(ProfileModel profile) {
    setState(() {
      _nameController.text = profile.fullName;
      _dobController.text = profile.dateOfBirth;
      _gender = profile.gender;
      _state = profile.state;
      _socialCategory = profile.socialCategory;
      _educationLevel = profile.educationLevel;
      _employmentStatus = profile.employmentStatus;
      _institutionType = profile.institutionType;
      _isFullTimeStudent = profile.isFullTimeStudent;
      _courseController.text = profile.courseName ?? '';
      _institutionController.text = profile.institutionName ?? '';
      _incomeController.text = profile.annualFamilyIncome?.toInt().toString() ?? '';
      _percentileController.text = profile.class12Percentile?.toString() ?? '';
      _attendanceController.text = profile.attendancePercentage?.toString() ?? '';
    });
  }

  void _applyMockDataForType(ProfileType type) {
    setState(() {
      switch (type) {
        case ProfileType.student:
          _nameController.text = 'Aarav Sharma';
          _dobController.text = '2004-06-15';
          _gender = 'Male';
          _state = 'Maharashtra';
          _socialCategory = 'OBC';
          _incomeController.text = '250000';
          _educationLevel = 'Undergraduate';
          _courseController.text = 'B.Tech Computer Science';
          _institutionController.text = 'COEP Technological University';
          _institutionType = 'Regular';
          _percentileController.text = '88.5';
          _attendanceController.text = '85.0';
          _isFullTimeStudent = true;
          _employmentStatus = 'Unemployed';
          break;

        case ProfileType.farmer:
          _nameController.text = 'Ramesh Chandra Patil';
          _dobController.text = '1978-04-12';
          _gender = 'Male';
          _state = 'Maharashtra';
          _socialCategory = 'General';
          _incomeController.text = '180000';
          _educationLevel = 'Class10';
          _courseController.text = 'Sugarcane & Rice Cultivation';
          _institutionController.text = 'Kolhapur Farm District';
          _institutionType = 'Regular';
          _percentileController.text = '';
          _attendanceController.text = '';
          _isFullTimeStudent = false;
          _employmentStatus = 'SelfEmployed';
          break;

        case ProfileType.jobSeeker:
          _nameController.text = 'Priya Verma';
          _dobController.text = '2001-09-20';
          _gender = 'Female';
          _state = 'Uttar Pradesh';
          _socialCategory = 'SC';
          _incomeController.text = '150000';
          _educationLevel = 'Undergraduate';
          _courseController.text = 'Software & Data Entry Apprentice';
          _institutionController.text = 'Skill India Center Lucknow';
          _institutionType = 'Regular';
          _percentileController.text = '78.0';
          _attendanceController.text = '';
          _isFullTimeStudent = false;
          _employmentStatus = 'Unemployed';
          break;

        case ProfileType.entrepreneur:
          _nameController.text = 'Vikramaditya Joshi';
          _dobController.text = '1992-11-05';
          _gender = 'Male';
          _state = 'Gujarat';
          _socialCategory = 'General';
          _incomeController.text = '450000';
          _educationLevel = 'Postgraduate';
          _courseController.text = 'Micro Retail Enterprise';
          _institutionController.text = 'Joshi Green Tech Solutions';
          _institutionType = 'Regular';
          _percentileController.text = '';
          _attendanceController.text = '';
          _isFullTimeStudent = false;
          _employmentStatus = 'SelfEmployed';
          break;

        case ProfileType.womanFamily:
          _nameController.text = 'Sunita Devi';
          _dobController.text = '1986-08-25';
          _gender = 'Female';
          _state = 'Maharashtra';
          _socialCategory = 'OBC';
          _incomeController.text = '120000';
          _educationLevel = 'Class12';
          _courseController.text = 'Maternity & Family Support';
          _institutionController.text = 'Nashik Primary Health Center';
          _institutionType = 'Regular';
          _percentileController.text = '';
          _attendanceController.text = '';
          _isFullTimeStudent = false;
          _employmentStatus = 'Unemployed';
          break;

        case ProfileType.seniorCitizen:
          _nameController.text = 'Harishchandra Kulkarni';
          _dobController.text = '1958-03-10';
          _gender = 'Male';
          _state = 'Karnataka';
          _socialCategory = 'General';
          _incomeController.text = '160000';
          _educationLevel = 'Class10';
          _courseController.text = 'Unorganized Pension Applicant';
          _institutionController.text = 'Bengaluru Senior Center';
          _institutionType = 'Regular';
          _percentileController.text = '';
          _attendanceController.text = '';
          _isFullTimeStudent = false;
          _employmentStatus = 'Unemployed';
          break;

        case ProfileType.generalCitizen:
          _nameController.text = 'Rajesh Kumar Singh';
          _dobController.text = '1985-01-18';
          _gender = 'Male';
          _state = 'Delhi';
          _socialCategory = 'General';
          _incomeController.text = '300000';
          _educationLevel = 'Undergraduate';
          _courseController.text = 'Housing & Free Electricity Scheme';
          _institutionController.text = 'Central Delhi Municipal Ward';
          _institutionType = 'Regular';
          _percentileController.text = '';
          _attendanceController.text = '';
          _isFullTimeStudent = false;
          _employmentStatus = 'PartTime';
          break;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _incomeController.dispose();
    _courseController.dispose();
    _institutionController.dispose();
    _percentileController.dispose();
    _attendanceController.dispose();
    super.dispose();
  }

  // ─── Privacy tooltip bottom sheet ─────────────────────────────────────────
  void _showWhyWeAsk(String fieldName, String reason) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.info_outline_rounded, color: AppTheme.primaryBlue),
              const SizedBox(width: 8),
              Text('Why do we ask this?',
                  style: Theme.of(context).textTheme.titleLarge),
            ]),
            const SizedBox(height: 12),
            Text(fieldName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 6),
            Text(reason, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Save & Navigate ───────────────────────────────────────────────────────
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final token = ref.read(authProvider).token ?? 'test-token-citizen';
      final repo = ref.read(profileRepositoryProvider);
      final profileType = ref.read(selectedProfileTypeProvider);

      final profile = ProfileModel(
        fullName: _nameController.text.trim(),
        dateOfBirth: _dobController.text.trim(),
        gender: _gender,
        state: _state,
        educationLevel: _educationLevel,
        courseName: _courseController.text.trim().isEmpty
            ? null
            : _courseController.text.trim(),
        institutionName: _institutionController.text.trim().isEmpty
            ? null
            : _institutionController.text.trim(),
        institutionType: _institutionType,
        socialCategory: _categoryPreferNotToSay ? 'PreferNotToSay' : _socialCategory,
        annualFamilyIncome: _incomePreferNotToSay
            ? null
            : double.tryParse(_incomeController.text),
        isFullTimeStudent: profileType == ProfileType.student ? _isFullTimeStudent : false,
        employmentStatus: _employmentStatus,
        citizenship: 'Indian',
        class12Percentile: double.tryParse(_percentileController.text),
        attendancePercentage: double.tryParse(_attendanceController.text),
      );

      final existing = await repo.getMyProfile(token);
      if (existing == null) {
        await repo.createProfile(token, profile);
      } else {
        await repo.updateProfile(token, profile);
      }

      ref.invalidate(currentProfileProvider);

      if (!mounted) return;

      // Show "Finding schemes for you..." overlay then navigate
      setState(() {
        _isSubmitting = false;
        _isNavigating = true;
      });

      await Future.delayed(const Duration(milliseconds: 50));

      if (mounted) {
        context.go('/recommendations');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: $e'),
            backgroundColor: AppTheme.errorRed,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _saveProfile,
            ),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final profileType = ref.watch(selectedProfileTypeProvider);
    final profileAsync = ref.watch(currentProfileProvider);

    // Full-screen navigating overlay
    if (_isNavigating) {
      return Scaffold(
        backgroundColor: AppTheme.surfaceLight,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppTheme.primaryBlue),
              const SizedBox(height: 20),
              Text(
                'Finding schemes for you...',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Matching your profile to eligible government schemes.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(profileType.displayName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/profile-type'),
        ),
        actions: [
          const DashboardButton(),
          TextButton(
            onPressed: () => context.go('/profile-type'),
            child: const Text('Change Type'),
          ),
        ],
      ),
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const LoadingStateWidget(message: 'Loading your profile...'),
          error: (_, __) => _buildForm(context, profileType),
          data: (_) => _buildForm(context, profileType),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, ProfileType type) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sample Mock Data Banner Chip
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryBlue.withAlpha(50)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: AppTheme.primaryBlue, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Prefilled with ${type.displayName} sample data.',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primaryNavy),
                    ),
                  ),
                  InkWell(
                    onTap: () => _applyMockDataForType(type),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Reset Sample Data',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Header
            _SectionHeader(
              icon: Icons.person_outline_rounded,
              title: 'Basic Information',
              subtitle: 'Required for all scheme eligibility checks',
            ),
            const SizedBox(height: 16),

            // ── Common Fields ──────────────────────────────────────────────
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Full Name *',
                hintText: 'As per your Aadhaar card',
                prefixIcon: Icon(Icons.badge_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (val) =>
                  (val == null || val.trim().isEmpty) ? 'Full name is required' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _dobController,
              keyboardType: TextInputType.datetime,
              decoration: const InputDecoration(
                labelText: 'Date of Birth *',
                hintText: 'YYYY-MM-DD',
                prefixIcon: Icon(Icons.cake_outlined),
                border: OutlineInputBorder(),
                helperText: 'Format: 1998-07-15',
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Date of birth is required';
                final regex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
                if (!regex.hasMatch(val.trim())) return 'Use YYYY-MM-DD format (e.g. 2000-05-20)';
                return null;
              },
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _gender,
              decoration: const InputDecoration(
                labelText: 'Gender *',
                prefixIcon: Icon(Icons.wc_outlined),
                border: OutlineInputBorder(),
              ),
              items: ['Male', 'Female', 'Transgender', 'Other']
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (val) => setState(() => _gender = val!),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _state,
              decoration: const InputDecoration(
                labelText: 'Home State *',
                prefixIcon: Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(),
              ),
              items: _kIndianStates
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (val) => setState(() => _state = val!),
            ),
            const SizedBox(height: 20),

            // ── Social Category ────────────────────────────────────────────
            _SectionHeader(
              icon: Icons.group_outlined,
              title: 'Social & Financial Details',
              subtitle: 'Used strictly for eligibility matching',
            ),
            const SizedBox(height: 16),

            if (!_categoryPreferNotToSay)
              DropdownButtonFormField<String>(
                value: _socialCategory,
                decoration: InputDecoration(
                  labelText: 'Social Category *',
                  prefixIcon: const Icon(Icons.people_outline_rounded),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.info_outline_rounded,
                        color: AppTheme.primaryBlue),
                    tooltip: 'Why do we ask this?',
                    onPressed: () => _showWhyWeAsk(
                      'Social Category',
                      'Many central and state schemes have reserved benefits for SC, ST, OBC, and EWS categories. '
                          'This field helps Schemora match you only to schemes you are actually eligible for.',
                    ),
                  ),
                ),
                items: ['General', 'OBC', 'SC', 'ST', 'EWS']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) => setState(() => _socialCategory = val!),
              ),
            _PrivacyChip(
              label: 'Prefer not to share category',
              selected: _categoryPreferNotToSay,
              onChanged: (v) => setState(() => _categoryPreferNotToSay = v),
            ),
            const SizedBox(height: 16),

            if (!_incomePreferNotToSay)
              TextFormField(
                controller: _incomeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Annual Family Income (₹)',
                  hintText: 'e.g. 250000',
                  prefixIcon: const Icon(Icons.currency_rupee_rounded),
                  border: const OutlineInputBorder(),
                  helperText: 'Optional — used only for income-based scheme thresholds',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.info_outline_rounded,
                        color: AppTheme.primaryBlue),
                    tooltip: 'Why do we ask this?',
                    onPressed: () => _showWhyWeAsk(
                      'Annual Family Income',
                      'Many schemes have income eligibility caps (e.g. ₹8 lakh for OBC NCL, '
                          '₹2.5 lakh for SC/ST scholarships). This helps us find schemes you actually qualify for.',
                    ),
                  ),
                ),
              ),
            _PrivacyChip(
              label: 'Prefer not to share income',
              selected: _incomePreferNotToSay,
              onChanged: (v) => setState(() => _incomePreferNotToSay = v),
            ),
            const SizedBox(height: 20),

            // ── Profile-Type-Specific Fields ───────────────────────────────
            ..._buildTypeSpecificFields(context, type),
            const SizedBox(height: 28),

            // ── CTA ─────────────────────────────────────────────────────────
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              icon: _isSubmitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.search_rounded),
              label: Text(_isSubmitting ? 'Saving...' : 'Save & Find My Schemes'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go('/profile-type'),
              child: const Text('Change profile type'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Dynamic fields per profile type ──────────────────────────────────────
  List<Widget> _buildTypeSpecificFields(BuildContext context, ProfileType type) {
    switch (type) {
      case ProfileType.student:
        return _studentFields();
      case ProfileType.farmer:
        return _farmerFields();
      case ProfileType.jobSeeker:
        return _jobSeekerFields();
      case ProfileType.entrepreneur:
        return _entrepreneurFields();
      case ProfileType.womanFamily:
        return _womanFamilyFields();
      case ProfileType.seniorCitizen:
        return _seniorCitizenFields();
      case ProfileType.generalCitizen:
        return _generalCitizenFields();
    }
  }

  List<Widget> _studentFields() => [
        _SectionHeader(
          icon: Icons.school_outlined,
          title: 'Academic Details',
          subtitle: 'Required for scholarship matching',
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _educationLevel,
          decoration: const InputDecoration(
            labelText: 'Education Level *',
            prefixIcon: Icon(Icons.menu_book_outlined),
            border: OutlineInputBorder(),
          ),
          items: ['Class10', 'Class12', 'Diploma', 'ITI', 'Undergraduate', 'Postgraduate', 'PhD']
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (val) => setState(() => _educationLevel = val!),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _institutionType,
          decoration: const InputDecoration(
            labelText: 'Institution Type',
            prefixIcon: Icon(Icons.account_balance_outlined),
            border: OutlineInputBorder(),
          ),
          items: ['Regular', 'Distance', 'Correspondence']
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (val) => setState(() => _institutionType = val!),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _courseController,
          decoration: const InputDecoration(
            labelText: 'Current Course / Programme',
            hintText: 'e.g. B.Tech Computer Science',
            prefixIcon: Icon(Icons.edit_note_rounded),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _institutionController,
          decoration: const InputDecoration(
            labelText: 'Institution Name',
            hintText: 'e.g. COEP Technological University',
            prefixIcon: Icon(Icons.location_city_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _percentileController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Class 12 Percentile (%)',
            hintText: 'e.g. 88.5',
            prefixIcon: Icon(Icons.percent_rounded),
            border: OutlineInputBorder(),
            helperText: 'Optional — used for merit-based scholarship filters',
          ),
        ),
        const SizedBox(height: 16),
        CheckboxListTile(
          value: _isFullTimeStudent,
          onChanged: (v) => setState(() => _isFullTimeStudent = v ?? true),
          title: const Text('I am a full-time regular student'),
          subtitle: const Text('Some schemes require full-time enrolment'),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ];

  List<Widget> _farmerFields() => [
        _SectionHeader(
          icon: Icons.agriculture_outlined,
          title: 'Agricultural Details',
          subtitle: 'Used for Kisan & crop scheme matching',
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _courseController,
          decoration: const InputDecoration(
            labelText: 'Type of Farming / Crop',
            hintText: 'e.g. Rice, Wheat, Horticulture, Dairy',
            prefixIcon: Icon(Icons.grass_rounded),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _institutionController,
          decoration: const InputDecoration(
            labelText: 'District / Farm Location',
            hintText: 'e.g. Nashik, Pune',
            prefixIcon: Icon(Icons.location_on_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _employmentStatus,
          decoration: const InputDecoration(
            labelText: 'Land Ownership Status',
            prefixIcon: Icon(Icons.landscape_outlined),
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'SelfEmployed', child: Text('Own Land')),
            DropdownMenuItem(value: 'PartTime', child: Text('Leased / Tenant Farming')),
            DropdownMenuItem(value: 'Unemployed', child: Text('Landless Agricultural Worker')),
          ],
          onChanged: (val) => setState(() => _employmentStatus = val!),
        ),
      ];

  List<Widget> _jobSeekerFields() => [
        _SectionHeader(
          icon: Icons.work_outline_rounded,
          title: 'Employment & Skills',
          subtitle: 'For skill development and employment schemes',
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _educationLevel,
          decoration: const InputDecoration(
            labelText: 'Highest Education Level',
            prefixIcon: Icon(Icons.menu_book_outlined),
            border: OutlineInputBorder(),
          ),
          items: ['Below Class 10', 'Class10', 'Class12', 'Diploma', 'ITI', 'Undergraduate', 'Postgraduate']
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (val) => setState(() => _educationLevel = val ?? _educationLevel),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _employmentStatus,
          decoration: const InputDecoration(
            labelText: 'Employment Status',
            prefixIcon: Icon(Icons.work_history_outlined),
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'Unemployed', child: Text('Currently Unemployed')),
            DropdownMenuItem(value: 'PartTime', child: Text('Part-Time / Casual Work')),
            DropdownMenuItem(value: 'FullTime', child: Text('Employed (Seeking Better Opportunity)')),
          ],
          onChanged: (val) => setState(() => _employmentStatus = val!),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _courseController,
          decoration: const InputDecoration(
            labelText: 'Key Skills',
            hintText: 'e.g. Welding, Driving, Computer Basics, Tailoring',
            prefixIcon: Icon(Icons.build_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _institutionController,
          decoration: const InputDecoration(
            labelText: 'Years of Work Experience',
            hintText: 'e.g. 2',
            prefixIcon: Icon(Icons.timeline_rounded),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
      ];

  List<Widget> _entrepreneurFields() => [
        _SectionHeader(
          icon: Icons.business_center_outlined,
          title: 'Business Details',
          subtitle: 'For MSME, startup & business support schemes',
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _courseController,
          decoration: const InputDecoration(
            labelText: 'Type of Business',
            hintText: 'e.g. Manufacturing, Retail, IT Services, Handicraft',
            prefixIcon: Icon(Icons.category_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _institutionController,
          decoration: const InputDecoration(
            labelText: 'Business Name (optional)',
            hintText: 'e.g. Sharma Enterprises',
            prefixIcon: Icon(Icons.business_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _employmentStatus,
          decoration: const InputDecoration(
            labelText: 'Business Stage',
            prefixIcon: Icon(Icons.trending_up_rounded),
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'Unemployed', child: Text('Idea Stage / Not Started')),
            DropdownMenuItem(value: 'PartTime', child: Text('Early Stage (< 2 years)')),
            DropdownMenuItem(value: 'SelfEmployed', child: Text('Established (2+ years)')),
          ],
          onChanged: (val) => setState(() => _employmentStatus = val!),
        ),
      ];

  List<Widget> _womanFamilyFields() => [
        _SectionHeader(
          icon: Icons.family_restroom_rounded,
          title: 'Family & Support Details',
          subtitle: 'For women empowerment & family welfare schemes',
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _employmentStatus,
          decoration: const InputDecoration(
            labelText: 'Occupation',
            prefixIcon: Icon(Icons.work_outline_rounded),
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'Unemployed', child: Text('Homemaker / Not Working')),
            DropdownMenuItem(value: 'PartTime', child: Text('Part-Time Worker')),
            DropdownMenuItem(value: 'FullTime', child: Text('Employed')),
            DropdownMenuItem(value: 'SelfEmployed', child: Text('Self-Employed / Business')),
          ],
          onChanged: (val) => setState(() => _employmentStatus = val!),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _courseController,
          decoration: const InputDecoration(
            labelText: 'Number of Dependent Children (optional)',
            hintText: 'e.g. 2',
            prefixIcon: Icon(Icons.child_care_outlined),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
      ];

  List<Widget> _seniorCitizenFields() => [
        _SectionHeader(
          icon: Icons.elderly_outlined,
          title: 'Senior Citizen Details',
          subtitle: 'For pension, healthcare & elderly welfare',
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _employmentStatus,
          decoration: const InputDecoration(
            labelText: 'Current Status',
            prefixIcon: Icon(Icons.work_off_outlined),
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'Unemployed', child: Text('Retired / Not Working')),
            DropdownMenuItem(value: 'PartTime', child: Text('Part-Time / Occasional Work')),
            DropdownMenuItem(value: 'SelfEmployed', child: Text('Self-Employed')),
          ],
          onChanged: (val) => setState(() => _employmentStatus = val!),
        ),
        const SizedBox(height: 16),
        CheckboxListTile(
          value: _hasDisability,
          onChanged: (v) => setState(() => _hasDisability = v ?? false),
          title: const Text('I have a disability / differently-abled'),
          subtitle: const Text('Relevant for disability-based benefit schemes'),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ];

  List<Widget> _generalCitizenFields() => [
        _SectionHeader(
          icon: Icons.person_outline_rounded,
          title: 'Additional Details',
          subtitle: 'Optional — helps find more relevant schemes',
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _employmentStatus,
          decoration: const InputDecoration(
            labelText: 'Employment Status',
            prefixIcon: Icon(Icons.work_history_outlined),
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'Unemployed', child: Text('Unemployed')),
            DropdownMenuItem(value: 'PartTime', child: Text('Part-Time')),
            DropdownMenuItem(value: 'FullTime', child: Text('Employed')),
            DropdownMenuItem(value: 'SelfEmployed', child: Text('Self-Employed')),
          ],
          onChanged: (val) => setState(() => _employmentStatus = val!),
        ),
      ];
}

// ─── Reusable Sub-Widgets ──────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withAlpha(20),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primaryBlue, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppTheme.primaryNavy)),
              Text(subtitle,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            ],
          ),
        ),
      ],
    );
  }
}

class _PrivacyChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onChanged;

  const _PrivacyChip({
    required this.label,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: FilterChip(
          label: Text(label, style: const TextStyle(fontSize: 12)),
          selected: selected,
          onSelected: onChanged,
          selectedColor: AppTheme.primaryBlue.withAlpha(30),
          checkmarkColor: AppTheme.primaryBlue,
          avatar: Icon(
            selected ? Icons.visibility_off_outlined : Icons.shield_outlined,
            size: 16,
            color: selected ? AppTheme.primaryBlue : const Color(0xFF64748B),
          ),
          showCheckmark: false,
        ),
      ),
    );
  }
}

// Indian states list for the dropdown
const List<String> _kIndianStates = [
  'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
  'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka',
  'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya', 'Mizoram',
  'Nagaland', 'Odisha', 'Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu',
  'Telangana', 'Tripura', 'Uttar Pradesh', 'Uttarakhand', 'West Bengal',
  'Andaman and Nicobar Islands', 'Chandigarh', 'Dadra and Nagar Haveli and Daman and Diu',
  'Delhi', 'Jammu and Kashmir', 'Ladakh', 'Lakshadweep', 'Puducherry',
];
