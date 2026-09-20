import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_enums.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/localization/localization_extension.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../application/subjects_providers.dart';

class SubjectDetailsScreen extends ConsumerWidget {
  final String subjectId;
  final String? subjectTitle;

  const SubjectDetailsScreen({super.key, required this.subjectId, this.subjectTitle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentsAsync = ref.watch(subjectContentsProvider(subjectId));

    return Scaffold(
      appBar: AppBar(title: Text(subjectTitle ?? context.t('subject_details'))),
      body: contentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorStateView(
          message: context.t('load_failed'),
          onRetry: () => ref.invalidate(subjectContentsProvider(subjectId)),
        ),
        data: (contents) {
          if (contents.isEmpty) {
            return EmptyState(message: context.t('no_content'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: contents.length,
            itemBuilder: (context, index) {
              final content = contents[index];
              final isLesson = content.type == ContentType.lesson;
              return Card(
                child: ListTile(
                  leading: Icon(
                    isLesson ? Icons.menu_book_outlined : Icons.assignment_outlined,
                    color: isLesson ? Colors.blue : Colors.deepOrange,
                  ),
                  title: Text('${(index + 1).toString().padLeft(2, '0')} - ${content.title}'),
                  subtitle: content.description != null ? Text(content.description!) : null,
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () => context.push(
                    isLesson
                        ? AppRoutes.lesson.replaceFirst(':id', content.id)
                        : AppRoutes.exam.replaceFirst(':id', content.id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
