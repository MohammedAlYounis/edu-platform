import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/network/supabase_client_provider.dart';
import '../models/app_notification.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(ref.watch(supabaseClientProvider));
});

class NotificationsRepository {
  final SupabaseClient _client;
  const NotificationsRepository(this._client);

  /// يجلب الإشعارات الموجّهة لكل الطلاب (target_type = all) أو لهذا الطالب
  /// تحديدًا (target_type = student)، مع دمج حالة القراءة من
  /// notification_reads يدويًا — بند 20 في التصميم.
  Future<List<AppNotification>> fetchMyNotifications({int limit = 50}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final rows = await _client
          .from('notifications')
          .select()
          .or(
            'target_type.eq.all,'
            'target_type.eq.subject,'
            'target_type.eq.content,'
            'and(target_type.eq.student,target_id.eq.$userId)',
          )
          .order('created_at', ascending: false)
          .limit(limit);

      if (rows.isEmpty) return [];

      final ids = rows.map((r) => r['id'] as String).toList();
      final readRows = await _client
          .from('notification_reads')
          .select('notification_id')
          .eq('user_id', userId)
          .inFilter('notification_id', ids);
      final readIds = readRows.map((r) => r['notification_id'] as String).toSet();

      return rows
          .map((r) => AppNotification.fromJson(r, isRead: readIds.contains(r['id'])))
          .toList();
    } catch (e, st) {
      throw mapExceptionToFailure(e, st);
    }
  }

  Future<void> markAsRead(String notificationId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _client.from('notification_reads').upsert({
        'notification_id': notificationId,
        'user_id': userId,
      });
    } catch (e, st) {
      throw mapExceptionToFailure(e, st);
    }
  }

  /// يسجّل/يحدّث fcm_token لهذا الجهاز — بند 19/40 في التصميم.
  Future<void> registerDevice({required String fcmToken, required String platform}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _client.from('user_devices').upsert(
        {
          'user_id': userId,
          'fcm_token': fcmToken,
          'platform': platform,
        },
        onConflict: 'user_id,fcm_token',
      );
    } catch (e, st) {
      throw mapExceptionToFailure(e, st);
    }
  }
}
