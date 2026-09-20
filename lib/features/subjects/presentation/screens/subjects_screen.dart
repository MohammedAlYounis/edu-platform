import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/localization/localization_extension.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../application/subjects_providers.dart';

class SubjectsScreen extends ConsumerWidget {
  const SubjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectsListProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.t('subjects'))),
      body: subjectsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorStateView(
          message: context.t('load_failed'),
          onRetry: () => ref.invalidate(subjectsListProvider),
        ),
        data: (subjects) {
          if (subjects.isEmpty) {
            return EmptyState(message: context.t('no_subjects'));
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(subjectsListProvider.future),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: subjects.length,
              itemBuilder: (context, index) {
                final subject = subjects[index];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: CircleAvatar(
                      radius: 26,
                      backgroundImage: subject.imageUrl != null
                          ? NetworkImage(subject.imageUrl!)
                          : null,
                      child: subject.imageUrl == null
                          ? Text(subject.title.substring(0, 1))
                          : null,
                    ),
                    title: Text(subject.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      '${context.t('lessons_and_exams')
                          .replaceFirst('{lessons}', subject.lessonsCount.toString())
                          .replaceFirst('{exams}', subject.examsCount.toString())}${subject.description != null ? '\n${subject.description}' : ''}',
                    ),
                    isThreeLine: subject.description != null,
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () => context.push(
                      AppRoutes.subjectDetails.replaceFirst(':id', subject.id),
                      extra: subject.title,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
