/// Image slots in `assets/images/` (registered in pubspec.yaml).
class AppAssets {
  const AppAssets._();

  /// No logo file was provided yet; the header shows a leaf icon until
  /// `logo.png` is added here.
  static const logo = 'assets/images/logo.png';
  static const avatar = 'assets/images/avatar_panda.jpg';

  static const flowerSunflower = 'assets/images/flower_sunflower.png';
  static const flowerDaisy = 'assets/images/flower_daisy.png';
  static const flowerRose = 'assets/images/flower_rose.png';
  static const flowerCosmos = 'assets/images/flower_cosmos.png';
  static const flowerGentian = 'assets/images/flower_gentian.png';
  static const flowerTulip = 'assets/images/flower_tulip.png';

  static const gardenBackground = 'assets/images/garden_bg.jpg';

  // Shop seed thumbnails reuse the flower art.
  static const seedSunflower = flowerSunflower;
  static const seedDaisy = flowerDaisy;
  static const seedRose = flowerRose;
}
