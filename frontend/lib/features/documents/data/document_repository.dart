import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schemora_frontend/core/network/api_client.dart';
import 'package:schemora_frontend/features/documents/domain/document_model.dart';

abstract class DocumentRepository {
  Future<UserDocumentModel> uploadDocument({
    required String docType,
    required String fileName,
    required String rawContent,
  });
  Future<List<UserDocumentModel>> listUserDocuments();
  Future<SchemeChecklistModel> getSchemeChecklist(String schemeId);
}

class DocumentRepositoryImpl implements DocumentRepository {
  final Dio _dio;

  DocumentRepositoryImpl(this._dio);

  @override
  Future<UserDocumentModel> uploadDocument({
    required String docType,
    required String fileName,
    required String rawContent,
  }) async {
    final response = await _dio.post(
      '/documents/upload-parse',
      data: {
        'doc_type': docType,
        'file_name': fileName,
        'raw_content': rawContent,
      },
    );
    return UserDocumentModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<List<UserDocumentModel>> listUserDocuments() async {
    final response = await _dio.get('/documents/my-documents');
    final list = response.data['data'] as List<dynamic>;
    return list.map((item) => UserDocumentModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  @override
  Future<SchemeChecklistModel> getSchemeChecklist(String schemeId) async {
    final response = await _dio.get('/documents/checklist/$schemeId');
    return SchemeChecklistModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}

final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return DocumentRepositoryImpl(dio);
});
