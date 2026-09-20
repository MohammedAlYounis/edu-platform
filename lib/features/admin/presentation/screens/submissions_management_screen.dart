import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_enums.dart';
import '../../../../core/localization/localization_extension.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../application/admin_providers.dart';

Map<String, SubmissionStatus?> _filters(BuildContext context) => {
      context.t('filter_all'): null,
      context.t('status_pending'): SubmissionStatus.pending,
      context.t('status_reviewing'): SubmissionStatus.reviewing,
      context.t('status_reviewed'): SubmissionStatus.reviewed,
      context.t('status_needs_resubmission'): SubmissionStatus.needsResubmission,
    };

class SubmissionsManagementScreen extends ConsumerWidget {
  const SubmissionsManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rowsAsync = ref.watch(submissionsListProvider);
    final currentFilter = ref.watch(submissionStatusFilterProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.t('submission_management'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: context.t('search_submissions_hint'),
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) => ref.read(submissionSearchQueryProvider.notifier).state = v,
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: _filters(context).entries.map((entry) {
                final selected = currentFilter == entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(entry.key),
                    selected: selected,
                    onSelected: (_) =>
                        ref.read(submissionStatusFilterProvider.notifier).state = entry.value,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: rowsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorStateView(
                message: context.t('load_failed'),
                onRetry: () => ref.invalidate(submissionsListProvider),
              ),
              data: (rows) {
                if (rows.isEmpty) return EmptyState(message: context.t('no_matching_submissions'));
                return ListView.builder(
                  itemCount: rows.length,
                  itemBuilder: (context, index) {
                    final r = rows[index];
                    return ListTile(
                      title: Text('${r.studentName} — ${r.examTitle}'),
                      subtitle: Text(r.studentNumber ?? ''),
                      trailing: StatusBadge(status: r.status),
                      onTap: () => context
                          .push(AdminRoutes.reviewSubmission.replaceFirst(':id', r.id)),
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
