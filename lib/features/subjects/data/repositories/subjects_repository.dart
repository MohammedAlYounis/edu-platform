import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/network/supabase_client_provider.dart';
import '../models/subject.dart';

final subjectsRepositoryProvider = Provider<SubjectsRepository>((ref) {
  return SubjectsRepository(ref.watch(supabaseClientProvider));
});

class SubjectsRepository {
  final SupabaseClient _client;
  const SubjectsRepository(this._client);

  /// يجلب المواد النشطة (RLS تتكفل بإخفاء غير النشطة عن الطالب أصلًا)
  /// مع عدد الدروس والاختبارات لكل مادة — بند 8 في التصميم.
  Future<List<Subject>> fetchSubjects() async {
    try {
      final rows = await _client
          .from('subjects')
          .select()
          .order('order_index');

      final subjects = rows.map((r) => Subject.fromJson(r)).toList();

      // استعلام عدد المحتوى لكل مادة دفعة واحدة بدل N+1 query
      final counts = await _client
          .from('contents')
          .select('subject_id, type')
          .eq('is_active', true);

      final lessonCounts = <String, int>{};
      final examCounts = <String, int>{};
      for (final row in counts) {
        final subjectId = row['subject_id'] as String;
        if (row['type'] == 'lesson') {
          lessonCounts[subjectId] = (lessonCounts[subjectId] ?? 0) + 1;
        } else {
          examCounts[subjectId] = (examCounts[subjectId] ?? 0) + 1;
        }
      }

      return subjects
          .map((s) => s.copyWith(
                lessonsCount: lessonCounts[s.id] ?? 0,
                examsCount: examCounts[s.id] ?? 0,
              ))
          .toList();
    } catch (e, st) {
      throw mapExceptionToFailure(e, st);
    }
  }

  Future<Subject> fetchSubjectById(String id) async {
    try {
      final row = await _client.from('subjects').select().eq('id', id).single();
      return Subject.fromJson(row);
    } catch (e, st) {
      throw mapExceptionToFailure(e, st);
    }
  }
}
