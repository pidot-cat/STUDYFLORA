import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../core/constants/garden_catalog.dart';
import '../core/constants/storage_keys.dart';
import '../models/plant.dart';
import '../models/plant_type.dart';
import '../services/storage_service.dart';
import 'inventory_provider.dart';
import 'user_provider.dart';

enum GardenTool { water, fertilize, shovel }

enum FxKind { water, fertilize, dig, plant, xp }

class GardenFx {
  const GardenFx(this.id, this.pot, this.kind, [this.text = '']);
  final int id;
  final int pot;
  final FxKind kind;
  final String text;
}

enum GardenResult {
  ok,
  emptyPot,
  occupied,
  alreadyWatered,
  alreadyFertilized,
  alreadyGrown,
  notReady,
  noWater,
  noFertilizer,
  noShovel,
  noCoins,
}

/// Pots, plants, tools and the Watering Can charges.
class GardenProvider extends ChangeNotifier {
  GardenProvider(this._s, this._user, this._inv) {
    _load();
    _refreshCharges(DateTime.now());
    _selected = defaultSelection(DateTime.now());
    _ticker = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_pots.any((p) => p != null)) notifyListeners();
    });
  }

  final StorageService _s;
  final UserProvider _user;
  final InventoryProvider _inv;

  late final List<Plant?> _pots;
  int? _selected;
  GardenTool tool = GardenTool.water;
  Timer? _ticker;

  int _charges = GardenCatalog.chargesPerCan;
  DateTime _chargeAt = DateTime.now();

  GardenFx? lastFx;
  int _fxCounter = 0;

  List<Plant?> get pots => List.unmodifiable(_pots);
  int? get selected => _selected;
  Plant? get selectedPlant => _selected == null ? null : _pots[_selected!];
  int get plantedCount => _pots.where((p) => p != null).length;

  // ---- Watering Can -------------------------------------------------------------

  int get maxCharges =>
      GardenCatalog.chargesPerCan *
      (_inv.count(GardenCatalog.toolWateringCan) < 1
          ? 1
          : _inv.count(GardenCatalog.toolWateringCan));

  int get charges {
    _refreshCharges(DateTime.now());
    return _charges;
  }

  void _refreshCharges(DateTime now) {
    final cap = maxCharges;
    if (_charges >= cap) {
      _charges = cap;
      _chargeAt = now;
      return;
    }
    final regenMs = GardenCatalog.chargeRegen.inMilliseconds;
    final gained = now.difference(_chargeAt).inMilliseconds ~/ regenMs;
    if (gained > 0) {
      _charges = (_charges + gained).clamp(0, cap);
      _chargeAt = _charges >= cap ? now : _chargeAt.add(Duration(milliseconds: gained * regenMs));
    }
  }

  // ---- selection / tool ----------------------------------------------------------

  void setTool(GardenTool t) {
    if (tool == t) return;
    tool = t;
    notifyListeners();
  }

  void select(int? pot) {
    _selected = pot;
    notifyListeners();
  }

  /// First plant that needs attention, else the first plant, else nothing.
  int? defaultSelection(DateTime now) {
    for (var i = 0; i < _pots.length; i++) {
      final p = _pots[i];
      if (p != null && (p.isThirsty(now) || p.needsWaterSoon(now))) return i;
    }
    for (var i = 0; i < _pots.length; i++) {
      if (_pots[i] != null) return i;
    }
    return null;
  }

  /// Plants sorted for the Home dashboard: ready first, then closest to harvest.
  List<MapEntry<int, Plant>> plantEntries(DateTime now) {
    final list = <MapEntry<int, Plant>>[
      for (var i = 0; i < _pots.length; i++)
        if (_pots[i] != null) MapEntry(i, _pots[i]!),
    ];
    list.sort((a, b) {
      final ra = a.value.isReady(now) ? 0 : 1;
      final rb = b.value.isReady(now) ? 0 : 1;
      if (ra != rb) return ra.compareTo(rb);
      return a.value.untilReady(now).compareTo(b.value.untilReady(now));
    });
    return list;
  }

  /// The plant most in need of water right now (thirsty first).
  MapEntry<int, Plant>? thirstiest(DateTime now) {
    MapEntry<int, Plant>? best;
    for (var i = 0; i < _pots.length; i++) {
      final p = _pots[i];
      if (p == null || p.isReady(now)) continue;
      final h = p.hydrationAt(now);
      if (h > 0.25) continue;
      if (best == null || h < best.value.hydrationAt(now)) best = MapEntry(i, p);
    }
    return best;
  }

  // ---- actions ----------------------------------------------------------------------

  GardenResult plant(int pot, PlantType type, {required bool buyIfNeeded}) {
    if (_pots[pot] != null) return GardenResult.occupied;
    if (_inv.count(type.seedId) > 0) {
      _inv.consume(type.seedId);
    } else if (buyIfNeeded) {
      if (!_user.spendCoins(type.seedPrice)) return GardenResult.noCoins;
    } else {
      return GardenResult.noCoins;
    }
    _pots[pot] = Plant.sow(type, DateTime.now());
    _selected = pot;
    _emit(pot, FxKind.plant);
    _save();
    notifyListeners();
    return GardenResult.ok;
  }

  GardenResult water(int pot) {
    final now = DateTime.now();
    final plant = _pots[pot];
    if (plant == null) return GardenResult.emptyPot;
    if (plant.isReady(now)) return GardenResult.alreadyGrown;
    if (plant.hydrationAt(now) > 0.9) return GardenResult.alreadyWatered;
    _refreshCharges(now);
    if (_charges <= 0) return GardenResult.noWater;

    plant.settle(now);
    plant.wetUntil = now.add(GardenCatalog.waterWindow);
    if (_charges >= maxCharges) _chargeAt = now; // regen clock starts on first use
    _charges--;
    _emit(pot, FxKind.water);
    _save();
    notifyListeners();
    return GardenResult.ok;
  }

  GardenResult fertilize(int pot) {
    final now = DateTime.now();
    final plant = _pots[pot];
    if (plant == null) return GardenResult.emptyPot;
    if (plant.isReady(now)) return GardenResult.alreadyGrown;
    if (plant.fertilized) return GardenResult.alreadyFertilized;
    if (!_inv.consume(GardenCatalog.toolFertilizer)) return GardenResult.noFertilizer;

    plant.settle(now);
    plant.fertilized = true;
    _emit(pot, FxKind.fertilize);
    _save();
    notifyListeners();
    return GardenResult.ok;
  }

  GardenResult dig(int pot) {
    if (_pots[pot] == null) return GardenResult.emptyPot;
    if (!_inv.consume(GardenCatalog.toolShovel)) return GardenResult.noShovel;
    _pots[pot] = null;
    _emit(pot, FxKind.dig);
    _save();
    notifyListeners();
    return GardenResult.ok;
  }

  /// Converts a fully grown plant to border XP. Returns the XP, or 0.
  int claim(int pot) {
    final now = DateTime.now();
    final plant = _pots[pot];
    if (plant == null || !plant.isReady(now)) return 0;
    final xp = plant.type.xp;
    _user.addXp(xp);
    _pots[pot] = null;
    _emit(pot, FxKind.xp, '+$xp XP');
    _save();
    notifyListeners();
    return xp;
  }

  /// Water the thirstiest plant (Home dashboard shortcut).
  GardenResult waterThirstiest() {
    final t = thirstiest(DateTime.now());
    if (t == null) return GardenResult.alreadyWatered;
    return water(t.key);
  }

  // ---- internals -----------------------------------------------------------------------

  void _emit(int pot, FxKind kind, [String text = '']) {
    lastFx = GardenFx(++_fxCounter, pot, kind, text);
  }

  void _load() {
    _pots = List<Plant?>.filled(GardenCatalog.potCount, null);
    final raw = _s.getStringList(StorageKeys.gardenPots) ?? const [];
    for (final entry in raw) {
      try {
        final m = jsonDecode(entry) as Map<String, dynamic>;
        final i = m['i'] as int;
        if (i >= 0 && i < _pots.length) {
          _pots[i] = Plant.fromJson(m['plant'] as Map<String, dynamic>);
        }
      } catch (_) {/* skip corrupt entry */}
    }
    _charges = _s.getInt(StorageKeys.gardenCharges, GardenCatalog.chargesPerCan);
    final at = _s.getString(StorageKeys.gardenChargeAt, '');
    _chargeAt = at.isEmpty ? DateTime.now() : (DateTime.tryParse(at) ?? DateTime.now());
  }

  void _save() {
    final out = <String>[];
    for (var i = 0; i < _pots.length; i++) {
      final p = _pots[i];
      if (p != null) out.add(jsonEncode({'i': i, 'plant': p.toJson()}));
    }
    _s.setStringList(StorageKeys.gardenPots, out);
    _s.setInt(StorageKeys.gardenCharges, _charges);
    _s.setString(StorageKeys.gardenChargeAt, _chargeAt.toIso8601String());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
