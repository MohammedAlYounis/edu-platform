import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_client_provider.dart';
import '../../../shared/models/content.dart';

final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  return ContentRepository(ref.watch(supabaseClientProvider));
});

class ContentRepository {
  final SupabaseClient _client;
  const ContentRepository(this._client);

  /// محتوى مادة واحدة، مرتّب بـ order_index (بند 9 في التصميم)
  Future<List<Content>> fetchContentsForSubject(String subjectId) async {
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

  Future<Content> fetchContentById(String id) async {
    try {
      final row = await _client.from('contents').select().eq('id', id).single();
      return Content.fromJson(row);
    } catch (e, st) {
      throw mapExceptionToFailure(e, st);
    }
  }

  /// آخر الدروس المضافة عبر كل المواد — لقسم "آخر الدروس" في Home
  Future<List<Content>> fetchRecentLessons({int limit = 5}) async {
    try {
      final rows = await _client
          .from('contents')
          .select()
          .eq('type', 'lesson')
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(limit);
      return rows.map((r) => Content.fromJson(r)).toList();
    } catch (e, st) {
      throw mapExceptionToFailure(e, st);
    }
  }

  /// الاختبارات المتاحة حاليًا فقط (نُصفّي بالتاريخ في Dart بعد الجلب
  /// لأن الحالة "active" محسوبة وليست مخزّنة — بند 51)
  Future<List<Content>> fetchActiveExams({int limit = 20}) async {
    try {
      final rows = await _client
          .from('contents')
          .select()
          .eq('type', 'exam')
          .eq('is_active', true)
          .order('available_until');
      final all = rows.map((r) => Content.fromJson(r)).toList();
      return all.where((c) => c.canAcceptSubmission).take(limit).toList();
    } catch (e, st) {
      throw mapExceptionToFailure(e, st);
    }
  }

  /// اختبارات ستنتهي قريبًا (ترتيبها الطبيعي هو الأقرب انتهاءً أولًا)
  Future<List<Content>> fetchExamsEndingSoon({int limit = 3}) async {
    final active = await fetchActiveExams(limit: 50);
    return active.take(limit).toList();
  }
}
