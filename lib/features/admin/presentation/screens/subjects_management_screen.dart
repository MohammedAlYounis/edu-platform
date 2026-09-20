import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/localization_extension.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../application/admin_providers.dart';
import '../../data/admin_repository.dart';
import '../../../subjects/data/models/subject.dart';

class SubjectsManagementScreen extends ConsumerStatefulWidget {
  const SubjectsManagementScreen({super.key});

  @override
  ConsumerState<SubjectsManagementScreen> createState() =>
      _SubjectsManagementScreenState();
}

class _SubjectsManagementScreenState
    extends ConsumerState<SubjectsManagementScreen> {
  Future<void> _showSubjectForm(
    BuildContext context, {
    Subject? existing,
    int nextOrder = 0,
  }) async {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final descController =
        TextEditingController(text: existing?.description ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title:
            Text(context.t(existing == null ? 'add_subject' : 'edit_subject')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: context.t('title_label')),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descController,
              decoration:
                  InputDecoration(labelText: context.t('description_optional')),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.t('save')),
          ),
        ],
      ),
    );

    if (saved != true || titleController.text.trim().isEmpty) return;

    final repo = ref.read(adminRepositoryProvider);
    if (existing == null) {
      await repo.createSubject(
        title: titleController.text.trim(),
        description: descController.text.trim().isEmpty
            ? null
            : descController.text.trim(),
        orderIndex: nextOrder,
      );
    } else {
      await repo.updateSubject(
        id: existing.id,
        title: titleController.text.trim(),
        description: descController.text.trim().isEmpty
            ? null
            : descController.text.trim(),
      );
    }
    ref.invalidate(allSubjectsAdminProvider);
  }

  Future<void> _onReorder(
      List<Subject> subjects, int oldIndex, int newIndex) async {
    final items = List<Subject>.from(subjects);
    final moved = items.removeAt(oldIndex);
    items.insert(newIndex, moved);
    await ref.read(adminRepositoryProvider).syncSubjectOrder(items);
    ref.invalidate(allSubjectsAdminProvider);
  }

  @override
  Widget build(BuildContext context) {
    final subjectsAsync = ref.watch(allSubjectsAdminProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.t('subjects_and_content'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSubjectForm(
          context,
          nextOrder: subjectsAsync.valueOrNull?.length ?? 0,
        ),
        icon: const Icon(Icons.add),
        label: Text(context.t('add_subject')),
      ),
      body: subjectsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorStateView(
          message: context.t('load_failed'),
          onRetry: () => ref.invalidate(allSubjectsAdminProvider),
        ),
        data: (subjects) {
          if (subjects.isEmpty)
            return EmptyState(message: context.t('no_subjects'));
          return ReorderableListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: subjects.length,
            onReorderItem: (oldIndex, newIndex) =>
                _onReorder(subjects, oldIndex, newIndex),
            itemBuilder: (context, index) {
              final subject = subjects[index];
              return Card(
                key: ValueKey(subject.id),
                child: ListTile(
                  leading: ReorderableDragStartListener(
                    index: index,
                    child: const Icon(Icons.drag_handle),
                  ),
                  title: Text(subject.title),
                  subtitle: Text(subject.description ?? ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () =>
                            _showSubjectForm(context, existing: subject),
                      ),
                      Switch(
                        value: subject.isActive,
                        onChanged: (value) async {
                          await ref
                              .read(adminRepositoryProvider)
                              .setSubjectActive(subject.id, value);
                          ref.invalidate(allSubjectsAdminProvider);
                        },
                      ),
                    ],
                  ),
                  onTap: () => context.push(
                    AdminRoutes.contentManagement
                        .replaceFirst(':id', subject.id),
                    extra: subject.title,
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
