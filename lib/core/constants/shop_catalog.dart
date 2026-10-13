import 'package:flutter/material.dart';

import '../../models/avatar_border.dart';
import '../../models/seed_item.dart';
import '../../models/tool_item.dart';
import 'app_assets.dart';

/// Single source of truth for everything sold in the Shop / Settings.
class ShopCatalog {
  const ShopCatalog._();

  // Values come straight from the approved Shop mockup.
  static const seeds = <SeedItem>[
    SeedItem(
      id: 'seed_sunflower',
      name: 'Sun Flower Seed',
      imageAsset: AppAssets.seedSunflower,
      rarity: SeedRarity.common,
      growthHours: 6,
      borderXp: 150,
      unitPrice: 15,
      bundlePrice: 60,
    ),
    SeedItem(
      id: 'seed_daisy',
      name: 'Daisy Flower Seed',
      imageAsset: AppAssets.seedDaisy,
      rarity: SeedRarity.rareGlow,
      growthHours: 6,
      borderXp: 350,
      unitPrice: 35,
      bundlePrice: 140,
    ),
    SeedItem(
      id: 'seed_rose',
      name: 'Rose Flower Seed',
      imageAsset: AppAssets.seedRose,
      rarity: SeedRarity.vibrant,
      growthHours: 6,
      borderXp: 220,
      unitPrice: 25,
      bundlePrice: 100,
    ),
  ];

  // The mockup has no Tools panel content, so these prices are placeholders
  // built in the Seeds card style. Easy to tweak here.
  static const tools = <ToolItem>[
    ToolItem(
      id: 'tool_watering_can',
      name: 'Watering Can',
      description: 'Keeps plants hydrated so growth never pauses.',
      price: 30,
      icon: Icons.water_drop_outlined,
    ),
    ToolItem(
      id: 'tool_fertilizer',
      name: 'Fertilizer',
      description: 'Nurtures a plant and cuts its growth time in half.',
      price: 20,
      icon: Icons.science_outlined,
    ),
    ToolItem(
      id: 'tool_shovel',
      name: 'Shovel',
      description: 'Clears a pot so you can replant something new.',
      price: 25,
      icon: Icons.construction_outlined,
    ),
  ];

  // Mirrors the Settings mockup.
  static const borders = <AvatarBorder>[
    AvatarBorder(
      id: 'verdant_sprout',
      name: 'Verdant Sprout',
      description: 'Tier 1 • Starter Plant Border',
      xpCost: 0,
      icon: Icons.spa_outlined,
      ringColor: Color(0xFFB8C9BE),
    ),
    AvatarBorder(
      id: 'emerald_laurel',
      name: 'Emerald Laurel Border',
      description: 'Unlocked from Bazaar • Ready',
      xpCost: 600,
      icon: Icons.eco,
      ringColor: Color(0xFF3DDC84),
    ),
    AvatarBorder(
      id: 'midnight_bloom',
      name: 'Midnight Bloom Cloche',
      description: 'Midnight glass cloche border',
      xpCost: 1000,
      icon: Icons.nightlight_round,
      ringColor: Color(0xFF8B7CF6),
    ),
  ];

  static AvatarBorder borderById(String id) =>
      borders.firstWhere((b) => b.id == id, orElse: () => borders.first);
}
