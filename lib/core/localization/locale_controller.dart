import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../storage/settings_keys.dart';
import '../storage/shared_prefs_provider.dart';
import 'app_localizations.dart';

final localeProvider = StateNotifierProvider<LocaleController, Locale>((ref) {
  return LocaleController(ref.watch(sharedPreferencesProvider));
});

class LocaleController extends StateNotifier<Locale> {
  final SharedPreferences _prefs;

  LocaleController(SharedPreferences prefs)
      : _prefs = prefs,
        super(Locale(prefs.getString(SettingsKeys.locale) ?? 'en'));

  Future<void> setLocale(Locale locale) async {
    if (!AppLocalizations.supportedLocales
        .any((supported) => supported.languageCode == locale.languageCode)) {
      return;
    }
    state = locale;
    await _prefs.setString(SettingsKeys.locale, locale.languageCode);
  }

  Future<void> toggle() => setLocale(
        state.languageCode == 'en' ? const Locale('ar') : const Locale('en'),
      );
}
