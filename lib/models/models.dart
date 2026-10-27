import 'dart:math' as math;

import 'flower.dart';

export 'flower.dart';

/// Garden rules
class GardenRules {
  static const potCount = 18;
  static const growDuration = Duration(hours: 6);
  static const hydrationDuration = Duration(hours: 6); // a full watering lasts 6h
  static const waterCapacity = 3; // watering can charges
  static const waterRegen = Duration(minutes: 10);
}

/// A flower planted in one of the 18 pots.
class Plant {
  final String flowerId;
  final int pot; // 1-based pot number
  int growthMs; // effective growth accumulated
  double hydration; // 0..100
  bool fertilized;
  DateTime lastTick;
  final DateTime plantedAt;

  Plant({
    required this.flowerId,
    required this.pot,
    this.growthMs = 0,
    this.hydration = 100,
    this.fertilized = false,
    required this.lastTick,
    required this.plantedAt,
  });

  Flower get flower => Flowers.byId(flowerId);
  int get _total => GardenRules.growDuration.inMilliseconds;
  double get progress => math.min(1.0, growthMs / _total);
  bool get ready => growthMs >= _total;
  bool get needsWater => hydration <= 0 && !ready;
  int get speed => fertilized ? 2 : 1;

  /// Real time still required until harvest (at the current speed).
  int get _left => math.max(0, _total - growthMs);
  Duration get remaining => Duration(milliseconds: (_left / speed).round());

  /// Real time remaining with speed 1 (used for "was" labels).
  Duration get remainingNoBoost => Duration(milliseconds: _left);

  /// Time until the plant needs water again.
  Duration get hydrationLeft =>
      Duration(milliseconds: (hydration / 100 * GardenRules.hydrationDuration.inMilliseconds).round());

  /// Advance the simulation to [now]. Growth only happens while hydrated.
  void tick(DateTime now) {
    final elapsed = now.difference(lastTick).inMilliseconds;
    if (elapsed <= 0) return;
    final hydratedMs = math.min(elapsed, hydrationLeft.inMilliseconds);
    if (!ready) growthMs = math.min(_total, growthMs + hydratedMs * speed);
    hydration = math.max(0.0, hydration - elapsed / GardenRules.hydrationDuration.inMilliseconds * 100);
    lastTick = now;
  }

  Map<String, dynamic> toJson() => {
        'f': flowerId,
        'p': pot,
        'g': growthMs,
        'h': hydration,
        'fz': fertilized,
        't': lastTick.millisecondsSinceEpoch,
        'pa': plantedAt.millisecondsSinceEpoch,
      };

  factory Plant.fromJson(Map<String, dynamic> j) => Plant(
        flowerId: j['f'],
        pot: j['p'],
        growthMs: j['g'],
        hydration: (j['h'] as num).toDouble(),
        fertilized: j['fz'] ?? false,
        lastTick: DateTime.fromMillisecondsSinceEpoch(j['t']),
        plantedAt: DateTime.fromMillisecondsSinceEpoch(j['pa']),
      );
}

enum ToolType { wateringCan, fertilizer, shovel }

class ToolInfo {
  final ToolType type;
  final String name;
  final String subtitle;
  final String asset;
  final String shopBlurb;
  final String inventoryBlurb;
  final int price;
  const ToolInfo(this.type, this.name, this.subtitle, this.asset, this.shopBlurb, this.inventoryBlurb, this.price);

  static const all = [
    ToolInfo(
        ToolType.wateringCan,
        'Watering Can',
        'Plant Hydration Tool',
        'assets/tools/watering_can.png',
        'Water plants to keep them hydrated. Holds 3 charges , with 1 charge restored every 10 minutes.',
        'Water plants to keep them hydrated. Holds 3 charges , with 1 charge restored every 10 minutes.',
        30),
    ToolInfo(
        ToolType.fertilizer,
        'Fertilizer',
        'Organic Plant Nutrient',
        'assets/tools/fertilizer.png',
        'Doubles plant growth speed. Can only be used once per plant.',
        'Doubles plant growth speed. Can be applied once per plant.',
        150),
    ToolInfo(
        ToolType.shovel,
        'Shovel',
        'Pot Maintenance Tool',
        'assets/tools/shovel.png',
        'Removes a flower to free up the pot for planting a new flower seed.',
        'Removes a plant after confirmation, freeing up the pot for replanting new flower seeds.',
        80),
  ];
  static ToolInfo of(ToolType t) => all.firstWhere((e) => e.type == t);
}

/// ---------------- Study ----------------

class QuizQuestion {
  final String prompt;
  final List<String> options;
  final int answer;
  final String insight;
  final bool fillBlank; // prompt contains "______" placeholder

  const QuizQuestion({
    required this.prompt,
    required this.options,
    required this.answer,
    required this.insight,
    this.fillBlank = false,
  });

  Map<String, dynamic> toJson() => {'p': prompt, 'o': options, 'a': answer, 'i': insight, 'fb': fillBlank};
  factory QuizQuestion.fromJson(Map<String, dynamic> j) => QuizQuestion(
      prompt: j['p'], options: List<String>.from(j['o']), answer: j['a'], insight: j['i'], fillBlank: j['fb'] ?? false);
}

class KeyPoint {
  final String term;
  final String detail;
  const KeyPoint(this.term, this.detail);
  Map<String, dynamic> toJson() => {'t': term, 'd': detail};
  factory KeyPoint.fromJson(Map<String, dynamic> j) => KeyPoint(j['t'], j['d']);
}

class StudyModule {
  final String id;
  final String title; // subject title, e.g. "Plant Cell Biology"
  final String fileName;
  final String ext; // pdf / docx / txt
  final int sizeBytes;
  final DateTime uploadedAt;
  final String category; // Biology, Chemistry, Economics...
  final String iconKey; // which icon to render on lists
  final List<KeyPoint> keyPoints;
  final List<String> overview; // "What you'll find" bullets
  final List<QuizQuestion> questions;
  final String fullText;
  int bestScore; // percent, -1 if never taken

  StudyModule({
    required this.id,
    required this.title,
    required this.fileName,
    required this.ext,
    required this.sizeBytes,
    required this.uploadedAt,
    required this.category,
    required this.iconKey,
    required this.keyPoints,
    required this.overview,
    required this.questions,
    this.fullText = '',
    this.bestScore = -1,
  });

  bool get mastered => bestScore >= 60;

  Map<String, dynamic> toJson() => {
        'id': id,
        't': title,
        'fn': fileName,
        'x': ext,
        's': sizeBytes,
        'u': uploadedAt.millisecondsSinceEpoch,
        'c': category,
        'ic': iconKey,
        'kp': keyPoints.map((e) => e.toJson()).toList(),
        'ov': overview,
        'q': questions.map((e) => e.toJson()).toList(),
        'ft': fullText,
        'b': bestScore,
      };

  factory StudyModule.fromJson(Map<String, dynamic> j) => StudyModule(
        id: j['id'],
        title: j['t'],
        fileName: j['fn'],
        ext: j['x'],
        sizeBytes: j['s'],
        uploadedAt: DateTime.fromMillisecondsSinceEpoch(j['u']),
        category: j['c'],
        iconKey: j['ic'],
        keyPoints: (j['kp'] as List).map((e) => KeyPoint.fromJson(Map<String, dynamic>.from(e))).toList(),
        overview: List<String>.from(j['ov']),
        questions: (j['q'] as List).map((e) => QuizQuestion.fromJson(Map<String, dynamic>.from(e))).toList(),
        fullText: j['ft'] ?? '',
        bestScore: j['b'] ?? -1,
      );
}

/// Answer state per question: null = unanswered.
class QuizAttempt {
  final String moduleId;
  final String title;
  final String fileName;
  final DateTime date;
  final int attemptNo;
  final List<int?> answers;
  final List<bool> flagged;
  final List<QuizQuestion> questions;
  final int coins;

  QuizAttempt({
    required this.moduleId,
    required this.title,
    required this.fileName,
    required this.date,
    required this.attemptNo,
    required this.answers,
    required this.flagged,
    required this.questions,
    required this.coins,
  });

  int get total => questions.length;
  int get correct {
    var n = 0;
    for (var i = 0; i < total; i++) {
      if (answers[i] == questions[i].answer) n++;
    }
    return n;
  }

  int get unanswered => answers.where((a) => a == null).length;
  int get incorrect => total - correct - unanswered;
  int get percent => total == 0 ? 0 : (correct * 100 / total).round();
  bool get mastered => percent >= 60;

  /// Indices for flash review: incorrect, unanswered or flagged (max 5).
  List<int> get reviewIndices {
    final out = <int>[];
    for (var i = 0; i < total; i++) {
      if (answers[i] != questions[i].answer || flagged[i]) out.add(i);
    }
    return out.take(5).toList();
  }

  Map<String, dynamic> toJson() => {
        'm': moduleId,
        't': title,
        'fn': fileName,
        'd': date.millisecondsSinceEpoch,
        'n': attemptNo,
        'a': answers,
        'f': flagged,
        'q': questions.map((e) => e.toJson()).toList(),
        'c': coins,
      };

  factory QuizAttempt.fromJson(Map<String, dynamic> j) => QuizAttempt(
        moduleId: j['m'],
        title: j['t'],
        fileName: j['fn'],
        date: DateTime.fromMillisecondsSinceEpoch(j['d']),
        attemptNo: j['n'],
        answers: List<int?>.from(j['a']),
        flagged: List<bool>.from(j['f']),
        questions: (j['q'] as List).map((e) => QuizQuestion.fromJson(Map<String, dynamic>.from(e))).toList(),
        coins: j['c'],
      );
}

/// Coin bracket shown on Quiz Results.
int coinsForPercent(int p) {
  if (p >= 100) return 100;
  if (p >= 90) return 75;
  if (p >= 80) return 50;
  if (p >= 70) return 30;
  if (p >= 60) return 20;
  if (p >= 50) return 10;
  return 5;
}

/// ---------------- Profile cosmetics ----------------

class AvatarOption {
  final String id;
  final String name;
  final String tag;
  final String asset;
  final String description;
  const AvatarOption(this.id, this.name, this.tag, this.asset, this.description);

  static const all = [
    AvatarOption('flora_bear', 'Flora Bear', 'Equipped', 'assets/avatars/flora_bear_small.png',
        'Gentle woodland guardian supporting daily focus and patience.'),
    AvatarOption('sprout_bunny', 'Sprout Bunny', 'Forest Kin', 'assets/avatars/sprout_bunny_small.png',
        'Quick-footed companion who loves fresh sprouts and steady streaks.'),
    AvatarOption('sage_fox', 'Sage Fox', 'Mindful', 'assets/avatars/sage_fox_small.png',
        'Clever guide who keeps your study sessions sharp and mindful.'),
    AvatarOption('clover_cat', 'Clover Cat', 'Serene', 'assets/avatars/clover_cat_small.png',
        'Serene companion who brings calm to every review.'),
    AvatarOption('moss_panda', 'Moss Panda', 'Peaceful', 'assets/avatars/moss_panda_small.png',
        'Peaceful friend who reminds you to rest and recharge.'),
    AvatarOption('fern_deer', 'Fern Deer', 'Gentle', 'assets/avatars/fern_deer_small.png',
        'Gentle wanderer who nurtures curiosity and growth.'),
  ];
  static AvatarOption byId(String id) => all.firstWhere((a) => a.id == id, orElse: () => all.first);
}

enum BorderStyleKind { starter, leaf, flower, vine, golden }

class BorderOption {
  final String id;
  final String name;
  final String rarity; // Basic / Rare / Epic
  final String detail; // e.g. "Basic • Default"
  final int xpCost;
  final BorderStyleKind kind;
  final String description;
  const BorderOption(this.id, this.name, this.rarity, this.detail, this.xpCost, this.kind, this.description);

  static const all = [
    BorderOption('starter', 'Starter Border', 'Basic', 'Basic • Default', 0, BorderStyleKind.starter,
        'A simple dashed ring for every new gardener.'),
    BorderOption('leaf', 'Leaf Frame', 'Basic', 'Basic', 500, BorderStyleKind.leaf,
        'A lush botanical border crafted with delicate foliage for your profile avatar.'),
    BorderOption('flower', 'Flower Frame', 'Basic', 'Basic', 1500, BorderStyleKind.flower,
        'A ring of tiny coral blossoms framing your profile avatar.'),
    BorderOption('vine', 'Vine Frame', 'Rare', 'Rare • Nature Frame', 3500, BorderStyleKind.vine,
        'A thick climbing vine that wraps your avatar in deep green.'),
    BorderOption('golden', 'Golden Frame', 'Epic', 'Epic', 7500, BorderStyleKind.golden,
        'A radiant golden ring reserved for dedicated scholars.'),
  ];
  static BorderOption byId(String id) => all.firstWhere((b) => b.id == id, orElse: () => all.first);
}

class SavedAccount {
  final String email;
  final String name;
  final String passwordHash;
  SavedAccount(this.email, this.name, this.passwordHash);
  Map<String, dynamic> toJson() => {'e': email, 'n': name, 'p': passwordHash};
  factory SavedAccount.fromJson(Map<String, dynamic> j) => SavedAccount(j['e'], j['n'], j['p']);
}

class SyncEvent {
  final DateTime at;
  final bool success;
  final bool manual;
  SyncEvent(this.at, this.success, this.manual);
  Map<String, dynamic> toJson() => {'a': at.millisecondsSinceEpoch, 's': success, 'm': manual};
  factory SyncEvent.fromJson(Map<String, dynamic> j) =>
      SyncEvent(DateTime.fromMillisecondsSinceEpoch(j['a']), j['s'], j['m']);
}

/// Level curve: Lv1 0-100, Lv2 100-300, Lv3 300-600, Lv4 600-1000 ...
class Levels {
  static const thresholds = [0, 100, 300, 600, 1000, 1500, 2100, 2800, 3600, 4500, 5500, 7500, 10000];
  static const names = [
    'Seedling',
    'Sprout',
    'Sproutling',
    'Budding',
    'Blooming',
    'Flourishing',
    'Evergreen',
    'Grove Keeper',
    'Botanist',
    'Arborist',
    'Flora Sage',
    'Garden Master'
  ];
  static int level(int xp) {
    var l = 1;
    for (var i = 1; i < thresholds.length; i++) {
      if (xp >= thresholds[i]) l = i + 1;
    }
    return math.min(l, thresholds.length - 1);
  }

  static int nextThreshold(int xp) => thresholds[level(xp)];
  static String name(int xp) => names[math.min(level(xp) - 1, names.length - 1)];
}
