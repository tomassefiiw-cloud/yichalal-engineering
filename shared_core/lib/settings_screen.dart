import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'l10n.dart';
import 'preferences.dart';
import 'theme.dart';

/// Shared Settings screen — language + theme toggles. Used by both
/// customer_app and mechanic_app via Profile → Settings.
class SettingsScreen extends StatelessWidget {
  /// Primary color of the calling app (orange or whatever).
  final Color primary;
  const SettingsScreen({super.key, this.primary = AppColors.orange});

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<Preferences>();
    final s = S.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.t('settings'))),
      body: ListView(padding: const EdgeInsets.symmetric(vertical: 12), children: [
        _section(context, s.t('language')),
        _langTile(context, prefs, AppLang.en, 'English', '🇬🇧'),
        _langTile(context, prefs, AppLang.am, 'አማርኛ', '🇪🇹'),
        _langTile(context, prefs, AppLang.om, 'Afaan Oromoo', '🇪🇹'),
        const SizedBox(height: 12),
        _section(context, s.t('theme')),
        _themeTile(context, prefs, ThemeMode.system, 'System default', Icons.brightness_auto_rounded),
        _themeTile(context, prefs, ThemeMode.light, 'Light', Icons.light_mode_rounded),
        _themeTile(context, prefs, ThemeMode.dark, 'Dark', Icons.dark_mode_rounded),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Text('Changes apply instantly across the app.',
              style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6), fontSize: 12)),
        ),
      ]),
    );
  }

  Widget _section(BuildContext context, String title) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
    child: Text(title.toUpperCase(),
        style: TextStyle(letterSpacing: 1.1, fontWeight: FontWeight.w800, fontSize: 11,
            color: primary)),
  );

  Widget _langTile(BuildContext context, Preferences prefs, AppLang l, String label, String flag) {
    final selected = prefs.lang == l;
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 22)),
      title: Text(label, style: TextStyle(fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
      trailing: selected ? Icon(Icons.check_circle_rounded, color: primary) : null,
      onTap: () => prefs.setLang(l),
    );
  }

  Widget _themeTile(BuildContext context, Preferences prefs, ThemeMode m, String label, IconData icon) {
    final selected = prefs.themeMode == m;
    return ListTile(
      leading: Icon(icon, color: selected ? primary : null),
      title: Text(label, style: TextStyle(fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
      trailing: selected ? Icon(Icons.check_circle_rounded, color: primary) : null,
      onTap: () => prefs.setThemeMode(m),
    );
  }
}
