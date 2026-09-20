import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/localization/localization_extension.dart';
import '../../../../core/localization/locale_controller.dart';
import '../../../../core/storage/settings_keys.dart';
import '../../../../core/storage/shared_prefs_provider.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../shared/services/pdf_cache_service.dart';
import '../../../../shared/widgets/language_switch_button.dart';
import '../../../auth/application/auth_notifier.dart';

/// بند 21 في التصميم: Profile, Student Number, Email, Notifications,
/// Language, Theme, Downloaded Files, About, Privacy Policy, Terms, Logout.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late SharedPreferences _prefs;
  bool _notificationsEnabled = true;
  String? _cacheClearingMessage;
  bool _isClearingCache = false;

  @override
  void initState() {
    super.initState();
    _prefs = ref.read(sharedPreferencesProvider);
    _notificationsEnabled =
        _prefs.getBool(SettingsKeys.notificationsEnabled) ?? true;
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);
    await _prefs.setBool(SettingsKeys.notificationsEnabled, value);
  }

  Future<void> _clearCache() async {
    setState(() {
      _isClearingCache = true;
      _cacheClearingMessage = null;
    });
    try {
      await ref.read(pdfCacheServiceProvider).clearCache();
      if (mounted) setState(() => _cacheClearingMessage = context.t('cache_cleared'));
    } catch (_) {
      if (mounted) setState(() => _cacheClearingMessage = context.t('cache_clear_failed'));
    } finally {
      if (mounted) setState(() => _isClearingCache = false);
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.t('logout')),
        content: Text(context.t('confirm_logout')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.t('logout')),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authNotifierProvider.notifier).signOut();
    }
  }

  void _showStaticTextDialog(String titleKey, String bodyKey) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.t(titleKey)),
        content: SingleChildScrollView(child: Text(context.t(bodyKey))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(context.t('close'))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(authNotifierProvider).valueOrNull;
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('settings')),
        actions: const [LanguageSwitchButton()],
      ),
      body: ListView(
        children: [
          // --- Profile ---
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  child: Text(
                    (profile?.fullName.isNotEmpty ?? false)
                        ? profile!.fullName.substring(0, 1)
                        : '?',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile?.fullName ?? '', style: Theme.of(context).textTheme.titleMedium),
                      Text('${context.t('student_number')}: ${profile?.studentNumber ?? "—"}'),
                      Text(profile?.email ?? '', style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(),

          // --- Notifications ---
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: Text(context.t('enable_notifications')),
            value: _notificationsEnabled,
            onChanged: _toggleNotifications,
          ),

          // --- Language ---
          ListTile(
            leading: const Icon(Icons.translate),
            title: Text(context.t('language')),
            trailing: DropdownButton<Locale>(
              value: locale,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(value: Locale('en'), child: Text('English')),
                DropdownMenuItem(value: Locale('ar'), child: Text('العربية')),
              ],
              onChanged: (value) {
                if (value != null) ref.read(localeProvider.notifier).setLocale(value);
              },
            ),
          ),

          // --- Theme ---
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: Text(context.t('theme')),
            trailing: DropdownButton<ThemeMode>(
              value: themeMode,
              underline: const SizedBox.shrink(),
              items: [
                DropdownMenuItem(value: ThemeMode.system, child: Text(context.t('theme_system'))),
                DropdownMenuItem(value: ThemeMode.light, child: Text(context.t('theme_light'))),
                DropdownMenuItem(value: ThemeMode.dark, child: Text(context.t('theme_dark'))),
              ],
              onChanged: (mode) {
                if (mode != null) ref.read(themeModeProvider.notifier).setThemeMode(mode);
              },
            ),
          ),

          // --- Downloaded files / Cache ---
          ListTile(
            leading: const Icon(Icons.storage_outlined),
            title: Text(context.t('downloaded_files')),
            subtitle: _cacheClearingMessage != null ? Text(_cacheClearingMessage!) : null,
            trailing: _isClearingCache
                ? const SizedBox(
                    height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : TextButton(onPressed: _clearCache, child: Text(context.t('clear_cache'))),
          ),
          const Divider(),

          // --- About / Privacy / Terms ---
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(context.t('about')),
            trailing: FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) =>
                  Text(snapshot.hasData ? 'v${snapshot.data!.version}' : ''),
            ),
            onTap: () => _showStaticTextDialog('about', 'about_body'),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(context.t('privacy_policy')),
            onTap: () => _showStaticTextDialog('privacy_policy', 'privacy_policy_body'),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(context.t('terms')),
            onTap: () => _showStaticTextDialog('terms', 'terms_body'),
          ),
          const Divider(),

          // --- Logout ---
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(context.t('logout'), style: const TextStyle(color: Colors.red)),
            onTap: _confirmLogout,
          ),
        ],
      ),
    );
  }
}
