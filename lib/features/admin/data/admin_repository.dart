import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_enums.dart';
import '../../../core/network/supabase_client_provider.dart';
import '../../../shared/models/content.dart';
import '../../../shared/utils/storage_file_name.dart';
import '../../subjects/data/models/subject.dart';
import 'models/admin_models.dart';
import 'models/dashboard_stats.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.watch(supabaseClientProvider));
});

/// كل عمليات لوحة الإدارة تمر من هنا. RLS تفرض `is_admin()` على كل جدول
/// أصلًا، لذا أي استدعاء من مستخدم غير admin سيفشل من الـ backend حتى لو
/// انكسرت الواجهة — بند 42: "لا تعتمد على إخفاء أزرار Flutter كوسيلة أمان".
class AdminRepository {
  final SupabaseClient _client;
  const AdminRepository(this._client);

  String get _currentAdminId => _client.auth.currentUser!.id;

  // ---------------------------------------------------------------
  // Dashboard
  // ---------------------------------------------------------------
  Future<DashboardStats> fetchDashboardStats() async {
    try {
      final results = await Future.wait([
        _client
            .from('profiles')
            .select('id')
            .eq('role', 'student')
            .count(CountOption.exact),
        _client.from('subjects').select('id').count(CountOption.exact),
        _client
            .from('contents')
            .select('id')
            .eq('type', 'lesson')
            .count(CountOption.exact),
        _client
            .from('contents')
            .select('id')
            .eq('type', 'exam')
            .count(CountOption.exact),
        _client
            .from('submissions')
            .select('id')
            .eq('status', 'pending')
            .count(CountOption.exact),
        _client
            .from('submissions')
            .select('id')
            .eq('status', 'reviewed')
            .count(CountOption.exact),
      ]);

      return DashboardStats(
        totalStudents: results[0].count,
        totalSubjects: results[1].count,
        totalLessons: results[2].count,
        totalExams: results[3].count,
        pendingSubmissions: results[4].count,
        reviewedSubmissions: results[5].count,
      );
    } catch (e, st) {
      throw mapExceptionToFailure(e, st);
    }
  }

  Future<List<StudentListItem>> fetchRecentStudents({int limit = 5}) async {
    try {
      final rows = await _client
          .from('profiles')
          .select()
          .eq('role', 'student')
          .order('created_at', ascending: false)
          .limit(limit);
      return rows.map((r) => StudentListItem.fromJson(r)).toList();
    } catch (e, st) {
      throw mapExceptionToFailure(e, st);
    }
  }

  Future<List<AdminSubmissionRow>> fetchRecentSubmissions({int limit = 5}) {
    return fetchSubmissions(limit: limit);
  }

  // ---------------------------------------------------------------
  // Students
  // ---------------------------------------------------------------

  /// بحث جزئي واحد يغطي full_name و student_number معًا — بند 24/52:
  /// server-side، وليس تحميل كل الطلاب ثم الفلترة محليًا.
  Future<List<StudentListItem>> searchStudents(String query) async {
    try {
      final trimmed = query.trim();
      var builder = _client.from('profiles').select().eq('role', 'student');

      if (trimmed.isNotEmpty) {
        builder = builder
            .or('full_name.ilike.%$trimmed%,student_number.ilike.%$trimmed%');
      }

      final rows = await builder.order('full_name').limit(50);
      return rows.map((r) => StudentListItem.fromJson(r)).toList();
    } catch (e, st) {
      throw mapExceptionToFailure(e, st);
    }
  }

  Future<StudentListItem> fetchStudentDetails(String studentId) async {
    try {
      final row =
          await _client.from('profiles').select().eq('id', studentId).single();
      return StudentListItem.fromJson(row);
    } catch (e, st) {
      throw mapExceptionToFailure(e, st);
    }
  }

  Future<List<AdminSubmissionRow>> fetchStudentSubmissions(String studentId) {
    return fetchSubmissions(studentId: studentId);
  }

  Future<void> setStudentActive(String studentId, bool isActive) async {
    try {
      await _client
          .from('profiles')
          .update({'is_active': isActive}).eq('id', studentId);
    } catch (e, st) {
      throw mapExceptionToFailure(e, st);
    }
  }

  // ---------------------------------------------------------------
  // Subjects (Admin يرى الكل، بما فيها غير النشطة)
  // ---------------------------------------------------------------
  Future<List<Subject>> fetchAllSubjects() async {
    try {
      final rows = await _client.from('subjects').select().order('order_index');
      return rows.map((r) => Subject.fromJson(r)).toList();
    } catch (e, st) {
      throw mapExceptionToFailure(e, st);
    }
  }

  Future<void> createSubject({
    required String title,
    String? description,
    required int orderIndex,
  }) async {
    try {
      await _client.from('subjects').insert({
        'title': title,
        'description': description,
        'order_index': orderIndex,
      });
    } catch (e, st) {
      throw mapExceptionToFailure(e, st);
    }
  }

  Future<void> updateSubject({
    required String id,
    required String title,
    String? description,
  }) async {
    try {
      await _client
          .from('subjects')
          .update({'title': title, 'description': description}).eq('id', id);
    } catch (e, st) {
      throw mapExceptionToFailure(e, st);
    }
  }

  /// Soft delete — بند 26: "يفضل استخدام Soft Delete بدل حذف البيانات مباشرة"
  Future<void> setSubjectActive(String id, bool isActive) async {
    try {
      await _client
          .from('subjects')
          .update({'is_active': isActive}).eq('id', id);
    } catch (e, st) {
      throw mapExceptionToFailure(e, st);
    }
  }

  Future<void> syncSubjectOrder(List<Subject> ordered) async {
    try {
      for (var i = 0; i < ordered.length; i++) {
        await _client
            .from('subjects')
            .update({'order_index': i}).eq('id', ordered[i].id);
      }
    } catch (e, st) {
      throw mapExceptionToFailure(e, st);
    }
  }

  // ---------------------------------------------------------------
  // Content (Lessons / Exams)
  // ---------------------------------------------------------------
  Future<List<Content>> fetchAllContentsForSubject(String subjectId) async {
    try {
      final rows = await _client
          .from('contents')
          .select()
          .eq('subject_id', subjectId)
          .order('order_index');
      return rows.map((r) => Content.fromJson(r)).toList();
    } catch (e, st) {
      throw mapExceptionToFailure(e, st);
    }
  }

  /// يرفع ملف PDF إلى bucket المناسب (lessons/exams) وينشئ صف content.
  Future<void> createContent({
    required String subjectId,
    required String title,
    String? description,
    required ContentType type,
    required Uint8List fileBytes,
    required String fileName,
    required int orderIndex,
    DateTime? availableFrom,
    DateTime? availableUntil,
  }) async {
    final bucket = type == ContentType.lesson ? 'lessons' : 'exams';
    final storagePath = '$subjectId/${createStorageFileName(fileName)}';

    try {
      await _client.storage.from(bucket).uploadBinary(
            storagePath,
            fileBytes,
            fileOptions: const FileOptions(
              contentType: 'application/pdf',
              upsert: false,
            ),
          );
    } catch (e, st) {
      throw mapExceptionToFailure(e, st);
    }

    try {
      await _client
          .from('contents')
          .insert({
            'subject_id': subjectId,
            'title': title,
            'description': description,
            'type': type == ContentType.lesson ? 'lesson' : 'exam',
            'file_path': storagePath,
            'file_name': fileName,
            'file_size': fileBytes.length,
            'mime_type': 'application/pdf',
            'order_index': orderIndex,
            'available_from': availableFrom?.toIso8601String(),
            'available_until': availableUntil?.toIso8601String(),
          })
          .select()
          .single();

      // إشعار تلقائي لكل الطلاب — بند 19: "New Lesson... عند إضافة درس جديد"
      // و"New Exam... عند إضافة اختبار جديد". فشل الإشعار لا يُفشل إنشاء المحتوى.
      try {
        await createNotification(
          title: type == ContentType.lesson
              ? 'درس جديد: $title'
              : 'اختبار جديد: $title',
          body: description ?? '',
          type: type == ContentType.lesson
              ? NotificationType.lesson
              : NotificationType.exam,
          targetType: 'subject',
          targetId: subjectId,
        );
      } catch (_) {}
    } catch (e, st) {
      // نفس مبدأ rollback المستخدم في SubmissionsRepository — لا نترك ملفًا يتيمًا
      try {
        await _client.storage.from(bucket).remove([storagePath]);
      } catch (_) {
        // Preserve the original database error; cleanup is best effort.
      }
      throw mapExceptionToFailure(e, st);
    }
  }

  Future<void> updateContent({
    required String id,
    required String title,
    String? description,
    DateTime? availableFrom,
    DateTime? availableUntil,
  }) async {
    try {
      await _client.from('contents').update({
        'title': title,
        'description': description,
        'available_from': availableFrom?.toIso8601String(),
        'available_until': availableUntil?.toIso8601String(),
      }).eq('id', id);
    } catch (e, st) {
      throw mapExceptionToFailure(e, st);
    }
  }

  Future<void> setContentActive(String id, bool isActive) async {
    try {
      await _client
          .from('contents')
          .update({'is_active': isActive}).eq('id', id);
    } catch (e, st) {
      throw mapExceptionToFailure(e, st);
    }
  }

  Future<void> deleteContent(String id) => setContentActive(id, false);

  Future<void> syncContentOrder(String subjectId, List<Content> ordered) async {
    try {
      for (var i = 0; i < ordered.length; i++) {
        await _client
            .from('contents')
            .update({'order_index': i}).eq('id', ordered[i].id);
      }
    } catch (e, st) {
      throw mapExceptionToFailure(e, st);
    }
  }

  // ---------------------------------------------------------------
  // Submissions
  // ---------------------------------------------------------------

  /// يدعم فلترة بالحالة، بحث باسم/رقم الطالب أو عنوان الاختبار، وتحديد
  /// طالب معيّن — كلها اختيارية ويمكن دمجها.
  Future<List<AdminSubmissionRow>> fetchSubmissions({
    SubmissionStatus? status,
    String? searchQuery,
    String? studentId,
    int limit = 100,
  }) async {
    try {
      var builder =
          _client.from('submissions').select().eq('is_superseded', false);

      if (status != null) builder = builder.eq('status', status.toDbValue());
      if (studentId != null) builder = builder.eq('student_id', studentId);

      final rows =
          await builder.order('submitted_at', ascending: false).limit(limit);

      if (rows.isEmpty) return [];

      final studentIds =
          rows.map((r) => r['student_id'] as String).toSet().toList();
      final contentIds =
          rows.map((r) => r['content_id'] as String).toSet().toList();

      final studentsRows =
          await _client.from('profiles').select().inFilter('id', studentIds);
      final contentsRows =
          await _client.from('contents').select().inFilter('id', contentIds);

      final studentsById = {for (final s in studentsRows) s['id'] as String: s};
      final contentsById = {for (final c in contentsRows) c['id'] as String: c};

      var result = rows.map((r) {
        final student = studentsById[r['student_id']];
        final content = contentsById[r['content_id']];
        return AdminSubmissionRow(
          id: r['id'] as String,
          studentName: student?['full_name'] as String? ?? '—',
          studentNumber: student?['student_number'] as String?,
          examTitle: content?['title'] as String? ?? '—',
          contentId: r['content_id'] as String,
          studentId: r['student_id'] as String,
          status: SubmissionStatus.fromString(r['status'] as String),
          grade: (r['grade'] as num?)?.toDouble(),
          submittedAt: DateTime.parse(r['submitted_at'] as String),
        );
      }).toList();

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim().toLowerCase();
        result = result
            .where((s) =>
                s.studentName.toLowerCase().contains(q) ||
                (s.studentNumber?.toLowerCase().contains(q) ?? false) ||
                s.examTitle.toLowerCase().contains(q))
            .toList();
      }

      return result;
    } catch (e, st) {
      throw mapExceptionToFailure(e, st);
    }
  }

  Future<Map<String, dynamic>> fetchSubmissionRaw(String submissionId) async {
    try {
      return await _client
          .from('submissions')
          .select()
          .eq('id', submissionId)
          .single();
    } catch (e, st) {
      throw mapExceptionToFailure(e, st);
    }
  }

  Future<SubmissionDetails> fetchSubmissionDetails(String submissionId) async {
    try {
      final row = await fetchSubmissionRaw(submissionId);
      final student = await _client
          .from('profiles')
          .select()
          .eq('id', row['student_id'] as String)
          .single();
      final content = await _client
          .from('contents')
          .select()
          .eq('id', row['content_id'] as String)
          .single();

      return SubmissionDetails(
        id: row['id'] as String,
        studentName: student['full_name'] as String,
        studentNumber: student['student_number'] as String?,
        examTitle: content['title'] as String,
        filePath: row['file_path'] as String,
        status: SubmissionStatus.fromString(row['status'] as String),
        grade: (row['grade'] as num?)?.toDouble(),
        reviewNote: row['review_note'] as String?,
        canResubmit: row['can_resubmit'] as bool,
        resubmissionReason: row['resubmission_reason'] as String?,
        submittedAt: DateTime.parse(row['submitted_at'] as String),
      );
    } catch (e, st) {
      throw mapExceptionToFailure(e, st);
    }
  }

  Future<void> startReview(String submissionId) async {
    try {
      await _client.from('submissions').update({
        'status': 'reviewing',
        'reviewer_id': _currentAdminId,
      }).eq('id', submissionId);
    } catch (e, st) {
      throw mapExceptionToFailure(e, st);
    }
  }

  Future<void> saveReview({
    required String submissionId,
    required double grade,
    String? note,
  }) async {
    try {
      final row = await fetchSubmissionRaw(submissionId);
      await _client.from('submissions').update({
        'status': 'reviewed',
        'grade': grade,
        'review_note': note,
        'reviewer_id': _currentAdminId,
        'reviewed_at': DateTime.now().toIso8601String(),
      }).eq('id', submissionId);

      // بند 19: "Submission Reviewed... عند تصحيح حل الطالب"
      try {
        await createNotification(
          title: 'تم تصحيح حلّك',
          body: 'علامتك: ${grade.toStringAsFixed(0)}/100',
          type: NotificationType.submission,
          targetType: 'student',
          targetId: row['student_id'] as String,
        );
      } catch (_) {}
    } catch (e, st) {
      throw mapExceptionToFailure(e, st);
    }
  }

  Future<void> requestResubmission({
    required String submissionId,
    required String reason,
  }) async {
    try {
      final row = await fetchSubmissionRaw(submissionId);
      await _client.from('submissions').update({
        'status': 'needs_resubmission',
        'can_resubmit': true,
        'resubmission_reason': reason,
        'reviewer_id': _currentAdminId,
      }).eq('id', submissionId);

      // بند 19: "Resubmission Required... عندما تطلب الإدارة إعادة إرسال الحل"
      try {
        await createNotification(
          title: 'طلبت الإدارة إعادة إرسال حلّك',
          body: reason,
          type: NotificationType.resubmission,
          targetType: 'student',
          targetId: row['student_id'] as String,
        );
      } catch (_) {}
    } catch (e, st) {
      throw mapExceptionToFailure(e, st);
    }
  }

  Future<String> getSubmissionSignedUrl(String storagePath) async {
    try {
      return await _client.storage
          .from('submissions')
          .createSignedUrl(storagePath, 300);
    } catch (e, st) {
      throw mapExceptionToFailure(e, st);
    }
  }

  // ---------------------------------------------------------------
  // Notifications
  // ---------------------------------------------------------------
  Future<void> createNotification({
    required String title,
    required String body,
    required NotificationType type,
    String? targetType, // 'all' | 'subject' | 'student'
    String? targetId,
  }) async {
    try {
      final inserted = await _client
          .from('notifications')
          .insert({
            'title': title,
            'body': body,
            'type': type.name,
            'target_type': targetType ?? 'all',
            'target_id': targetId,
          })
          .select()
          .single();

      // إرسال الـ push الفعلي عبر Edge Function — بند 33: "إرسال FCM Push
      // Notification". فشل الإرسال لا يُفشل إنشاء الإشعار نفسه (يبقى مخزَّنًا
      // ومرئيًا داخل التطبيق حتى لو تعطّل الـ push مؤقتًا).
      try {
        await _client.functions.invoke('send-notification', body: {
          'notification_id': inserted['id'],
          'title': title,
          'body': body,
          'type': type.name,
          'target_type': targetType ?? 'all',
          'target_id': targetId,
        });
      } catch (_) {
        // يُسجَّل لاحقًا عبر أداة monitoring حقيقية إن وُجدت؛ لا نُفشل العملية.
      }
    } catch (e, st) {
      throw mapExceptionToFailure(e, st);
    }
  }
}
