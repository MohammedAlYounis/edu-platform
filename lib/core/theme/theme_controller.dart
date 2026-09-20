import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../storage/settings_keys.dart';
import '../storage/shared_prefs_provider.dart';

final themeModeProvider = StateNotifierProvider<ThemeController, ThemeMode>((ref) {
  return ThemeController(ref.watch(sharedPreferencesProvider));
});

/// بند 21 في التصميم: "يجب دعم Light/Dark Theme" مع خيار يدوي للمستخدم
/// (وليس system فقط).
class ThemeController extends StateNotifier<ThemeMode> {
  final SharedPreferences _prefs;

  ThemeController(SharedPreferences prefs)
      : _prefs = prefs,
        super(_readSaved(prefs));

  static ThemeMode _readSaved(SharedPreferences prefs) {
    final saved = prefs.getString(SettingsKeys.themeMode);
    return switch (saved) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _prefs.setString(SettingsKeys.themeMode, mode.name);
  }
}
