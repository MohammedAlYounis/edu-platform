import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import '../../../core/errors/failure.dart';
import '../../../shared/services/fcm_service.dart';
import '../data/models/user_profile.dart';
import '../data/repositories/auth_repository.dart';

/// الحالة الكاملة للمصادقة: null = غير مسجّل، وإلا الـ profile الكامل
/// (بما فيه role) — هذا ما يحتاجه GoRouter فعليًا للتوجيه الصحيح،
/// وليس auth.User الخام فقط.
final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, UserProfile?>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<UserProfile?> {
  late final AuthRepository _repository;
  bool get hasSession => _repository.currentSession != null;

  @override
  Future<UserProfile?> build() async {
    _repository = ref.watch(authRepositoryProvider);

    // نستمع لتغيّرات الجلسة (login/logout/token refresh) ونعيد جلب الـ profile
    // في كل مرة، بدل الاعتماد على الحالة القديمة.
    ref.listen(_authStateStreamProvider, (previous, next) {
      next.whenData((_) => _refresh());
    });

    return _repository.fetchCurrentProfile();
  }

  Future<void> _refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.fetchCurrentProfile());
    // بند 19/40: تسجيل جهاز الطالب لحظة توفر جلسة صالحة — يغطي كل مسارات
    // الدخول (Password و Google OAuth) من مكان واحد بدل تكراره في كل دالة.
    if (state.valueOrNull != null) {
      unawaited(ref.read(fcmServiceProvider).saveTokenForCurrentUser());
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repository.signInWithPassword(email: email, password: password);
      return _repository.fetchCurrentProfile();
    });
    if (state.hasError) {
      final error = state.error;
      throw error is Failure ? error : const UnknownFailure();
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String studentNumber,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repository.signUp(
        email: email,
        password: password,
        fullName: fullName,
        studentNumber: studentNumber,
      );
      // Supabase قد يتطلب تأكيد البريد افتراضيًا فلا تُنشأ جلسة فورًا —
      // register_screen يتحقق من notifier.hasSession ويعرض رسالة توضيحية
      // بنفسه، فنكتفي هنا بإرجاع null دون اعتبارها خطأ.
      if (_repository.currentSession == null) return null;
      return _repository.fetchCurrentProfile();
    });
    if (state.hasError) {
      final error = state.error;
      throw error is Failure ? error : const UnknownFailure();
    }
  }

  Future<void> signInWithGoogle() async {
    // OAuth يفتح متصفحًا خارجيًا؛ الحالة تُحدَّث تلقائيًا عبر
    // authStateChange listener أعلاه بعد عودة المستخدم للتطبيق.
    await _repository.signInWithGoogle();
  }

  Future<void> sendPasswordReset({required String email}) async {
    await _repository.sendPasswordResetEmail(email);
  }

  Future<void> resendConfirmationEmail({required String email}) async {
    await _repository.resendConfirmationEmail(email);
  }

  Future<void> signOut() async {
    await _repository.signOut();
    state = const AsyncData(null);
  }
}

final _authStateStreamProvider = StreamProvider((ref) {
  return ref.watch(authRepositoryProvider).onAuthStateChange;
});
