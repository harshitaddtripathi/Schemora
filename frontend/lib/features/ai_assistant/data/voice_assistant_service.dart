import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VoiceAssistantService {
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _isSpeechInitialized = false;
  bool _isListening = false;
  bool _isSpeaking = false;

  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;

  VoiceAssistantService() {
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      _tts.setStartHandler(() {
        _isSpeaking = true;
      });
      _tts.setCompletionHandler(() {
        _isSpeaking = false;
      });
      _tts.setErrorHandler((msg) {
        _isSpeaking = false;
      });
    } catch (e) {
      debugPrint('TTS init error: $e');
    }
  }

  Future<bool> initSpeech() async {
    if (_isSpeechInitialized) return true;
    try {
      _isSpeechInitialized = await _speech.initialize(
        onError: (val) {
          debugPrint('Speech error: $val');
          _isListening = false;
        },
        onStatus: (val) {
          debugPrint('Speech status: $val');
          if (val == 'done' || val == 'notListening') {
            _isListening = false;
          }
        },
      );
      return _isSpeechInitialized;
    } catch (e) {
      debugPrint('Speech init failed: $e');
      return false;
    }
  }

  String _getLocaleId(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'hi_IN';
      case 'mr':
        return 'mr_IN';
      case 'en':
      default:
        return 'en_IN';
    }
  }

  Future<void> startListening({
    required String languageCode,
    required Function(String recognizedText, bool isFinal) onResult,
    required VoidCallback onDone,
  }) async {
    final available = await initSpeech();
    if (!available) {
      onResult('Speech recognition unavailable or microphone permission denied', true);
      return;
    }

    _isListening = true;
    final localeId = _getLocaleId(languageCode);

    try {
      await _speech.listen(
        onResult: (result) {
          onResult(result.recognizedWords, result.finalResult);
          if (result.finalResult) {
            _isListening = false;
            onDone();
          }
        },
        listenOptions: SpeechListenOptions(
          localeId: localeId,
          cancelOnError: true,
          listenMode: ListenMode.dictation,
        ),
      );
    } catch (e) {
      _isListening = false;
      debugPrint('Error starting listening: $e');
    }
  }

  Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    }
  }

  Future<void> speak(String text, {required String languageCode}) async {
    try {
      await stopSpeaking();
      final ttsLanguage = languageCode == 'hi'
          ? 'hi-IN'
          : languageCode == 'mr'
              ? 'mr-IN'
              : 'en-US';
      await _tts.setLanguage(ttsLanguage);
      await _tts.speak(text);
    } catch (e) {
      debugPrint('TTS error: $e');
    }
  }

  Future<void> stopSpeaking() async {
    try {
      await _tts.stop();
      _isSpeaking = false;
    } catch (e) {
      debugPrint('TTS stop error: $e');
    }
  }
}

final voiceAssistantServiceProvider = Provider<VoiceAssistantService>((ref) {
  return VoiceAssistantService();
});
