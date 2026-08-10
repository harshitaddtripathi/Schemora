import 'package:flutter_test/flutter_test.dart';
import 'package:schemora_frontend/features/profile/domain/profile_model.dart';

void main() {
  group('ProfileModel Unit Tests', () {
    test('ProfileModel.fromJson deserializes valid backend data', () {
      final json = {
        'id': 'prof-999',
        'user_id': 'usr-888',
        'full_name': 'Sneha Rao',
        'date_of_birth': '2005-04-12',
        'age': 21,
        'gender': 'Female',
        'state': 'Karnataka',
        'education_level': 'Postgraduate',
        'course_name': 'M.Tech AI',
        'institution_name': 'IISc Bengaluru',
        'institution_type': 'Regular',
        'social_category': 'General',
        'annual_family_income': 350000.0,
        'is_full_time_student': true,
        'employment_status': 'Unemployed',
        'citizenship': 'Indian',
        'class12_percentile': 96.0,
        'attendance_percentage': 90.0,
      };

      final profile = ProfileModel.fromJson(json);

      expect(profile.id, equals('prof-999'));
      expect(profile.userId, equals('usr-888'));
      expect(profile.fullName, equals('Sneha Rao'));
      expect(profile.age, equals(21));
      expect(profile.gender, equals('Female'));
      expect(profile.annualFamilyIncome, equals(350000.0));
      expect(profile.class12Percentile, equals(96.0));
    });

    test('ProfileModel.toJson creates valid payload map for backend API', () {
      final profile = ProfileModel(
        fullName: 'Sneha Rao',
        dateOfBirth: '2005-04-12',
        gender: 'Female',
        state: 'Karnataka',
        educationLevel: 'Postgraduate',
        socialCategory: 'General',
        annualFamilyIncome: 350000.0,
      );

      final json = profile.toJson();

      expect(json['full_name'], equals('Sneha Rao'));
      expect(json['date_of_birth'], equals('2005-04-12'));
      expect(json['gender'], equals('Female'));
      expect(json['annual_family_income'], equals(350000.0));
      expect(json['citizenship'], equals('Indian'));
    });
  });
}
