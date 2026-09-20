import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/localization_extension.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../application/admin_providers.dart';
import '../../data/models/dashboard_stats.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.t('admin_dashboard'))),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardStatsProvider);
          ref.invalidate(recentStudentsProvider);
          ref.invalidate(recentSubmissionsAdminProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            statsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorStateView(
                message: context.t('load_failed'),
                onRetry: () => ref.invalidate(dashboardStatsProvider),
              ),
              data: (stats) => _StatsGrid(stats: stats),
            ),
            const SizedBox(height: 28),
            Text(context.t('recent_students'), style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _RecentStudentsList(),
            const SizedBox(height: 28),
            Text(context.t('recent_submissions'), style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _RecentSubmissionsList(),
          ],
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final DashboardStats stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final items = [
      (context.t('total_students'), stats.totalStudents, Icons.people_outline, Colors.blue),
      (context.t('total_subjects'), stats.totalSubjects, Icons.menu_book_outlined, Colors.teal),
      (context.t('total_lessons'), stats.totalLessons, Icons.article_outlined, Colors.indigo),
      (context.t('total_exams'), stats.totalExams, Icons.assignment_outlined, Colors.deepPurple),
      (context.t('pending_submissions_stat'), stats.pendingSubmissions, Icons.hourglass_empty,
          Colors.orange),
      (context.t('reviewed_submissions_stat'), stats.reviewedSubmissions,
          Icons.check_circle_outline, Colors.green),
    ];

    return GridView.count(
      crossAxisCount: MediaQuery.sizeOf(context).width >= 900 ? 3 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: items
          .map((i) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(i.$3, color: i.$4),
                      Text('${i.$2}',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      Text(i.$1, style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class _RecentStudentsList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(recentStudentsProvider);
    return async.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text(context.t('load_failed'), style: const TextStyle(color: Colors.grey)),
      data: (students) {
        if (students.isEmpty) return Text(context.t('no_students_yet'));
        return Column(
          children: students
              .map((s) => Card(
                    child: ListTile(
                      title: Text(s.fullName),
                      subtitle: Text('${context.t('student_number')}: ${s.studentNumber ?? "—"}'),
                    ),
                  ))
              .toList(),
        );
      },
    );
  }
}

class _RecentSubmissionsList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(recentSubmissionsAdminProvider);
    return async.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text(context.t('load_failed'), style: const TextStyle(color: Colors.grey)),
      data: (rows) {
        if (rows.isEmpty) return Text(context.t('no_submissions_yet'));
        return Column(
          children: rows
              .map((r) => Card(
                    child: ListTile(
                      title: Text('${r.studentName} — ${r.examTitle}'),
                      subtitle: Text(r.studentNumber ?? ''),
                      trailing: StatusBadge(status: r.status),
                    ),
                  ))
              .toList(),
        );
      },
    );
  }
}
