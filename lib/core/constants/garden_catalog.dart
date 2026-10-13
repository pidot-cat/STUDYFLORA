import '../../models/plant_type.dart';
import 'app_assets.dart';

class GardenCatalog {
  const GardenCatalog._();

  static const potCount = 18;

  /// Every plant needs 6 hours of watered growth.
  static const growthDuration = Duration(hours: 6);

  /// One watering keeps a plant hydrated (and growing) for this long.
  static const waterWindow = Duration(hours: 2);

  /// Fertilizer doubles growth speed (6h -> 3h total).
  static const fertilizerBoost = 2.0;

  /// The Watering Can holds 3 charges per can owned (you start with one can).
  static const chargesPerCan = 3;
  static const chargeRegen = Duration(minutes: 10);

  static const toolWateringCan = 'tool_watering_can';
  static const toolFertilizer = 'tool_fertilizer';
  static const toolShovel = 'tool_shovel';

  // XP for the first three matches the Shop mockup (+150 / +350 / +220).
  static const types = <PlantType>[
    PlantType(
      id: 'sunflower',
      name: 'Golden Sunflower',
      seedId: 'seed_sunflower',
      asset: AppAssets.flowerSunflower,
      xp: 150,
      seedPrice: 15,
    ),
    PlantType(
      id: 'daisy',
      name: 'Meadow Daisy',
      seedId: 'seed_daisy',
      asset: AppAssets.flowerDaisy,
      xp: 350,
      seedPrice: 35,
    ),
    PlantType(
      id: 'rose',
      name: 'Crimson Rose',
      seedId: 'seed_rose',
      asset: AppAssets.flowerRose,
      xp: 220,
      seedPrice: 25,
    ),
    PlantType(
      id: 'cosmos',
      name: 'Pink Cosmos',
      seedId: 'seed_cosmos',
      asset: AppAssets.flowerCosmos,
      xp: 180,
      seedPrice: 20,
    ),
    PlantType(
      id: 'tulip',
      name: 'Violet Tulip',
      seedId: 'seed_tulip',
      asset: AppAssets.flowerTulip,
      xp: 260,
      seedPrice: 30,
    ),
    PlantType(
      id: 'gentian',
      name: 'Royal Gentian',
      seedId: 'seed_gentian',
      asset: AppAssets.flowerGentian,
      xp: 300,
      seedPrice: 40,
    ),
  ];

  static PlantType byId(String id) =>
      types.firstWhere((t) => t.id == id, orElse: () => types.first);

  /// Pot centres as fractions (x, y) of the garden image, measured from
  /// the supplied greenhouse picture (3 rows x 6 pots).
  static const potCentres = <(double, double)>[
    (0.170, 0.218), (0.297, 0.230), (0.434, 0.224), (0.582, 0.230), (0.708, 0.224), (0.837, 0.218),
    (0.131, 0.462), (0.273, 0.451), (0.417, 0.466), (0.576, 0.480), (0.713, 0.448), (0.853, 0.460),
    (0.102, 0.707), (0.251, 0.713), (0.399, 0.713), (0.594, 0.718), (0.740, 0.703), (0.896, 0.718),
  ];
}
