/// مفاتيح SharedPreferences لإعدادات المستخدم المحلية — ثابت واحد
/// مشترك بدل تكرار الـ string بأكتر من ملف.
abstract class SettingsKeys {
  static const locale = 'locale';
  static const themeMode = 'theme_mode';
  static const notificationsEnabled = 'notifications_enabled';
  static const lastOpenedContents = 'last_opened_contents';
}
