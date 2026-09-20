import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';

import '../../../../core/constants/app_enums.dart';
import '../../../../core/localization/localization_extension.dart';
import '../../../../shared/widgets/pdf_viewer_widget.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../application/admin_providers.dart';
import '../../data/admin_repository.dart';
import '../../data/models/admin_models.dart';

class ReviewSubmissionScreen extends ConsumerWidget {
  final String submissionId;
  const ReviewSubmissionScreen({super.key, required this.submissionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(submissionDetailsProvider(submissionId));

    return Scaffold(
      appBar: AppBar(title: Text(context.t('review_submission'))),
      body: detailsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorStateView(
          message: context.t('load_failed'),
          onRetry: () => ref.invalidate(submissionDetailsProvider(submissionId)),
        ),
        data: (details) => _ReviewBody(details: details),
      ),
    );
  }
}

class _ReviewBody extends ConsumerStatefulWidget {
  final SubmissionDetails details;
  const _ReviewBody({required this.details});

  @override
  ConsumerState<_ReviewBody> createState() => _ReviewBodyState();
}

class _ReviewBodyState extends ConsumerState<_ReviewBody> {
  late final form = FormGroup({
    'grade': FormControl<String>(
      value: widget.details.grade?.toStringAsFixed(0),
      validators: [Validators.number(), Validators.min(0), Validators.max(100)],
    ),
    'note': FormControl<String>(value: widget.details.reviewNote),
  });

  final _resubmissionReasonController = TextEditingController();
  bool _isSaving = false;

  Future<void> _startReviewIfPending() async {
    if (widget.details.status == SubmissionStatus.pending) {
      await ref.read(adminRepositoryProvider).startReview(widget.details.id);
      ref.invalidate(submissionDetailsProvider(widget.details.id));
    }
  }

  Future<void> _saveReview() async {
    if (form.invalid) {
      form.markAllAsTouched();
      return;
    }
    setState(() => _isSaving = true);
    try {
      await ref.read(adminRepositoryProvider).saveReview(
            submissionId: widget.details.id,
            grade: double.parse(form.control('grade').value as String),
            note: (form.control('note').value as String?)?.trim().isEmpty ?? true
                ? null
                : form.control('note').value as String,
          );
      ref.invalidate(submissionDetailsProvider(widget.details.id));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.t('save_review'))));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.t('save_failed'))));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _requestResubmission() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.t('request_resubmission')),
        content: TextField(
          controller: _resubmissionReasonController,
          decoration: InputDecoration(labelText: context.t('resubmission_reason')),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, _resubmissionReasonController.text.trim()),
            child: Text(context.t('send_request')),
          ),
        ],
      ),
    );

    if (reason == null || reason.isEmpty) return;

    await ref.read(adminRepositoryProvider).requestResubmission(
          submissionId: widget.details.id,
          reason: reason,
        );
    ref.invalidate(submissionDetailsProvider(widget.details.id));
  }

  @override
  void initState() {
    super.initState();
    // بند 31: "يجب تسجيل reviewed_at و reviewer_id" — يبدأ عند فتح الشاشة أول مرة
    WidgetsBinding.instance.addPostFrameCallback((_) => _startReviewIfPending());
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.details;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(d.studentName, style: Theme.of(context).textTheme.titleLarge),
        Text('${context.t('student_number')}: ${d.studentNumber ?? "—"}'),
        const SizedBox(height: 4),
        Text('${context.t('exam')}: ${d.examTitle}'),
        const SizedBox(height: 8),
        StatusBadge(status: d.status),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: Text(context.t('view_solution_file')),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PdfViewerWidget(
                bucket: 'submissions',
                storagePath: d.filePath,
                title: context.t('solution_of').replaceFirst('{name}', d.studentName),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 12),
        Text(context.t('correction'), style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        ReactiveForm(
          formGroup: form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ReactiveTextField<String>(
                formControlName: 'grade',
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: context.t('grade_field_label')),
                validationMessages: {
                  ValidationMessage.number: (_) => context.t('enter_valid_number'),
                  ValidationMessage.min: (_) => context.t('grade_min_error'),
                  ValidationMessage.max: (_) => context.t('grade_max_error'),
                },
              ),
              const SizedBox(height: 12),
              ReactiveTextField<String>(
                formControlName: 'note',
                maxLines: 3,
                decoration: InputDecoration(labelText: context.t('notes_optional')),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveReview,
                child: _isSaving
                    ? const SizedBox(
                        height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(context.t('save_correction')),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _requestResubmission,
                child: Text(context.t('request_resubmission')),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
