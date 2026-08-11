/// The seven citizen profile types Schemora supports.
/// Each type drives which fields appear in the profile form and how the
/// recommendation engine interprets the stored data.
enum ProfileType {
  student,
  farmer,
  jobSeeker,
  entrepreneur,
  womanFamily,
  seniorCitizen,
  generalCitizen;

  String get displayName {
    switch (this) {
      case ProfileType.student:
        return 'Student / Learner';
      case ProfileType.farmer:
        return 'Farmer';
      case ProfileType.jobSeeker:
        return 'Job Seeker / Worker';
      case ProfileType.entrepreneur:
        return 'Entrepreneur / Business Owner';
      case ProfileType.womanFamily:
        return 'Woman / Family Support';
      case ProfileType.seniorCitizen:
        return 'Senior Citizen';
      case ProfileType.generalCitizen:
        return 'General Citizen';
    }
  }

  String get subtitle {
    switch (this) {
      case ProfileType.student:
        return 'Scholarships, education loans & academic schemes';
      case ProfileType.farmer:
        return 'Kisan cards, crop insurance & agricultural subsidies';
      case ProfileType.jobSeeker:
        return 'Skill development, employment & livelihood schemes';
      case ProfileType.entrepreneur:
        return 'MSME loans, startup grants & business support';
      case ProfileType.womanFamily:
        return 'Women empowerment, maternity & family welfare';
      case ProfileType.seniorCitizen:
        return 'Pension, healthcare & elderly welfare schemes';
      case ProfileType.generalCitizen:
        return 'Housing, ration, utilities & other citizen schemes';
    }
  }

  /// Maps to backend `employment_status` field default for this profile type.
  String get defaultEmploymentStatus {
    switch (this) {
      case ProfileType.student:
        return 'Unemployed';
      case ProfileType.farmer:
        return 'SelfEmployed';
      case ProfileType.jobSeeker:
        return 'Unemployed';
      case ProfileType.entrepreneur:
        return 'SelfEmployed';
      case ProfileType.womanFamily:
        return 'Unemployed';
      case ProfileType.seniorCitizen:
        return 'Unemployed';
      case ProfileType.generalCitizen:
        return 'Unemployed';
    }
  }
}
