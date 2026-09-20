import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/constants/app_enums.dart';



part 'user_profile.freezed.dart';

@Freezed(fromJson: false, toJson: false)
class UserProfile with _$UserProfile {
  const UserProfile._();

  const factory UserProfile({
    required String id,
    required String fullName,
    String? studentNumber,
    required String email,
    String? avatarUrl,
    required UserRole role,
    required bool isActive,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        fullName: json['full_name'] as String,
        studentNumber: json['student_number'] as String?,
        email: json['email'] as String,
        avatarUrl: json['avatar_url'] as String?,
        role: UserRole.fromString(json['role'] as String),
        isActive: json['is_active'] as bool,
      );

  bool get isAdmin => role == UserRole.admin;
  bool get isStudent => role == UserRole.student;
}
