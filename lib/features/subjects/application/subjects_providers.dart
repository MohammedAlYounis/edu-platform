import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/content_repository.dart';
import '../data/models/subject.dart';
import '../data/repositories/subjects_repository.dart';
import '../../../shared/models/content.dart';

final subjectsListProvider = FutureProvider.autoDispose<List<Subject>>((ref) {
  return ref.watch(subjectsRepositoryProvider).fetchSubjects();
});

final subjectContentsProvider =
    FutureProvider.autoDispose.family<List<Content>, String>((ref, subjectId) {
  return ref.watch(contentRepositoryProvider).fetchContentsForSubject(subjectId);
});

final contentByIdProvider =
    FutureProvider.autoDispose.family<Content, String>((ref, contentId) {
  return ref.watch(contentRepositoryProvider).fetchContentById(contentId);
});

final recentLessonsProvider = FutureProvider.autoDispose<List<Content>>((ref) {
  return ref.watch(contentRepositoryProvider).fetchRecentLessons();
});

final activeExamsProvider = FutureProvider.autoDispose<List<Content>>((ref) {
  return ref.watch(contentRepositoryProvider).fetchActiveExams();
});

final examsEndingSoonProvider = FutureProvider.autoDispose<List<Content>>((ref) {
  return ref.watch(contentRepositoryProvider).fetchExamsEndingSoon();
});
