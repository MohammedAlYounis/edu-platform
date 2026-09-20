class DashboardStats {
  final int totalStudents;
  final int totalSubjects;
  final int totalLessons;
  final int totalExams;
  final int pendingSubmissions;
  final int reviewedSubmissions;

  const DashboardStats({
    required this.totalStudents,
    required this.totalSubjects,
    required this.totalLessons,
    required this.totalExams,
    required this.pendingSubmissions,
    required this.reviewedSubmissions,
  });
}
