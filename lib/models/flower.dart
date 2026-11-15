import 'package:flutter/material.dart';

enum Rarity { common, uncommon, rare }

extension RarityX on Rarity {
  String get label => switch (this) { Rarity.common => 'Common', Rarity.uncommon => 'Uncommon', Rarity.rare => 'Rare' };
}

/// The 12 flowers of FR-4.1. Price is per single seed packet; a bundle of 5
/// costs 4× (one free seed).
class Flower {
  final String id;
  final String name;
  final String blurb;
  final Rarity rarity;
  final Color tint;

  const Flower(this.id, this.name, this.blurb, this.rarity, this.tint);

  int get seedPrice => switch (rarity) { Rarity.common => 50, Rarity.uncommon => 80, Rarity.rare => 120 };
  int get bundlePrice => seedPrice * 4;
  int get harvestXp => switch (rarity) { Rarity.common => 15, Rarity.uncommon => 25, Rarity.rare => 40 };

  String get seedAsset => 'assets/plants/${id}_seed.webp';
  String get sproutAsset => 'assets/plants/${id}_sprout.webp';
  String get bloomAsset => 'assets/plants/${id}_bloom.webp';
  String get wiltedAsset => 'assets/plants/${id}_wilted.webp';

  static const all = <Flower>[
    Flower('sunflower', 'Sunflower', 'Brightens your garden with golden blooms.', Rarity.common, Color(0xFFFFF1CC)),
    Flower('tulip', 'Tulip', 'Adds a calming touch with colorful petals.', Rarity.common, Color(0xFFFDE3EA)),
    Flower('lavender', 'Lavender', 'Brings a soothing scent and soft purple blooms.', Rarity.uncommon, Color(0xFFEDE6FB)),
    Flower('rose', 'Rose', 'Adds timeless beauty with vibrant blossoms.', Rarity.uncommon, Color(0xFFFBE2DD)),
    Flower('daisy', 'Daisy', 'A cheerful flower that brings positivity and new beginnings.', Rarity.common, Color(0xFFFAF5E4)),
    Flower('cosmos', 'Cosmos', 'Adds delicate blooms and a splash of color.', Rarity.common, Color(0xFFFCE4F1)),
    Flower('iris', 'Iris', 'Brings elegance with striking, colorful petals.', Rarity.uncommon, Color(0xFFE6E8FB)),
    Flower('peony', 'Peony', 'Adds lush, full blooms to your garden.', Rarity.rare, Color(0xFFFDE4EC)),
    Flower('ranunculus', 'Ranunculus', 'Creates layered blooms with delicate petals.', Rarity.rare, Color(0xFFFDE6DC)),
    Flower('hydrangea', 'Hydrangea', 'Brightens your garden with clusters of colorful flowers.', Rarity.rare, Color(0xFFE3EEFC)),
    Flower('lily', 'Lily', 'Adds graceful blooms and elegant petals.', Rarity.uncommon, Color(0xFFE9F6EC)),
    Flower('daffodil', 'Daffodil', 'Welcomes spring with bright, sunny blooms.', Rarity.rare, Color(0xFFFFF0CF)),
  ];

  static final Map<String, Flower> byId = {for (final f in all) f.id: f};
  static Flower of(String id) => byId[id] ?? all.first;
}
