/// One plantable flower. All six share the same 6-hour base growth time.
class PlantType {
  const PlantType({
    required this.id,
    required this.name,
    required this.seedId,
    required this.asset,
    required this.xp,
    required this.seedPrice,
  });

  final String id;
  final String name;

  /// Inventory id of its seed (the first three match the Shop's seed ids).
  final String seedId;
  final String asset;

  /// Border XP granted when the grown plant is claimed.
  final int xp;

  /// Price used when buying the seed directly from the Garden's planting sheet.
  final int seedPrice;
}
