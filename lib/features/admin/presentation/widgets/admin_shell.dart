import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../../auth/application/auth_notifier.dart';
import '../../../../core/localization/localization_extension.dart';
import '../../../../core/localization/locale_controller.dart';
import '../../../../shared/widgets/language_switch_button.dart';

class _AdminNavItem {
  final String labelKey;
  final IconData icon;
  final String route;
  const _AdminNavItem(this.labelKey, this.icon, this.route);
}

const _navItems = [
  _AdminNavItem(
      'admin_dashboard', Icons.dashboard_outlined, AdminRoutes.dashboard),
  _AdminNavItem('students', Icons.people_outline, AdminRoutes.students),
  _AdminNavItem(
      'subjects_and_content', Icons.menu_book_outlined, AdminRoutes.subjects),
  _AdminNavItem('submission_management', Icons.assignment_turned_in_outlined,
      AdminRoutes.submissions),
  _AdminNavItem(
      'notifications', Icons.notifications_outlined, AdminRoutes.notifications),
];

/// بند 22/49: لوحة إدارة منفصلة منطقيًا، Responsive —
/// Desktop: Sidebar ثابت. Mobile/Tablet: Drawer قابل للسحب.
class AdminShell extends ConsumerWidget {
  final Widget child;
  final String currentRoute;

  const AdminShell(
      {super.key, required this.child, required this.currentRoute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            _Sidebar(currentRoute: currentRoute),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('admin_dashboard')),
        actions: const [LanguageSwitchButton()],
      ),
      drawer:
          Drawer(child: _Sidebar(currentRoute: currentRoute, isDrawer: true)),
      body: child,
    );
  }
}

class _Sidebar extends ConsumerWidget {
  final String currentRoute;
  final bool isDrawer;
  const _Sidebar({required this.currentRoute, this.isDrawer = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(authNotifierProvider).valueOrNull;

    return Container(
      width: isDrawer ? null : 260,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(Icons.school, size: 40),
                  const SizedBox(height: 8),
                  Text(profile?.fullName ?? context.t('admin_label'),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: ListView(
                  children: _navItems.map((item) {
                    final selected = currentRoute == item.route;
                    return ListTile(
                      leading: Icon(item.icon),
                      title: Text(context.t(item.labelKey)),
                      selected: selected,
                      onTap: () {
                        if (isDrawer) Navigator.pop(context);
                        context.go(item.route);
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.translate),
              title: Text(context.t('switch_language')),
              onTap: () => ref.read(localeProvider.notifier).toggle(),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(context.t('logout')),
              onTap: () => ref.read(authNotifierProvider.notifier).signOut(),
            ),
          ],
        ),
      ),
    );
  }
}
