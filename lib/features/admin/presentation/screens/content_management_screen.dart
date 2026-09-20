import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_enums.dart';
import '../../../../core/localization/localization_extension.dart';
import '../../../../shared/models/content.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../application/admin_providers.dart';
import '../../data/admin_repository.dart';

class ContentManagementScreen extends ConsumerStatefulWidget {
  final String subjectId;
  final String? subjectTitle;

  const ContentManagementScreen(
      {super.key, required this.subjectId, this.subjectTitle});

  @override
  ConsumerState<ContentManagementScreen> createState() =>
      _ContentManagementScreenState();
}

class _ContentManagementScreenState
    extends ConsumerState<ContentManagementScreen> {
  String get subjectId => widget.subjectId;

  Future<DateTime?> _pickDateTime(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: DateTime.now(),
    );
    if (date == null || !context.mounted) return null;
    final time =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null) return date;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _showAddContentDialog({
    required ContentType type,
    required int nextOrder,
  }) async {
    final context = this.context;
    final titleController = TextEditingController();
    final descController = TextEditingController();
    DateTime? availableFrom;
    DateTime? availableUntil;
    PlatformFile? pickedFile;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(type == ContentType.lesson
              ? context.t('add_lesson')
              : context.t('add_exam')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration:
                      InputDecoration(labelText: context.t('title_label')),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descController,
                  decoration: InputDecoration(
                      labelText: context.t('description_optional')),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.attach_file),
                  label: Text(pickedFile?.name ?? context.t('choose_pdf_file')),
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles(
                        type: FileType.custom, allowedExtensions: ['pdf']);
                    if (result != null)
                      setState(() => pickedFile = result.files.single);
                  },
                ),
                if (type == ContentType.exam) ...[
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(availableFrom == null
                        ? context.t('choose_start_date')
                        : '${context.t('from_prefix')} ${DateFormat('yyyy/MM/dd hh:mm a').format(availableFrom!)}'),
                    trailing: const Icon(Icons.calendar_today, size: 18),
                    onTap: () async {
                      final date = await _pickDateTime(context);
                      if (date != null) setState(() => availableFrom = date);
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(availableUntil == null
                        ? context.t('choose_end_date')
                        : '${context.t('to_prefix')} ${DateFormat('yyyy/MM/dd hh:mm a').format(availableUntil!)}'),
                    trailing: const Icon(Icons.calendar_today, size: 18),
                    onTap: () async {
                      final date = await _pickDateTime(context);
                      if (date != null) setState(() => availableUntil = date);
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.t('cancel')),
            ),
            FilledButton(
              onPressed: () {
                if (titleController.text.trim().isEmpty ||
                    pickedFile?.path == null) return;
                if (type == ContentType.exam &&
                    (availableFrom == null ||
                        availableUntil == null ||
                        !availableUntil!.isAfter(availableFrom!))) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.t('date_validation_error'))),
                  );
                  return;
                }
                Navigator.pop(context, true);
              },
              child: Text(context.t('save')),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || pickedFile?.path == null) return;

    try {
      await ref.read(adminRepositoryProvider).createContent(
            subjectId: subjectId,
            title: titleController.text.trim(),
            description: descController.text.trim().isEmpty
                ? null
                : descController.text.trim(),
            type: type,
            file: File(pickedFile!.path!),
            fileName: pickedFile!.name,
            orderIndex: nextOrder,
            availableFrom: availableFrom,
            availableUntil: availableUntil,
          );
      ref.invalidate(subjectContentsAdminProvider(subjectId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.t('add_content_failed'))));
      }
    }
  }

  Future<void> _showEditContentDialog(Content content) async {
    final titleController = TextEditingController(text: content.title);
    final descController =
        TextEditingController(text: content.description ?? '');
    DateTime? availableFrom = content.availableFrom;
    DateTime? availableUntil = content.availableUntil;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(context.t('edit_content')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration:
                      InputDecoration(labelText: context.t('title_label')),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descController,
                  decoration: InputDecoration(
                      labelText: context.t('description_optional')),
                ),
                if (content.isExam) ...[
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(availableFrom == null
                        ? context.t('choose_start_date')
                        : '${context.t('from_prefix')} ${DateFormat('yyyy/MM/dd hh:mm a').format(availableFrom!)}'),
                    trailing: const Icon(Icons.calendar_today, size: 18),
                    onTap: () async {
                      final date = await _pickDateTime(context);
                      if (date != null) setState(() => availableFrom = date);
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(availableUntil == null
                        ? context.t('choose_end_date')
                        : '${context.t('to_prefix')} ${DateFormat('yyyy/MM/dd hh:mm a').format(availableUntil!)}'),
                    trailing: const Icon(Icons.calendar_today, size: 18),
                    onTap: () async {
                      final date = await _pickDateTime(context);
                      if (date != null) setState(() => availableUntil = date);
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.t('cancel')),
            ),
            FilledButton(
              onPressed: () {
                if (titleController.text.trim().isEmpty) return;
                if (content.isExam &&
                    availableFrom != null &&
                    availableUntil != null &&
                    !availableUntil!.isAfter(availableFrom!)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.t('date_validation_error'))),
                  );
                  return;
                }
                Navigator.pop(context, true);
              },
              child: Text(context.t('save')),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    await ref.read(adminRepositoryProvider).updateContent(
          id: content.id,
          title: titleController.text.trim(),
          description: descController.text.trim().isEmpty
              ? null
              : descController.text.trim(),
          availableFrom: content.isExam ? availableFrom : null,
          availableUntil: content.isExam ? availableUntil : null,
        );
    ref.invalidate(subjectContentsAdminProvider(subjectId));
  }

  Future<void> _onReorder(
      List<Content> contents, int oldIndex, int newIndex) async {
    final items = List<Content>.from(contents);
    final moved = items.removeAt(oldIndex);
    items.insert(newIndex, moved);
    await ref.read(adminRepositoryProvider).syncContentOrder(subjectId, items);
    ref.invalidate(subjectContentsAdminProvider(subjectId));
  }

  @override
  Widget build(BuildContext context) {
    final contentsAsync = ref.watch(subjectContentsAdminProvider(subjectId));

    return Scaffold(
      appBar: AppBar(title: Text(widget.subjectTitle ?? context.t('content'))),
      floatingActionButton: contentsAsync.maybeWhen(
        data: (contents) => PopupMenuButton<ContentType>(
          icon: const Icon(Icons.add_circle, size: 48),
          onSelected: (type) =>
              _showAddContentDialog(type: type, nextOrder: contents.length),
          itemBuilder: (context) => [
            PopupMenuItem(
                value: ContentType.lesson,
                child: Text(context.t('add_lesson'))),
            PopupMenuItem(
                value: ContentType.exam, child: Text(context.t('add_exam'))),
          ],
        ),
        orElse: () => null,
      ),
      body: contentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorStateView(
          message: context.t('load_failed'),
          onRetry: () =>
              ref.invalidate(subjectContentsAdminProvider(subjectId)),
        ),
        data: (contents) {
          if (contents.isEmpty)
            return EmptyState(message: context.t('no_content'));
          return ReorderableListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: contents.length,
            onReorderItem: (oldIndex, newIndex) =>
                _onReorder(contents, oldIndex, newIndex),
            itemBuilder: (context, index) {
              final content = contents[index];
              final isLesson = content.type == ContentType.lesson;
              return Card(
                key: ValueKey(content.id),
                child: ListTile(
                  leading: ReorderableDragStartListener(
                    index: index,
                    child: Icon(
                      isLesson
                          ? Icons.menu_book_outlined
                          : Icons.assignment_outlined,
                      color: isLesson ? Colors.blue : Colors.deepOrange,
                    ),
                  ),
                  title: Text(
                      '${(index + 1).toString().padLeft(2, '0')} - ${content.title}'),
                  subtitle: !isLesson && content.availableUntil != null
                      ? Text(
                          '${context.t('ends_prefix')} ${DateFormat('yyyy/MM/dd hh:mm a').format(content.availableUntil!)}')
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _showEditContentDialog(content),
                      ),
                      Switch(
                        value: content.isActive,
                        onChanged: (value) async {
                          await ref
                              .read(adminRepositoryProvider)
                              .setContentActive(content.id, value);
                          ref.invalidate(
                              subjectContentsAdminProvider(subjectId));
                        },
                      ),
                    ],
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
