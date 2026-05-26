import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:yichalal_core/yichalal_core.dart';

import 'screens/mechanic_shell.dart';

// Reuse the customer auth screen — it already handles mechanic role.
import 'package:yichalal_mechanic/screens/auth_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor: Colors.transparent));
  await Repo.instance.init();
  final auth = Auth();
  await auth.bootstrap();
  await Notify.init();
  if (auth.currentUser != null) await Notify.watchUser(auth.currentUser!.id);
  runApp(ChangeNotifierProvider.value(value: auth, child: const MechanicApp()));
}

class MechanicApp extends StatelessWidget {
  const MechanicApp({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<Auth>();
    return LangProvider(
      initial: AppLang.en,
      builder: (_, __, ___) => MaterialApp(
        title: 'Yichalal — Mechanic',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(primary: AppColors.mintDark),
        darkTheme: AppTheme.dark(primary: AppColors.mintDark),
        themeMode: ThemeMode.system,
        home: KeyedSubtree(
          key: ValueKey('${auth.currentUser?.id ?? 'guest'}-mechanic'),
          child: auth.currentUser == null ? const AuthScreen(role: UserRole.mechanic) : const MechanicShell(),
        ),
      ),
    );
  }
}
