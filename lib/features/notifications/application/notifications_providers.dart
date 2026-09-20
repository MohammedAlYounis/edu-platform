import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/app_notification.dart';
import '../data/repositories/notifications_repository.dart';

final myNotificationsProvider = FutureProvider.autoDispose<List<AppNotification>>((ref) {
  return ref.watch(notificationsRepositoryProvider).fetchMyNotifications();
});

final unreadNotificationsCountProvider = Provider.autoDispose<int>((ref) {
  final notifications = ref.watch(myNotificationsProvider).valueOrNull ?? [];
  return notifications.where((n) => !n.isRead).length;
});
