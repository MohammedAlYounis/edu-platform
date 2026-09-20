import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// لا تستخدم هذا الـ provider مباشرة بدون override — main() يستبدله
/// بقيمة حقيقية (await SharedPreferences.getInstance()) قبل runApp عبر
/// ProviderContainer(overrides: [...]) — بهذا تبقى القراءة متزامنة
/// (sync) بكل مكان بعد الإقلاع، رغم أن التهيئة نفسها async لمرة واحدة.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider غير مُهيّأ — تأكد أن main() يمرره عبر override قبل runApp.',
  );
});
