import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/screens/admin_notifications_screen.dart';
import '../../features/admin/presentation/screens/content_management_screen.dart';
import '../../features/admin/presentation/screens/dashboard_screen.dart';
import '../../features/admin/presentation/screens/review_submission_screen.dart';
import '../../features/admin/presentation/screens/student_details_screen.dart';
import '../../features/admin/presentation/screens/students_screen.dart';
import '../../features/admin/presentation/screens/subjects_management_screen.dart';
import '../../features/admin/presentation/screens/submissions_management_screen.dart';
import '../../features/admin/presentation/widgets/admin_shell.dart';
import '../../features/auth/application/auth_notifier.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/exams/presentation/screens/exam_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/lessons/presentation/screens/lesson_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/subjects/presentation/screens/subject_details_screen.dart';
import '../../features/subjects/presentation/screens/subjects_screen.dart';

/// مسارات الطالب فقط في هذه المرحلة (Phase 1).
/// مسارات /admin/* ستُضاف كملف guard منفصل عند بناء لوحة الإدارة (Phase 5)
/// لأنها تعمل كتطبيق Flutter Web مستقل منطقيًا حسب التصميم المعتمد.
abstract class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const home = '/home';
  static const subjects = '/subjects';
  static const subjectDetails = '/subjects/:id';
  static const lesson = '/lesson/:id';
  static const exam = '/exam/:id';
  static const notifications = '/notifications';
  static const settings = '/settings';
}

/// مسارات لوحة الإدارة — منفصلة منطقيًا خلف AdminShell (بند 22)،
/// ومحمية بفحص isAdmin في redirect أدناه (وليس فقط بإخفاء أزرار، بند 42).
abstract class AdminRoutes {
  static const dashboard = '/admin';
  static const students = '/admin/students';
  static const studentDetails = '/admin/students/:id';
  static const subjects = '/admin/subjects';
  static const contentManagement = '/admin/subjects/:id/content';
  static const submissions = '/admin/submissions';
  static const reviewSubmission = '/admin/submissions/:id';
  static const notifications = '/admin/notifications';
}

/// نحتفظ بمرجع للـ router الحالي حتى تستطيع خدمات خارج شجرة الـ Widgets
/// (مثل FcmService عند الضغط على إشعار) التنقّل مباشرة دون BuildContext.
class AppRouterHolder {
  static GoRouter? router;
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: GoRouterRefreshStream(
      ref.watch(authRepositoryProvider).onAuthStateChange,
    ),
    redirect: (context, state) {
      final profile = authState.valueOrNull;
      final loggedIn = profile != null;
      final isAdmin = profile?.isAdmin ?? false;
      final goingToAuthPages = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register ||
          state.matchedLocation == AppRoutes.forgotPassword;
      final onSplash = state.matchedLocation == AppRoutes.splash;
      final goingToAdmin = state.matchedLocation.startsWith('/admin');

      // لسّا جاري التحقق من الجلسة → لا تعيد التوجيه، اترك Splash يتصرف
      if (authState.isLoading) return null;

      if (!loggedIn && (onSplash || !goingToAuthPages)) {
        return AppRoutes.login;
      }
      if (loggedIn && (goingToAuthPages || onSplash)) {
        return isAdmin ? AdminRoutes.dashboard : AppRoutes.home;
      }
      // طالب عادي يحاول الوصول للوحة الإدارة — الحماية الحقيقية في RLS،
      // هذا فقط لتجربة استخدام أوضح (بند 42: لا اعتماد على الواجهة وحدها).
      if (loggedIn && !isAdmin && goingToAdmin) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.subjects,
        builder: (context, state) => const SubjectsScreen(),
      ),
      GoRoute(
        path: AppRoutes.subjectDetails,
        builder: (context, state) => SubjectDetailsScreen(
          subjectId: state.pathParameters['id']!,
          subjectTitle: state.extra as String?,
        ),
      ),
      GoRoute(
        path: AppRoutes.lesson,
        builder: (context, state) =>
            LessonScreen(contentId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.exam,
        builder: (context, state) =>
            ExamScreen(contentId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            AdminShell(currentRoute: state.matchedLocation, child: child),
        routes: [
          GoRoute(
            path: AdminRoutes.dashboard,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: AdminRoutes.students,
            builder: (context, state) => const StudentsScreen(),
          ),
          GoRoute(
            path: AdminRoutes.studentDetails,
            builder: (context, state) =>
                StudentDetailsScreen(studentId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: AdminRoutes.subjects,
            builder: (context, state) => const SubjectsManagementScreen(),
          ),
          GoRoute(
            path: AdminRoutes.contentManagement,
            builder: (context, state) => ContentManagementScreen(
              subjectId: state.pathParameters['id']!,
              subjectTitle: state.extra as String?,
            ),
          ),
          GoRoute(
            path: AdminRoutes.submissions,
            builder: (context, state) => const SubmissionsManagementScreen(),
          ),
          GoRoute(
            path: AdminRoutes.reviewSubmission,
            builder: (context, state) => ReviewSubmissionScreen(
                submissionId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: AdminRoutes.notifications,
            builder: (context, state) => const AdminNotificationsScreen(),
          ),
        ],
      ),
    ],
  );

  AppRouterHolder.router = router;
  return router;
});

/// يحوّل أي Stream إلى Listenable يفهمه GoRouter، حتى يعيد تقييم redirect
/// تلقائيًا عند كل تغيّر في authNotifierProvider (بدل الاعتماد فقط على
/// إعادة بناء الـ Widget، وهو غير كافٍ لتحديث GoRouter نفسه).
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
