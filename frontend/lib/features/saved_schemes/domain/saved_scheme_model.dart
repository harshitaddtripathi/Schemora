class SavedSchemeItemModel {
  final String id;
  final String schemeId;
  final String schemeTitle;
  final String provider;
  final String jurisdiction;
  final String status;
  final String? notes;
  final String updatedAt;

  SavedSchemeItemModel({
    required this.id,
    required this.schemeId,
    required this.schemeTitle,
    required this.provider,
    required this.jurisdiction,
    required this.status,
    this.notes,
    required this.updatedAt,
  });

  factory SavedSchemeItemModel.fromJson(Map<String, dynamic> json) {
    return SavedSchemeItemModel(
      id: json['id'] as String,
      schemeId: json['scheme_id'] as String,
      schemeTitle: json['scheme_title'] as String,
      provider: json['provider'] as String,
      jurisdiction: json['jurisdiction'] as String,
      status: json['status'] as String,
      notes: json['notes'] as String?,
      updatedAt: json['updated_at'] as String,
    );
  }
}
