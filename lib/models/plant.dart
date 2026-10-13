import '../core/constants/garden_catalog.dart';
import 'plant_type.dart';

/// A plant growing in one pot. Growth is computed from timestamps, so it
/// keeps "running" while the app is closed and never needs a background task.
///
/// Rules:
///  * progress goes 0 -> 1 and only advances while the plant is hydrated
///  * a watering keeps it hydrated for [GardenCatalog.waterWindow]
///  * fertilizer doubles the growth speed (6h -> 3h)
class Plant {
  Plant({
    required this.typeId,
    required this.plantedAt,
    required this.progress,
    required this.lastUpdate,
    required this.wetUntil,
    this.fertilized = false,
  });

  /// A fresh seed: starts hydrated.
  factory Plant.sow(PlantType type, DateTime now) => Plant(
        typeId: type.id,
        plantedAt: now,
        progress: 0,
        lastUpdate: now,
        wetUntil: now.add(GardenCatalog.waterWindow),
      );

  final String typeId;
  final DateTime plantedAt;
  double progress;
  DateTime lastUpdate;
  DateTime wetUntil;
  bool fertilized;

  PlantType get type => GardenCatalog.byId(typeId);

  static final double _baseMs = GardenCatalog.growthDuration.inMilliseconds.toDouble();

  double get _ratePerMs =>
      (fertilized ? GardenCatalog.fertilizerBoost : 1.0) / _baseMs;

  /// Progress (0..1) as of [now], counting only hydrated time.
  double progressAt(DateTime now) {
    if (progress >= 1) return 1;
    if (!now.isAfter(lastUpdate)) return progress;
    final end = now.isBefore(wetUntil) ? now : wetUntil;
    final wetMs = end.isAfter(lastUpdate) ? end.difference(lastUpdate).inMilliseconds : 0;
    return (progress + wetMs * _ratePerMs).clamp(0.0, 1.0);
  }

  /// Locks in the current progress so rates/hydration can change safely.
  void settle(DateTime now) {
    progress = progressAt(now);
    lastUpdate = now;
  }

  bool isReady(DateTime now) => progressAt(now) >= 1;

  /// 0..1 moisture. Drains linearly over [GardenCatalog.waterWindow].
  double hydrationAt(DateTime now) {
    if (!now.isBefore(wetUntil)) return 0;
    return wetUntil.difference(now).inMilliseconds /
        GardenCatalog.waterWindow.inMilliseconds;
  }

  bool isThirsty(DateTime now) => !isReady(now) && hydrationAt(now) <= 0;

  bool needsWaterSoon(DateTime now) {
    if (isReady(now)) return false;
    final h = hydrationAt(now);
    return h > 0 && h <= 0.25;
  }

  /// 1, 2 or 3 while growing (seed, young, blooming); 3 also covers "ready".
  int stageAt(DateTime now) {
    final p = progressAt(now);
    if (p < 1 / 3) return 1;
    if (p < 2 / 3) return 2;
    return 3;
  }

  /// Time until the next stage, assuming the plant stays watered.
  Duration untilNextStage(DateTime now) {
    final p = progressAt(now);
    if (p >= 1) return Duration.zero;
    final stage = stageAt(now);
    final boundary = stage == 3 ? 1.0 : stage / 3;
    return _toDuration((boundary - p) / _ratePerMs);
  }

  /// Time until harvest, assuming the plant stays watered.
  Duration untilReady(DateTime now) {
    final p = progressAt(now);
    if (p >= 1) return Duration.zero;
    return _toDuration((1 - p) / _ratePerMs);
  }

  static Duration _toDuration(double ms) =>
      Duration(milliseconds: ms.isFinite ? ms.round() : 0);

  Map<String, dynamic> toJson() => {
        't': typeId,
        'pa': plantedAt.toIso8601String(),
        'p': progress,
        'lu': lastUpdate.toIso8601String(),
        'wu': wetUntil.toIso8601String(),
        'f': fertilized,
      };

  factory Plant.fromJson(Map<String, dynamic> j) => Plant(
        typeId: j['t'] as String,
        plantedAt: DateTime.parse(j['pa'] as String),
        progress: (j['p'] as num).toDouble(),
        lastUpdate: DateTime.parse(j['lu'] as String),
        wetUntil: DateTime.parse(j['wu'] as String),
        fertilized: j['f'] as bool? ?? false,
      );
}
