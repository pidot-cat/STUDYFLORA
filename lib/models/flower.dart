import 'package:flutter/material.dart';

class Flower {
  final String id;
  final String name;
  final String emoji;
  final String asset; // round badge illustration
  final String? sprite; // tiny sprite drawn inside the garden pot (falls back to asset)
  final String description; // garden / planting description
  final String shopBlurb;
  final Color tint; // soft circle behind the icon
  final int rewardXp;
  final int rewardCoins;

  const Flower({
    required this.id,
    required this.name,
    required this.emoji,
    required this.asset,
    this.sprite,
    required this.description,
    required this.shopBlurb,
    required this.tint,
    this.rewardXp = 10,
    this.rewardCoins = 20,
  });
}

class Flowers {
  static const _f = 'assets/flowers/';

  static const all = <Flower>[
    Flower(
        id: 'sunflower',
        name: 'Sunflower',
        emoji: '🌻',
        asset: '${_f}sunflower.png',
        sprite: '${_f}sprite_sunflower.png',
        description: 'A bright and cheerful flower that symbolizes happiness and positivity.',
        shopBlurb: 'Brightens your garden with golden blooms.',
        tint: Color(0xFFFFF4D6)),
    Flower(
        id: 'tulip',
        name: 'Tulip',
        emoji: '🌷',
        asset: '${_f}tulip.png',
        description: 'A graceful flower that represents perfect love and fresh starts.',
        shopBlurb: 'Adds a calming touch with colorful petals.',
        tint: Color(0xFFFDE7EC)),
    Flower(
        id: 'lavender',
        name: 'Lavender',
        emoji: '🪻',
        asset: '${_f}lavender.png',
        sprite: '${_f}sprite_lavender.png',
        description: 'A calming herb-flower known for serenity and devotion.',
        shopBlurb: 'Brings a soothing scent and soft purple blooms.',
        tint: Color(0xFFEDE9FE)),
    Flower(
        id: 'rose',
        name: 'Rose',
        emoji: '🌹',
        asset: '${_f}rose.png',
        sprite: '${_f}sprite_rose.png',
        description: 'A timeless flower that symbolizes love and admiration.',
        shopBlurb: 'Adds timeless beauty with vibrant blossoms.',
        tint: Color(0xFFFDE7EA)),
    Flower(
        id: 'daisy',
        name: 'Daisy',
        emoji: '🌼',
        asset: '${_f}daisy.png',
        sprite: '${_f}sprite_daisy.png',
        description: 'A cheerful flower that brings positivity and new beginnings.',
        shopBlurb: 'Brightens your garden with cheerful white petals.',
        tint: Color(0xFFFBF5DC)),
    Flower(
        id: 'cosmos',
        name: 'Cosmos',
        emoji: '🌸',
        asset: '${_f}cosmos.png',
        description: 'A delicate flower that stands for order, peace and harmony.',
        shopBlurb: 'Adds delicate blooms and a splash of color.',
        tint: Color(0xFFFCE7F3)),
    Flower(
        id: 'iris',
        name: 'Iris',
        emoji: '💐',
        asset: '${_f}iris.png',
        description: 'An elegant flower symbolizing wisdom and hope.',
        shopBlurb: 'Brings elegance with striking, colorful petals.',
        tint: Color(0xFFEDE9FE)),
    Flower(
        id: 'peony',
        name: 'Peony',
        emoji: '🌺',
        asset: '${_f}peony.png',
        description: 'A lush flower representing prosperity and good fortune.',
        shopBlurb: 'Adds lush, full blooms to your garden.',
        tint: Color(0xFFFDE7EC)),
    Flower(
        id: 'ranunculus',
        name: 'Ranunculus',
        emoji: '🏵️',
        asset: '${_f}ranunculus.png',
        description: 'A layered bloom that says you are radiant and charming.',
        shopBlurb: 'Creates layered blooms with delicate petals.',
        tint: Color(0xFFFFEDD5)),
    Flower(
        id: 'hydrangea',
        name: 'Hydrangea',
        emoji: '💠',
        asset: '${_f}hydrangea.png',
        description: 'A clustered flower expressing gratitude and understanding.',
        shopBlurb: 'Brightens your garden with clusters of colorful flowers.',
        tint: Color(0xFFDBEAFE)),
    Flower(
        id: 'lily',
        name: 'Lily',
        emoji: '🤍',
        asset: '${_f}lily.png',
        description: 'A graceful flower that symbolizes purity and renewal.',
        shopBlurb: 'Adds graceful blooms and elegant petals.',
        tint: Color(0xFFE3F5E8)),
    Flower(
        id: 'daffodil',
        name: 'Daffodil',
        emoji: '🌼',
        asset: '${_f}daffodil.png',
        description: 'A sunny flower celebrating rebirth and new beginnings.',
        shopBlurb: 'Welcomes spring with bright, sunny blooms.',
        tint: Color(0xFFFEF9C3)),
  ];

  static Flower byId(String id) => all.firstWhere((f) => f.id == id, orElse: () => all.first);
}
