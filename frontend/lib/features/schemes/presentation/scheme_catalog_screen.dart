import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:schemora_frontend/core/theme/app_theme.dart';
import 'package:schemora_frontend/core/widgets/common_states.dart';
import 'package:schemora_frontend/core/widgets/dashboard_button.dart';
import 'package:schemora_frontend/features/schemes/data/scheme_repository.dart';
import 'package:schemora_frontend/features/schemes/domain/scheme_model.dart';

import 'package:schemora_frontend/features/saved_schemes/data/saved_scheme_repository.dart';

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
        title: const Text('Schemora Catalog'),
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
                    decoration: InputDecoration(
                      hintText: 'Search schemes (e.g. scholarship, internship)...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (val) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      FilterChip(
                        label: const Text('All'),
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
                    return const LoadingStateWidget(message: 'Searching scheme catalog...');
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
                      description: 'No schemes match your search criteria.',
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: schemes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final scheme = schemes[index];
                      final isSaved = savedIds.contains(scheme.id);

                      return Card(
                        elevation: 2,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(
                            scheme.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 6),
                              Text(scheme.shortDescription, maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryBlue.withAlpha(20),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      scheme.jurisdiction,
                                      style: const TextStyle(fontSize: 12, color: AppTheme.primaryNavy, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      scheme.provider,
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                  color: isSaved ? AppTheme.warningOrange : Colors.grey,
                                ),
                                tooltip: isSaved ? 'Remove from Saved' : 'Save Scheme',
                                onPressed: () async {
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
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                            ],
                          ),
                          onTap: () => context.push('/catalog/${scheme.id}'),
                        ),
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
