import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/localization/localization_extension.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../../shared/widgets/language_switch_button.dart';
import '../../../auth/application/auth_notifier.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../shared/services/last_opened_content_service.dart';
import '../../../submissions/application/submissions_providers.dart';
import '../../../subjects/application/subjects_providers.dart';

/// Home الفعلية — بند 7 في التصميم: Welcome، آخر الدروس، الاختبارات
/// الحالية، الاختبارات القريبة من الانتهاء، آخر الحلول، Quick Actions.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(authNotifierProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('home')),
        actions: [
          const LanguageSwitchButton(),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(recentLessonsProvider);
          ref.invalidate(activeExamsProvider);
          ref.invalidate(examsEndingSoonProvider);
          ref.invalidate(recentSubmissionsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              context
                  .t('welcome')
                  .replaceFirst('{name}', profile?.fullName ?? ''),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            _QuickActions(),
            const SizedBox(height: 24),
            _SectionTitle(context.t('continue_where_left_off')),
            _ContinueSection(),
            const SizedBox(height: 24),
            _SectionTitle(context.t('ending_soon_exams')),
            _ExamsEndingSoonSection(),
            const SizedBox(height: 24),
            _SectionTitle(context.t('active_exams')),
            _ActiveExamsSection(),
            const SizedBox(height: 24),
            _SectionTitle(context.t('recent_lessons')),
            _RecentLessonsSection(),
            const SizedBox(height: 24),
            _SectionTitle(context.t('recent_submissions')),
            _RecentSubmissionsSection(),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _ContinueSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(lastOpenedEntriesProvider);
    if (entries.isEmpty) {
      return Text(context.t('no_continue_items'));
    }
    return Column(
      children: entries
          .map(
            (e) => Card(
              child: ListTile(
                leading: Icon(
                  e.type == ContentType.lesson
                      ? Icons.menu_book_outlined
                      : Icons.assignment_outlined,
                ),
                title: Text(e.title),
                onTap: () {
                  final route = e.type == ContentType.lesson
                      ? AppRoutes.lesson.replaceFirst(':id', e.id)
                      : AppRoutes.exam.replaceFirst(':id', e.id);
                  context.push(route);
                },
              ),
            ),
          )
          .toList(),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.menu_book_outlined),
            label: Text(context.t('subjects')),
            onPressed: () => context.push(AppRoutes.subjects),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.notifications_outlined),
            label: Text(context.t('notifications')),
            onPressed: () => context.push(AppRoutes.notifications),
          ),
        ),
      ],
    );
  }
}

class _ExamsEndingSoonSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examsAsync = ref.watch(examsEndingSoonProvider);
    return examsAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) =>
          Text(context.t('load_failed'), style: const TextStyle(color: Colors.grey)),
      data: (exams) {
        if (exams.isEmpty) {
          return Text(context.t('no_ending_soon_exams'));
        }
        return Column(
          children: exams
              .map((e) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.timer_outlined,
                          color: Colors.deepOrange),
                      title: Text(e.title),
                      subtitle: e.availableUntil != null
                          ? Text(
                              DateFormat('yyyy/MM/dd hh:mm a').format(e.availableUntil!))
                          : null,
                      onTap: () => context
                          .push(AppRoutes.exam.replaceFirst(':id', e.id)),
                    ),
                  ))
              .toList(),
        );
      },
    );
  }
}

class _ActiveExamsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examsAsync = ref.watch(activeExamsProvider);
    return examsAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) =>
          Text(context.t('load_failed'), style: const TextStyle(color: Colors.grey)),
      data: (exams) {
        if (exams.isEmpty) {
          return EmptyState(message: context.t('no_exams_available'));
        }
        return Column(
          children: exams
              .map((e) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.assignment_outlined),
                      title: Text(e.title),
                      onTap: () => context
                          .push(AppRoutes.exam.replaceFirst(':id', e.id)),
                    ),
                  ))
              .toList(),
        );
      },
    );
  }
}

class _RecentLessonsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonsAsync = ref.watch(recentLessonsProvider);
    return lessonsAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) =>
          Text(context.t('load_failed'), style: const TextStyle(color: Colors.grey)),
      data: (lessons) {
        if (lessons.isEmpty) return Text(context.t('no_lessons'));
        return Column(
          children: lessons
              .map((l) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.menu_book_outlined,
                          color: Colors.blue),
                      title: Text(l.title),
                      onTap: () => context
                          .push(AppRoutes.lesson.replaceFirst(':id', l.id)),
                    ),
                  ))
              .toList(),
        );
      },
    );
  }
}

class _RecentSubmissionsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submissionsAsync = ref.watch(recentSubmissionsProvider);
    return submissionsAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) =>
          Text(context.t('load_failed'), style: const TextStyle(color: Colors.grey)),
      data: (submissions) {
        if (submissions.isEmpty) return Text(context.t('no_submissions'));
        return Column(
          children: submissions
              .map((s) => Card(
                    child: ListTile(
                      title: Text(s.fileName),
                      trailing: StatusBadge(status: s.status),
                    ),
                  ))
              .toList(),
        );
      },
    );
  }
}
