import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/constants/app_enums.dart';

part 'content.freezed.dart';

@Freezed(fromJson: false, toJson: false)
class Content with _$Content {
  const Content._();

  const factory Content({
    required String id,
    required String subjectId,
    required String title,
    String? description,
    required ContentType type,
    required String filePath,
    required String fileName,
    int? fileSize,
    String? mimeType,
    required int orderIndex,
    DateTime? availableFrom,
    DateTime? availableUntil,
    required bool isActive,
  }) = _Content;

  factory Content.fromJson(Map<String, dynamic> json) => Content(
        id: json['id'] as String,
        subjectId: json['subject_id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        type: ContentType.fromString(json['type'] as String),
        filePath: json['file_path'] as String,
        fileName: json['file_name'] as String,
        fileSize: json['file_size'] as int?,
        mimeType: json['mime_type'] as String?,
        orderIndex: json['order_index'] as int,
        availableFrom: json['available_from'] == null
            ? null
            : DateTime.parse(json['available_from'] as String),
        availableUntil: json['available_until'] == null
            ? null
            : DateTime.parse(json['available_until'] as String),
        isActive: json['is_active'] as bool,
      );

  bool get isLesson => type == ContentType.lesson;
  bool get isExam => type == ContentType.exam;

  /// تُحسب دائمًا من الوقت الحالي مقابل available_from/until،
  /// ولا تُخزَّن كحالة ثابتة في قاعدة البيانات (بند 51 في التصميم:
  /// "يجب حساب حالة الاختبار بناءً على الوقت الحالي... وليس حفظ حالة قابلة للتناقض").
  ExamAvailability get availability {
    final now = DateTime.now();
    if (availableFrom != null && now.isBefore(availableFrom!)) {
      return ExamAvailability.upcoming;
    }
    if (availableUntil != null && now.isAfter(availableUntil!)) {
      return ExamAvailability.expired;
    }
    return ExamAvailability.active;
  }

  bool get canAcceptSubmission => isExam && availability == ExamAvailability.active;
}
