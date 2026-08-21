import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:schemora_frontend/core/theme/app_theme.dart';
import 'package:schemora_frontend/core/widgets/dashboard_button.dart';
import 'package:schemora_frontend/features/ai_assistant/data/ai_repository.dart';
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

  Future<void> _sendMessage() async {
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
        _messages.add(
          ChatMessageModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: 'Error connecting to AI service: $e',
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
            items: const [
              DropdownMenuItem(value: 'en', child: Text('English')),
              DropdownMenuItem(value: 'hi', child: Text('हिंदी')),
              DropdownMenuItem(value: 'mr', child: Text('मराठी')),
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
                          Text(
                            msg.text,
                            style: TextStyle(
                              color: msg.isUser ? Colors.white : AppTheme.primaryNavy,
                              fontSize: 15,
                            ),
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
                                    onTap: () async {
                                      var cleanUrl = c.url.trim();
                                      if (!cleanUrl.startsWith('http')) {
                                        cleanUrl = 'https://$cleanUrl';
                                      }
                                      final uri = Uri.parse(cleanUrl);
                                      try {
                                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                                      } catch (_) {}
                                    },
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
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Ask a question about guidelines...',
                        border: OutlineInputBorder(),
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
