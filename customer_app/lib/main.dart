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
  runApp(ChangeNotifierProvider.value(value: auth, child: const CustomerApp()));
}

class CustomerApp extends StatefulWidget {
  const CustomerApp({super.key});
  @override
  State<CustomerApp> createState() => _CustomerAppState();
}

class _CustomerAppState extends State<CustomerApp> {
  AppLang _lang = AppLang.en;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<Auth>();
    return LangProvider(
      initial: _lang,
      builder: (context, lang, setLang) {
        return MaterialApp(
          title: 'Yichalal — Customer',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.system,
          home: KeyedSubtree(
            key: ValueKey('${auth.currentUser?.id ?? 'guest'}-customer'),
            child: auth.currentUser == null
                ? const AuthScreen(role: UserRole.customer)
                : const CustomerShell(),
          ),
        );
      },
    );
  }
}
