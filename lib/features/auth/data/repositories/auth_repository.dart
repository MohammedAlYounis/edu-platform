import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/network/supabase_client_provider.dart';
import '../models/user_profile.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});

/// كل تفاعل مع Supabase Auth يمر من هنا فقط.
/// الـ UI والـ Notifier لا يستدعيان SupabaseClient مباشرة.
class AuthRepository {
  final SupabaseClient _client;
  const AuthRepository(this._client);

  Session? get currentSession => _client.auth.currentSession;
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } catch (e, st) {
      throw mapExceptionToFailure(e, st);
    }
  }

  /// full_name و student_number يُمرَّران كـ metadata فيلتقطهما
  /// trigger `handle_new_user` في قاعدة البيانات وينشئ صف profiles تلقائيًا.
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String studentNumber,
  }) async {
    try {
      await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'student_number': studentNumber,
        },
      );
    } on AuthException catch (e, st) {
      // student_number مكرر يظهر كخطأ unique constraint من الـ trigger،
      // يصل كرسالة عامة من Supabase — نحوّلها لرسالة أوضح إن أمكن تمييزها.
      if (e.message.contains('duplicate key') ||
          e.message.contains('profiles_student_number_key')) {
        throw const ValidationFailure('student_number_taken');
      }
      throw mapExceptionToFailure(e, st);
    } catch (e, st) {
      throw mapExceptionToFailure(e, st);
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        queryParams: const {'prompt': 'select_account'},
      );
    } catch (e, st) {
      throw mapExceptionToFailure(e, st);
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } catch (e, st) {
      throw mapExceptionToFailure(e, st);
    }
  }

  Future<void> resendConfirmationEmail(String email) async {
    try {
      await _client.auth.resend(type: OtpType.signup, email: email);
    } catch (e, st) {
      throw mapExceptionToFailure(e, st);
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e, st) {
      throw mapExceptionToFailure(e, st);
    }
  }

  /// يُستدعى بعد كل تغيّر في حالة الجلسة لجلب الـ profile الكامل
  /// (role, student_number...) — auth.User وحده لا يكفي للتوجيه حسب الدور.
  Future<UserProfile?> fetchCurrentProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final row = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (row != null) return UserProfile.fromJson(row);

      // The profile trigger runs immediately after auth.users insertion, but
      // a short retry prevents a race during the first login.
      for (var attempt = 0; attempt < 3; attempt++) {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        final retry = await _client
            .from('profiles')
            .select()
            .eq('id', userId)
            .maybeSingle();
        if (retry != null) return UserProfile.fromJson(retry);
      }
      throw const AuthFailure('profile_not_ready');
    } catch (e, st) {
      throw mapExceptionToFailure(e, st);
    }
  }
}
