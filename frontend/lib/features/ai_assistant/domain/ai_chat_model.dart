class SourceCitationModel {
  final String sourceName;
  final String url;
  final String lastVerifiedAt;

  SourceCitationModel({
    required this.sourceName,
    required this.url,
    this.lastVerifiedAt = '2026-08-07',
  });

  factory SourceCitationModel.fromJson(Map<String, dynamic> json) {
    return SourceCitationModel(
      sourceName: json['source_name'] as String? ?? 'Official Source',
      url: json['url'] as String? ?? '',
      lastVerifiedAt: json['last_verified_at'] as String? ?? '2026-08-07',
    );
  }
}

class ChatMessageModel {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<SourceCitationModel> citations;
  /// Language code (e.g. 'en', 'hi', 'mr') in which this message was written/received.
  /// Used to select the correct TTS voice when reading aloud.
  final String? language;

  ChatMessageModel({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.citations = const [],
    this.language,
  });
}
