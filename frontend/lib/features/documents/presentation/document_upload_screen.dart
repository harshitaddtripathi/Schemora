import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schemora_frontend/core/theme/app_theme.dart';
import 'package:schemora_frontend/features/documents/data/document_repository.dart';
import 'package:schemora_frontend/features/documents/domain/document_model.dart';

class DocumentUploadScreen extends ConsumerStatefulWidget {
  const DocumentUploadScreen({super.key});

  @override
  ConsumerState<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends ConsumerState<DocumentUploadScreen> {
  String _selectedDocType = 'Aadhaar';
  String _selectedFileName = 'aadhaar_card_scanned.pdf';
  
  final _nameController = TextEditingController(text: 'Aarav Sharma');
  final _dobController = TextEditingController(text: '2005-06-15');
  final _idNumController = TextEditingController(text: '9999_8888_1234');
  final _incomeController = TextEditingController(text: '200000');

  bool _isUploading = false;
  bool _showUploadForm = false;

  static const List<Map<String, dynamic>> _docTypes = [
    {
      'id': 'Aadhaar',
      'label': 'Aadhaar Card',
      'subtitle': 'Identity & Date of Birth',
      'icon': Icons.badge_outlined,
      'color': Color(0xFF2563EB),
      'defaultId': '9999_8888_1234',
      'file': 'aadhaar_card_scanned.pdf',
    },
    {
      'id': 'PAN',
      'label': 'PAN Card',
      'subtitle': 'Financial & Bank Linking',
      'icon': Icons.credit_card_rounded,
      'color': Color(0xFF7C3AED),
      'defaultId': 'ABCDE-1234-F',
      'file': 'pan_card_copy.jpg',
    },
    {
      'id': 'IncomeCertificate',
      'label': 'Income Certificate',
      'subtitle': 'Annual Family Income Proof',
      'icon': Icons.request_quote_rounded,
      'color': Color(0xFF059669),
      'defaultId': 'INC-2026-9876',
      'file': 'income_certificate_2026.pdf',
    },
    {
      'id': 'CasteCertificate',
      'label': 'Caste Certificate',
      'subtitle': 'Category / Caste Verification',
      'icon': Icons.account_balance_rounded,
      'color': Color(0xFFD97706),
      'defaultId': 'CST-2026-4321',
      'file': 'caste_certificate.pdf',
    },
    {
      'id': 'Marksheet',
      'label': 'Marksheet / Degree',
      'subtitle': 'Academic Passing Certificate',
      'icon': Icons.school_rounded,
      'color': Color(0xFF2563EB),
      'defaultId': 'ROLL-2026-1001',
      'file': 'class12_marksheet.pdf',
    },
    {
      'id': 'DomicileCertificate',
      'label': 'Domicile Certificate',
      'subtitle': 'State Residence Proof',
      'icon': Icons.location_city_rounded,
      'color': Color(0xFF0D9488),
      'defaultId': 'DOM-2026-5544',
      'file': 'domicile_certificate.pdf',
    },
    {
      'id': 'RationCard',
      'label': 'Ration Card',
      'subtitle': 'Family Beneficiary Status',
      'icon': Icons.rice_bowl_rounded,
      'color': Color(0xFFDB2777),
      'defaultId': 'RAT-2026-9988',
      'file': 'ration_card.pdf',
    },
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _idNumController.dispose();
    _incomeController.dispose();
    super.dispose();
  }

  void _onDocTypeChanged(String newType) {
    final meta = _docTypes.firstWhere((element) => element['id'] == newType, orElse: () => _docTypes.first);
    setState(() {
      _selectedDocType = newType;
      _idNumController.text = meta['defaultId'] as String;
      _selectedFileName = meta['file'] as String;
    });
  }

  Future<void> _handleUpload() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter full name on document')),
      );
      return;
    }

    setState(() => _isUploading = true);
    try {
      final repo = ref.read(documentRepositoryProvider);

      Map<String, dynamic> rawMap = {
        "full_name": _nameController.text.trim(),
        "date_of_birth": _dobController.text.trim(),
        "document_number": _idNumController.text.trim(),
      };

      if (_selectedDocType == 'Aadhaar') {
        rawMap["aadhaar_number"] = _idNumController.text.trim();
      } else if (_selectedDocType == 'PAN') {
        rawMap["pan_number"] = _idNumController.text.trim();
      } else if (_selectedDocType == 'IncomeCertificate') {
        rawMap["annual_income"] = double.tryParse(_incomeController.text.trim()) ?? 200000.0;
        rawMap["certificate_number"] = _idNumController.text.trim();
      } else {
        rawMap["certificate_number"] = _idNumController.text.trim();
      }

      final doc = await repo.uploadDocument(
        docType: _selectedDocType,
        fileName: _selectedFileName,
        rawContent: rawMap.toString(),
      );

      // Invalidate provider to auto-refresh vault list
      ref.invalidate(userDocumentsProvider);

      if (mounted) {
        setState(() {
          _showUploadForm = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Document uploaded & encrypted! Masked: ${doc.maskedIdentifier ?? doc.fileName}'),
                ),
              ],
            ),
            backgroundColor: AppTheme.successGreen,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _handleDelete(String docId, String docName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Document?'),
        content: Text('Are you sure you want to remove "$docName" from your Vault?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(documentRepositoryProvider).deleteDocument(docId);
        ref.invalidate(userDocumentsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Document deleted from Vault'), behavior: SnackBarBehavior.floating),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final docsAsync = ref.watch(userDocumentsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: AppTheme.primaryBlue, size: 22),
            SizedBox(width: 8),
            Text(
              'Document Vault',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Color(0xFF0F172A)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B)),
            tooltip: 'Refresh Vault',
            onPressed: () => ref.invalidate(userDocumentsProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => setState(() => _showUploadForm = !_showUploadForm),
        backgroundColor: _showUploadForm ? const Color(0xFF64748B) : AppTheme.primaryBlue,
        icon: Icon(_showUploadForm ? Icons.close_rounded : Icons.cloud_upload_rounded, color: Colors.white),
        label: Text(
          _showUploadForm ? 'Close Form' : 'Upload Document',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(userDocumentsProvider),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Vault Security Header ─────────────────────────────────────
                _buildSecurityHeader(),
                const SizedBox(height: 16),

                // ── Upload Form Card ─────────────────────────────────────────
                if (_showUploadForm) ...[
                  _buildUploadFormCard(),
                  const SizedBox(height: 20),
                ],

                // ── Vault Documents Section ──────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Your Verified Documents',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF0F172A)),
                    ),
                    if (!_showUploadForm)
                      TextButton.icon(
                        onPressed: () => setState(() => _showUploadForm = true),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Add New'),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // ── Document List from Backend ────────────────────────────────
                docsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 12),
                          Text('Loading document vault...', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                  error: (err, stack) => _buildErrorCard(err),
                  data: (docs) => docs.isEmpty ? _buildEmptyVaultView() : _buildDocumentList(docs),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Security Header Card ───────────────────────────────────────────────────
  Widget _buildSecurityHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.security_rounded, color: Colors.cyanAccent, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Schemora Zero-Trust Vault',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      'AES-256 Encrypted • Automatic Redaction',
                      style: TextStyle(color: Color(0xFF93C5FD), fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Upload your identity & income certificates once to auto-fill government scheme applications and verify eligibility instantly.',
            style: TextStyle(color: Color(0xFFE2E8F0), fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  // ── Upload Form Card ───────────────────────────────────────────────────────
  Widget _buildUploadFormCard() {
    final currentTypeMeta = _docTypes.firstWhere(
      (element) => element['id'] == _selectedDocType,
      orElse: () => _docTypes.first,
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryBlue.withAlpha(80), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withAlpha(15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cloud_upload_rounded, color: AppTheme.primaryBlue, size: 22),
              const SizedBox(width: 8),
              const Text(
                'Upload New Document',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => setState(() => _showUploadForm = false),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 8),

          // Document Type Selector
          const Text(
            '1. Select Document Type',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedDocType,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            items: _docTypes.map((dt) {
              return DropdownMenuItem<String>(
                value: dt['id'] as String,
                child: Row(
                  children: [
                    Icon(dt['icon'] as IconData, size: 18, color: dt['color'] as Color),
                    const SizedBox(width: 10),
                    Text(dt['label'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) _onDocTypeChanged(val);
            },
          ),
          const SizedBox(height: 16),

          // File Dropzone / Attachment Picker Simulation Card
          const Text(
            '2. Select Document File / Photo',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              // Simulate file picker choice
              final chosen = await showModalBottomSheet<String>(
                context: context,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
                builder: (ctx) => Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Choose Attachment Source', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(Icons.camera_alt_rounded, color: AppTheme.primaryBlue),
                        title: const Text('Scan with Camera'),
                        subtitle: const Text('Take a photo of physical document'),
                        onTap: () => Navigator.pop(ctx, 'camera_scan.jpg'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.photo_library_rounded, color: Colors.purple),
                        title: const Text('Pick from Gallery / Files'),
                        subtitle: Text('Select ${_selectedDocType.toLowerCase()}_file.pdf'),
                        onTap: () => Navigator.pop(ctx, '${_selectedDocType.toLowerCase()}_scanned.pdf'),
                      ),
                    ],
                  ),
                ),
              );
              if (chosen != null) {
                setState(() => _selectedFileName = chosen);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryBlue.withAlpha(100), style: BorderStyle.solid),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (currentTypeMeta['color'] as Color).withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(currentTypeMeta['icon'] as IconData, color: currentTypeMeta['color'] as Color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedFileName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Tap to scan or choose a different file',
                          style: TextStyle(fontSize: 11, color: AppTheme.primaryBlue, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.file_upload_outlined, color: AppTheme.primaryBlue),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Document Details Input Fields
          const Text(
            '3. Document Information (Auto-Extracted)',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Full Name on Document',
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _dobController,
                  decoration: InputDecoration(
                    labelText: 'DOB (YYYY-MM-DD)',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _idNumController,
                  decoration: InputDecoration(
                    labelText: 'Doc Number / ID',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
          if (_selectedDocType == 'IncomeCertificate') ...[
            const SizedBox(height: 10),
            TextField(
              controller: _incomeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Annual Family Income (₹)',
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
          const SizedBox(height: 18),

          // Upload Action Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isUploading ? null : _handleUpload,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: _isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.shield_rounded, color: Colors.white),
              label: Text(
                _isUploading ? 'Encrypting & Uploading...' : 'Upload & Verify in Vault',
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Document List View ─────────────────────────────────────────────────────
  Widget _buildDocumentList(List<UserDocumentModel> docs) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: docs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, idx) {
        final doc = docs[idx];
        final typeMeta = _docTypes.firstWhere(
          (element) => element['id'] == doc.docType,
          orElse: () => {
            'label': doc.docType,
            'icon': Icons.description_rounded,
            'color': AppTheme.primaryBlue,
          },
        );

        final isVerified = doc.verificationStatus.toLowerCase() == 'verified';
        final isWarning = doc.verificationStatus.toLowerCase() == 'warning';

        final statusColor = isVerified
            ? AppTheme.successGreen
            : (isWarning ? AppTheme.warningOrange : AppTheme.errorRed);

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(6),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (typeMeta['color'] as Color).withAlpha(24),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(typeMeta['icon'] as IconData, color: typeMeta['color'] as Color, size: 24),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    typeMeta['label'] as String,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(24),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withAlpha(100)),
                  ),
                  child: Text(
                    doc.verificationStatus,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'Masked ID: ${doc.maskedIdentifier ?? "XXXX-XXXX"}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                ),
                Text(
                  'File: ${doc.fileName}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                if (doc.verificationNotes != null && doc.verificationNotes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    doc.verificationNotes!,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
              tooltip: 'Delete Document',
              onPressed: () => _handleDelete(doc.id, typeMeta['label'] as String),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyVaultView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(Icons.folder_open_rounded, size: 54, color: Colors.grey.shade400),
          const SizedBox(height: 14),
          const Text(
            'Your Vault is Empty',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 6),
          Text(
            'Upload your Aadhaar, PAN, Income or Marksheet documents to secure your records and streamline scheme applications.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: () => setState(() => _showUploadForm = true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.cloud_upload_rounded, color: Colors.white),
            label: const Text('Upload Your First Document', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(Object err) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Could not load documents: $err',
              style: const TextStyle(fontSize: 12, color: Colors.red),
            ),
          ),
          TextButton(
            onPressed: () => ref.invalidate(userDocumentsProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
