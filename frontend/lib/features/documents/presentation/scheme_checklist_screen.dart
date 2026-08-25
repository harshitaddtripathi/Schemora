import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:schemora_frontend/core/theme/app_theme.dart';
import 'package:schemora_frontend/core/widgets/dashboard_button.dart';
import 'package:schemora_frontend/features/documents/data/document_repository.dart';
import 'package:schemora_frontend/features/documents/domain/document_model.dart';

class SchemeChecklistScreen extends ConsumerStatefulWidget {
  final String schemeId;

  const SchemeChecklistScreen({super.key, required this.schemeId});

  @override
  ConsumerState<SchemeChecklistScreen> createState() => _SchemeChecklistScreenState();
}

class _SchemeChecklistScreenState extends ConsumerState<SchemeChecklistScreen> {
  late Future<SchemeChecklistModel> _checklistFuture;

  @override
  void initState() {
    super.initState();
    _checklistFuture = ref.read(documentRepositoryProvider).getSchemeChecklist(widget.schemeId);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Available':
        return Colors.green;
      case 'Warning':
        return Colors.orange;
      case 'CorrectionRequired':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Go Back',
          onPressed: () => context.canPop() ? context.pop() : context.go('/dashboard'),
        ),
        title: const Text('Application Checklist'),
        actions: const [
          DashboardButton(),
        ],
      ),
      body: FutureBuilder<SchemeChecklistModel>(
        future: _checklistFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading checklist: ${snapshot.error}'));
          }

          final data = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.schemeTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryNavy),
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: data.readinessPercentage / 100.0,
                  minHeight: 10,
                  backgroundColor: Colors.grey.shade200,
                  color: data.isReadyForApplication ? Colors.green : AppTheme.primaryBlue,
                ),
                const SizedBox(height: 8),
                Text(
                  'Application Readiness: ${data.readinessPercentage.toInt()}%',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Required Documents',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                ...data.items.map((item) => Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(item.status).withAlpha(30),
                          child: Icon(
                            item.status == 'Available' ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                            color: _getStatusColor(item.status),
                          ),
                        ),
                        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (item.maskedIdentifier != null)
                              Text('Masked ID: ${item.maskedIdentifier}', style: const TextStyle(fontSize: 12)),
                            Text(item.notes, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                          ],
                        ),
                        trailing: Chip(
                          label: Text(item.status, style: const TextStyle(fontSize: 11, color: Colors.white)),
                          backgroundColor: _getStatusColor(item.status),
                        ),
                      ),
                    )),
                const SizedBox(height: 20),
                const Text(
                  'Application Steps',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                ...data.applicationSteps.map((step) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(step, style: const TextStyle(fontSize: 14)),
                    )),
              ],
            ),
          );
        },
      ),
    );
  }
}
