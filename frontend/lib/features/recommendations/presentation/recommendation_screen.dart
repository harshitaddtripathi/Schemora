import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:schemora_frontend/core/theme/app_theme.dart';
import 'package:schemora_frontend/core/widgets/common_states.dart';
import 'package:schemora_frontend/core/widgets/dashboard_button.dart';
import 'package:schemora_frontend/core/widgets/scheme_image_helper.dart';
import 'package:schemora_frontend/features/schemes/data/scheme_repository.dart';
import 'package:schemora_frontend/features/profile/domain/profile_type_provider.dart';

class RecommendationScreen extends ConsumerWidget {
  const RecommendationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final top3Async = ref.watch(top3RecommendationsProvider);
    final profileType = ref.watch(selectedProfileTypeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Matched Schemes (${profileType.displayName})'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          const DashboardButton(),
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Change Profile',
            onPressed: () => context.go('/profile-type'),
          ),
          IconButton(
            icon: const Icon(Icons.grid_view_rounded),
            tooltip: 'Catalog',
            onPressed: () => context.push('/catalog'),
          ),
        ],
      ),
      body: SafeArea(
        child: top3Async.when(
          loading: () => const LoadingStateWidget(message: 'Evaluating scheme eligibility rules...'),
          error: (err, stack) => ErrorStateWidget(
            message: 'Failed to calculate recommendations: $err',
            onRetry: () => ref.invalidate(top3RecommendationsProvider),
          ),
          data: (items) {
            if (items.isEmpty) {
              return const EmptyStateWidget(
                title: 'No Matching Schemes Found',
                description: 'No eligible schemes found for this profile type.',
              );
            }

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              children: [
                // Top Summary Header Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF2563EB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryNavy.withAlpha(50),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(40),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFFFBBF24), size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${profileType.displayName} Matches',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Showing ${items.length} verified government schemes matched to your eligibility rules.',
                              style: TextStyle(color: Colors.white.withAlpha(210), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                ...items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isMatched = item.status == 'RuleMatched';
                  final percent = (item.confidenceScore * 100).toInt();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(8),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Relatable Header Thumbnail Image Banner
                          SizedBox(
                            height: 110,
                            width: double.infinity,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.asset(
                                  SchemeImageHelper.getSchemeImage(title: item.schemeTitle),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const SizedBox(),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.black.withAlpha(160),
                                        Colors.black.withAlpha(40),
                                        Colors.transparent,
                                      ],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 10,
                                  left: 12,
                                  right: 12,
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryNavy,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          'Match #${index + 1}',
                                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isMatched ? const Color(0xFF10B981) : const Color(0xFFD97706),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          isMatched ? '100% Eligible' : 'Needs Verification',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withAlpha(130),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '$percent% Match',
                                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.all(18.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.schemeTitle,
                                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.primaryNavy),
                                ),

                                const SizedBox(height: 8),

                                Text(
                                  item.benefitSummary,
                                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
                                ),

                                const SizedBox(height: 14),

                                // Match Confidence Bar
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: item.confidenceScore,
                                    minHeight: 6,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isMatched ? AppTheme.successGreen : AppTheme.primaryBlue,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 16),
                                const Divider(height: 1),
                                const SizedBox(height: 12),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Provider: ${item.provider}',
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      onPressed: () => context.push('/catalog/${item.schemeId}'),
                                      icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                                      label: const Text('View Scheme'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryBlue,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ),
                                  ],
                                ),

                                if (item.unresolvedFields.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withAlpha(15),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.orange.withAlpha(40)),
                                    ),
                                    child: Text(
                                      'Additional Info Required: ${item.unresolvedFields.join(", ")}',
                                      style: const TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
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


