import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schemora_frontend/features/ai_assistant/data/voice_assistant_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VoiceAssistantService Unit Tests', () {
    test('voiceAssistantServiceProvider provides VoiceAssistantService instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = container.read(voiceAssistantServiceProvider);
      expect(service, isA<VoiceAssistantService>());
      expect(service.isListening, isFalse);
      expect(service.isSpeaking, isFalse);
    });
  });
}
