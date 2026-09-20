import 'package:flutter/material.dart';

import '../../core/constants/app_enums.dart';
import '../../core/localization/localization_extension.dart';
import '../../core/theme/app_theme.dart';

/// بند 48 في التصميم: "استخدم ألوانًا مختلفة للحالات ولكن بدون الاعتماد
/// على اللون وحده" — لذلك نضيف دائمًا أيقونة + نص، أبدًا لون فقط.
class StatusBadge extends StatelessWidget {
  final SubmissionStatus status;
  const StatusBadge({super.key, required this.status});

  (Color, IconData) get _config => switch (status) {
        SubmissionStatus.pending => (StatusColors.pending, Icons.hourglass_empty),
        SubmissionStatus.reviewing => (StatusColors.reviewing, Icons.rate_review),
        SubmissionStatus.reviewed => (StatusColors.reviewed, Icons.check_circle),
        SubmissionStatus.needsResubmission => (
            StatusColors.needsResubmission,
            Icons.warning_amber,
          ),
      };

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _config;
    final label = switch (status) {
      SubmissionStatus.pending => context.t('status_pending'),
      SubmissionStatus.reviewing => context.t('status_reviewing'),
      SubmissionStatus.reviewed => context.t('status_reviewed'),
      SubmissionStatus.needsResubmission => context.t('status_needs_resubmission'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
