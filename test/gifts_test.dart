import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_application_project/core/constants.dart';
import 'package:mobile_application_project/models/cosmetics.dart';
import 'package:mobile_application_project/providers/game_provider.dart';
import 'package:mobile_application_project/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Welcome coins, daily free flower, free border claim, watering-can limit
/// and the achievement coin rewards.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GameProvider game;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final store = await StorageService.create();
    game = GameProvider(store);
    await game.load('tester');
  });

  test('new accounts claim 150 welcome coins once', () {
    expect(game.coins, 0);
    expect(game.welcomePending, isTrue);
    game.claimWelcome();
    expect(game.coins, GameRules.welcomeCoins);
    game.claimWelcome();
    expect(game.coins, GameRules.welcomeCoins);
    expect(game.welcomePending, isFalse);
  });

  test('older saves never get the welcome gift and keep their free border', () {
    game.applyJson({'coins': 40, 'ownedBorders': ['clover'], 'equippedBorder': 'clover'});
    expect(game.welcomePending, isFalse);
    expect(game.ownedBorders, containsAll(['starter', 'clover']));
    expect(game.freeBordersToClaim, 0);
  });

  test('the free border is claimed from the shop with its badge', () {
    expect(game.freeBordersToClaim, 1);
    final r = game.buyBorder('starter');
    expect(r.ok, isTrue);
    expect(game.ownedBorders, contains('starter'));
    expect(game.badges['b_sprout'], isTrue);
    expect(game.freeBordersToClaim, 0);
  });

  test('the daily free flower can be claimed once per day', () {
    final seeds = game.totalSeeds;
    if (game.dailyGiftReady) {
      expect(game.claimDailyGift(), isNotNull);
      expect(game.totalSeeds, seeds + 1);
    }
    expect(game.dailyGiftReady, isFalse);
    expect(game.claimDailyGift(), isNull);
    expect(game.nextDailyGift.hour, GameRules.dailyGiftHour);
  });

  test('up to 10 watering cans can be bought at once', () {
    game.coins = 10000;
    final r = game.buyTool(ToolKind.water, 10);
    expect(r.ok, isTrue);
    expect(game.waterCharges, GameRules.maxWaterCharges);
    expect(game.buyTool(ToolKind.water, 1).ok, isFalse);
  });

  test('every achievement pays coins', () {
    for (final b in Badges.achievements) {
      expect(b.rewardCoins, greaterThan(0), reason: b.name);
      expect(b.rewardXp, 0, reason: b.name);
    }
  });
}
