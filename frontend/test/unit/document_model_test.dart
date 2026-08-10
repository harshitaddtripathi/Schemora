import 'package:flutter_test/flutter_test.dart';
import 'package:schemora_frontend/features/documents/domain/document_model.dart';

void main() {
  group('DocumentModel Unit Tests', () {
    test('UserDocumentModel.fromJson parses document payload correctly', () {
      final json = {
        'id': 'doc-1',
        'doc_type': 'Aadhaar',
        'file_name': 'aadhaar.json',
        'masked_identifier': 'XXXX-XXXX-1234',
        'verification_status': 'Verified',
        'verification_notes': 'Document details match profile',
      };

      final doc = UserDocumentModel.fromJson(json);

      expect(doc.id, equals('doc-1'));
      expect(doc.docType, equals('Aadhaar'));
      expect(doc.maskedIdentifier, equals('XXXX-XXXX-1234'));
      expect(doc.verificationStatus, equals('Verified'));
    });

    test('SchemeChecklistModel.fromJson parses checklist response', () {
      final json = {
        'scheme_id': 'sch-central-csss-001',
        'scheme_title': 'Central Sector Scheme',
        'readiness_percentage': 100.0,
        'is_ready_for_application': true,
        'items': [
          {
            'doc_type': 'Aadhaar',
            'title': 'Aadhaar Card',
            'is_mandatory': true,
            'status': 'Available',
            'masked_identifier': 'XXXX-XXXX-1234',
            'notes': 'Ready for submission',
          }
        ],
        'application_steps': ['1. Verify profile', '2. Submit on portal'],
      };

      final checklist = SchemeChecklistModel.fromJson(json);

      expect(checklist.schemeId, equals('sch-central-csss-001'));
      expect(checklist.readinessPercentage, equals(100.0));
      expect(checklist.isReadyForApplication, isTrue);
      expect(checklist.items.length, equals(1));
      expect(checklist.items[0].status, equals('Available'));
    });
  });
}
