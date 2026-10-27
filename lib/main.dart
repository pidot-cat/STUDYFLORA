import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'screens/onboarding/splash_screen.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final state = AppState();
  await state.init();
  runApp(ChangeNotifierProvider.value(value: state, child: const StudyFloraApp()));
}

class StudyFloraApp extends StatelessWidget {
  const StudyFloraApp({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = context.select<AppState, bool>((s) => s.darkMode);
    return MaterialApp(
      title: 'StudyFlora',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(false),
      darkTheme: AppTheme.build(true),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      home: const SplashScreen(),
    );
  }
}
