import 'dart:io';
import 'dart:math';
import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../core/constants.dart';
import '../providers/game_provider.dart';

/// Garden reminders that show up even when the app is closed (Android
/// scheduled notifications). They are scheduled when the user leaves the app
/// and cleared again when the app is opened, so nothing pops up while the
/// user is already looking at the garden.
///
/// Reminders:
///  • a plant ran out of water (growth paused)
///  • a plant is ready to harvest
///  • the watering can is full again
///  • "come back" nudges after 1 and 3 days away
class GardenNotifications {
  GardenNotifications._();
  static final instance = GardenNotifications._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  bool _exact = false; // exact alarms allowed → reminders arrive on time

  static const _channel = AndroidNotificationDetails(
    'garden_reminders',
    'Garden reminders',
    channelDescription: 'Water, harvest and watering-can reminders for your StudyFlora garden.',
    importance: Importance.high,
    priority: Priority.high,
    icon: 'ic_stat_flora',
    color: Color(0xFF2F7D57),
  );
  static const _details = NotificationDetails(android: _channel);

  // Notification ids (fixed so a new schedule replaces the old one).
  static const _idThirstyNow = 10;
  static const _idReadyNow = 11;
  static const _idCanFull = 12;
  static const _idMiss1 = 13;
  static const _idMiss3 = 14;
  static int _idPot(int n) => 100 + n; // one per pot

  bool get _supported => !kIsWeb && Platform.isAndroid;

  Future<void> _init() async {
    if (_ready || !_supported) return;
    try {
      await _plugin.initialize(
        const InitializationSettings(android: AndroidInitializationSettings('ic_stat_flora')),
      );
      _ready = true;
      _exact = await _plugin
              .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
              ?.canScheduleExactNotifications() ??
          false;
    } catch (e) {
      debugPrint('Notifications unavailable: $e');
    }
  }

  /// Android 13+ asks the user once for permission to show notifications.
  Future<void> requestPermission() async {
    await _init();
    if (!_ready) return;
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (_) {}
  }

  /// Clears every scheduled and shown garden reminder.
  Future<void> cancelAll() async {
    await _init();
    if (!_ready) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }

  /// Plans the reminders for the current garden. Call when the app goes to
  /// the background.
  Future<void> schedule(GameProvider game, {required bool enabled}) async {
    await _init();
    if (!_ready) return;
    await cancelAll();
    if (!enabled || !game.loaded) return;

    final now = GameClock.nowMs(); // game time (includes the demo time skip)
    final realNow = DateTime.now();
    // Game time → real wall-clock time.
    DateTime real(int gameMs) => DateTime.fromMillisecondsSinceEpoch(gameMs).subtract(GameClock.offset);

    final thirstyNow = <String>[];
    final readyNow = <String>[];
    var growing = 0;

    for (final p in game.pots) {
      if (p.isEmpty) continue;
      final name = p.flower?.name ?? 'plant';
      if (p.isReadyAt(now)) {
        readyNow.add(name);
        continue;
      }
      growing++;
      if (p.needsWaterAt(now)) {
        thirstyNow.add(name);
        continue;
      }
      // Hydrated and growing: it either finishes before the water runs out,
      // or it gets thirsty first.
      final readyAt = now + p.remainingAt(now).inMilliseconds;
      if (readyAt <= p.hydratedUntil) {
        await _at(_idPot(p.number), real(readyAt), '🌸 Your $name is ready to harvest!',
            'Pot ${p.number} is fully grown. Open StudyFlora to harvest it and earn rewards.');
      } else {
        await _at(_idPot(p.number), real(p.hydratedUntil), '💧 Your $name needs water',
            'Pot ${p.number} ran out of water, so it stopped growing. Water it to keep it growing.');
      }
    }

    // Plants that were already thirsty / ready when the user left.
    if (thirstyNow.isNotEmpty) {
      await _at(
        _idThirstyNow,
        realNow.add(const Duration(hours: 1)),
        thirstyNow.length == 1 ? '💧 Your ${thirstyNow.first} is thirsty' : '💧 ${thirstyNow.length} plants are thirsty',
        'Their growth is paused until you water them. Your garden is waiting!',
      );
    }
    if (readyNow.isNotEmpty) {
      await _at(
        _idReadyNow,
        realNow.add(const Duration(hours: 1)),
        readyNow.length == 1
            ? '🌸 Your ${readyNow.first} is ready to harvest!'
            : '🌸 ${readyNow.length} plants are ready to harvest!',
        'Harvest them in the Garden to collect your rewards.',
      );
    }

    // Watering can refilled (only useful while something is growing).
    final charges = game.chargesAt(now);
    if (growing > 0 && charges < GameRules.baseWaterCharges) {
      final missing = GameRules.baseWaterCharges - charges;
      final fullIn = game.nextChargeIn(now) + GameRules.chargeRestore * max(0, missing - 1);
      await _at(_idCanFull, realNow.add(fullIn), '🚿 Your watering can is full again',
          'You have ${GameRules.baseWaterCharges} waterings ready. Keep your plants growing!');
    }

    // Come-back nudges.
    await _at(_idMiss1, realNow.add(const Duration(days: 1)), '🌱 Your garden misses you',
        'Study a module, take a quiz and earn coins for new seeds.');
    await _at(_idMiss3, realNow.add(const Duration(days: 3)), '📚 Time for a quick study session?',
        'Your plants and your quizzes are waiting. A few minutes today keeps your streak going.');
  }

  Future<void> _at(int id, DateTime when, String title, String body) async {
    if (!when.isAfter(DateTime.now().add(const Duration(seconds: 30)))) return;
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(when.toUtc(), tz.UTC),
        _details,
        androidScheduleMode: _exact ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('Could not schedule reminder $id: $e');
    }
  }
}
