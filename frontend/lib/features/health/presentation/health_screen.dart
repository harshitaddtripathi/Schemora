import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schemora_frontend/core/theme/app_theme.dart';
import 'package:schemora_frontend/core/widgets/common_states.dart';
import 'package:schemora_frontend/features/health/data/health_repository.dart';

class HealthScreen extends ConsumerWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthState = ref.watch(healthStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schemora API Diagnostic'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(healthStatusProvider),
          )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: healthState.when(
            loading: () => const LoadingStateWidget(message: 'Checking API backend status...'),
            error: (err, stack) => ErrorStateWidget(
              message: 'Could not connect to FastAPI server.\n\n$err',
              onRetry: () => ref.invalidate(healthStatusProvider),
            ),
            data: (health) => Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: health.databaseConnected
                                    ? AppTheme.successGreen.withAlpha(26)
                                    : AppTheme.warningOrange.withAlpha(26),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                health.databaseConnected
                                    ? Icons.check_circle_rounded
                                    : Icons.warning_amber_rounded,
                                color: health.databaseConnected
                                    ? AppTheme.successGreen
                                    : AppTheme.warningOrange,
                                size: 48,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              health.databaseConnected
                                  ? 'Backend Fully Operational'
                                  : 'Backend Degraded (DB Offline)',
                              style: Theme.of(context).textTheme.titleLarge,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Environment: ${health.environment}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const Divider(height: 32),
                            _buildHealthRow(context, 'API Version', health.version),
                            _buildHealthRow(
                              context,
                              'Database Status',
                              health.databaseConnected ? 'Connected' : 'Disconnected',
                              valueColor: health.databaseConnected
                                  ? AppTheme.successGreen
                                  : AppTheme.errorRed,
                            ),
                            _buildHealthRow(context, 'Response Time', '${health.latencyMs} ms'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => ref.invalidate(healthStatusProvider),
                      icon: const Icon(Icons.sync_rounded),
                      label: const Text('Re-Check System Health'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHealthRow(BuildContext context, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: valueColor ?? AppTheme.primaryNavy,
                ),
          ),
        ],
      ),
    );
  }
}
