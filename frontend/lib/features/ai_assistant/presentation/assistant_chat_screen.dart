import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schemora_frontend/core/theme/app_theme.dart';
import 'package:schemora_frontend/core/utils/url_launcher_helper.dart';
import 'package:schemora_frontend/core/widgets/dashboard_button.dart';
import 'package:schemora_frontend/features/ai_assistant/data/ai_repository.dart';
import 'package:schemora_frontend/features/ai_assistant/data/voice_assistant_service.dart';
import 'package:schemora_frontend/features/ai_assistant/domain/ai_chat_model.dart';

class AssistantChatScreen extends ConsumerStatefulWidget {
  final String? schemeId;
  final String? schemeTitle;

  const AssistantChatScreen({super.key, this.schemeId, this.schemeTitle});

  @override
  ConsumerState<AssistantChatScreen> createState() => _AssistantChatScreenState();
}

class _AssistantChatScreenState extends ConsumerState<AssistantChatScreen> {
  final _controller = TextEditingController();
  final List<ChatMessageModel> _messages = [];
  bool _isLoading = false;
  bool _isListening = false;
  String? _currentlySpeakingId;
  String _selectedLang = 'en';

  @override
  void initState() {
    super.initState();
    _messages.add(
      ChatMessageModel(
        id: 'msg-welcome',
        text: widget.schemeTitle != null
            ? 'Hello! I am your AI assistant for ${widget.schemeTitle}. How can I assist you with eligibility or application guidelines today?'
            : 'Hello! I am your Schemora AI Assistant. Ask me any question regarding central or state government schemes!',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggleVoiceListening() async {
    final voiceService = ref.read(voiceAssistantServiceProvider);
    if (_isListening) {
      await voiceService.stopListening();
      setState(() => _isListening = false);
    } else {
      setState(() {
        _isListening = true;
      });

      await voiceService.startListening(
        languageCode: _selectedLang,
        onResult: (text, isFinal) {
          if (mounted) {
            setState(() {
              _controller.text = text;
              _controller.selection = TextSelection.fromPosition(
                TextPosition(offset: _controller.text.length),
              );
            });
          }
        },
        onDone: () {
          if (mounted) {
            setState(() => _isListening = false);
          }
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
      await voiceService.speak(msg.text, languageCode: _selectedLang);
    }
  }

  Future<void> _sendMessage() async {
    if (_isListening) {
      await _toggleVoiceListening();
    }

    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    final userMsg = ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _isLoading = true;
      _controller.clear();
    });

    try {
      final repo = ref.read(aiRepositoryProvider);
      final respData = await repo.askAssistant(
        text,
        schemeId: widget.schemeId,
        language: _selectedLang,
      );

      final citationsData = (respData['citations'] as List<dynamic>?)
              ?.map((c) => SourceCitationModel.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [];

      final botMsg = ChatMessageModel(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        text: respData['answer'] as String,
        isUser: false,
        timestamp: DateTime.now(),
        citations: citationsData,
      );

      if (mounted) {
        setState(() => _messages.add(botMsg));
      }
    } catch (e) {
      if (mounted) {
        final errText = e.toString().contains('connection timeout') || e.toString().contains('receive timeout')
            ? 'Connection timed out while reaching AI Assistant. Please check server status and try again.'
            : 'Error connecting to AI service: $e';
        _messages.add(
          ChatMessageModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: errText,
            isUser: false,
            timestamp: DateTime.now(),
          ),
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
        title: Text(widget.schemeTitle != null ? 'AI Assistant' : 'Schemora AI Assistant'),
        actions: [
          const DashboardButton(),
          DropdownButton<String>(
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
            onChanged: (val) => setState(() => _selectedLang = val!),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isSpeaking = _currentlySpeakingId == msg.id;

                  return Align(
                    alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                      decoration: BoxDecoration(
                        color: msg.isUser ? AppTheme.primaryBlue : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(10),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
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
                                  ),
                                ),
                              ),
                              if (!msg.isUser) ...[
                                const SizedBox(width: 4),
                                InkWell(
                                  onTap: () => _toggleSpeakMessage(msg),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: isSpeaking ? AppTheme.primaryBlue.withAlpha(38) : Colors.transparent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isSpeaking ? Icons.volume_up_rounded : Icons.volume_mute_rounded,
                                      size: 20,
                                      color: isSpeaking ? AppTheme.primaryBlue : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ]
                            ],
                          ),
                          if (msg.citations.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            const Divider(height: 12),
                            const Text(
                              'Official Sources & Citations:',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                            ),
                            const SizedBox(height: 4),
                            ...msg.citations.map((c) => Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: InkWell(
                                    onTap: () => UrlLauncherHelper.openUrl(context, c.url),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.open_in_new_rounded, size: 12, color: AppTheme.primaryBlue),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            '${c.sourceName} (${c.url})',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppTheme.primaryBlue,
                                              decoration: TextDecoration.underline,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_isListening)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryBlue.withAlpha(20),
                      AppTheme.primaryBlue.withAlpha(35),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryBlue.withAlpha(60)),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withAlpha(15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.graphic_eq_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Listening to your voice...',
                            style: TextStyle(
                              color: AppTheme.primaryNavy,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Speak your question clearly',
                            style: TextStyle(
                              color: AppTheme.primaryBlue,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Done',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: Row(
                children: [
                  Tooltip(
                    message: _isListening ? 'Stop Listening' : 'Voice Assistant / Speak',
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
                      decoration: InputDecoration(
                        hintText: _isListening ? 'Listening to your voice...' : 'Ask a question or tap mic...',
                        border: const OutlineInputBorder(),
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
            ),
          ],
        ),
      ),
    );
  }
}

