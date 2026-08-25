import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:schemora_frontend/core/theme/app_theme.dart';
import 'package:schemora_frontend/core/widgets/dashboard_button.dart';
import 'package:schemora_frontend/features/saved_schemes/data/saved_scheme_repository.dart';
import 'package:schemora_frontend/features/saved_schemes/domain/saved_scheme_model.dart';

const List<String> allStatuses = [
  'Saved',
  'Drafting',
  'DocumentsPending',
  'AppliedOnOfficialPortal',
  'UnderReview',
  'Approved',
  'Rejected',
];

class SavedSchemesScreen extends ConsumerStatefulWidget {
  const SavedSchemesScreen({super.key});

  @override
  ConsumerState<SavedSchemesScreen> createState() => _SavedSchemesScreenState();
}

class _SavedSchemesScreenState extends ConsumerState<SavedSchemesScreen> {
  late Future<List<SavedSchemeItemModel>> _savedFuture;

  @override
  void initState() {
    super.initState();
    _refreshList();
  }

  void _refreshList() {
    setState(() {
      _savedFuture = ref.read(savedSchemeRepositoryProvider).listSavedSchemes();
    });
  }

  Future<void> _updateStatus(String schemeId, String newStatus) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(savedSchemeRepositoryProvider).updateStatus(schemeId, newStatus);
      _refreshList();
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Failed to update status: $e')),
        );
      }
    }
  }

  void _showOfficialPortalDialog(String schemeTitle, String schemeId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Schemora?'),
        content: Text(
          'You are leaving Schemora to apply directly on the official government portal for "$schemeTitle".\n\n'
          'Schemora is not affiliated with the government portal, but we have verified this official link.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(savedSchemeRepositoryProvider).logPortalEvent(schemeId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening Official Government Portal...')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
            child: const Text('Open Official Portal', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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
        title: const Text('Saved Schemes & Tracker'),
        actions: [
          const DashboardButton(),
        ],
      ),
      body: FutureBuilder<List<SavedSchemeItemModel>>(
        future: _savedFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading saved schemes: ${snapshot.error}'));
          }

          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return const Center(
              child: Text(
                'No saved schemes yet.\nBrowse the catalog to save schemes and track application status!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.schemeTitle,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryNavy),
                      ),
                      const SizedBox(height: 4),
                      Text('${item.provider} • ${item.jurisdiction}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text('Application Status: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: item.status,
                              isDense: true,
                              decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                              items: allStatuses
                                  .map((st) => DropdownMenuItem(value: st, child: Text(st, style: const TextStyle(fontSize: 13))))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) _updateStatus(item.schemeId, val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _showOfficialPortalDialog(item.schemeTitle, item.schemeId),
                            icon: const Icon(Icons.open_in_new_rounded, size: 16),
                            label: const Text('Official Portal'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
