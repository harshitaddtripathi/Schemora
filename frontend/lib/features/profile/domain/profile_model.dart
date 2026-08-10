class ProfileModel {
  final String? id;
  final String? userId;
  final String fullName;
  final String dateOfBirth;
  final int age;
  final String gender;
  final String state;
  final String educationLevel;
  final String? courseName;
  final String? institutionName;
  final String institutionType;
  final String socialCategory;
  final double? annualFamilyIncome;
  final bool isFullTimeStudent;
  final String employmentStatus;
  final String citizenship;
  final double? class12Percentile;
  final double? attendancePercentage;

  ProfileModel({
    this.id,
    this.userId,
    required this.fullName,
    required this.dateOfBirth,
    this.age = 0,
    required this.gender,
    required this.state,
    required this.educationLevel,
    this.courseName,
    this.institutionName,
    this.institutionType = 'Regular',
    required this.socialCategory,
    this.annualFamilyIncome,
    this.isFullTimeStudent = true,
    this.employmentStatus = 'Unemployed',
    this.citizenship = 'Indian',
    this.class12Percentile,
    this.attendancePercentage,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String?,
      userId: json['user_id'] as String?,
      fullName: json['full_name'] as String? ?? '',
      dateOfBirth: json['date_of_birth'] as String? ?? '2005-01-01',
      age: json['age'] as int? ?? 0,
      gender: json['gender'] as String? ?? 'Male',
      state: json['state'] as String? ?? 'Maharashtra',
      educationLevel: json['education_level'] as String? ?? 'Undergraduate',
      courseName: json['course_name'] as String?,
      institutionName: json['institution_name'] as String?,
      institutionType: json['institution_type'] as String? ?? 'Regular',
      socialCategory: json['social_category'] as String? ?? 'General',
      annualFamilyIncome: (json['annual_family_income'] as num?)?.toDouble(),
      isFullTimeStudent: json['is_full_time_student'] as bool? ?? true,
      employmentStatus: json['employment_status'] as String? ?? 'Unemployed',
      citizenship: json['citizenship'] as String? ?? 'Indian',
      class12Percentile: (json['class12_percentile'] as num?)?.toDouble(),
      attendancePercentage: (json['attendance_percentage'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'date_of_birth': dateOfBirth,
      'gender': gender,
      'state': state,
      'education_level': educationLevel,
      'course_name': courseName,
      'institution_name': institutionName,
      'institution_type': institutionType,
      'social_category': socialCategory,
      'annual_family_income': annualFamilyIncome,
      'is_full_time_student': isFullTimeStudent,
      'employment_status': employmentStatus,
      'citizenship': citizenship,
      'class12_percentile': class12Percentile,
      'attendance_percentage': attendancePercentage,
    };
  }
}
