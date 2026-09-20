import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/localization_extension.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../application/admin_providers.dart';

class StudentsScreen extends ConsumerWidget {
  const StudentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(studentsSearchResultProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.t('students'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: context.t('search_students_hint'),
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) =>
                  ref.read(studentSearchQueryProvider.notifier).state = value,
            ),
          ),
          Expanded(
            child: studentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorStateView(
                message: context.t('load_failed'),
                onRetry: () => ref.invalidate(studentsSearchResultProvider),
              ),
              data: (students) {
                if (students.isEmpty) {
                  return EmptyState(message: context.t('no_matching_students'));
                }
                return ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final s = students[index];
                    return ListTile(
                      leading: CircleAvatar(child: Text(s.fullName.substring(0, 1))),
                      title: Text(s.fullName),
                      subtitle: Text('${s.studentNumber ?? "—"} • ${s.email}'),
                      trailing: s.isActive
                          ? null
                          : Chip(
                              label: Text(context.t('disabled_label')),
                              backgroundColor: const Color(0xFFFFE0E0),
                            ),
                      onTap: () => context.push(
                        AdminRoutes.studentDetails.replaceFirst(':id', s.id),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
