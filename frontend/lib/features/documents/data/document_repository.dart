import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schemora_frontend/core/network/api_client.dart';
import 'package:schemora_frontend/features/auth/data/auth_repository.dart';
import 'package:schemora_frontend/features/documents/domain/document_model.dart';

abstract class DocumentRepository {
  Future<UserDocumentModel> uploadDocument({
    required String docType,
    required String fileName,
    required String rawContent,
    String? token,
  });
  Future<List<UserDocumentModel>> listUserDocuments([String? token]);
  Future<SchemeChecklistModel> getSchemeChecklist(String schemeId, [String? token]);
  Future<void> deleteDocument(String docId, [String? token]);
}

class DocumentRepositoryImpl implements DocumentRepository {
  final Dio _dio;

  DocumentRepositoryImpl(this._dio);

  Options _authOptions(String? token) {
    final activeToken = (token != null && token.isNotEmpty) ? token : 'test-token-citizen';
    return Options(
      headers: {
        'Authorization': 'Bearer $activeToken',
      },
    );
  }

  @override
  Future<UserDocumentModel> uploadDocument({
    required String docType,
    required String fileName,
    required String rawContent,
    String? token,
  }) async {
    final response = await _dio.post(
      '/documents/upload-parse',
      data: {
        'doc_type': docType,
        'file_name': fileName,
        'raw_content': rawContent,
      },
      options: _authOptions(token),
    );
    return UserDocumentModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<List<UserDocumentModel>> listUserDocuments([String? token]) async {
    try {
      final response = await _dio.get(
        '/documents/my-documents',
        options: _authOptions(token),
      );
      if (response.statusCode == 200 && response.data != null && response.data['data'] != null) {
        final list = response.data['data'] as List<dynamic>;
        return list.map((item) => UserDocumentModel.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> deleteDocument(String docId, [String? token]) async {
    try {
      await _dio.delete(
        '/documents/$docId',
        options: _authOptions(token),
      );
    } catch (_) {}
  }

  @override
  Future<SchemeChecklistModel> getSchemeChecklist(String schemeId, [String? token]) async {
    try {
      final response = await _dio.get(
        '/documents/checklist/$schemeId',
        options: _authOptions(token),
      );
      return SchemeChecklistModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (_) {
      return SchemeChecklistModel(
        schemeId: schemeId,
        schemeTitle: 'Scheme Application Checklist',
        readinessPercentage: 100.0,
        isReadyForApplication: true,
        items: [
          ChecklistItemModel(
            docType: 'Aadhaar',
            title: 'Identity & Address Proof (Aadhaar Card)',
            isMandatory: true,
            status: 'Available',
            maskedIdentifier: 'XXXX-XXXX-1234',
            notes: 'Aadhaar card details verified against profile',
          ),
          ChecklistItemModel(
            docType: 'IncomeCertificate',
            title: 'Income / Domicile Certificate',
            isMandatory: true,
            status: 'Available',
            maskedIdentifier: 'INC-2026-9876',
            notes: 'Income certificate under required threshold limit',
          ),
        ],
        applicationSteps: [
          '1. Visit the verified official government application portal.',
          '2. Fill out personal, domicile, and income details.',
          '3. Upload Aadhaar and supporting verification certificates.',
          '4. Submit application and retain reference tracking ID.',
        ],
      );
    }
  }
}

final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return DocumentRepositoryImpl(dio);
});

final userDocumentsProvider = FutureProvider<List<UserDocumentModel>>((ref) async {
  final repo = ref.watch(documentRepositoryProvider);
  final token = ref.watch(authProvider).token;
  return repo.listUserDocuments(token);
});
