import 'dart:math';

import 'package:flutter/foundation.dart';

import '../core/constants.dart';
import '../models/cosmetics.dart';
import '../models/flower.dart';
import '../models/pot.dart';
import '../services/storage_service.dart';
import 'feedback_bus.dart';

class ActionResult {
  final bool ok;
  final String message;
  const ActionResult(this.ok, this.message);
  static const done = ActionResult(true, '');
}

/// Coins, XP, inventory, garden, cosmetics and badges for the signed-in user.
/// Every change is saved immediately (NFR 4.3) and reported to the sync queue.
class GameProvider extends ChangeNotifier {
  GameProvider(this._store);
  final StorageService _store;

  /// Hooked up by SyncProvider: called after every saved change.
  VoidCallback? onChanged;

  String? _uid;
  bool get loaded => _uid != null;

  // ---- economy
  int coins = GameRules.startCoins;
  int xp = GameRules.startXp;
  int lifetimeXp = 0;

  // ---- inventory
  Map<String, int> seeds = {};
  int fertilizers = 0;
  int shovels = 0;
  int waterCharges = GameRules.baseWaterCharges;
  int lastChargeAt = 0;

  // ---- garden (list order = position on the table)
  List<Pot> pots = [];

  // ---- profile cosmetics
  String avatarId = 'bear';
  Set<String> ownedBorders = {'starter'};
  String equippedBorder = BorderDef.noneId;
  Map<String, bool> badges = {}; // id -> reward claimed?
  String? showcaseBadge = 'b_sprout';

  // ---- stats for achievements
  int planted = 0, harvests = 0, waterings = 0, verifiedUploads = 0, quizzesDone = 0, perfectQuizzes = 0, mastered = 0;
  Set<String> harvestedKinds = {};

  /// Days the app was used (local date "yyyy-mm-dd") — powers the Home calendar
  /// and study streak.
  Set<String> activeDays = {};

  // ---- gifts
  /// New accounts claim their 150 welcome coins from a celebration screen.
  bool welcomePending = false;

  /// Day ("yyyy-mm-dd") the daily free flower was last claimed.
  String? dailyGiftDay;

  int updatedAt = 0;

  /// Newly unlocked achievements waiting for a celebration dialog.
  final List<String> celebrations = [];

  // ===========================================================================
  // Load / save
  // ===========================================================================
  Future<void> load(String uid) async {
    _uid = uid;
    final j = _store.readJson(StorageService.gameKey(uid));
    if (j == null) {
      _reset();
      await _save(silent: true);
    } else {
      applyJson(j);
    }
    _markActiveToday();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Activity / streak (Home calendar)
  // ---------------------------------------------------------------------------
  static String dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool isActiveOn(DateTime d) => activeDays.contains(dayKey(d));

  void _markActiveToday() {
    final k = dayKey(DateTime.now());
    if (activeDays.add(k)) _save(silent: true);
  }

  /// Consecutive active days ending today (or yesterday, if not opened yet today).
  int get streak {
    var d = DateTime.now();
    if (!isActiveOn(d)) d = d.subtract(const Duration(days: 1));
    var n = 0;
    while (isActiveOn(d)) {
      n++;
      d = d.subtract(const Duration(days: 1));
    }
    return n;
  }

  /// Most recent active day before today (null if none).
  DateTime? get lastActiveBeforeToday {
    final today = dayKey(DateTime.now());
    final past = activeDays.where((k) => k.compareTo(today) < 0).toList()..sort();
    if (past.isEmpty) return null;
    return DateTime.tryParse(past.last);
  }

  void unload() {
    _uid = null;
    _reset();
    notifyListeners();
  }

  void _reset() {
    coins = GameRules.startCoins;
    xp = GameRules.startXp;
    lifetimeXp = 0;
    seeds = {'sunflower': 2, 'tulip': 1, 'daisy': 1};
    fertilizers = 1;
    shovels = 1;
    waterCharges = GameRules.baseWaterCharges;
    lastChargeAt = GameClock.nowMs();
    pots = List.generate(GameRules.potCount, (i) => Pot(number: i + 1));
    avatarId = 'bear';
    // The free Verdant Sprout border is claimed in the Shop (red dot until then).
    ownedBorders = {};
    equippedBorder = BorderDef.noneId; // plain avatar until the user picks a border
    badges = {};
    showcaseBadge = null;
    welcomePending = true;
    dailyGiftDay = null;
    planted = harvests = waterings = verifiedUploads = quizzesDone = perfectQuizzes = mastered = 0;
    harvestedKinds = {};
    activeDays = {};
    updatedAt = GameClock.nowMs();
    celebrations.clear();
    GameClock.offset = Duration.zero; // never carry a demo time-skip into another account
  }

  Map<String, dynamic> toJson() => {
        'coins': coins,
        'xp': xp,
        'lifetimeXp': lifetimeXp,
        'seeds': seeds,
        'fertilizers': fertilizers,
        'shovels': shovels,
        'waterCharges': waterCharges,
        'lastChargeAt': lastChargeAt,
        'pots': pots.map((p) => p.toJson()).toList(),
        'avatarId': avatarId,
        'ownedBorders': ownedBorders.toList(),
        'equippedBorder': equippedBorder,
        'badges': badges,
        'showcaseBadge': showcaseBadge,
        'stats': {
          'planted': planted,
          'harvests': harvests,
          'waterings': waterings,
          'verifiedUploads': verifiedUploads,
          'quizzesDone': quizzesDone,
          'perfectQuizzes': perfectQuizzes,
          'mastered': mastered,
          'harvestedKinds': harvestedKinds.toList(),
        },
        'activeDays': activeDays.toList(),
        'welcomePending': welcomePending,
        'dailyGiftDay': dailyGiftDay,
        'freeBorderClaimable': true, // saves from before: the free border was owned automatically
        'timeOffsetMs': GameClock.offset.inMilliseconds,
        'updatedAt': updatedAt,
      };

  void applyJson(Map<String, dynamic> j) {
    coins = (j['coins'] ?? GameRules.startCoins) as int;
    xp = (j['xp'] ?? 0) as int;
    lifetimeXp = (j['lifetimeXp'] ?? xp) as int;
    seeds = Map<String, int>.from((j['seeds'] ?? const {}) as Map);
    fertilizers = (j['fertilizers'] ?? 0) as int;
    shovels = (j['shovels'] ?? 0) as int;
    waterCharges = (j['waterCharges'] ?? GameRules.baseWaterCharges) as int;
    lastChargeAt = (j['lastChargeAt'] ?? GameClock.nowMs()) as int;
    final rawPots = (j['pots'] ?? const []) as List;
    pots = rawPots.map((e) => Pot.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    if (pots.length != GameRules.potCount) {
      final have = pots.map((p) => p.number).toSet();
      for (var n = 1; n <= GameRules.potCount; n++) {
        if (!have.contains(n)) pots.add(Pot(number: n));
      }
      pots = pots.take(GameRules.potCount).toList();
    }
    avatarId = (j['avatarId'] ?? 'bear') as String;
    ownedBorders = ((j['ownedBorders'] ?? const ['starter']) as List).cast<String>().toSet();
    if (j['freeBorderClaimable'] != true) ownedBorders.add('starter'); // older saves already had it
    equippedBorder = (j['equippedBorder'] ?? 'starter') as String;
    badges = Map<String, bool>.from((j['badges'] ?? const {}) as Map);
    showcaseBadge = j['showcaseBadge'] as String?;
    final s = Map<String, dynamic>.from((j['stats'] ?? const {}) as Map);
    planted = (s['planted'] ?? 0) as int;
    harvests = (s['harvests'] ?? 0) as int;
    waterings = (s['waterings'] ?? 0) as int;
    verifiedUploads = (s['verifiedUploads'] ?? 0) as int;
    quizzesDone = (s['quizzesDone'] ?? 0) as int;
    perfectQuizzes = (s['perfectQuizzes'] ?? 0) as int;
    mastered = (s['mastered'] ?? 0) as int;
    harvestedKinds = ((s['harvestedKinds'] ?? const []) as List).cast<String>().toSet();
    activeDays = ((j['activeDays'] ?? const []) as List).cast<String>().toSet();
    welcomePending = (j['welcomePending'] ?? false) as bool; // older accounts got their coins already
    dailyGiftDay = j['dailyGiftDay'] as String?;
    if (_uid != null) activeDays.add(dayKey(DateTime.now())); // keep today after a cloud restore
    GameClock.offset = Duration(milliseconds: (j['timeOffsetMs'] ?? 0) as int);
    updatedAt = (j['updatedAt'] ?? 0) as int;
  }

  Future<void> _save({bool silent = false}) async {
    final uid = _uid;
    if (uid == null) return;
    updatedAt = DateTime.now().millisecondsSinceEpoch;
    await _store.writeJson(StorageService.gameKey(uid), toJson());
    if (!silent) onChanged?.call();
  }

  void refresh() => notifyListeners();

  void _commit() {
    activeDays.add(dayKey(DateTime.now()));
    _checkAchievements();
    notifyListeners();
    _save();
  }

  // ===========================================================================
  // Economy
  // ===========================================================================
  int get level => 1 + lifetimeXp ~/ GameRules.xpPerLevel;
  int get xpIntoLevel => lifetimeXp % GameRules.xpPerLevel;
  double get levelProgress => xpIntoLevel / GameRules.xpPerLevel;

  void addCoins(int n, {bool announce = true}) {
    coins += n;
    if (announce) FeedbackBus.instance.emit('+$n coins', RewardKind.coins);
    _commit();
  }

  void addXp(int n, {bool announce = true}) {
    xp += n;
    lifetimeXp += n;
    if (announce) FeedbackBus.instance.emit('+$n XP', RewardKind.xp);
    _commit();
  }

  /// Weighted random seed: common seeds are likelier than rare ones.
  String grantRandomSeed() {
    final rnd = Random();
    final pool = <String>[];
    for (final f in Flower.all) {
      final w = switch (f.rarity) { Rarity.common => 6, Rarity.uncommon => 3, Rarity.rare => 1 };
      for (var i = 0; i < w; i++) {
        pool.add(f.id);
      }
    }
    final id = pool[rnd.nextInt(pool.length)];
    seeds[id] = (seeds[id] ?? 0) + 1;
    FeedbackBus.instance.emit('1 ${Flower.of(id).name} seed added to your inventory', RewardKind.seed);
    _commit();
    return id;
  }

  // ===========================================================================
  // Gifts: welcome coins and the daily free flower
  // ===========================================================================
  void claimWelcome() {
    if (!welcomePending) return;
    welcomePending = false;
    coins += GameRules.welcomeCoins;
    _commit();
  }

  /// When today's free flower unlocks (8:00 AM, phone time).
  static DateTime dailyGiftTime(DateTime day) => DateTime(day.year, day.month, day.day, GameRules.dailyGiftHour);

  bool get dailyGiftReady {
    final now = DateTime.now();
    return dailyGiftDay != dayKey(now) && !now.isBefore(dailyGiftTime(now));
  }

  /// Next time a free flower becomes claimable.
  DateTime get nextDailyGift {
    final now = DateTime.now();
    if (dailyGiftReady) return now;
    final today = dailyGiftTime(now);
    if (now.isBefore(today) && dailyGiftDay != dayKey(now)) return today;
    return dailyGiftTime(now.add(const Duration(days: 1)));
  }

  /// Returns the flower id of the random seed, or null if not ready.
  String? claimDailyGift() {
    if (!dailyGiftReady) return null;
    dailyGiftDay = dayKey(DateTime.now());
    return grantRandomSeed();
  }

  /// Things waiting on the Home tab (welcome coins, daily flower).
  int get homeClaims => (welcomePending ? 1 : 0) + (dailyGiftReady ? 1 : 0);

  /// Free borders that can be claimed in the Shop.
  int get freeBordersToClaim => BorderDef.all.where((b) => b.isFree && !ownedBorders.contains(b.id)).length;

  /// Free tools (upload rewards). Purchases go through [buyTool].
  void grantTool(ToolKind kind, int qty) {
    if (qty <= 0) return;
    switch (kind) {
      case ToolKind.fertilizer:
        fertilizers += qty;
      case ToolKind.shovel:
        shovels += qty;
      case ToolKind.water:
        final now = GameClock.nowMs();
        _settleCharges(now);
        waterCharges = min(GameRules.maxWaterCharges, waterCharges + 3 * qty);
        lastChargeAt = now;
    }
    FeedbackBus.instance.emit('$qty ${ToolDef.of(kind).name}${qty > 1 ? 's' : ''} added to your inventory', RewardKind.tool);
    _commit();
  }

  int get totalSeeds => seeds.values.fold(0, (a, b) => a + b);
  int seedCount(String id) => seeds[id] ?? 0;

  // ===========================================================================
  // Watering-can charges (3, +1 every 10 min)
  // ===========================================================================
  int chargesAt(int now) {
    if (waterCharges >= GameRules.baseWaterCharges) return waterCharges;
    final regen = (now - lastChargeAt) ~/ GameRules.chargeRestore.inMilliseconds;
    return min(GameRules.baseWaterCharges, waterCharges + max(0, regen));
  }

  Duration nextChargeIn(int now) {
    if (chargesAt(now) >= GameRules.baseWaterCharges) return Duration.zero;
    final r = GameRules.chargeRestore.inMilliseconds;
    final elapsed = (now - lastChargeAt) % r;
    return Duration(milliseconds: r - elapsed);
  }

  void _settleCharges(int now) {
    if (waterCharges >= GameRules.baseWaterCharges) {
      lastChargeAt = now;
      return;
    }
    final r = GameRules.chargeRestore.inMilliseconds;
    final regen = (now - lastChargeAt) ~/ r;
    if (regen > 0) {
      waterCharges = min(GameRules.baseWaterCharges, waterCharges + regen);
      lastChargeAt = waterCharges >= GameRules.baseWaterCharges ? now : lastChargeAt + regen * r;
    }
  }

  // ===========================================================================
  // Garden
  // ===========================================================================
  Pot potByNumber(int n) => pots.firstWhere((p) => p.number == n);
  int indexOfPot(int n) => pots.indexWhere((p) => p.number == n);

  int emptyCount() => pots.where((p) => p.isEmpty).length;
  int readyCount(int now) => pots.where((p) => p.isReadyAt(now)).length;
  int growingCount(int now) => pots.where((p) => !p.isEmpty && !p.isReadyAt(now)).length;
  int thirstyCount(int now) => pots.where((p) => p.needsWaterAt(now)).length;
  List<Pot> activePots() => pots.where((p) => !p.isEmpty).toList();

  /// Drag-and-drop: swap two positions. The pot number travels with its plant.
  void swapPots(int fromIndex, int toIndex) {
    if (fromIndex == toIndex) return;
    final a = pots[fromIndex];
    pots[fromIndex] = pots[toIndex];
    pots[toIndex] = a;
    notifyListeners();
    _save();
  }

  /// Move to an index, shifting the others (used by "arrange" reordering).
  void movePot(int fromIndex, int toIndex) {
    if (fromIndex == toIndex) return;
    final p = pots.removeAt(fromIndex);
    pots.insert(toIndex, p);
    notifyListeners();
    _save();
  }

  ActionResult plant(int potNumber, String flowerId) {
    final pot = potByNumber(potNumber);
    if (!pot.isEmpty) return const ActionResult(false, 'This pot is already in use.');
    if (seedCount(flowerId) <= 0) return const ActionResult(false, 'You have no seeds of this flower.');
    seeds[flowerId] = seedCount(flowerId) - 1;
    if (seeds[flowerId] == 0) seeds.remove(flowerId);
    pot.plant(flowerId, GameClock.nowMs());
    planted++;
    FeedbackBus.instance.emit('${Flower.of(flowerId).name} planted', RewardKind.seed);
    _commit();
    return ActionResult.done;
  }

  /// FR-4.2 — buy the seed with coins right at planting time.
  ActionResult buyAndPlant(int potNumber, String flowerId) {
    final f = Flower.of(flowerId);
    if (!potByNumber(potNumber).isEmpty) return const ActionResult(false, 'This pot is already in use.');
    if (coins < f.seedPrice) return ActionResult(false, 'You need ${f.seedPrice - coins} more coins.');
    coins -= f.seedPrice;
    seeds[flowerId] = seedCount(flowerId) + 1;
    return plant(potNumber, flowerId);
  }

  ActionResult water(int potNumber) {
    final now = GameClock.nowMs();
    final pot = potByNumber(potNumber);
    if (pot.isEmpty) return const ActionResult(false, 'Plant a seed first.');
    if (pot.isReadyAt(now)) return const ActionResult(false, 'Fully grown plants don’t need water.');
    if (!pot.canWater(now)) return const ActionResult(false, 'This plant is already full of water.');
    _settleCharges(now);
    if (waterCharges <= 0) {
      return ActionResult(false, 'Watering can is empty. Next charge in ${_mmss(nextChargeIn(now))} — or buy a can in the Shop.');
    }
    final wasFull = waterCharges >= GameRules.baseWaterCharges;
    waterCharges--;
    if (wasFull && waterCharges < GameRules.baseWaterCharges) lastChargeAt = now;
    pot.water(now);
    waterings++;
    FeedbackBus.instance.emit('Watered! +2 hours of growth time', RewardKind.water);
    _commit();
    return ActionResult.done;
  }

  ActionResult fertilize(int potNumber) {
    final now = GameClock.nowMs();
    final pot = potByNumber(potNumber);
    if (pot.isEmpty) return const ActionResult(false, 'Plant a seed first.');
    if (pot.isReadyAt(now)) return const ActionResult(false, 'This plant is already fully grown.');
    if (pot.fertilized) return const ActionResult(false, 'Fertilizer can be used only once per plant.');
    if (fertilizers <= 0) return const ActionResult(false, 'No fertilizer left. Buy one in the Shop.');
    fertilizers--;
    pot.fertilize(now);
    FeedbackBus.instance.emit('Fertilized! This plant now grows 2× faster', RewardKind.tool);
    _commit();
    return ActionResult.done;
  }

  ActionResult shovel(int potNumber) {
    final pot = potByNumber(potNumber);
    if (pot.isEmpty) return const ActionResult(false, 'This pot is already empty.');
    if (shovels <= 0) return const ActionResult(false, 'No shovel left. Buy one in the Shop.');
    shovels--;
    final name = pot.flower!.name;
    pot.clear();
    FeedbackBus.instance.emit('$name removed. The pot is now empty', RewardKind.tool);
    _commit();
    return ActionResult.done;
  }

  /// FR-4.8 — claim XP; the pot becomes free.
  ActionResult harvest(int potNumber) {
    final now = GameClock.nowMs();
    final pot = potByNumber(potNumber);
    if (!pot.isReadyAt(now)) return const ActionResult(false, 'This plant is still growing.');
    final f = pot.flower!;
    pot.clear();
    harvests++;
    harvestedKinds.add(f.id);
    xp += f.harvestXp;
    lifetimeXp += f.harvestXp;
    FeedbackBus.instance.emit('${f.name} harvested! +${f.harvestXp} XP', RewardKind.xp);
    _commit();
    return ActionResult(true, '+${f.harvestXp} XP');
  }

  // ===========================================================================
  // Shop
  // ===========================================================================
  ActionResult buySeeds(String flowerId, int packs, {required bool bundle}) {
    final f = Flower.of(flowerId);
    final cost = (bundle ? f.bundlePrice : f.seedPrice) * packs;
    if (coins < cost) return ActionResult(false, 'You need ${cost - coins} more coins.');
    coins -= cost;
    final count = packs * (bundle ? 5 : 1);
    seeds[flowerId] = seedCount(flowerId) + count;
    FeedbackBus.instance.emit('$count ${f.name} seed${count > 1 ? 's' : ''} added to your inventory', RewardKind.seed);
    _commit();
    return ActionResult.done;
  }

  int ownedTool(ToolKind k) => switch (k) {
        ToolKind.water => chargesAt(GameClock.nowMs()),
        ToolKind.fertilizer => fertilizers,
        ToolKind.shovel => shovels,
      };

  ActionResult buyTool(ToolKind kind, int qty) {
    final t = ToolDef.of(kind);
    final cost = t.price * qty;
    if (coins < cost) return ActionResult(false, 'You need ${cost - coins} more coins.');
    if (kind == ToolKind.water) {
      final now = GameClock.nowMs();
      _settleCharges(now);
      final room = (GameRules.maxWaterCharges - waterCharges) ~/ 3;
      if (room <= 0) {
        return const ActionResult(false, 'Your watering can is full (${GameRules.maxWaterCharges} charges max).');
      }
      if (qty > room) {
        return ActionResult(false, 'You can only buy $room more can${room == 1 ? '' : 's'} right now (${GameRules.maxWaterCharges} charges max).');
      }
      waterCharges = min(GameRules.maxWaterCharges, waterCharges + 3 * qty);
      lastChargeAt = now;
    } else if (kind == ToolKind.fertilizer) {
      fertilizers += qty;
    } else {
      shovels += qty;
    }
    coins -= cost;
    FeedbackBus.instance.emit(kind == ToolKind.water ? 'Watering can refilled (+${3 * qty} charges)' : '$qty ${t.name}${qty > 1 ? 's' : ''} added to your inventory', RewardKind.tool);
    _commit();
    return ActionResult.done;
  }

  /// FR-5.2 — XP purchase; the matching themed badge is granted too.
  ActionResult buyBorder(String borderId) {
    final b = BorderDef.of(borderId);
    if (ownedBorders.contains(borderId)) return const ActionResult(false, 'You already own this border.');
    if (xp < b.priceXp) return ActionResult(false, 'You need ${b.priceXp - xp} more XP.');
    xp -= b.priceXp;
    ownedBorders.add(borderId);
    equippedBorder = borderId;
    badges[b.badgeId] = true;
    showcaseBadge = b.badgeId;
    FeedbackBus.instance.emit('${b.name} border and ${Badges.of(b.badgeId).name} badge unlocked', RewardKind.badge);
    _commit();
    return ActionResult.done;
  }

  void equipBorder(String id) {
    if (id != BorderDef.noneId && !ownedBorders.contains(id)) return;
    equippedBorder = id;
    notifyListeners();
    _save();
  }

  void setAvatar(String id) {
    avatarId = id;
    notifyListeners();
    _save();
  }

  /// Achievement badge drawn on the avatar border: the showcased achievement,
  /// otherwise the latest one earned. Null → the border's own badge.
  String? get avatarBadge {
    // The badge the user picked in Badges & Achievements (an achievement or
    // a border badge). Nothing picked → null → the equipped border's own badge.
    final sc = showcaseBadge;
    if (sc != null && badges.containsKey(sc) && Badges.all.any((b) => b.id == sc)) return sc;
    return null;
  }

  void setShowcaseBadge(String? id) {
    if (id != null && !badges.containsKey(id)) return;
    showcaseBadge = id;
    notifyListeners();
    _save();
  }

  // ===========================================================================
  // Achievements
  // ===========================================================================
  bool hasBadge(String id) => badges.containsKey(id);
  bool isClaimed(String id) => badges[id] == true;
  int get unclaimedBadges => badges.values.where((v) => !v).length;

  void _checkAchievements() {
    void unlock(String id, bool cond) {
      if (cond && !badges.containsKey(id)) {
        badges[id] = false;
        celebrations.add(id);
      }
    }

    unlock('a_first_seed', planted >= 1);
    unlock('a_first_harvest', harvests >= 1);
    unlock('a_green_thumb', harvests >= 10);
    unlock('a_botanist', harvestedKinds.length >= Flower.all.length);
    unlock('a_hydration', waterings >= 25);
    unlock('a_bookworm', verifiedUploads >= 3);
    unlock('a_quiz_ace', perfectQuizzes >= 1);
    unlock('a_scholar', mastered >= 3);
    unlock('a_dedicated', quizzesDone >= 10);
    unlock('a_collector', ownedBorders.length >= 3);
  }

  ActionResult claimBadge(String id) {
    if (badges[id] != false) return const ActionResult(false, 'Nothing to claim.');
    final b = Badges.of(id);
    badges[id] = true;
    if (b.rewardCoins > 0) {
      coins += b.rewardCoins;
      FeedbackBus.instance.emit('+${b.rewardCoins} coins for ${b.name}', RewardKind.coins);
    }
    if (b.rewardXp > 0) {
      xp += b.rewardXp;
      lifetimeXp += b.rewardXp;
      FeedbackBus.instance.emit('+${b.rewardXp} XP for ${b.name}', RewardKind.xp);
    }
    _commit();
    return ActionResult.done;
  }

  String? takeCelebration() => celebrations.isEmpty ? null : celebrations.removeAt(0);

  // Study → game hooks
  void recordVerifiedUpload() {
    verifiedUploads++;
    _commit();
  }

  void recordQuiz({required int percent, required int coinsEarned, required int masteredModules}) {
    quizzesDone++;
    if (percent >= 100) perfectQuizzes++;
    mastered = masteredModules;
    if (coinsEarned > 0) {
      coins += coinsEarned;
      FeedbackBus.instance.emit('+$coinsEarned coins from your quiz', RewardKind.coins);
    }
    _commit();
  }

  // ===========================================================================
  // Demo time skip (Settings → Testing). Moves the game clock forward.
  // ===========================================================================
  void timeSkip(Duration d) {
    GameClock.offset += d;
    FeedbackBus.instance.emit('Time skipped +${d.inMinutes} min', RewardKind.info);
    notifyListeners();
    _save();
  }

  void resetTimeSkip() {
    GameClock.offset = Duration.zero;
    notifyListeners();
    _save();
  }

  static String _mmss(Duration d) =>
      '${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';
}
