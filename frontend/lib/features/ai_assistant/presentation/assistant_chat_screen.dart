import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:schemora_frontend/core/providers/app_language_provider.dart';
import 'package:schemora_frontend/core/theme/app_theme.dart';
import 'package:schemora_frontend/core/utils/url_launcher_helper.dart';
import 'package:schemora_frontend/core/widgets/dashboard_button.dart';
import 'package:schemora_frontend/features/ai_assistant/data/ai_repository.dart';
import 'package:schemora_frontend/features/ai_assistant/data/voice_assistant_service.dart';
import 'package:schemora_frontend/features/ai_assistant/domain/ai_chat_model.dart';

// ── Localized UI strings for all supported languages ──────────────────────────

class _L {
  // Welcome messages
  static String welcome(String lang, String? schemeTitle) {
    if (schemeTitle != null) {
      return switch (lang) {
        'hi' => 'नमस्ते! मैं $schemeTitle के लिए आपका AI सहायक हूँ। पात्रता या आवेदन प्रक्रिया के बारे में पूछें।',
        'mr' => 'नमस्कार! मी $schemeTitle साठी तुमचा AI सहाय्यक आहे। पात्रता किंवा अर्ज प्रक्रियेबद्दल विचारा।',
        'bn' => 'নমস্কার! আমি $schemeTitle-এর জন্য আপনার AI সহকারী। যোগ্যতা বা আবেদন প্রক্রিয়া সম্পর্কে জিজ্ঞাসা করুন।',
        'te' => 'నమస్కారం! నేను $schemeTitle కోసం మీ AI సహాయకుడిని. అర్హత లేదా దరఖాస్తు గురించి అడగండి।',
        'ta' => 'வணக்கம்! நான் $schemeTitle-க்கான உங்கள் AI உதவியாளர். தகுதி அல்லது விண்ணப்ப செயல்முறை பற்றி கேளுங்கள்.',
        'gu' => 'નમસ્તે! હું $schemeTitle માટે તમારો AI સહાયક છું। પાત્રતા અથવા અરજી પ્રક્રિયા વિશે પૂછો.',
        'kn' => 'ನಮಸ್ಕಾರ! ನಾನು $schemeTitle ಗಾಗಿ ನಿಮ್ಮ AI ಸಹಾಯಕ. ಅರ್ಹತೆ ಅಥವಾ ಅರ್ಜಿ ಪ್ರಕ್ರಿಯೆ ಕುರಿತು ಕೇಳಿ.',
        'ml' => 'നമസ്കാരം! ഞാൻ $schemeTitle-ന്റെ AI സഹായകനാണ്. അർഹത അല്ലെങ്കിൽ അപേക്ഷ പ്രക്രിയയെ കുറിച്ച് ചോദിക്കൂ.',
        'pa' => 'ਸਤ ਸ੍ਰੀ ਅਕਾਲ! ਮੈਂ $schemeTitle ਲਈ ਤੁਹਾਡਾ AI ਸਹਾਇਕ ਹਾਂ। ਯੋਗਤਾ ਜਾਂ ਅਰਜ਼ੀ ਪ੍ਰਕਿਰਿਆ ਬਾਰੇ ਪੁੱਛੋ।',
        _ => 'Hello! I am your AI assistant for $schemeTitle. Ask me about eligibility or application guidelines.',
      };
    }
    return switch (lang) {
      'hi' => 'नमस्ते! मैं स्केमोरा AI सहायक हूँ। केंद्र या राज्य सरकार की किसी भी योजना के बारे में पूछें!',
      'mr' => 'नमस्कार! मी स्केमोरा AI सहाय्यक आहे. केंद्र किंवा राज्य सरकारी योजनांबद्दल काहीही विचारा!',
      'bn' => 'নমস্কার! আমি স্কেমোরা AI সহকারী। কেন্দ্র বা রাজ্য সরকারের যেকোনো প্রকল্প সম্পর্কে জিজ্ঞাসা করুন!',
      'te' => 'నమస్కారం! నేను స్కీమోరా AI సహాయకుడిని. కేంద్ర లేదా రాష్ట్ర ప్రభుత్వ పథకాల గురించి అడగండి!',
      'ta' => 'வணக்கம்! நான் ஸ்கீமோரா AI உதவியாளர். மத்திய அல்லது மாநில அரசு திட்டங்கள் பற்றி கேளுங்கள்!',
      'gu' => 'નમસ્તે! હું સ્કીમોરા AI સહાયક છું. કેન્દ્ર અથવા રાજ્ય સરકારની કોઈ પણ યોજના વિશે પૂછો!',
      'kn' => 'ನಮಸ್ಕಾರ! ನಾನು ಸ್ಕೀಮೋರಾ AI ಸಹಾಯಕ. ಕೇಂದ್ರ ಅಥವಾ ರಾಜ್ಯ ಸರ್ಕಾರದ ಯಾವುದೇ ಯೋಜನೆ ಕುರಿತು ಕೇಳಿ!',
      'ml' => 'നമസ്കാരം! ഞാൻ സ്കീമോറ AI സഹായകനാണ്. കേന്ദ്ര അല്ലെങ്കിൽ സംസ്ഥാന സർക്കാർ പദ്ധതികളെ കുറിച്ച് ചോദിക്കൂ!',
      'pa' => 'ਸਤ ਸ੍ਰੀ ਅਕਾਲ! ਮੈਂ ਸਕੀਮੋਰਾ AI ਸਹਾਇਕ ਹਾਂ। ਕੇਂਦਰ ਜਾਂ ਰਾਜ ਸਰਕਾਰ ਦੀਆਂ ਯੋਜਨਾਵਾਂ ਬਾਰੇ ਕੁਝ ਵੀ ਪੁੱਛੋ!',
      _ => 'Hello! I am your Schemora AI Assistant. Ask me any question regarding central or state government schemes!',
    };
  }

  static String listeningTitle(String lang) => switch (lang) {
        'hi' => 'आपकी आवाज़ सुन रहे हैं...',
        'mr' => 'तुमचा आवाज ऐकत आहे...',
        'bn' => 'আপনার কথা শুনছি...',
        'te' => 'మీ మాటలు వింటున్నాం...',
        'ta' => 'உங்கள் குரலைக் கேட்கிறோம்...',
        'gu' => 'તમારો અવાજ સાંભળી રહ્યો છું...',
        'kn' => 'ನಿಮ್ಮ ಧ್ವನಿಯನ್ನು ಕೇಳುತ್ತಿದ್ದೇನೆ...',
        'ml' => 'നിങ്ങളുടെ ശബ്ദം ശ്രദ്ധിക്കുന്നു...',
        'pa' => 'ਤੁਹਾਡੀ ਆਵਾਜ਼ ਸੁਣ ਰਿਹਾ ਹਾਂ...',
        _ => 'Listening to your voice...',
      };

  static String listeningSubtitle(String lang) => switch (lang) {
        'hi' => 'स्पष्ट रूप से बोलें',
        'mr' => 'स्पष्टपणे बोला',
        'bn' => 'স্পষ্টভাবে বলুন',
        'te' => 'స్పష్టంగా మాట్లాడండి',
        'ta' => 'தெளிவாக பேசுங்கள்',
        'gu' => 'સ્પષ્ટ રીતે બોલો',
        'kn' => 'ಸ್ಪಷ್ಟವಾಗಿ ಮಾತನಾಡಿ',
        'ml' => 'വ്യക്തമായി സംസാരിക്കൂ',
        'pa' => 'ਸਾਫ਼ ਬੋਲੋ',
        _ => 'Speak your question clearly',
      };

  static String doneButton(String lang) => switch (lang) {
        'hi' => 'हो गया',
        'mr' => 'झाले',
        'bn' => 'হয়েছে',
        'te' => 'అయింది',
        'ta' => 'முடிந்தது',
        'gu' => 'થઈ ગયું',
        'kn' => 'ಆಯಿತು',
        'ml' => 'ആയി',
        'pa' => 'ਹੋ ਗਿਆ',
        _ => 'Done',
      };

  static String hintText(String lang, bool isListening) {
    if (isListening) return listeningTitle(lang);
    return switch (lang) {
      'hi' => 'प्रश्न लिखें या माइक दबाएं...',
      'mr' => 'प्रश्न लिहा किंवा मायक दाबा...',
      'bn' => 'প্রশ্ন লিখুন বা মাইক চাপুন...',
      'te' => 'ప్రశ్న రాయండి లేదా మైక్ నొక్కండి...',
      'ta' => 'கேள்வி எழுதுங்கள் அல்லது மைக் அழுத்துங்கள்...',
      'gu' => 'પ્રશ્ન લખો અથવા માઇક દબાવો...',
      'kn' => 'ಪ್ರಶ್ನೆ ಬರೆಯಿರಿ ಅಥವಾ ಮೈಕ್ ಒತ್ತಿ...',
      'ml' => 'ചോദ്യം ടൈപ്പ് ചെയ്യുക അല്ലെങ്കിൽ മൈക്ക് അമർത്തുക...',
      'pa' => 'ਸਵਾਲ ਲਿਖੋ ਜਾਂ ਮਾਈਕ ਦਬਾਓ...',
      _ => 'Ask a question or tap mic...',
    };
  }

  static String citationsHeader(String lang) => switch (lang) {
        'hi' => 'आधिकारिक स्रोत और उद्धरण:',
        'mr' => 'अधिकृत स्रोत आणि उद्धरणे:',
        'bn' => 'সরকারি উৎস ও উদ্ধৃতি:',
        'te' => 'అధికారిక మూలాలు మరియు ఉల్లేఖనాలు:',
        'ta' => 'அதிகாரப்பூர்வ ஆதாரங்கள்:',
        'gu' => 'સત્તાવાર સ્ત્રોત અને ઉદ્ધરણ:',
        'kn' => 'ಅಧಿಕೃತ ಮೂಲಗಳು ಮತ್ತು ಉಲ್ಲೇಖಗಳು:',
        'ml' => 'ഔദ്യോഗിക ഉറവിടങ്ങൾ:',
        'pa' => 'ਅਧਿਕਾਰਤ ਸਰੋਤ:',
        _ => 'Official Sources & Citations:',
      };

  static String micTooltip(String lang, bool isListening) {
    if (isListening) {
      return switch (lang) {
        'hi' => 'सुनना बंद करें',
        'mr' => 'ऐकणे थांबवा',
        'bn' => 'শোনা বন্ধ করুন',
        'te' => 'వినడం ఆపు',
        'ta' => 'கேட்பதை நிறுத்து',
        _ => 'Stop Listening',
      };
    }
    return switch (lang) {
      'hi' => 'वॉयस असिस्टेंट',
      'mr' => 'व्हॉइस असिस्टंट',
      'bn' => 'ভয়েস সহকারী',
      'te' => 'వాయిస్ అసిస్టెంట్',
      'ta' => 'குரல் உதவியாளர்',
      _ => 'Voice Assistant / Speak',
    };
  }

  static String appBarTitle(String lang, String? schemeTitle) {
    if (schemeTitle != null) {
      return switch (lang) {
        'hi' => 'AI सहायक',
        'mr' => 'AI सहाय्यक',
        'bn' => 'AI সহকারী',
        'te' => 'AI సహాయకుడు',
        'ta' => 'AI உதவியாளர்',
        _ => 'AI Assistant',
      };
    }
    return switch (lang) {
      'hi' => 'स्केमोरा AI सहायक',
      'mr' => 'स्केमोरा AI सहाय्यक',
      'bn' => 'স্কেমোরা AI সহকারী',
      'te' => 'స్కీమోరా AI సహాయకుడు',
      'ta' => 'ஸ்கீமோரா AI உதவியாளர்',
      _ => 'Schemora AI Assistant',
    };
  }
}

// ── Language auto-detection from typed script ─────────────────────────────────

String _detectLanguageFromText(String text) {
  if (text.isEmpty) return 'en';
  // Sample first ~50 chars for detection
  final sample = text.substring(0, text.length.clamp(0, 50));

  // Unicode block ranges
  final hasDevanagari = RegExp(r'[\u0900-\u097F]').hasMatch(sample);
  final hasBengali = RegExp(r'[\u0980-\u09FF]').hasMatch(sample);
  final hasTelugu = RegExp(r'[\u0C00-\u0C7F]').hasMatch(sample);
  final hasTamil = RegExp(r'[\u0B80-\u0BFF]').hasMatch(sample);
  final hasGujarati = RegExp(r'[\u0A80-\u0AFF]').hasMatch(sample);
  final hasKannada = RegExp(r'[\u0C80-\u0CFF]').hasMatch(sample);
  final hasMalayalam = RegExp(r'[\u0D00-\u0D7F]').hasMatch(sample);
  final hasGurmukhi = RegExp(r'[\u0A00-\u0A7F]').hasMatch(sample);
  final hasOdia = RegExp(r'[\u0B00-\u0B7F]').hasMatch(sample);
  final hasArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(sample);

  if (hasBengali) return 'bn';
  if (hasTelugu) return 'te';
  if (hasTamil) return 'ta';
  if (hasGujarati) return 'gu';
  if (hasKannada) return 'kn';
  if (hasMalayalam) return 'ml';
  if (hasGurmukhi) return 'pa';
  if (hasOdia) return 'or';
  if (hasArabic) return 'ur';
  if (hasDevanagari) {
    // Distinguish Hindi vs Marathi vs Nepali — basic heuristic via common words
    if (RegExp(r'\b(आहे|नाही|कसे|मला|तुम्ही|आम्ही)\b').hasMatch(sample)) return 'mr';
    if (RegExp(r'\b(छ|गर्नु|हुन्छ|नेपाल)\b').hasMatch(sample)) return 'ne';
    return 'hi';
  }
  return 'en'; // Default English
}

// ── Main screen ───────────────────────────────────────────────────────────────

class AssistantChatScreen extends ConsumerStatefulWidget {
  final String? schemeId;
  final String? schemeTitle;

  const AssistantChatScreen({super.key, this.schemeId, this.schemeTitle});

  @override
  ConsumerState<AssistantChatScreen> createState() => _AssistantChatScreenState();
}

class _AssistantChatScreenState extends ConsumerState<AssistantChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessageModel> _messages = [];
  bool _isLoading = false;
  bool _isListening = false;
  String? _currentlySpeakingId;
  String _selectedLang = 'en';

  @override
  void initState() {
    super.initState();
    // Initialize language from the global app language setting
    final appLang = ref.read(appLanguageProvider);
    _selectedLang = appLang.code;
    _messages.add(
      ChatMessageModel(
        id: 'msg-welcome',
        text: _L.welcome(_selectedLang, widget.schemeTitle),
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
    // Listen for typed text to auto-detect language
    _controller.addListener(_onTextChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Keep _selectedLang in sync with the global app language
    final appLang = ref.read(appLanguageProvider);
    if (appLang.code != _selectedLang && !_isListening) {
      setState(() => _selectedLang = appLang.code);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _controller.text.trim();
    if (text.length < 3) return; // Need at least a few chars
    final detected = _detectLanguageFromText(text);
    if (detected != _selectedLang && detected != 'en') {
      // Auto-switch language only when we detect a non-Latin script
      setState(() => _selectedLang = detected);
    }
  }

  void _onLanguageChanged(String lang) {
    setState(() => _selectedLang = lang);
    // Stop any ongoing speech/listening when switching languages
    final voice = ref.read(voiceAssistantServiceProvider);
    voice.stopSpeaking();
    if (_isListening) {
      voice.stopListening();
      _isListening = false;
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _toggleVoiceListening() async {
    final voiceService = ref.read(voiceAssistantServiceProvider);
    if (_isListening) {
      await voiceService.stopListening();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);

      await voiceService.startListening(
        languageCode: _selectedLang, // STT uses the active language
        onResult: (text, isFinal) {
          if (mounted) {
            setState(() {
              _controller.text = text;
              _controller.selection = TextSelection.fromPosition(
                TextPosition(offset: _controller.text.length),
              );
            });
            // Auto-detect language from spoken text when recognized
            if (isFinal && text.isNotEmpty) {
              final detected = _detectLanguageFromText(text);
              if (detected != _selectedLang) {
                setState(() => _selectedLang = detected);
              }
            }
          }
        },
        onDone: () {
          if (mounted) setState(() => _isListening = false);
        },
      );
    }
  }

  Future<void> _toggleSpeakMessage(ChatMessageModel msg) async {
    final voiceService = ref.read(voiceAssistantServiceProvider);
    if (_currentlySpeakingId == msg.id) {
      await voiceService.stopSpeaking();
      setState(() => _currentlySpeakingId = null);
    } else {
      setState(() => _currentlySpeakingId = msg.id);
      // TTS uses the language that was active when the message was received
      await voiceService.speak(msg.text, languageCode: msg.language ?? _selectedLang);
      if (mounted) setState(() => _currentlySpeakingId = null);
    }
  }

  Future<void> _sendMessage() async {
    if (_isListening) await _toggleVoiceListening();

    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    // Final language detection before sending
    final detectedLang = _detectLanguageFromText(text);
    if (detectedLang != 'en' && detectedLang != _selectedLang) {
      setState(() => _selectedLang = detectedLang);
    }
    final langToUse = _selectedLang;

    final userMsg = ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
      language: langToUse,
    );

    setState(() {
      _messages.add(userMsg);
      _isLoading = true;
      _controller.clear();
    });
    _scrollToBottom();

    try {
      final repo = ref.read(aiRepositoryProvider);
      final respData = await repo.askAssistant(
        text,
        schemeId: widget.schemeId,
        language: langToUse, // Always send the active language
      );

      final citationsData = (respData['citations'] as List<dynamic>?)
              ?.map((c) => SourceCitationModel.fromJson(c as Map<String, dynamic>))
              .where((c) => c.url.isNotEmpty) // Filter out citations with empty URLs
              .toList() ??
          [];

      final botMsg = ChatMessageModel(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        text: respData['answer'] as String,
        isUser: false,
        timestamp: DateTime.now(),
        citations: citationsData,
        language: langToUse, // Store the language so TTS knows which voice to use
      );

      if (mounted) {
        setState(() => _messages.add(botMsg));
        _scrollToBottom();
        // Auto-speak bot response if user asked via voice
        if (_isListening == false && botMsg.text.length < 500) {
          // Don't auto-speak very long responses to avoid poor UX
        }
      }
    } catch (e) {
      if (mounted) {
        final errText = e.toString().contains('connection timeout') || e.toString().contains('receive timeout')
            ? 'Connection timed out. Please check server status and try again.'
            : 'Error connecting to AI service: $e';
        setState(() {
          _messages.add(ChatMessageModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: errText,
            isUser: false,
            timestamp: DateTime.now(),
            language: 'en',
          ));
        });
        _scrollToBottom();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = _selectedLang;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Go Back',
          onPressed: () => context.canPop() ? context.pop() : context.go('/dashboard'),
        ),
        title: Text(_L.appBarTitle(lang, widget.schemeTitle)),
        actions: [
          const DashboardButton(),
          _buildLanguageDropdown(),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Active language indicator chip
            if (lang != 'en')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                color: AppTheme.primaryBlue.withAlpha(18),
                child: Row(
                  children: [
                    Icon(Icons.translate_rounded, size: 14, color: AppTheme.primaryBlue),
                    const SizedBox(width: 6),
                    Text(
                      _languageLabel(lang),
                      style: TextStyle(
                        color: AppTheme.primaryBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '— Voice & AI response in this language',
                      style: TextStyle(color: AppTheme.primaryBlue.withAlpha(180), fontSize: 11),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
              ),
            ),
            if (_isListening) _buildListeningIndicator(lang),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: CircularProgressIndicator(),
              ),
            _buildInputBar(lang),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageModel msg) {
    final isSpeaking = _currentlySpeakingId == msg.id;
    final msgLang = msg.language ?? _selectedLang;

    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        decoration: BoxDecoration(
          color: msg.isUser ? AppTheme.primaryBlue : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(msg.isUser ? 20 : 4),
            bottomRight: Radius.circular(msg.isUser ? 4 : 20),
          ),
          border: msg.isUser
              ? null
              : Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: msg.isUser ? AppTheme.primaryBlue.withAlpha(50) : Colors.black.withAlpha(8),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    msg.text,
                    style: TextStyle(
                      color: msg.isUser ? Colors.white : AppTheme.primaryNavy,
                      fontSize: 15,
                      height: 1.45,
                    ),
                  ),
                ),
                // TTS speak button on bot messages
                if (!msg.isUser) ...[
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => _toggleSpeakMessage(msg),
                    borderRadius: BorderRadius.circular(20),
                    child: Tooltip(
                      message: isSpeaking
                          ? (msgLang == 'hi' ? 'बोलना बंद करें' : 'Stop speaking')
                          : AppTranslations.tr('listen_label', msgLang),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: isSpeaking ? AppTheme.primaryBlue.withAlpha(38) : Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isSpeaking ? Icons.volume_up_rounded : Icons.volume_mute_rounded,
                          size: 19,
                          color: isSpeaking ? AppTheme.primaryBlue : Colors.grey.shade500,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            // Citations
            if (msg.citations.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Divider(height: 1, thickness: 1),
              const SizedBox(height: 8),
              Text(
                _L.citationsHeader(msgLang),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(height: 4),
              ...msg.citations.map(
                (c) => Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: InkWell(
                    onTap: () => UrlLauncherHelper.openUrl(context, c.url),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.open_in_new_rounded, size: 12, color: AppTheme.primaryBlue),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.sourceName,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                              Text(
                                c.url,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.primaryBlue,
                                  decoration: TextDecoration.underline,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildListeningIndicator(String lang) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppTheme.primaryBlue.withAlpha(20),
          AppTheme.primaryBlue.withAlpha(35),
        ]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryBlue.withAlpha(60)),
        boxShadow: [
          BoxShadow(color: AppTheme.primaryBlue.withAlpha(15), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: AppTheme.primaryBlue, shape: BoxShape.circle),
            child: const Icon(Icons.graphic_eq_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _L.listeningTitle(lang),
                  style: const TextStyle(color: AppTheme.primaryNavy, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  _L.listeningSubtitle(lang),
                  style: TextStyle(color: AppTheme.primaryBlue, fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _toggleVoiceListening,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: Text(_L.doneButton(lang), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(String lang) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: Row(
        children: [
          Tooltip(
            message: _L.micTooltip(lang, _isListening),
            child: Container(
              decoration: BoxDecoration(
                color: _isListening ? AppTheme.primaryBlue.withAlpha(25) : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _toggleVoiceListening,
                icon: Icon(
                  _isListening ? Icons.graphic_eq_rounded : Icons.mic_none_rounded,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.send,
              decoration: InputDecoration(
                hintText: _L.hintText(lang, _isListening),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: _sendMessage,
            icon: const Icon(Icons.send_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageDropdown() {
    return DropdownButton<String>(
      value: _selectedLang,
      underline: const SizedBox(),
      icon: const Icon(Icons.language_rounded),
      items: const [
        DropdownMenuItem(value: 'en', child: Text('English')),
        DropdownMenuItem(value: 'hi', child: Text('हिंदी')),
        DropdownMenuItem(value: 'mr', child: Text('मराठी')),
        DropdownMenuItem(value: 'bn', child: Text('বাংলা')),
        DropdownMenuItem(value: 'te', child: Text('తెలుగు')),
        DropdownMenuItem(value: 'ta', child: Text('தமிழ்')),
        DropdownMenuItem(value: 'gu', child: Text('ગુજરાતી')),
        DropdownMenuItem(value: 'kn', child: Text('ಕನ್ನಡ')),
        DropdownMenuItem(value: 'ml', child: Text('മലയാളം')),
        DropdownMenuItem(value: 'pa', child: Text('ਪੰਜਾਬੀ')),
        DropdownMenuItem(value: 'or', child: Text('ଓଡ଼ିଆ')),
        DropdownMenuItem(value: 'as', child: Text('অসমীয়া')),
        DropdownMenuItem(value: 'ur', child: Text('اردو')),
        DropdownMenuItem(value: 'sa', child: Text('संस्कृत')),
        DropdownMenuItem(value: 'ne', child: Text('नेपाली')),
        DropdownMenuItem(value: 'sd', child: Text('سنڌي')),
        DropdownMenuItem(value: 'kok', child: Text('कोंकणी')),
        DropdownMenuItem(value: 'mai', child: Text('मैथिली')),
        DropdownMenuItem(value: 'doi', child: Text('डोगरी')),
      ],
      onChanged: (val) => _onLanguageChanged(val!),
    );
  }

  String _languageLabel(String code) => switch (code) {
        'hi' => 'हिंदी',
        'mr' => 'मराठी',
        'bn' => 'বাংলা',
        'te' => 'తెలుగు',
        'ta' => 'தமிழ்',
        'gu' => 'ગુજરાતી',
        'kn' => 'ಕನ್ನಡ',
        'ml' => 'മലയാളം',
        'pa' => 'ਪੰਜਾਬੀ',
        'or' => 'ଓଡ଼ିଆ',
        'as' => 'অসমীয়া',
        'ur' => 'اردو',
        'ne' => 'नेपाली',
        _ => code.toUpperCase(),
      };
}
