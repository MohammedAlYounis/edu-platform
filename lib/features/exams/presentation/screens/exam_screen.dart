import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_enums.dart';
import '../../../../core/localization/localization_extension.dart';
import '../../../../shared/services/last_opened_content_service.dart';
import '../../../../shared/models/content.dart';
import '../../../../shared/widgets/pdf_viewer_widget.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../submissions/application/submissions_providers.dart';
import '../../../submissions/data/models/submission.dart';
import '../../../subjects/application/subjects_providers.dart';

class ExamScreen extends ConsumerWidget {
  final String contentId;
  const ExamScreen({super.key, required this.contentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAsync = ref.watch(contentByIdProvider(contentId));

    return Scaffold(
      appBar: AppBar(title: Text(context.t('exam'))),
      body: contentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorStateView(
          message: context.t('load_failed'),
          onRetry: () => ref.invalidate(contentByIdProvider(contentId)),
        ),
        data: (content) => RecordLastOpenedContent(
          contentId: content.id,
          title: content.title,
          type: ContentType.exam,
          child: _ExamBody(content: content),
        ),
      ),
    );
  }
}

class _ExamBody extends ConsumerWidget {
  final Content content;
  const _ExamBody({required this.content});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submissionAsync = ref.watch(mySubmissionProvider(content.id));
    final dateFmt = DateFormat('yyyy/MM/dd - hh:mm a');

    return submissionAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorStateView(
        message: context.t('load_failed'),
        onRetry: () => ref.invalidate(mySubmissionProvider(content.id)),
      ),
      data: (submission) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(content.title, style: Theme.of(context).textTheme.headlineSmall),
            if (content.description != null) ...[
              const SizedBox(height: 8),
              Text(content.description!),
            ],
            const SizedBox(height: 16),
            _InfoRow(
              icon: Icons.play_circle_outline,
              label: context.t('exam_starts'),
              value: content.availableFrom != null ? dateFmt.format(content.availableFrom!) : '—',
            ),
            _InfoRow(
              icon: Icons.stop_circle_outlined,
              label: context.t('exam_ends'),
              value: content.availableUntil != null ? dateFmt.format(content.availableUntil!) : '—',
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: Text(context.t('open_questions')),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PdfViewerWidget(
                    bucket: 'exams',
                    storagePath: content.filePath,
                    title: content.title,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),
            Text(context.t('submission_status'), style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _SubmissionSection(content: content, submission: submission),
          ],
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Text('$label: '),
          Expanded(child: Text(value, textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}

class _SubmissionSection extends ConsumerWidget {
  final Content content;
  final Submission? submission;
  const _SubmissionSection({required this.content, required this.submission});

  Future<void> _pickAndConfirm(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null || result.files.single.path == null) return;

    final path = result.files.single.path!;
    final fileName = result.files.single.name;
    final file = File(path);
    final sizeKb = (await file.length()) / 1024;

    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.t('confirm_submission_title')),
        content: Text(
          '${context.t('file_label')}: $fileName\n'
          '${context.t('size_label')}: ${sizeKb.toStringAsFixed(0)} KB\n\n'
          '${context.t('confirm_submission_body')}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.t('submit_solution')),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await ref.read(submissionUploadProvider(content.id).notifier).upload(file, fileName);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uploadState = ref.watch(submissionUploadProvider(content.id));

    ref.listen(submissionUploadProvider(content.id), (previous, next) {
      if (next.status == UploadStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(next.errorMessage!)));
      }
      if (next.status == UploadStatus.success) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(context.t('solution_sent'))));
      }
    });

    // لا يوجد حل بعد → إظهار زر الرفع إن كان الاختبار متاحًا فعليًا
    if (submission == null) {
      if (!content.canAcceptSubmission) {
        return Text(
          content.availability == ExamAvailability.upcoming
              ? context.t('exam_not_started_yet')
              : context.t('exam_ended_no_submission'),
          style: const TextStyle(color: Colors.grey),
        );
      }
      return ElevatedButton.icon(
        icon: uploadState.status == UploadStatus.uploading
            ? const SizedBox(
                height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.upload_file),
        label: Text(context.t('upload_solution')),
        onPressed:
            uploadState.status == UploadStatus.uploading ? null : () => _pickAndConfirm(context, ref),
      );
    }

    // يوجد حل — اعرض الحالة والنتيجة إن وُجدت
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StatusBadge(status: submission!.status),
        const SizedBox(height: 12),
        if (submission!.status == SubmissionStatus.reviewed) ...[
          Text(
            context.t('grade_out_of_100').replaceFirst(
                  '{grade}',
                  submission!.grade?.toStringAsFixed(0) ?? '—',
                ),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (submission!.reviewNote != null) ...[
            const SizedBox(height: 8),
            Text(context.t('admin_notes')),
            Text(submission!.reviewNote!),
          ],
        ],
        if (submission!.status == SubmissionStatus.needsResubmission && submission!.canResubmit) ...[
          Text(
            context.t('resubmission_requested') +
                (submission!.resubmissionReason != null
                    ? '\n${context.t('resubmission_reason_prefix').replaceFirst('{reason}', submission!.resubmissionReason!)}'
                    : ''),
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.upload_file),
            label: Text(context.t('upload_new_solution')),
            onPressed: uploadState.status == UploadStatus.uploading
                ? null
                : () => _pickAndConfirm(context, ref),
          ),
        ],
      ],
    );
  }
}
