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
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(8),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.schemeTitle,
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.primaryNavy, letterSpacing: -0.3),
                                ),
                                const SizedBox(height: 4),
                                Text('${item.provider} • ${item.jurisdiction}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.bookmark_remove_rounded, color: AppTheme.warningOrange),
                            tooltip: 'Remove from Saved',
                            onPressed: () async {
                              try {
                                await ref.read(savedSchemeIdsProvider.notifier).toggleSave(item.schemeId);
                                _refreshList();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Scheme removed from My Saved Schemes')),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to remove scheme: $e')),
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const Text('Status: ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.primaryNavy)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: item.status,
                              isDense: true,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              items: allStatuses
                                  .map((st) => DropdownMenuItem(value: st, child: Text(st, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primaryNavy))))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) _updateStatus(item.schemeId, val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => context.push('/catalog/${item.schemeId}'),
                            icon: const Icon(Icons.info_outline_rounded, size: 16),
                            label: const Text('View Details', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _showOfficialPortalDialog(item.schemeTitle, item.schemeId),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryBlue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.open_in_new_rounded, size: 16, color: Colors.white),
                            label: const Text('Official Portal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
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
