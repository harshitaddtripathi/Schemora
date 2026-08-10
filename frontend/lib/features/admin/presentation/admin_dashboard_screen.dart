// admin_dashboard_screen.dart — Phase 7 Admin Dashboard
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schemora_frontend/core/network/api_client.dart';
import 'package:schemora_frontend/core/theme/app_theme.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  List<Map<String, dynamic>> _schemes = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSchemes();
  }

  Future<void> _loadSchemes() async {
    setState(() { _loading = true; _error = null; });
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('/admin/schemes');
      setState(() {
        _schemes = List<Map<String, dynamic>>.from(res.data['data'] as List);
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _publishKnowledge(String schemeId) async {
    final dio = ref.read(dioProvider);
    await dio.post('/admin/knowledge/publish', data: {
      'scheme_id': schemeId,
      'source_text': 'Official guideline content for scheme $schemeId reviewed by administrator.',
      'source_url': 'https://scholarships.gov.in/public/schemeGuidelines/$schemeId',
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Knowledge published for $schemeId'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _unpublishKnowledge(String schemeId) async {
    final dio = ref.read(dioProvider);
    await dio.post('/admin/knowledge/unpublish', data: {'scheme_id': schemeId});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Knowledge unpublished for $schemeId'), backgroundColor: Colors.orange),
      );
    }
  }

  void _showSchemeEditDialog(Map<String, dynamic> scheme) {
    final titleCtrl = TextEditingController(text: scheme['title'] as String? ?? '');
    final deadlineCtrl = TextEditingController(text: scheme['deadline_text'] as String? ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Scheme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 12),
            TextField(controller: deadlineCtrl, decoration: const InputDecoration(labelText: 'Deadline Text')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final dio = ref.read(dioProvider);
              await dio.put('/admin/schemes/${scheme['id']}', data: {
                'title': titleCtrl.text,
                'deadline_text': deadlineCtrl.text,
              });
              _loadSchemes();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: AppTheme.primaryNavy,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadSchemes),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                      child: Row(
                        children: [
                          const Icon(Icons.admin_panel_settings_rounded, color: AppTheme.primaryBlue),
                          const SizedBox(width: 8),
                          Text('${_schemes.length} Schemes', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const Spacer(),
                          Text('Administrator', style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _schemes.length,
                        itemBuilder: (context, i) {
                          final s = _schemes[i];
                          final isActive = s['is_active'] as bool? ?? true;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isActive ? Colors.green.shade100 : Colors.red.shade100,
                                child: Icon(Icons.school_rounded, color: isActive ? Colors.green : Colors.red, size: 20),
                              ),
                              title: Text(s['title'] as String? ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              subtitle: Text('${s['provider']} • ${s['jurisdiction']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              trailing: PopupMenuButton<String>(
                                onSelected: (action) {
                                  if (action == 'edit') _showSchemeEditDialog(s);
                                  if (action == 'publish') _publishKnowledge(s['id'] as String);
                                  if (action == 'unpublish') _unpublishKnowledge(s['id'] as String);
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(value: 'edit', child: Text('Edit Scheme')),
                                  PopupMenuItem(value: 'publish', child: Text('Publish Knowledge')),
                                  PopupMenuItem(value: 'unpublish', child: Text('Unpublish Knowledge')),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
