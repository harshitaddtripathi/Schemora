import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:schemora_frontend/core/theme/app_theme.dart';
import 'package:schemora_frontend/core/widgets/common_states.dart';
import 'package:schemora_frontend/core/widgets/dashboard_button.dart';
import 'package:schemora_frontend/features/schemes/data/scheme_repository.dart';
import 'package:schemora_frontend/features/schemes/domain/scheme_model.dart';

import 'package:schemora_frontend/features/saved_schemes/data/saved_scheme_repository.dart';

import 'package:schemora_frontend/core/widgets/scheme_card.dart';

class SchemeCatalogScreen extends ConsumerStatefulWidget {
  const SchemeCatalogScreen({super.key});

  @override
  ConsumerState<SchemeCatalogScreen> createState() => _SchemeCatalogScreenState();
}

class _SchemeCatalogScreenState extends ConsumerState<SchemeCatalogScreen> {
  final _searchController = TextEditingController();
  String _selectedJurisdiction = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(schemeRepositoryProvider);
    final savedIds = ref.watch(savedSchemeIdsProvider).value ?? {};

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Go Back',
          onPressed: () => context.canPop() ? context.pop() : context.go('/dashboard'),
        ),
        title: const Text('All Government Schemes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_rounded, color: AppTheme.primaryBlue),
            tooltip: 'Saved Schemes',
            onPressed: () => context.push('/saved-schemes'),
          ),
          const DashboardButton(),
          IconButton(
            icon: const Icon(Icons.star_rounded, color: AppTheme.warningOrange),
            tooltip: 'Top Recommendations',
            onPressed: () => context.push('/recommendations'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(fontSize: 14, color: AppTheme.primaryNavy),
                    decoration: InputDecoration(
                      hintText: 'Search schemes by keyword, ministry or benefit...',
                      prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryBlue),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF94A3B8)),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
                      ),
                    ),
                    onChanged: (val) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      FilterChip(
                        label: const Text('All Schemes'),
                        selected: _selectedJurisdiction == '',
                        onSelected: (_) => setState(() => _selectedJurisdiction = ''),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Central'),
                        selected: _selectedJurisdiction == 'Central',
                        onSelected: (_) => setState(() => _selectedJurisdiction = 'Central'),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('State'),
                        selected: _selectedJurisdiction == 'State',
                        onSelected: (_) => setState(() => _selectedJurisdiction = 'State'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<SchemeModel>>(
                future: repo.getSchemes(
                  query: _searchController.text,
                  jurisdiction: _selectedJurisdiction,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LoadingStateWidget(message: 'Loading schemes catalog...');
                  }
                  if (snapshot.hasError) {
                    return ErrorStateWidget(
                      message: 'Failed to load catalog: ${snapshot.error}',
                      onRetry: () => setState(() {}),
                    );
                  }
                  final schemes = snapshot.data ?? [];
                  if (schemes.isEmpty) {
                    return const EmptyStateWidget(
                      title: 'No Schemes Found',
                      description: 'No schemes match your current search parameters.',
                      icon: Icons.search_off_rounded,
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: schemes.length,
                    itemBuilder: (context, index) {
                      final scheme = schemes[index];
                      final isSaved = savedIds.contains(scheme.id);

                      return SchemeCard(
                        scheme: scheme,
                        isSaved: isSaved,
                        onTap: () => context.push('/catalog/${scheme.id}'),
                        onBookmarkTap: () async {
                          try {
                            final nowSaved = await ref
                                .read(savedSchemeIdsProvider.notifier)
                                .toggleSave(scheme.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    nowSaved
                                        ? 'Scheme saved to My Saved Schemes!'
                                        : 'Scheme removed from Saved Schemes.',
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
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
