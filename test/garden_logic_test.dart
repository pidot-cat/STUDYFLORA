import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studyflora/core/constants/garden_catalog.dart';
import 'package:studyflora/core/constants/shop_catalog.dart';
import 'package:studyflora/models/plant.dart';
import 'package:studyflora/providers/garden_provider.dart';
import 'package:studyflora/providers/inventory_provider.dart';
import 'package:studyflora/providers/user_provider.dart';
import 'package:studyflora/services/storage_service.dart';

void main() {
  final t0 = DateTime(2026, 10, 6, 8);
  final tulip = GardenCatalog.byId('tulip');

  group('Plant growth math', () {
    test('a watered plant grows linearly and takes 6 hours', () {
      final p = Plant.sow(tulip, t0)..wetUntil = t0.add(const Duration(hours: 10));
      expect(p.progressAt(t0.add(const Duration(hours: 3))), closeTo(0.5, 1e-9));
      expect(p.isReady(t0.add(const Duration(hours: 6))), isTrue);
    });

    test('growth pauses when the water runs out', () {
      final p = Plant.sow(tulip, t0); // hydrated for 2h
      expect(p.progressAt(t0.add(const Duration(hours: 2))), closeTo(1 / 3, 1e-9));
      expect(p.progressAt(t0.add(const Duration(hours: 5))), closeTo(1 / 3, 1e-9));
      expect(p.isThirsty(t0.add(const Duration(hours: 5))), isTrue);
    });

    test('watering resumes growth from where it paused', () {
      final p = Plant.sow(tulip, t0);
      final t5 = t0.add(const Duration(hours: 5));
      p.settle(t5);
      p.wetUntil = t5.add(GardenCatalog.waterWindow);
      expect(p.progressAt(t5.add(const Duration(hours: 1))), closeTo(1 / 3 + 1 / 6, 1e-9));
    });

    test('fertilizer halves the total growth time', () {
      final p = Plant.sow(tulip, t0)..wetUntil = t0.add(const Duration(hours: 10));
      p.settle(t0);
      p.fertilized = true;
      expect(p.isReady(t0.add(const Duration(hours: 3))), isTrue);
      expect(p.untilReady(t0), const Duration(hours: 3));
    });

    test('stages switch at 1/3 and 2/3', () {
      final p = Plant.sow(tulip, t0)..wetUntil = t0.add(const Duration(hours: 10));
      expect(p.stageAt(t0.add(const Duration(minutes: 90))), 1);
      expect(p.stageAt(t0.add(const Duration(hours: 3))), 2);
      expect(p.stageAt(t0.add(const Duration(hours: 5))), 3);
    });

    test('plants survive a save/load round trip', () {
      final p = Plant.sow(tulip, t0)..fertilized = true;
      final back = Plant.fromJson(p.toJson());
      expect(back.typeId, 'tulip');
      expect(back.fertilized, isTrue);
      expect(back.wetUntil, p.wetUntil);
    });
  });

  group('GardenProvider', () {
    late UserProvider user;
    late InventoryProvider inv;
    late GardenProvider garden;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init();
      user = UserProvider(storage);
      inv = InventoryProvider(storage, user);
      garden = GardenProvider(storage, user, inv);
    });

    tearDown(() => garden.dispose());

    test('planting an unowned seed buys it with coins', () {
      final before = user.coins;
      expect(garden.plant(0, tulip, buyIfNeeded: true), GardenResult.ok);
      expect(user.coins, before - tulip.seedPrice);
      expect(garden.pots[0], isNotNull);
    });

    test('planting uses an owned seed instead of coins', () {
      final sunflower = GardenCatalog.byId('sunflower');
      inv.buySeed(ShopCatalog.seeds.first); // Sun Flower Seed, 1 pc
      final coins = user.coins;
      expect(garden.plant(1, sunflower, buyIfNeeded: true), GardenResult.ok);
      expect(user.coins, coins);
      expect(inv.count('seed_sunflower'), 0);
    });

    test('cannot plant in an occupied pot', () {
      garden.plant(2, tulip, buyIfNeeded: true);
      expect(garden.plant(2, tulip, buyIfNeeded: true), GardenResult.occupied);
    });

    test('shovel and fertilizer need inventory', () {
      garden.plant(3, tulip, buyIfNeeded: true);
      expect(garden.fertilize(3), GardenResult.noFertilizer);
      expect(garden.dig(3), GardenResult.noShovel);
    });

    test('a fresh plant refuses extra water and uses no charge', () {
      garden.plant(4, tulip, buyIfNeeded: true);
      final c = garden.charges;
      expect(garden.water(4), GardenResult.alreadyWatered);
      expect(garden.charges, c);
    });

    test('claiming before the plant is ready gives nothing', () {
      garden.plant(5, tulip, buyIfNeeded: true);
      expect(garden.claim(5), 0);
    });
  });
}
