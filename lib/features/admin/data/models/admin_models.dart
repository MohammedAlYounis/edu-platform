import '../../../../core/constants/app_enums.dart';

/// صف مبسّط لعرض الطلاب في القائمة (بدون كل تفاصيل UserProfile)
class StudentListItem {
  final String id;
  final String fullName;
  final String? studentNumber;
  final String email;
  final bool isActive;

  const StudentListItem({
    required this.id,
    required this.fullName,
    required this.studentNumber,
    required this.email,
    required this.isActive,
  });

  factory StudentListItem.fromJson(Map<String, dynamic> json) => StudentListItem(
        id: json['id'] as String,
        fullName: json['full_name'] as String,
        studentNumber: json['student_number'] as String?,
        email: json['email'] as String,
        isActive: json['is_active'] as bool,
      );
}

/// نسخة موسّعة من AdminSubmissionRow لشاشة المراجعة التفصيلية —
/// تحتاج filePath وملاحظات/سبب إعادة الإرسال، وهي بيانات لا تُعرض في القوائم.
class SubmissionDetails {
  final String id;
  final String studentName;
  final String? studentNumber;
  final String examTitle;
  final String filePath;
  final SubmissionStatus status;
  final double? grade;
  final String? reviewNote;
  final bool canResubmit;
  final String? resubmissionReason;
  final DateTime submittedAt;

  const SubmissionDetails({
    required this.id,
    required this.studentName,
    required this.studentNumber,
    required this.examTitle,
    required this.filePath,
    required this.status,
    required this.grade,
    required this.reviewNote,
    required this.canResubmit,
    required this.resubmissionReason,
    required this.submittedAt,
  });
}
/// صف مدمج لعرض قائمة الحلول (submission + اسم الطالب + عنوان الاختبار)
/// — تجميع يدوي بدل الاعتماد على تسمية foreign keys في استعلام nested select،
/// أوضح وأقل عرضة للكسر عند أي تعديل بنية لاحق.
class AdminSubmissionRow {
  final String id;
  final String studentName;
  final String? studentNumber;
  final String examTitle;
  final String contentId;
  final String studentId;
  final SubmissionStatus status;
  final double? grade;
  final DateTime submittedAt;

  const AdminSubmissionRow({
    required this.id,
    required this.studentName,
    required this.studentNumber,
    required this.examTitle,
    required this.contentId,
    required this.studentId,
    required this.status,
    required this.grade,
    required this.submittedAt,
  });
}
