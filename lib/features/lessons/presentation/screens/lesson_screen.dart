import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_enums.dart';
import '../../../../core/localization/localization_extension.dart';
import '../../../../shared/services/last_opened_content_service.dart';
import '../../../../shared/widgets/pdf_viewer_widget.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../subjects/application/subjects_providers.dart';

/// الدرس لا يقبل Submission إطلاقًا (بند 10 في التصميم) — عرض PDF فقط.
class LessonScreen extends ConsumerWidget {
  final String contentId;
  const LessonScreen({super.key, required this.contentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAsync = ref.watch(contentByIdProvider(contentId));

    return contentAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(context.t('lesson'))),
        body: ErrorStateView(
          message: context.t('load_failed'),
          onRetry: () => ref.invalidate(contentByIdProvider(contentId)),
        ),
      ),
      data: (content) => RecordLastOpenedContent(
        contentId: content.id,
        title: content.title,
        type: ContentType.lesson,
        child: PdfViewerWidget(
          bucket: 'lessons',
          storagePath: content.filePath,
          title: content.title,
        ),
      ),
    );
  }
}
