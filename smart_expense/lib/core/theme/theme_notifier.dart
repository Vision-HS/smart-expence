import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class ThemeNotifier extends ValueNotifier<ThemeMode> {
  static final ThemeNotifier instance = ThemeNotifier._init();

  ThemeNotifier._init() : super(ThemeMode.light) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final savedTheme = await DatabaseHelper.instance.getSetting('app_theme');
      if (savedTheme == 'dark') {
        value = ThemeMode.dark;
      } else if (savedTheme == 'system') {
        value = ThemeMode.system;
      } else {
        value = ThemeMode.light;
      }
    } catch (_) {
      value = ThemeMode.light;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    value = mode;
    String modeString = 'light';
    if (mode == ThemeMode.dark) {
      modeString = 'dark';
    } else if (mode == ThemeMode.system) {
      modeString = 'system';
    }
    try {
      await DatabaseHelper.instance.setSetting('app_theme', modeString);
    } catch (_) {}
  }

  Future<void> toggleTheme() async {
    if (value == ThemeMode.dark) {
      await setThemeMode(ThemeMode.light);
    } else {
      await setThemeMode(ThemeMode.dark);
    }
  }

  bool isDark(BuildContext context) {
    if (value == ThemeMode.dark) return true;
    if (value == ThemeMode.light) return false;
    return MediaQuery.of(context).platformBrightness == Brightness.dark;
  }
}
