import 'package:flutter/material.dart';

/// Free profile avatars (Settings → Change avatar).
class Avatar {
  final String id;
  final String name;
  const Avatar(this.id, this.name);
  String get asset => 'assets/avatars/$id.webp';

  static const all = [
    Avatar('bear', 'Mint Bear'),
    Avatar('bunny', 'Blush Bunny'),
    Avatar('cat', 'Sleepy Cat'),
    Avatar('panda', 'Study Panda'),
    Avatar('fox', 'Sunny Fox'),
    Avatar('deer', 'Little Deer'),
  ];
  static Avatar of(String id) => all.firstWhere((a) => a.id == id, orElse: () => all.first);
}

/// A badge. Two families:
///  * border badges — granted together with the avatar border of the same theme;
///  * achievement badges — unlocked by studying / gardening milestones.
class BadgeDef {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final List<Color> colors; // gradient
  final String? borderId; // non-null for border badges
  final int rewardCoins;
  final int rewardXp;

  const BadgeDef({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.colors,
    this.borderId,
    this.rewardCoins = 0,
    this.rewardXp = 0,
  });

  bool get isAchievement => borderId == null;
}

/// Avatar borders (FR-5.2) — bought with XP, each comes with a matching badge.
class BorderDef {
  final String id;
  final String name;
  final String description;
  final int priceXp;
  final String rarity;
  final String badgeId;

  /// Measured from the (re-centred) border art, as fractions of the image size:
  /// radius of the inner photo circle, and centre + size of the corner badge.
  final double innerRadius;
  final double badgeX;
  final double badgeY;
  final double badgeSize;

  /// Centre of the inner photo circle (the art is not always perfectly
  /// centred, e.g. the crown pushes the ring down).
  final double cx;
  final double cy;

  const BorderDef(this.id, this.name, this.description, this.priceXp, this.rarity, this.badgeId,
      {required this.innerRadius, required this.badgeX, required this.badgeY, required this.badgeSize, this.cx = 0.5, this.cy = 0.5});

  String get asset => 'assets/borders/$id.webp';
  bool get isFree => priceXp == 0;

  static const all = [
    BorderDef('starter', 'Verdant Sprout', 'A simple dotted vine for every new gardener.', 0, 'Starter', 'b_sprout',
        innerRadius: 0.335, badgeX: 0.805, badgeY: 0.795, badgeSize: 0.40),
    BorderDef('clover', 'Clover Charm', 'A lucky ring of clover beads for steady learners.', 300, 'Basic', 'b_clover',
        innerRadius: 0.355, badgeX: 0.787, badgeY: 0.766, badgeSize: 0.40, cx: 0.504),
    BorderDef('leaf', 'Leaf Frame', 'A lush botanical border crafted with delicate foliage.', 500, 'Basic', 'b_leaf',
        innerRadius: 0.34, badgeX: 0.800, badgeY: 0.768, badgeSize: 0.41, cx: 0.504, cy: 0.504),
    BorderDef('coral', 'Coral Blossom', 'Warm coral blooms orbiting your avatar.', 800, 'Rare', 'b_coral',
        innerRadius: 0.35, badgeX: 0.778, badgeY: 0.778, badgeSize: 0.42, cy: 0.502),
    BorderDef('crown', 'Golden Crown', 'A royal laurel for true reviewer champions.', 1200, 'Epic', 'b_crown',
        innerRadius: 0.345, badgeX: 0.778, badgeY: 0.789, badgeSize: 0.43, cx: 0.498, cy: 0.527),
  ];
  static BorderDef of(String id) => all.firstWhere((b) => b.id == id, orElse: () => all.first);

  /// New accounts start with a plain avatar; the user equips a border in
  /// Settings → Avatar & Border.
  static const noneId = 'none';
  static BorderDef? maybe(String id) {
    for (final b in all) {
      if (b.id == id) return b;
    }
    return null;
  }

  static String nameOf(String id) => maybe(id)?.name ?? 'No border';
}

class Badges {
  static const all = <BadgeDef>[
    // ---- border badges ----
    BadgeDef(id: 'b_sprout', name: 'Seedling', description: 'Comes with the Verdant Sprout border.', icon: Icons.spa_rounded, colors: [Color(0xFF7BD7A6), Color(0xFF1E7A4F)], borderId: 'starter'),
    BadgeDef(id: 'b_clover', name: 'Lucky Learner', description: 'Comes with the Clover Charm border.', icon: Icons.filter_vintage_rounded, colors: [Color(0xFF45C07E), Color(0xFF0F5E3A)], borderId: 'clover'),
    BadgeDef(id: 'b_leaf', name: 'Leaf Scholar', description: 'Comes with the Leaf Frame border.', icon: Icons.eco_rounded, colors: [Color(0xFF5ED38F), Color(0xFF1B6B45)], borderId: 'leaf'),
    BadgeDef(id: 'b_coral', name: 'Coral Bloomer', description: 'Comes with the Coral Blossom border.', icon: Icons.local_florist_rounded, colors: [Color(0xFFFFA48A), Color(0xFFD9573A)], borderId: 'coral'),
    BadgeDef(id: 'b_crown', name: 'Flora Royalty', description: 'Comes with the Golden Crown border.', icon: Icons.workspace_premium_rounded, colors: [Color(0xFFFFD36B), Color(0xFFE08A00)], borderId: 'crown'),
    // ---- achievements ----
    BadgeDef(id: 'a_first_seed', name: 'First Sprout', description: 'Plant your very first seed.', icon: Icons.grass_rounded, colors: [Color(0xFF9BE3B9), Color(0xFF2E8B57)], rewardXp: 10),
    BadgeDef(id: 'a_first_harvest', name: 'First Harvest', description: 'Claim XP from a fully grown plant.', icon: Icons.agriculture_rounded, colors: [Color(0xFFFFC98B), Color(0xFFD2643A)], rewardXp: 20),
    BadgeDef(id: 'a_green_thumb', name: 'Green Thumb', description: 'Harvest 10 plants.', icon: Icons.yard_rounded, colors: [Color(0xFF6FD99B), Color(0xFF15703F)], rewardXp: 60),
    BadgeDef(id: 'a_botanist', name: 'Botanist', description: 'Harvest all 12 kinds of flowers.', icon: Icons.local_florist_rounded, colors: [Color(0xFFE59CFF), Color(0xFF7B3FC4)], rewardXp: 200),
    BadgeDef(id: 'a_hydration', name: 'Hydration Hero', description: 'Water plants 25 times.', icon: Icons.water_drop_rounded, colors: [Color(0xFF8CC8FF), Color(0xFF2B7BD6)], rewardXp: 30),
    BadgeDef(id: 'a_bookworm', name: 'Bookworm', description: 'Upload 3 verified study modules.', icon: Icons.menu_book_rounded, colors: [Color(0xFFB4C6FF), Color(0xFF3E58C9)], rewardCoins: 60),
    BadgeDef(id: 'a_quiz_ace', name: 'Quiz Ace', description: 'Score 100% on a practice quiz.', icon: Icons.emoji_events_rounded, colors: [Color(0xFFFFE08A), Color(0xFFE0A100)], rewardCoins: 80),
    BadgeDef(id: 'a_scholar', name: 'Scholar', description: 'Master 3 modules (best score ≥ 60%).', icon: Icons.school_rounded, colors: [Color(0xFF7FE0D0), Color(0xFF0F7F73)], rewardCoins: 120),
    BadgeDef(id: 'a_dedicated', name: 'Dedicated', description: 'Finish 10 practice quizzes.', icon: Icons.local_fire_department_rounded, colors: [Color(0xFFFFB27A), Color(0xFFE0521F)], rewardCoins: 100),
    BadgeDef(id: 'a_collector', name: 'Collector', description: 'Own 3 avatar borders.', icon: Icons.collections_rounded, colors: [Color(0xFFFFA9C8), Color(0xFFC23B74)], rewardCoins: 80),
  ];
  static BadgeDef of(String id) => all.firstWhere((b) => b.id == id, orElse: () => all.first);
  static List<BadgeDef> get borderBadges => all.where((b) => !b.isAchievement).toList();
  static List<BadgeDef> get achievements => all.where((b) => b.isAchievement).toList();
}

enum ToolKind { water, fertilizer, shovel }

class ToolDef {
  final ToolKind kind;
  final String name;
  final String description;
  final String unit;
  final int price;
  final String asset;
  final String effect;
  final String usage;
  const ToolDef(this.kind, this.name, this.description, this.unit, this.price, this.asset, this.effect, this.usage);

  static const all = [
    ToolDef(ToolKind.water, 'Watering Can', 'Water plants to keep them hydrated. Adds 3 charges instantly; 1 charge also restores every 10 minutes.', 'Can (3 charges)', 30, 'assets/tools/water.webp', '+2h Hydration', '1 Charge / Water'),
    ToolDef(ToolKind.fertilizer, 'Fertilizer', 'Doubles plant growth speed. Can only be used once per plant.', 'Fertilizer (Bottle)', 150, 'assets/tools/fert.webp', '2× Growth Speed', '1 Use / Plant'),
    ToolDef(ToolKind.shovel, 'Shovel', 'Removes a flower to free up the pot for planting a new flower seed.', 'Shovel (Single use)', 80, 'assets/tools/shovel.webp', 'Frees a Pot', '1 Use / Dig'),
  ];
  static ToolDef of(ToolKind k) => all.firstWhere((t) => t.kind == k);
}
