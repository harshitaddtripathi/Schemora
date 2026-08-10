import 'package:flutter_test/flutter_test.dart';
import 'package:schemora_frontend/features/schemes/domain/scheme_model.dart';

void main() {
  group('SchemeModel & RecommendationItemModel Unit Tests', () {
    test('SchemeModel.fromJson parses backend API response correctly', () {
      final json = {
        'id': 'sch-central-csss-001',
        'slug': 'central-sector-scheme-of-scholarship',
        'title': 'Central Sector Scheme of Scholarship',
        'short_description': 'Scholarship for college students',
        'provider': 'Ministry of Education',
        'jurisdiction': 'Central',
        'benefit_type': 'Financial',
        'benefit_summary': 'Financial support for higher education',
        'implementation_status': 'Implemented',
        'is_published': true,
        'rules': [
          {
            'id': 'r1',
            'rule_id': 'csss-r001',
            'field_name': 'class12_percentile',
            'operator': 'gte',
            'expected_value': '80',
            'rule_type': 'mandatory',
          }
        ],
        'sources': [
          {
            'id': 's1',
            'source_name': 'NSP Official Portal',
            'url': 'https://scholarships.gov.in',
            'source_type': 'OfficialPortal',
          }
        ],
      };

      final scheme = SchemeModel.fromJson(json);

      expect(scheme.id, equals('sch-central-csss-001'));
      expect(scheme.title, equals('Central Sector Scheme of Scholarship'));
      expect(scheme.rules.length, equals(1));
      expect(scheme.sources.length, equals(1));
      expect(scheme.rules[0].operator, equals('gte'));
    });

    test('RecommendationItemModel.fromJson parses recommendation item', () {
      final json = {
        'scheme_id': 'sch-central-csss-001',
        'scheme_title': 'Central Sector Scheme',
        'provider': 'Ministry of Education',
        'jurisdiction': 'Central',
        'benefit_summary': 'INR 12000 per year',
        'status': 'RuleMatched',
        'confidence_score': 1.0,
        'matched_rules_count': 3,
        'unresolved_rules_count': 0,
        'failed_rules_count': 0,
        'unresolved_fields': [],
      };

      final item = RecommendationItemModel.fromJson(json);

      expect(item.schemeId, equals('sch-central-csss-001'));
      expect(item.status, equals('RuleMatched'));
      expect(item.confidenceScore, equals(1.0));
      expect(item.unresolvedFields, isEmpty);
    });
  });
}
