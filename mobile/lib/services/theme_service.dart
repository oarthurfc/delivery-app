import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static const themeKey = 'is_dark_mode';
  final SharedPreferences _prefs;
  late bool _isDarkMode;

  ThemeService(this._prefs) {
    _isDarkMode = _prefs.getBool(themeKey) ?? false;
  }

  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _prefs.setBool(themeKey, _isDarkMode);
    notifyListeners();
  }
}