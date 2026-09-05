import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static const String _keyDarkMode = 'is_dark_mode';
  static final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);
  static SharedPreferences? _prefs;

  static bool get isDarkMode => themeModeNotifier.value == ThemeMode.dark;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final isDark = _prefs?.getBool(_keyDarkMode) ?? false;
    themeModeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  static void toggleDarkMode(bool enabled) {
    themeModeNotifier.value = enabled ? ThemeMode.dark : ThemeMode.light;
    _prefs?.setBool(_keyDarkMode, enabled);
  }
}
