import 'dart:async';

import 'package:flutter/material.dart';

import '../services/sound_service.dart';

enum RewardKind { coins, xp, seed, water, tool, info, badge }

class RewardEvent {
  final String text;
  final RewardKind kind;
  const RewardEvent(this.text, this.kind);
}

/// Mirrors the Settings toggles so low-level widgets can read them cheaply.
class FeedbackPrefs {
  static bool sound = true; // tap click + haptics
  static bool alerts = true; // floating reward / achievement pop-ups
}

/// While > 0, "Achievement unlocked" pop-ups wait (e.g. during the upload
/// dialog and its report sheet) so they never cover or close another dialog.
final celebrationHold = ValueNotifier<int>(0);

/// Fire-and-forget channel for floating "+20 coins" style feedback (FR-4.10).
/// The app shell listens and animates them over every screen.
class FeedbackBus {
  FeedbackBus._();
  static final instance = FeedbackBus._();
  final _ctrl = StreamController<RewardEvent>.broadcast();
  Stream<RewardEvent> get stream => _ctrl.stream;
  void emit(String text, RewardKind kind) {
    final sfx = switch (kind) {
      RewardKind.coins => Sfx.coin,
      RewardKind.xp => Sfx.harvest,
      RewardKind.seed => Sfx.plant,
      RewardKind.water => Sfx.water,
      RewardKind.tool => Sfx.success,
      RewardKind.badge => Sfx.badge,
      RewardKind.info => null,
    };
    if (sfx != null) SoundService.instance.play(sfx);
    if (FeedbackPrefs.alerts) _ctrl.add(RewardEvent(text, kind));
  }
}

/// One-second heartbeat used by widgets that show live timers.
class ClockTicker extends ChangeNotifier {
  ClockTicker() {
    _t = Timer.periodic(const Duration(seconds: 1), (_) => notifyListeners());
  }
  late final Timer _t;
  @override
  void dispose() {
    _t.cancel();
    super.dispose();
  }
}
