import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/constants/app_enums.dart';

part 'app_notification.freezed.dart';

@Freezed(fromJson: false, toJson: false)
class AppNotification with _$AppNotification {
  const factory AppNotification({
    required String id,
    required String title,
    required String body,
    required NotificationType type,
    String? targetType,
    String? targetId,
    required DateTime createdAt,
    required bool isRead,
  }) = _AppNotification;

  factory AppNotification.fromJson(Map<String, dynamic> json,
          {required bool isRead}) =>
      AppNotification(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        type: NotificationType.fromString(json['type'] as String),
        targetType: json['target_type'] as String?,
        targetId: json['target_id'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        isRead: isRead,
      );
}
