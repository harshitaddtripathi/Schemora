import 'package:flutter_test/flutter_test.dart';
import 'package:schemora_frontend/features/ai_assistant/domain/ai_chat_model.dart';

void main() {
  group('AIChatModel Unit Tests', () {
    test('SourceCitationModel.fromJson parses backend citations', () {
      final json = {
        'source_name': 'MyScheme Portal',
        'url': 'https://myscheme.gov.in/schemes/csss',
        'last_verified_at': '2026-08-07',
      };

      final citation = SourceCitationModel.fromJson(json);

      expect(citation.sourceName, equals('MyScheme Portal'));
      expect(citation.url, equals('https://myscheme.gov.in/schemes/csss'));
      expect(citation.lastVerifiedAt, equals('2026-08-07'));
    });

    test('ChatMessageModel holds user and bot messages', () {
      final msg = ChatMessageModel(
        id: 'msg-1',
        text: 'Hello assistant',
        isUser: true,
        timestamp: DateTime.now(),
      );

      expect(msg.id, equals('msg-1'));
      expect(msg.isUser, isTrue);
      expect(msg.citations, isEmpty);
    });
  });
}
