import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:yichalal_core/yichalal_core.dart';

import 'screens/auth_screen.dart';
import 'screens/mechanic_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor: Colors.transparent));
  await Repo.instance.init();
  final auth = Auth();
  await auth.bootstrap();
  await Notify.init();
  if (auth.currentUser != null) await Notify.watchUser(auth.currentUser!.id);
  final healthErr = await Repo.instance.healthCheck();
  runApp(ChangeNotifierProvider.value(value: auth, child: MechanicApp(healthError: healthErr)));
}

class MechanicApp extends StatefulWidget {
  final String? healthError;
  const MechanicApp({super.key, this.healthError});
  @override
  State<MechanicApp> createState() => _MechanicAppState();
}

class _MechanicAppState extends State<MechanicApp> {
  AppLang _lang = AppLang.en;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<Auth>();
    return LangProvider(
      initial: _lang,
      builder: (context, lang, setLang) {
        return MaterialApp(
          title: 'Yichalal — Mechanic',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.system,
          builder: (context, child) =>
              _HealthBanner(error: widget.healthError, child: child ?? const SizedBox()),
          home: KeyedSubtree(
            key: ValueKey('${auth.currentUser?.id ?? 'guest'}-mechanic'),
            child: auth.currentUser == null
                ? const AuthScreen(role: UserRole.mechanic)
                : const MechanicShell(),
          ),
        );
      },
    );
  }
}

class _HealthBanner extends StatelessWidget {
  final String? error;
  final Widget child;
  const _HealthBanner({this.error, required this.child});
  @override
  Widget build(BuildContext context) {
    if (error == null) return child;
    return Material(
      color: Colors.transparent,
      child: Column(children: [
        SafeArea(
          bottom: false,
          child: Container(
            width: double.infinity,
            color: const Color(0xFFE03E2F),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(children: [
              const Icon(Icons.cloud_off_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(error!,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
        ),
        Expanded(child: child),
      ]),
    );
  }
}
