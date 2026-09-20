import 'package:flutter_dotenv/flutter_dotenv.dart';

/// إعدادات المشروع الأساسية — تُقرأ من ملف .env في جذر المشروع.
///
/// main() يستدعي AppConfig.load() قبل أي شيء آخر. لا تصل إلى supabaseUrl
/// أو supabaseAnonKey قبل اكتمال هذا الاستدعاء.
///
/// .env مُستثنى من Git عبر .gitignore — كل مطوّر يضع مفاتيحه الخاصة محليًا.
abstract class AppConfig {
  static Future<void> load() => dotenv.load(fileName: '.env');

  static String get supabaseUrl => dotenv.get('SUPABASE_URL', fallback: '');

  static String get supabaseAnonKey =>
      dotenv.get('SUPABASE_ANON_KEY', fallback: '');
  static String get firebaseWebVapidKey =>
      dotenv.get('FIREBASE_WEB_VAPID_KEY', fallback: '');

  static const bool isProduction = bool.fromEnvironment('dart.vm.product');

  static void assertConfigured() {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw StateError(
        'Missing Supabase configuration. Set SUPABASE_URL and SUPABASE_ANON_KEY in .env.',
      );
    }
  }
}
