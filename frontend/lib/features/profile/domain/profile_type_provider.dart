import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schemora_frontend/features/profile/domain/profile_type.dart';

/// Holds the profile type the user selected on the Profile Type Selection screen.
/// Persists in memory for the session so the profile form knows which fields to show.
final selectedProfileTypeProvider = StateProvider<ProfileType>((ref) {
  return ProfileType.student; // sensible default
});
