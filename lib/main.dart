import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/garden_provider.dart';
import 'providers/inventory_provider.dart';
import 'providers/nav_provider.dart';
import 'providers/study_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/user_provider.dart';
import 'screens/main_shell.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final storage = await StorageService.init();
  runApp(StudyFloraApp(storage: storage));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final Future<StorageService> _storageFuture;

  @override
  void initState() {
    super.initState();
    _storageFuture = StorageService.init();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StorageService>(
      future: _storageFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        return StudyFloraApp(storage: snapshot.data!);
      },
    );
  }
}

class StudyFloraApp extends StatelessWidget {
  const StudyFloraApp({super.key, required this.storage});

  final StorageService storage;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(storage)),
        ChangeNotifierProvider(create: (_) => UserProvider(storage)),
        ChangeNotifierProvider(
            create: (c) => InventoryProvider(storage, c.read<UserProvider>())),
        ChangeNotifierProvider(
            create: (c) => GardenProvider(
                storage, c.read<UserProvider>(), c.read<InventoryProvider>())),
        ChangeNotifierProvider(
            create: (c) => StudyProvider(storage, c.read<UserProvider>())),
        ChangeNotifierProvider(create: (_) => NavProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (_, theme, __) => MaterialApp(
          title: 'StudyFlora',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: theme.mode,
          home: const MainShell(),
        ),
      ),
    );
  }
}
