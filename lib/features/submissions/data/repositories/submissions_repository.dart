import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/network/supabase_client_provider.dart';
import '../../../../shared/utils/storage_file_name.dart';
import '../models/submission.dart';

final submissionsRepositoryProvider = Provider<SubmissionsRepository>((ref) {
  return SubmissionsRepository(ref.watch(supabaseClientProvider));
});

class SubmissionsRepository {
  final SupabaseClient _client;
  const SubmissionsRepository(this._client);

  /// حل الطالب الحالي (الفعّال، أي غير superseded) لاختبار معيّن، أو null
  /// إن لم يُرسِل بعد. is_superseded تُدار بالكامل من الـ trigger في DB.
  Future<Submission?> fetchMySubmissionForContent(String contentId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final row = await _client
          .from('submissions')
          .select()
          .eq('content_id', contentId)
          .eq('student_id', userId)
          .eq('is_superseded', false)
          .maybeSingle();
      return row == null ? null : Submission.fromJson(row);
    } catch (e, st) {
      throw mapExceptionToFailure(e, st);
    }
  }

  /// آخر حل للطالب عبر كل الاختبارات — لقسم "آخر الحلول" في Home
  Future<List<Submission>> fetchMyRecentSubmissions({int limit = 5}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final rows = await _client
          .from('submissions')
          .select()
          .eq('student_id', userId)
          .eq('is_superseded', false)
          .order('submitted_at', ascending: false)
          .limit(limit);
      return rows.map((r) => Submission.fromJson(r)).toList();
    } catch (e, st) {
      throw mapExceptionToFailure(e, st);
    }
  }

  /// يرفع ملف الحل إلى Storage ثم ينشئ صف submission.
  /// قاعدة "حل واحد فقط" مفروضة في DB (trigger + unique index) —
  /// إن حاول الطالب الإرسال مرتين سيصل استثناء واضح من الـ backend.
  Future<void> submitSolution({
    required String contentId,
    required File file,
    required String fileName,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthFailure('sign_in_required');
    }

    final storagePath = 'submissions/$userId/$contentId/${createStorageFileName(fileName)}';

    try {
      await _client.storage.from('submissions').upload(storagePath, file);
    } catch (e, st) {
      throw mapExceptionToFailure(e, st);
    }

    try {
      await _client.from('submissions').insert({
        'content_id': contentId,
        'student_id': userId,
        'file_path': storagePath,
        'file_name': fileName,
        'file_size': await file.length(),
        'mime_type': 'application/pdf',
      });
    } catch (e, st) {
      // فشل إنشاء السجل بعد نجاح الرفع — لا نترك ملفًا يتيمًا في Storage
      // (بند 50: "لا تنشئ Submission ناقصًا... تعامل مع الملف المرفوع بطريقة آمنة")
      await _client.storage.from('submissions').remove([storagePath]);
      throw mapExceptionToFailure(e, st);
    }
  }

  /// رابط مؤقت آمن لعرض/تنزيل ملف الحل (bucket غير عام أصلًا)
  Future<String> getSignedUrl(String storagePath, {int expiresInSeconds = 300}) async {
    try {
      return await _client.storage
          .from('submissions')
          .createSignedUrl(storagePath, expiresInSeconds);
    } catch (e, st) {
      throw mapExceptionToFailure(e, st);
    }
  }
}
