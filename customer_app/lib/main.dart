import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:yichalal_core/yichalal_core.dart';

import 'screens/auth_screen.dart';
import 'screens/customer_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor: Colors.transparent));
  await Repo.instance.init();
  final auth = Auth();
  await auth.bootstrap();
  await Notify.init();
  if (auth.currentUser != null) await Notify.watchUser(auth.currentUser!.id);
  final prefs = Preferences();
  await prefs.load();
  final healthErr = await Repo.instance.healthCheck();
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: auth),
      ChangeNotifierProvider.value(value: prefs),
    ],
    child: CustomerApp(healthError: healthErr),
  ));
}

class CustomerApp extends StatelessWidget {
  final String? healthError;
  const CustomerApp({super.key, this.healthError});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<Auth>();
    final prefs = context.watch<Preferences>();
    return LangProvider(
      lang: prefs.lang,
      child: MaterialApp(
        title: 'Yichalal — Customer',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: prefs.themeMode,
        builder: (context, child) =>
            _HealthBanner(error: healthError, child: child ?? const SizedBox()),
        home: KeyedSubtree(
          key: ValueKey('${auth.currentUser?.id ?? 'guest'}-customer'),
          child: auth.currentUser == null
              ? const AuthScreen(role: UserRole.customer)
              : const CustomerShell(),
        ),
      ),
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
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
        ),
        Expanded(child: child),
      ]),
    );
  }
}
