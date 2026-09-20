import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';

import '../../../../core/constants/app_enums.dart';
import '../../../../core/localization/localization_extension.dart';
import '../../application/admin_providers.dart';
import '../../data/admin_repository.dart';
import '../../data/models/admin_models.dart';
import '../../../subjects/data/models/subject.dart';

enum _NotificationTarget { all, subject, student }

class AdminNotificationsScreen extends ConsumerStatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  ConsumerState<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState
    extends ConsumerState<AdminNotificationsScreen> {
  final form = FormGroup({
    'title': FormControl<String>(validators: [Validators.required]),
    'body': FormControl<String>(validators: [Validators.required]),
  });

  _NotificationTarget _target = _NotificationTarget.all;
  String? _selectedSubjectId;
  String? _selectedStudentId;
  bool _isSending = false;

  Future<void> _send() async {
    if (form.invalid) {
      form.markAllAsTouched();
      return;
    }
    if (_target == _NotificationTarget.subject && _selectedSubjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t('select_subject_required'))));
      return;
    }
    if (_target == _NotificationTarget.student && _selectedStudentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t('select_student_required'))));
      return;
    }

    setState(() => _isSending = true);
    try {
      final target = _target;
      final targetType = switch (target) {
        _NotificationTarget.all => 'all',
        _NotificationTarget.subject => 'subject',
        _NotificationTarget.student => 'student',
      };
      final targetId = switch (target) {
        _NotificationTarget.all => null,
        _NotificationTarget.subject => _selectedSubjectId,
        _NotificationTarget.student => _selectedStudentId,
      };

      await ref.read(adminRepositoryProvider).createNotification(
            title: form.control('title').value as String,
            body: form.control('body').value as String,
            type: NotificationType.general,
            targetType: targetType,
            targetId: targetId,
          );
      final successMessage = switch (target) {
        _NotificationTarget.all => context.t('notification_sent_all'),
        _NotificationTarget.subject => context.t('notification_sent_subject'),
        _NotificationTarget.student => context.t('notification_sent_student'),
      };
      form.reset();
      setState(() {
        _target = _NotificationTarget.all;
        _selectedSubjectId = null;
        _selectedStudentId = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(successMessage)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.t('notification_send_failed'))));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjectsAsync = ref.watch(allSubjectsAdminProvider);
    final studentsAsync = ref.watch(studentsSearchResultProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.t('new_notification'))),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ReactiveForm(
          formGroup: form,
          child: ListView(
            children: [
              ReactiveTextField<String>(
                formControlName: 'title',
                decoration:
                    InputDecoration(labelText: context.t('notification_title')),
              ),
              const SizedBox(height: 12),
              ReactiveTextField<String>(
                formControlName: 'body',
                maxLines: 4,
                decoration:
                    InputDecoration(labelText: context.t('notification_body')),
              ),
              const SizedBox(height: 20),
              Text(context.t('notification_target_label'),
                  style: Theme.of(context).textTheme.titleSmall),
              RadioListTile<_NotificationTarget>(
                title: Text(context.t('notification_target_all')),
                value: _NotificationTarget.all,
                groupValue: _target,
                onChanged: (v) => setState(() => _target = v!),
              ),
              RadioListTile<_NotificationTarget>(
                title: Text(context.t('notification_target_subject')),
                value: _NotificationTarget.subject,
                groupValue: _target,
                onChanged: (v) => setState(() => _target = v!),
              ),
              if (_target == _NotificationTarget.subject)
                subjectsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => Text(context.t('load_failed')),
                  data: (subjects) => DropdownButtonFormField<String>(
                    initialValue: _selectedSubjectId,
                    decoration:
                        InputDecoration(labelText: context.t('select_subject')),
                    items: subjects
                        .map((Subject s) =>
                            DropdownMenuItem(value: s.id, child: Text(s.title)))
                        .toList(),
                    onChanged: (id) => setState(() => _selectedSubjectId = id),
                  ),
                ),
              RadioListTile<_NotificationTarget>(
                title: Text(context.t('notification_target_student')),
                value: _NotificationTarget.student,
                groupValue: _target,
                onChanged: (v) => setState(() => _target = v!),
              ),
              if (_target == _NotificationTarget.student)
                studentsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => Text(context.t('load_failed')),
                  data: (students) => DropdownButtonFormField<String>(
                    initialValue: _selectedStudentId,
                    decoration:
                        InputDecoration(labelText: context.t('select_student')),
                    items: students
                        .map((StudentListItem s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(
                                  '${s.fullName} (${s.studentNumber ?? '—'})'),
                            ))
                        .toList(),
                    onChanged: (id) => setState(() => _selectedStudentId = id),
                  ),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSending ? null : _send,
                child: _isSending
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(context.t('send_notification')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
