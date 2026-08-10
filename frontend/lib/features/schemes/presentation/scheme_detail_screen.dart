import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schemora_frontend/core/theme/app_theme.dart';
import 'package:schemora_frontend/core/widgets/common_states.dart';
import 'package:schemora_frontend/features/schemes/data/scheme_repository.dart';
import 'package:schemora_frontend/features/schemes/domain/scheme_model.dart';

class SchemeDetailScreen extends ConsumerWidget {
  final String schemeId;

  const SchemeDetailScreen({super.key, required this.schemeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(schemeRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scheme Details'),
      ),
      body: SafeArea(
        child: FutureBuilder<SchemeModel>(
          future: repo.getSchemeDetails(schemeId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingStateWidget(message: 'Loading scheme details...');
            }
            if (snapshot.hasError) {
              return ErrorStateWidget(
                message: 'Failed to load details: ${snapshot.error}',
              );
            }

            final scheme = snapshot.data!;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(scheme.title, style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 22)),
                  const SizedBox(height: 8),
                  Text('Provider: ${scheme.provider}', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 16),
                  Card(
                    color: AppTheme.primaryBlue.withAlpha(15),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Key Benefits Summary', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryNavy)),
                          const SizedBox(height: 4),
                          Text(scheme.benefitSummary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Description', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(scheme.detailedDescription ?? scheme.shortDescription),
                  const SizedBox(height: 24),
                  Text('Eligibility Rules (${scheme.rules.length})', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 12),
                  ...scheme.rules.map((rule) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            rule.ruleType == 'mandatory' ? Icons.check_circle_outline : Icons.info_outline,
                            color: rule.ruleType == 'mandatory' ? AppTheme.primaryBlue : Colors.orange,
                          ),
                          title: Text('${rule.fieldName} ${rule.operator} ${rule.expectedValue}'),
                          subtitle: Text(rule.failureReason ?? 'Mandatory rule condition'),
                        ),
                      )),
                  const SizedBox(height: 24),
                  if (scheme.sources.isNotEmpty) ...[
                    Text('Official Sources', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 12),
                    ...scheme.sources.map((src) => ListTile(
                          leading: const Icon(Icons.link_rounded, color: AppTheme.primaryBlue),
                          title: Text(src.sourceName),
                          subtitle: Text(src.url, style: const TextStyle(color: AppTheme.primaryBlue)),
                        )),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
