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

  /// Returns a human-readable reason why a user with this profile type is not eligible
  /// for a scheme targeted at `targetType`.
  String getIneligibilityReason(ProfileType targetType) {
    if (this == targetType || targetType == ProfileType.generalCitizen) {
      return '';
    }

    switch (this) {
      case ProfileType.student:
        switch (targetType) {
          case ProfileType.farmer:
            return 'Your active profile is Student / Learner. Farmer schemes require an agricultural occupation or landholding.';
          case ProfileType.entrepreneur:
            return 'Your active profile is Student / Learner. Business & MSME schemes require an active enterprise or business registration.';
          case ProfileType.womanFamily:
            return 'Your active profile is Student / Learner. Women & Family schemes are restricted to female house heads or women beneficiaries.';
          case ProfileType.seniorCitizen:
            return 'Your active profile is Student / Learner (Age ~20). Senior citizen schemes require age 60+ or retired pension status.';
          case ProfileType.jobSeeker:
            return 'Your active profile is Student / Learner. Worker schemes require unorganized sector employment or full-time job-seeking status.';
          default:
            return 'Your active profile is Student / Learner, which does not match the eligibility requirements for this scheme.';
        }
      case ProfileType.farmer:
        switch (targetType) {
          case ProfileType.student:
            return 'Your active profile is Farmer. Student scholarships require regular educational institution enrolment.';
          case ProfileType.entrepreneur:
            return 'Your active profile is Farmer. Business loans require non-farm MSME enterprise registration.';
          case ProfileType.seniorCitizen:
            return 'Your active profile is Farmer. Senior citizen schemes require age 60+ or retired status.';
          default:
            return 'Your active profile is Farmer, which does not match the eligibility criteria for this scheme.';
        }
      case ProfileType.jobSeeker:
        switch (targetType) {
          case ProfileType.student:
            return 'Your active profile is Job Seeker. Student scholarships require full-time enrolment in an educational institution.';
          case ProfileType.farmer:
            return 'Your active profile is Job Seeker. Farmer schemes require agricultural landholding.';
          default:
            return 'Your active profile is Job Seeker / Worker, which does not match the eligibility criteria for this scheme.';
        }
      default:
        return 'Your active profile is $displayName, which does not match the eligibility criteria for a ${targetType.displayName} scheme.';
    }
  }
}
