class UserDocumentModel {
  final String id;
  final String docType;
  final String fileName;
  final String? maskedIdentifier;
  final String verificationStatus;
  final String? verificationNotes;

  UserDocumentModel({
    required this.id,
    required this.docType,
    required this.fileName,
    this.maskedIdentifier,
    required this.verificationStatus,
    this.verificationNotes,
  });

  factory UserDocumentModel.fromJson(Map<String, dynamic> json) {
    return UserDocumentModel(
      id: json['id'] as String,
      docType: json['doc_type'] as String,
      fileName: json['file_name'] as String,
      maskedIdentifier: json['masked_identifier'] as String?,
      verificationStatus: json['verification_status'] as String,
      verificationNotes: json['verification_notes'] as String?,
    );
  }
}

class ChecklistItemModel {
  final String docType;
  final String title;
  final bool isMandatory;
  final String status;
  final String? maskedIdentifier;
  final String notes;

  ChecklistItemModel({
    required this.docType,
    required this.title,
    required this.isMandatory,
    required this.status,
    this.maskedIdentifier,
    required this.notes,
  });

  factory ChecklistItemModel.fromJson(Map<String, dynamic> json) {
    return ChecklistItemModel(
      docType: json['doc_type'] as String,
      title: json['title'] as String,
      isMandatory: json['is_mandatory'] as bool,
      status: json['status'] as String,
      maskedIdentifier: json['masked_identifier'] as String?,
      notes: json['notes'] as String,
    );
  }
}

class SchemeChecklistModel {
  final String schemeId;
  final String schemeTitle;
  final double readinessPercentage;
  final bool isReadyForApplication;
  final List<ChecklistItemModel> items;
  final List<String> applicationSteps;

  SchemeChecklistModel({
    required this.schemeId,
    required this.schemeTitle,
    required this.readinessPercentage,
    required this.isReadyForApplication,
    required this.items,
    required this.applicationSteps,
  });

  factory SchemeChecklistModel.fromJson(Map<String, dynamic> json) {
    return SchemeChecklistModel(
      schemeId: json['scheme_id'] as String,
      schemeTitle: json['scheme_title'] as String,
      readinessPercentage: (json['readiness_percentage'] as num).toDouble(),
      isReadyForApplication: json['is_ready_for_application'] as bool,
      items: (json['items'] as List<dynamic>)
          .map((item) => ChecklistItemModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      applicationSteps: (json['application_steps'] as List<dynamic>).cast<String>(),
    );
  }
}
