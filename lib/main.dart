import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'services/auth_service.dart';
import 'services/sound_service.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final store = await StorageService.create();
  await AuthService.init();
  await SoundService.instance.init(sfx: store.getBool('sf.sound', true), music: store.getBool('sf.music', true));
  runApp(StudyFloraApp(store: store));
}
