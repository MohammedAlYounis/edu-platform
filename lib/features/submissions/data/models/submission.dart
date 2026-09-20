import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/constants/app_enums.dart';

part 'submission.freezed.dart';

@Freezed(fromJson: false, toJson: false)
class Submission with _$Submission {
  const factory Submission({
    required String id,
    required String contentId,
    required String studentId,
    required String filePath,
    required String fileName,
    required SubmissionStatus status,
    double? grade,
    String? reviewNote,
    required DateTime submittedAt,
    DateTime? reviewedAt,
    required bool canResubmit,
    String? resubmissionReason,
  }) = _Submission;

  factory Submission.fromJson(Map<String, dynamic> json) => Submission(
        id: json['id'] as String,
        contentId: json['content_id'] as String,
        studentId: json['student_id'] as String,
        filePath: json['file_path'] as String,
        fileName: json['file_name'] as String,
        status: SubmissionStatus.fromString(json['status'] as String),
        grade: (json['grade'] as num?)?.toDouble(),
        reviewNote: json['review_note'] as String?,
        submittedAt: DateTime.parse(json['submitted_at'] as String),
        reviewedAt: json['reviewed_at'] == null
            ? null
            : DateTime.parse(json['reviewed_at'] as String),
        canResubmit: json['can_resubmit'] as bool,
        resubmissionReason: json['resubmission_reason'] as String?,
      );
}
