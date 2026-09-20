/// دور المستخدم — يُخزَّن كنص في profiles.role
enum UserRole {
  student,
  admin;

  static UserRole fromString(String value) => switch (value) {
        'admin' => UserRole.admin,
        _ => UserRole.student,
      };
}

/// نوع المحتوى داخل مادة (Subject)
enum ContentType {
  lesson,
  exam;

  static ContentType fromString(String value) => switch (value) {
        'exam' => ContentType.exam,
        _ => ContentType.lesson,
      };
}

/// حالة الاختبار — محسوبة في الواجهة من available_from/available_until
/// وليست مخزّنة في قاعدة البيانات (راجع قسم Data Rules في التصميم المعتمد)
enum ExamAvailability { upcoming, active, expired }

/// حالة الحل — تُخزَّن كنص في submissions.status
enum SubmissionStatus {
  pending,
  reviewing,
  reviewed,
  needsResubmission;

  static SubmissionStatus fromString(String value) => switch (value) {
        'reviewing' => SubmissionStatus.reviewing,
        'reviewed' => SubmissionStatus.reviewed,
        'needs_resubmission' => SubmissionStatus.needsResubmission,
        _ => SubmissionStatus.pending,
      };

  String toDbValue() => switch (this) {
        SubmissionStatus.pending => 'pending',
        SubmissionStatus.reviewing => 'reviewing',
        SubmissionStatus.reviewed => 'reviewed',
        SubmissionStatus.needsResubmission => 'needs_resubmission',
      };
}

/// نوع الإشعار
enum NotificationType {
  general,
  lesson,
  exam,
  submission,
  resubmission;

  static NotificationType fromString(String value) => switch (value) {
        'lesson' => NotificationType.lesson,
        'exam' => NotificationType.exam,
        'submission' => NotificationType.submission,
        'resubmission' => NotificationType.resubmission,
        _ => NotificationType.general,
      };
}
