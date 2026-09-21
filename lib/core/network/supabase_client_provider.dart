import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../errors/failure.dart';

/// Provider وحيد للوصول إلى Supabase Client عبر كامل المشروع.
/// لا تستدعِ Supabase.instance.client مباشرة داخل الـ Repositories —
/// مرّر هذا الـ provider بدلًا من ذلك، لتسهيل الاختبار والاستبدال لاحقًا.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// يحوّل أي استثناء قادم من Supabase/الشبكة إلى Failure يحمل مفتاح ترجمة
/// (وليس نصًا جاهزًا) — استخدمه بكل Repository داخل try/catch.
///
/// كل Failure يُطبع تفصيله الحقيقي بالـ console (debugPrint) — بدون هذا،
/// المستخدم والمطوّر يشوفون فقط الرسالة المترجمة العامة ("تعذر الرفع")
/// ولا طريقة لمعرفة السبب الفعلي (403 من RLS؟ bucket مفقود؟ نوع ملف مرفوض؟)
/// بدون فتح Supabase Dashboard يدويًا في كل مرة.
Failure mapExceptionToFailure(Object error, [StackTrace? stackTrace]) {
  final failure = _resolveFailure(error, stackTrace);
  debugPrint('[Failure:${failure.messageKey}] ${failure.debugDetails}');
  return failure;
}

Failure _resolveFailure(Object error, StackTrace? stackTrace) {
  if (error is AuthException) {
    return AuthFailure(_mapAuthMessageKey(error.message), debugDetails: '$error');
  }
  if (error is PostgrestException) {
    if (error.code == 'PGRST301' || error.code == '42501') {
      return PermissionFailure(debugDetails: '$error');
    }
    return UnknownFailure(debugDetails: '$error');
  }
  if (error is StorageException) {
    return StorageFailure(
      'upload_failed',
      debugDetails: 'statusCode=${error.statusCode} message=${error.message} error=${error.error}',
    );
  }
  return UnknownFailure(debugDetails: '$error\n$stackTrace');
}

String _mapAuthMessageKey(String raw) {
  final message = raw.toLowerCase();
  if (message.contains('invalid login credentials')) return 'invalid_credentials';
  if (message.contains('already registered') || message.contains('user already registered')) {
    return 'email_already_registered';
  }
  if (message.contains('email not confirmed')) return 'email_not_confirmed';
  return 'sign_in_failed';
}
