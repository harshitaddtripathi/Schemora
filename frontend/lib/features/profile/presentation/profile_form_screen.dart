import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schemora_frontend/core/theme/app_theme.dart';
import 'package:schemora_frontend/core/widgets/common_states.dart';
import 'package:schemora_frontend/features/auth/data/auth_repository.dart';
import 'package:schemora_frontend/features/profile/data/profile_repository.dart';
import 'package:schemora_frontend/features/profile/domain/profile_model.dart';

class ProfileFormScreen extends ConsumerStatefulWidget {
  const ProfileFormScreen({super.key});

  @override
  ConsumerState<ProfileFormScreen> createState() => _ProfileFormScreenState();
}

class _ProfileFormScreenState extends ConsumerState<ProfileFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController(text: 'Aarav Sharma');
  final _dobController = TextEditingController(text: '2005-06-15');
  final _courseController = TextEditingController(text: 'B.Tech Computer Science');
  final _institutionController = TextEditingController(text: 'COEP Technological University');
  final _incomeController = TextEditingController(text: '200000');
  final _percentileController = TextEditingController(text: '88.5');

  String _gender = 'Male';
  String _state = 'Maharashtra';
  String _educationLevel = 'Undergraduate';
  String _socialCategory = 'OBC';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _courseController.dispose();
    _institutionController.dispose();
    _incomeController.dispose();
    _percentileController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final token = ref.read(authProvider).token ?? 'test-token-citizen';
      final repo = ref.read(profileRepositoryProvider);

      final profile = ProfileModel(
        fullName: _nameController.text,
        dateOfBirth: _dobController.text,
        gender: _gender,
        state: _state,
        educationLevel: _educationLevel,
        courseName: _courseController.text,
        institutionName: _institutionController.text,
        socialCategory: _socialCategory,
        annualFamilyIncome: double.tryParse(_incomeController.text),
        class12Percentile: double.tryParse(_percentileController.text),
      );

      final existing = await repo.getMyProfile(token);
      if (existing == null) {
        await repo.createProfile(token, profile);
      } else {
        await repo.updateProfile(token, profile);
      }

      ref.invalidate(currentProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Student profile saved successfully!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Profile'),
      ),
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const LoadingStateWidget(message: 'Loading student profile...'),
          error: (err, stack) => ErrorStateWidget(
            message: 'Error loading profile: $err',
            onRetry: () => ref.invalidate(currentProfileProvider),
          ),
          data: (profile) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Academic & Eligibility Profile', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 8),
                    Text(
                      'Complete your profile to match eligible scholarships and central/state schemes.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Full Name *', border: OutlineInputBorder()),
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _dobController,
                      decoration: const InputDecoration(labelText: 'Date of Birth (YYYY-MM-DD) *', border: OutlineInputBorder()),
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _gender,
                      decoration: const InputDecoration(labelText: 'Gender *', border: OutlineInputBorder()),
                      items: ['Male', 'Female', 'Transgender', 'Other']
                          .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                          .toList(),
                      onChanged: (val) => setState(() => _gender = val!),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _state,
                      decoration: const InputDecoration(labelText: 'Domicile State *', border: OutlineInputBorder()),
                      items: ['Maharashtra', 'Delhi', 'Karnataka', 'Gujarat', 'Tamil Nadu', 'Rajasthan']
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (val) => setState(() => _state = val!),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _educationLevel,
                      decoration: const InputDecoration(labelText: 'Education Level *', border: OutlineInputBorder()),
                      items: ['Class10', 'Class12', 'Diploma', 'ITI', 'Undergraduate', 'Postgraduate', 'PhD']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (val) => setState(() => _educationLevel = val!),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _socialCategory,
                      decoration: const InputDecoration(labelText: 'Social Category *', border: OutlineInputBorder()),
                      items: ['General', 'OBC', 'SC', 'ST', 'EWS']
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (val) => setState(() => _socialCategory = val!),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _incomeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Annual Family Income (INR)',
                        helperText: 'Optional sensitive field used strictly for income eligibility thresholds.',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _percentileController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Class 12 Percentile (%)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _saveProfile,
                      icon: const Icon(Icons.save_rounded),
                      label: Text(_isSubmitting ? 'Saving...' : 'Save Student Profile'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
