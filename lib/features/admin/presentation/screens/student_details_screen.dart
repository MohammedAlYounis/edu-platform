import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/localization_extension.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../application/admin_providers.dart';
import '../../data/admin_repository.dart';

class StudentDetailsScreen extends ConsumerWidget {
  final String studentId;
  const StudentDetailsScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentAsync = ref.watch(studentDetailsProvider(studentId));
    final submissionsAsync = ref.watch(studentSubmissionsProvider(studentId));

    return Scaffold(
      appBar: AppBar(title: Text(context.t('student_profile'))),
      body: studentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorStateView(
          message: context.t('load_failed'),
          onRetry: () => ref.invalidate(studentDetailsProvider(studentId)),
        ),
        data: (student) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(student.fullName, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('${context.t('student_number')}: ${student.studentNumber ?? "—"}'),
            Text('${context.t('email')}: ${student.email}'),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(context.t('account_enabled')),
              value: student.isActive,
              onChanged: (value) async {
                await ref.read(adminRepositoryProvider).setStudentActive(studentId, value);
                ref.invalidate(studentDetailsProvider(studentId));
              },
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            Text(context.t('submitted_solutions'), style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            submissionsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text(context.t('load_failed')),
              data: (rows) {
                if (rows.isEmpty) return Text(context.t('no_submissions_yet'));
                return Column(
                  children: rows
                      .map((r) => Card(
                            child: ListTile(
                              title: Text(r.examTitle),
                              subtitle:
                                  Text(r.grade != null ? '${r.grade!.toStringAsFixed(0)}/100' : ''),
                              trailing: StatusBadge(status: r.status),
                              onTap: () => context.push(
                                AdminRoutes.reviewSubmission.replaceFirst(':id', r.id),
                              ),
                            ),
                          ))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
