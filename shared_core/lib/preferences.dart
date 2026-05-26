import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n.dart';

/// App-wide preferences (language + theme mode) — persisted to disk and
/// applied live across the whole MaterialApp via ChangeNotifier.
class Preferences extends ChangeNotifier {
  static const _kLang = 'pref_lang';
  static const _kTheme = 'pref_theme_mode';

  AppLang _lang = AppLang.en;
  ThemeMode _themeMode = ThemeMode.system;

  AppLang get lang => _lang;
  ThemeMode get themeMode => _themeMode;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final l = p.getString(_kLang);
    if (l != null) {
      _lang = AppLang.values.firstWhere((x) => x.name == l, orElse: () => AppLang.en);
    }
    final t = p.getString(_kTheme);
    if (t != null) {
      _themeMode = ThemeMode.values.firstWhere((x) => x.name == t, orElse: () => ThemeMode.system);
    }
  }

  Future<void> setLang(AppLang l) async {
    if (l == _lang) return;
    _lang = l;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setString(_kLang, l.name);
  }

  Future<void> setThemeMode(ThemeMode m) async {
    if (m == _themeMode) return;
    _themeMode = m;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setString(_kTheme, m.name);
  }
}
