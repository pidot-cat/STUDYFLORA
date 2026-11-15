import 'dart:math' as math;

import '../core/constants.dart';
import 'flower.dart';

enum PlantStage { empty, seed, sprout, bloom }

/// One of the 18 garden pots. The pot keeps its number ("Pot 4") and moves
/// together with its plant when the user drags it to another spot.
///
/// Growth is stored as "base growth already done" plus the timestamp of the
/// last settlement, so progress can be recomputed after the app was closed
/// (FR-4.3, NFR 4.3) and the fertilizer rule never makes the % jump.
class Pot {
  final int number; // 1..18, stays with the pot
  String? flowerId;
  int plantedAt; // ms
  double growthMs; // base growth completed, 0..growDuration
  int settledAt; // ms of last settlement
  int hydratedUntil; // ms; growth only happens before this
  bool fertilized;
  int fertilizedAt;

  Pot({
    required this.number,
    this.flowerId,
    this.plantedAt = 0,
    this.growthMs = 0,
    this.settledAt = 0,
    this.hydratedUntil = 0,
    this.fertilized = false,
    this.fertilizedAt = 0,
  });

  bool get isEmpty => flowerId == null;
  Flower? get flower => flowerId == null ? null : Flower.of(flowerId!);
  double get speed => fertilized ? GameRules.fertilizerMultiplier : 1.0;
  static double get _total => GameRules.growDuration.inMilliseconds.toDouble();

  /// Pure: growth that would be done at [now] without mutating.
  double growthAt(int now) {
    if (isEmpty) return 0;
    final end = math.min(now, hydratedUntil);
    final wetMs = math.max(0, end - settledAt);
    return math.min(_total, growthMs + wetMs * speed);
  }

  /// Bake elapsed growth into the stored value (call before changing speed or water).
  void settle(int now) {
    if (isEmpty) return;
    growthMs = growthAt(now);
    settledAt = now;
  }

  double progressAt(int now) => isEmpty ? 0 : (growthAt(now) / _total).clamp(0.0, 1.0);

  bool isReadyAt(int now) => !isEmpty && progressAt(now) >= 1.0;

  bool isHydratedAt(int now) => hydratedUntil > now;

  /// 0..1 where 1 = at least one full watering (2 h) left.
  double hydrationAt(int now) {
    final left = math.max(0, hydratedUntil - now);
    return (left / GameRules.waterGives.inMilliseconds).clamp(0.0, 1.0);
  }

  Duration hydrationLeftAt(int now) => Duration(milliseconds: math.max(0, hydratedUntil - now));

  /// Hydrated time still needed to finish (real time, at current speed).
  Duration remainingAt(int now) {
    final left = _total - growthAt(now);
    return Duration(milliseconds: (left / speed).ceil());
  }

  PlantStage stageAt(int now) {
    if (isEmpty) return PlantStage.empty;
    final p = progressAt(now);
    if (p >= 1) return PlantStage.bloom;
    if (p >= GameRules.sproutAt) return PlantStage.sprout;
    return PlantStage.seed;
  }

  /// Growth paused because it ran out of water (FR-4.5).
  bool isWiltedAt(int now) => !isEmpty && !isReadyAt(now) && !isHydratedAt(now) && growthAt(now) > 0;

  bool needsWaterAt(int now) => !isEmpty && !isReadyAt(now) && !isHydratedAt(now);

  String imageAt(int now) {
    final f = flower;
    if (f == null) return 'assets/plants/pot_empty.webp';
    switch (stageAt(now)) {
      case PlantStage.bloom:
        return f.bloomAsset;
      case PlantStage.sprout:
        return isHydratedAt(now) ? f.sproutAsset : f.wiltedAsset;
      case PlantStage.seed:
      case PlantStage.empty:
        return f.seedAsset;
    }
  }

  void plant(String id, int now) {
    flowerId = id;
    plantedAt = now;
    growthMs = 0;
    settledAt = now;
    hydratedUntil = now; // starts dry: the user waters to begin growth
    fertilized = false;
    fertilizedAt = 0;
  }

  void clear() {
    flowerId = null;
    plantedAt = 0;
    growthMs = 0;
    settledAt = 0;
    hydratedUntil = 0;
    fertilized = false;
    fertilizedAt = 0;
  }

  void water(int now) {
    settle(now);
    final base = math.max(now, hydratedUntil);
    final cap = now + GameRules.maxHydration.inMilliseconds;
    hydratedUntil = math.min(base + GameRules.waterGives.inMilliseconds, cap);
  }

  bool canWater(int now) =>
      !isEmpty && !isReadyAt(now) && hydratedUntil - now < GameRules.maxHydration.inMilliseconds - 60000;

  /// FR-4.6: from now on growth runs at 2×, i.e. remaining time is halved,
  /// while the displayed % stays where it is.
  void fertilize(int now) {
    settle(now);
    fertilized = true;
    fertilizedAt = now;
  }

  Map<String, dynamic> toJson() => {
        'n': number,
        'f': flowerId,
        'pa': plantedAt,
        'g': growthMs,
        'sa': settledAt,
        'hu': hydratedUntil,
        'fz': fertilized,
        'fa': fertilizedAt,
      };

  factory Pot.fromJson(Map<String, dynamic> j) => Pot(
        number: j['n'] as int,
        flowerId: j['f'] as String?,
        plantedAt: (j['pa'] ?? 0) as int,
        growthMs: ((j['g'] ?? 0) as num).toDouble(),
        settledAt: (j['sa'] ?? 0) as int,
        hydratedUntil: (j['hu'] ?? 0) as int,
        fertilized: (j['fz'] ?? false) as bool,
        fertilizedAt: (j['fa'] ?? 0) as int,
      );
}
