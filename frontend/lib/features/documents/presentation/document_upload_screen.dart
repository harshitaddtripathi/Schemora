import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schemora_frontend/core/theme/app_theme.dart';
import 'package:schemora_frontend/core/widgets/dashboard_button.dart';
import 'package:schemora_frontend/features/documents/data/document_repository.dart';
import 'package:schemora_frontend/features/documents/domain/document_model.dart';

class DocumentUploadScreen extends ConsumerStatefulWidget {
  const DocumentUploadScreen({super.key});

  @override
  ConsumerState<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends ConsumerState<DocumentUploadScreen> {
  String _selectedDocType = 'Aadhaar';
  final _nameController = TextEditingController(text: 'Aarav Sharma');
  final _dobController = TextEditingController(text: '2005-06-15');
  final _idNumController = TextEditingController(text: '9999_8888_1234');
  bool _isLoading = false;
  UserDocumentModel? _uploadedDoc;

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _idNumController.dispose();
    super.dispose();
  }

  Future<void> _handleUpload() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(documentRepositoryProvider);
      final rawContent = '''
      {
        "full_name": "${_nameController.text.trim()}",
        "date_of_birth": "${_dobController.text.trim()}",
        "${_selectedDocType.toLowerCase()}_number": "${_idNumController.text.trim()}",
        "annual_income": 200000.0
      }
      ''';

      final doc = await repo.uploadDocument(
        docType: _selectedDocType,
        fileName: '${_selectedDocType.toLowerCase()}_sample.json',
        rawContent: rawContent,
      );

      if (mounted) {
        setState(() => _uploadedDoc = doc);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Document uploaded & verified: ${doc.verificationStatus}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload & Mask Document'),
        actions: const [
          DashboardButton(),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Document Type',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedDocType,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'Aadhaar', child: Text('Aadhaar Card (Identity & DOB)')),
                DropdownMenuItem(value: 'PAN', child: Text('PAN Card (Bank Account Linking)')),
                DropdownMenuItem(value: 'IncomeCertificate', child: Text('Income Certificate')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedDocType = val;
                    if (val == 'Aadhaar') _idNumController.text = '9999_8888_1234';
                    if (val == 'PAN') _idNumController.text = 'ABCDE_1234_F';
                    if (val == 'IncomeCertificate') _idNumController.text = 'INC-2026-9876';
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Full Name on Document', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _dobController,
              decoration: const InputDecoration(labelText: 'Date of Birth (YYYY-MM-DD)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _idNumController,
              decoration: InputDecoration(
                labelText: 'Document Number ($_selectedDocType)',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _handleUpload,
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
                icon: const Icon(Icons.cloud_upload_rounded, color: Colors.white),
                label: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Upload & Perform OCR Analysis', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
            if (_uploadedDoc != null) ...[
              const SizedBox(height: 24),
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'OCR & Masking Result',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryNavy),
                      ),
                      const Divider(),
                      Text('Document Type: ${_uploadedDoc!.docType}'),
                      Text('Masked Identifier: ${_uploadedDoc!.maskedIdentifier ?? "N/A"}'),
                      Text('Status: ${_uploadedDoc!.verificationStatus}'),
                      if (_uploadedDoc!.verificationNotes != null)
                        Text('Notes: ${_uploadedDoc!.verificationNotes}', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
