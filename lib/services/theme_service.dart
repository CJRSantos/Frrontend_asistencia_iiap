import 'package:flutter/material.dart';
import 'storage_service.dart';

class ThemeService {
  static final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

  static bool get isDarkMode => themeModeNotifier.value == ThemeMode.dark;

  static Future<void> init() async {
    final isDark = await StorageService.getDarkModeStatus();
    themeModeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  static Future<void> toggleDarkMode(bool enabled) async {
    themeModeNotifier.value = enabled ? ThemeMode.dark : ThemeMode.light;
    await StorageService.saveDarkMode(enabled);
  }
}
