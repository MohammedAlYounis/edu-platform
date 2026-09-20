import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/app_config.dart';
import '../../core/routing/app_router.dart';
import '../../core/storage/settings_keys.dart';
import '../../core/storage/shared_prefs_provider.dart';
import '../../features/notifications/data/repositories/notifications_repository.dart';

/// يُستدعى من main() *خارج* أي widget — لازم top-level function مع
/// @pragma حتى يعمل Android وهو مغلق تمامًا (بند 19 في التصميم).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // لا حاجة لأي منطق هنا حاليًا؛ Firebase تعرض الإشعار تلقائيًا في الخلفية.
  // الـ Deep Linking الفعلي يحدث عند الضغط، عبر onMessageOpenedApp/getInitialMessage.
}

final fcmServiceProvider = Provider<FcmService>((ref) {
  return FcmService(
    ref.watch(notificationsRepositoryProvider),
    ref.watch(sharedPreferencesProvider),
  );
});

class FcmService {
  final NotificationsRepository _notificationsRepository;
  final SharedPreferences _prefs;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  FcmService(this._notificationsRepository, this._prefs);

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    if (!kIsWeb) {
      await _localNotifications.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
        onDidReceiveNotificationResponse: (response) {
          if (response.payload != null) _handleDeepLink(response.payload!);
        },
      );
    }

    // إظهار إشعار فعلي عند وصول رسالة والتطبيق مفتوح (foreground) —
    // Firebase لا يعرض إشعار النظام تلقائيًا في هذه الحالة على Android.
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;

      // بند 21: تفعيل/تعطيل الإشعارات من شاشة الإعدادات — لا يزال السجل
      // يُخزَّن بالـ DB (يظهر بقائمة الإشعارات لاحقًا)، لكن لا نُقاطع
      // المستخدم بإشعار نظام لو عطّله صراحة.
      final notificationsEnabled =
          _prefs.getBool(SettingsKeys.notificationsEnabled) ?? true;
      if (notificationsEnabled != true) return;

      if (!kIsWeb) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'default_channel',
              'General notifications',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          payload: message.data['type'] != null
              ? '${message.data['type']}:${message.data['id']}'
              : null,
        );
      }
    });

    // التطبيق كان في الخلفية والمستخدم ضغط الإشعار
    FirebaseMessaging.onMessageOpenedApp
        .listen((message) => _handleRemoteMessage(message));

    // التطبيق كان مغلقًا تمامًا وفُتح من الإشعار
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) _handleRemoteMessage(initialMessage);

    await saveTokenForCurrentUser();
    messaging.onTokenRefresh.listen((_) => saveTokenForCurrentUser());
  }

  /// عام حتى يُستدعى مرة أخرى بعد نجاح تسجيل الدخول — عند initialize()
  /// الأولى قد لا يكون هناك مستخدم مسجَّل بعد، فيُتجاهل الحفظ بصمت.
  Future<void> saveTokenForCurrentUser() async {
    try {
      if (kIsWeb && AppConfig.firebaseWebVapidKey.isEmpty) return;
      final token = await FirebaseMessaging.instance.getToken(
        vapidKey: kIsWeb && AppConfig.firebaseWebVapidKey.isNotEmpty
            ? AppConfig.firebaseWebVapidKey
            : null,
      );
      if (token == null) return;
      final platform = kIsWeb ? 'web' : (Platform.isIOS ? 'ios' : 'android');
      await _notificationsRepository.registerDevice(
          fcmToken: token, platform: platform);
    } catch (_) {
      // فشل تسجيل الجهاز لا يجب أن يمنع تشغيل التطبيق.
    }
  }

  void _handleRemoteMessage(RemoteMessage message) {
    final type = message.data['type'] as String?;
    final id = message.data['id'] as String?;
    if (type != null && id != null) _navigateForDeepLink(type, id);
  }

  void _handleDeepLink(String payload) {
    final parts = payload.split(':');
    if (parts.length == 2) _navigateForDeepLink(parts[0], parts[1]);
  }

  /// بند 19: "الإشعار يجب أن يدعم Deep Linking... يفتح صفحة الاختبار مباشرة"
  void _navigateForDeepLink(String type, String id) {
    final router = AppRouterHolder.router;
    if (router == null) return;

    switch (type) {
      case 'lesson':
        router.push('/lesson/$id');
      case 'exam':
        router.push('/exam/$id');
      case 'submission':
      case 'resubmission':
        // target_id هنا هو معرّف الطالب (لأغراض الاستهداف)، وليس معرّف
        // الاختبار — لا يوجد رابط مباشر آمن، فنكتفي بفتح قائمة الإشعارات.
        router.push('/notifications');
      default:
        router.push('/notifications');
    }
  }
}
