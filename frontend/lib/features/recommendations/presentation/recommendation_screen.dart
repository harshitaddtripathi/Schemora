import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:schemora_frontend/core/theme/app_theme.dart';
import 'package:schemora_frontend/core/widgets/common_states.dart';
import 'package:schemora_frontend/features/schemes/data/scheme_repository.dart';

import 'package:schemora_frontend/features/profile/domain/profile_type_provider.dart';

class RecommendationScreen extends ConsumerWidget {
  const RecommendationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final top3Async = ref.watch(top3RecommendationsProvider);
    final profileType = ref.watch(selectedProfileTypeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('My Matches (${profileType.displayName})'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            tooltip: 'Edit Profile',
            onPressed: () => context.go('/profile-type'),
          ),
          IconButton(
            icon: const Icon(Icons.grid_view_rounded),
            tooltip: 'All Schemes',
            onPressed: () => context.push('/catalog'),
          ),
        ],
      ),
      body: SafeArea(
        child: top3Async.when(
          loading: () => const LoadingStateWidget(message: 'Evaluating eligibility rules & calculating recommendations...'),
          error: (err, stack) => ErrorStateWidget(
            message: 'Failed to calculate recommendations: $err',
            onRetry: () => ref.invalidate(top3RecommendationsProvider),
          ),
          data: (items) {
            if (items.isEmpty) {
              return const EmptyStateWidget(
                title: 'No Eligible Schemes',
                description: 'No eligible schemes found. Try updating your citizen profile.',
              );
            }

            return ListView(
              padding: const EdgeInsets.all(20.0),
              children: [
                Text('All Eligible ${profileType.displayName} Schemes', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 22)),
                const SizedBox(height: 6),
                Text(
                  'Showing all ${items.length} matched schemes across Central & State governments.',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                ...items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isMatched = item.status == 'RuleMatched';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                backgroundColor: AppTheme.primaryNavy,
                                radius: 14,
                                child: Text(
                                  '#${index + 1}',
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.schemeTitle,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                flex: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isMatched ? AppTheme.successGreen.withAlpha(25) : Colors.orange.withAlpha(25),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    item.status,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isMatched ? AppTheme.successGreen : Colors.orange.shade800,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(item.benefitSummary, style: Theme.of(context).textTheme.bodyMedium),
                          const SizedBox(height: 12),
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            runSpacing: 8,
                            spacing: 12,
                            children: [
                              Text(
                                'Confidence: ${(item.confidenceScore * 100).toInt()}%',
                                style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primaryNavy),
                              ),
                              TextButton.icon(
                                onPressed: () => context.push('/catalog/${item.schemeId}'),
                                icon: const Icon(Icons.info_outline, size: 16),
                                label: const Text('View Details'),
                              ),
                            ],
                          ),
                          if (item.unresolvedFields.isNotEmpty) ...[
                            const Divider(),
                            Text(
                              'Missing Information: ${item.unresolvedFields.join(", ")}',
                              style: const TextStyle(fontSize: 12, color: Colors.orange),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}
