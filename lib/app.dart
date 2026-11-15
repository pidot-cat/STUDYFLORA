import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/feedback_bus.dart';
import 'providers/game_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/study_provider.dart';
import 'providers/sync_provider.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/shell.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/sound_service.dart';
import 'services/storage_service.dart';
import 'services/sync_service.dart';
import 'widgets/network_banner.dart';

class StudyFloraApp extends StatefulWidget {
  const StudyFloraApp({super.key, required this.store});
  final StorageService store;

  @override
  State<StudyFloraApp> createState() => _StudyFloraAppState();
}

class _StudyFloraAppState extends State<StudyFloraApp> with WidgetsBindingObserver {
  late final GameProvider game = GameProvider(widget.store);
  late final StudyProvider study = StudyProvider(widget.store, game);
  late final SyncProvider sync = SyncProvider(widget.store, game, study, SyncService());
  late final AuthProvider auth = AuthProvider(AuthService(widget.store), game, study, sync);
  late final SettingsProvider settings = SettingsProvider(widget.store);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Pause the garden music whenever the app leaves the screen.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    SoundService.instance.setAppVisible(state == AppLifecycleState.resumed);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: game),
        ChangeNotifierProvider.value(value: study),
        ChangeNotifierProvider.value(value: sync),
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(create: (_) => ClockTicker()),
        ChangeNotifierProvider(create: (_) => NavState()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, s, _) {
          // Transparent status bar so the app background shows behind it (no white strip).
          SystemChrome.setSystemUIOverlayStyle((s.darkMode ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
              .copyWith(statusBarColor: Colors.transparent));
          return MaterialApp(
            title: 'Study Flora',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.build(Brightness.light),
            darkTheme: AppTheme.build(Brightness.dark),
            themeMode: s.themeMode,
            themeAnimationDuration: const Duration(milliseconds: 350),
            // Respect the phone's font size, but cap it so fixed-size cards
            // never overflow on "Largest" accessibility settings.
            builder: (context, child) {
              final mq = MediaQuery.of(context);
              return MediaQuery(
                data: mq.copyWith(textScaler: mq.textScaler.clamp(minScaleFactor: 0.9, maxScaleFactor: 1.15)),
                child: NetworkBanner(child: child!),
              );
            },
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}

/// After the splash/onboarding: signed in → app shell, otherwise → sign in.
class RootGate extends StatelessWidget {
  const RootGate({super.key});
  @override
  Widget build(BuildContext context) {
    final signedIn = context.select<AuthProvider, bool>((a) => a.signedIn);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      child: signedIn ? const AppShell(key: ValueKey('shell')) : const SignInScreen(key: ValueKey('signin')),
    );
  }
}
