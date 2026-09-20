import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_enums.dart';
import '../../../../core/localization/localization_extension.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../application/notifications_providers.dart';
import '../../data/models/app_notification.dart';
import '../../data/repositories/notifications_repository.dart';

/// بند 20 في التصميم: title, body, date, read/unread, type — مع دعم
/// الضغط على الإشعار لفتح الوجهة المناسبة (نفس منطق Deep Link من FCM).
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  IconData _iconFor(NotificationType type) => switch (type) {
        NotificationType.lesson => Icons.menu_book_outlined,
        NotificationType.exam => Icons.assignment_outlined,
        NotificationType.submission => Icons.grading_outlined,
        NotificationType.resubmission => Icons.replay_outlined,
        NotificationType.general => Icons.campaign_outlined,
      };

  void _handleTap(BuildContext context, WidgetRef ref, AppNotification notification) {
    ref.read(notificationsRepositoryProvider).markAsRead(notification.id);
    ref.invalidate(myNotificationsProvider);

    // نفس منطق التوجيه المستخدم في FcmService، لكن هنا داخل شجرة الـ Widgets
    switch (notification.type) {
      case NotificationType.lesson:
        if (notification.targetId != null) context.push('/lesson/${notification.targetId}');
      case NotificationType.exam:
        if (notification.targetId != null) context.push('/exam/${notification.targetId}');
      case NotificationType.submission:
      case NotificationType.resubmission:
        // target_id هنا معرّف الطالب (للاستهداف)، وليس معرّف الاختبار —
        // لا يوجد رابط اختبار آمن نفتحه من هذا الإشعار مباشرة.
        break;
      case NotificationType.general:
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(myNotificationsProvider);
    final dateFmt = DateFormat('yyyy/MM/dd - hh:mm a');

    return Scaffold(
      appBar: AppBar(title: Text(context.t('notifications'))),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(myNotificationsProvider.future),
        child: notificationsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ErrorStateView(
            message: context.t('load_failed'),
            onRetry: () => ref.invalidate(myNotificationsProvider),
          ),
          data: (notifications) {
            if (notifications.isEmpty) {
              return EmptyState(
                message: context.t('notifications_empty'),
                icon: Icons.notifications_none,
              );
            }
            return ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final n = notifications[index];
                return ListTile(
                  leading: Icon(_iconFor(n.type), color: n.isRead ? Colors.grey : Colors.blue),
                  title: Text(
                    n.title,
                    style: TextStyle(fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold),
                  ),
                  subtitle: Text('${n.body}\n${dateFmt.format(n.createdAt)}'),
                  isThreeLine: true,
                  trailing: n.isRead ? null : const CircleAvatar(radius: 5, backgroundColor: Colors.blue),
                  onTap: () => _handleTap(context, ref, n),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
