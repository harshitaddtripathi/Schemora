import 'package:flutter_test/flutter_test.dart';
import 'package:schemora_frontend/features/saved_schemes/domain/saved_scheme_model.dart';

void main() {
  group('SavedSchemeItemModel Unit Tests', () {
    test('SavedSchemeItemModel.fromJson deserializes backend response', () {
      final json = {
        'id': 'saved-1',
        'scheme_id': 'sch-central-csss-001',
        'scheme_title': 'Central Sector Scheme',
        'provider': 'Ministry of Education',
        'jurisdiction': 'Central',
        'status': 'AppliedOnOfficialPortal',
        'notes': 'Submitted application',
        'updated_at': '2026-08-10T12:00:00Z',
      };

      final item = SavedSchemeItemModel.fromJson(json);

      expect(item.id, equals('saved-1'));
      expect(item.schemeId, equals('sch-central-csss-001'));
      expect(item.status, equals('AppliedOnOfficialPortal'));
      expect(item.notes, equals('Submitted application'));
    });
  });
}
