import 'package:flutter/material.dart';

import '../services/storage_service.dart';
import '../services/sound_service.dart';
import 'feedback_bus.dart';

/// Device-level preferences (FR-5.3, FR-5.4).
class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._store)
      : darkMode = _store.getBool('sf.dark'),
        music = _store.getBool('sf.music', true),
        sound = _store.getBool('sf.sound', true),
        notifications = _store.getBool('sf.notif', true),
        onboardingSeen = _store.getBool('sf.onboarded'),
        returningUser = _store.getBool('sf.returning'),
        gardenTipSeen = _store.getBool('sf.gardenTip') {
    FeedbackPrefs.sound = sound;
    FeedbackPrefs.alerts = notifications;
  }

  final StorageService _store;
  bool darkMode;
  bool music;
  bool sound;
  bool notifications;
  bool onboardingSeen;
  bool returningUser; // has logged in on this phone before → "Welcome back"
  bool gardenTipSeen; // first-time garden guide dismissed

  void markReturning() {
    if (returningUser) return;
    returningUser = true;
    _store.setBool('sf.returning', true);
    notifyListeners();
  }

  void dismissGardenTip() {
    gardenTipSeen = true;
    _store.setBool('sf.gardenTip', true);
    notifyListeners();
  }

  ThemeMode get themeMode => darkMode ? ThemeMode.dark : ThemeMode.light;

  void setDark(bool v) {
    darkMode = v;
    _store.setBool('sf.dark', v);
    notifyListeners();
  }

  void setMusic(bool v) {
    music = v;
    SoundService.instance.setMusic(v);
    _store.setBool('sf.music', v);
    notifyListeners();
  }

  void setSound(bool v) {
    sound = v;
    FeedbackPrefs.sound = v;
    SoundService.instance.setSfx(v);
    _store.setBool('sf.sound', v);
    notifyListeners();
  }

  void setNotifications(bool v) {
    notifications = v;
    FeedbackPrefs.alerts = v;
    _store.setBool('sf.notif', v);
    notifyListeners();
  }

  void finishOnboarding() {
    onboardingSeen = true;
    _store.setBool('sf.onboarded', true);
    notifyListeners();
  }
}
