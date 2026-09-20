import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_enums.dart';
import '../../../shared/models/content.dart';
import '../../subjects/data/models/subject.dart';
import '../data/admin_repository.dart';
import '../data/models/admin_models.dart';
import '../data/models/dashboard_stats.dart';

final dashboardStatsProvider = FutureProvider.autoDispose<DashboardStats>((ref) {
  return ref.watch(adminRepositoryProvider).fetchDashboardStats();
});

final recentStudentsProvider = FutureProvider.autoDispose<List<StudentListItem>>((ref) {
  return ref.watch(adminRepositoryProvider).fetchRecentStudents();
});

final recentSubmissionsAdminProvider =
    FutureProvider.autoDispose<List<AdminSubmissionRow>>((ref) {
  return ref.watch(adminRepositoryProvider).fetchRecentSubmissions();
});

/// نص البحث الحالي لشاشة الطلاب (يُحدَّث من TextField مباشرة)
final studentSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

final studentsSearchResultProvider = FutureProvider.autoDispose<List<StudentListItem>>((ref) {
  final query = ref.watch(studentSearchQueryProvider);
  return ref.watch(adminRepositoryProvider).searchStudents(query);
});

final studentDetailsProvider =
    FutureProvider.autoDispose.family<StudentListItem, String>((ref, studentId) {
  return ref.watch(adminRepositoryProvider).fetchStudentDetails(studentId);
});

final studentSubmissionsProvider =
    FutureProvider.autoDispose.family<List<AdminSubmissionRow>, String>((ref, studentId) {
  return ref.watch(adminRepositoryProvider).fetchStudentSubmissions(studentId);
});

final submissionDetailsProvider =
    FutureProvider.autoDispose.family<SubmissionDetails, String>((ref, submissionId) {
  return ref.watch(adminRepositoryProvider).fetchSubmissionDetails(submissionId);
});

final allSubjectsAdminProvider = FutureProvider.autoDispose<List<Subject>>((ref) {
  return ref.watch(adminRepositoryProvider).fetchAllSubjects();
});

final subjectContentsAdminProvider =
    FutureProvider.autoDispose.family<List<Content>, String>((ref, subjectId) {
  return ref.watch(adminRepositoryProvider).fetchAllContentsForSubject(subjectId);
});

/// فلتر الحالة الحالي لشاشة إدارة الحلول — null يعني "الكل"
final submissionStatusFilterProvider =
    StateProvider.autoDispose<SubmissionStatus?>((ref) => null);

final submissionSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

final submissionsListProvider = FutureProvider.autoDispose<List<AdminSubmissionRow>>((ref) {
  final status = ref.watch(submissionStatusFilterProvider);
  final query = ref.watch(submissionSearchQueryProvider);
  return ref.watch(adminRepositoryProvider).fetchSubmissions(
        status: status,
        searchQuery: query,
      );
});
