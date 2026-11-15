import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_application_project/models/flower.dart';
import 'package:mobile_application_project/models/study.dart';
import 'package:mobile_application_project/providers/game_provider.dart';
import 'package:mobile_application_project/providers/study_provider.dart';
import 'package:mobile_application_project/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Verified-upload reward: the user picks ONE of random seed / fertilizer /
/// shovel, once per unique file.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GameProvider game;
  late StudyProvider study;

  StudyModule module({bool verified = true}) => StudyModule(
        id: 'm${DateTime.now().microsecondsSinceEpoch}',
        hash: 'h${DateTime.now().microsecondsSinceEpoch}',
        title: 'Test module',
        fileName: 'test.pdf',
        fileType: 'pdf',
        fileBytes: 1000,
        wordCount: 300,
        keyPoints: const [KeyPoint('A', 'Alpha is the first letter.'), KeyPoint('B', 'Beta is the second letter.')],
        createdAt: 0,
        verified: verified,
      );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final store = await StorageService.create();
    game = GameProvider(store);
    await game.load('tester');
    study = StudyProvider(store, game);
    await study.load('tester');
  });

  test('fertilizer reward adds exactly one fertilizer and nothing else', () {
    final f = game.fertilizers, s = game.shovels, seeds = game.totalSeeds, coins = game.coins, xp = game.xp;
    final m = module();
    final r = study.claimUploadReward(m, UploadReward.fertilizer);
    expect(r, isNotNull);
    expect(r!.kind, UploadReward.fertilizer);
    expect(game.fertilizers, f + 1);
    expect(game.shovels, s);
    expect(game.totalSeeds, seeds);
    expect(game.coins, coins);
    expect(game.xp, xp);
    expect(m.rewardClaimed, isTrue);
    expect(m.rewardChoice, 'fertilizer');
  });

  test('shovel reward adds exactly one shovel', () {
    final f = game.fertilizers, s = game.shovels;
    final r = study.claimUploadReward(module(), UploadReward.shovel);
    expect(r!.label, '1 Shovel');
    expect(game.shovels, s + 1);
    expect(game.fertilizers, f);
  });

  test('random seed reward adds one real seed and remembers which', () {
    final seeds = game.totalSeeds;
    final m = module();
    final r = study.claimUploadReward(m, UploadReward.seed);
    expect(game.totalSeeds, seeds + 1);
    expect(Flower.byId.containsKey(m.rewardItem), isTrue);
    expect(r!.label, '${Flower.of(m.rewardItem!).name} seed');
    expect(StudyProvider.rewardLabel(m), 'Random seed: ${Flower.of(m.rewardItem!).name}');
  });

  test('a reward can be claimed only once per module', () {
    final m = module();
    expect(study.claimUploadReward(m, UploadReward.shovel), isNotNull);
    final s = game.shovels, f = game.fertilizers, seeds = game.totalSeeds;
    expect(study.claimUploadReward(m, UploadReward.shovel), isNull);
    expect(study.claimUploadReward(m, UploadReward.fertilizer), isNull);
    expect(study.claimUploadReward(m, UploadReward.seed), isNull);
    expect(game.shovels, s);
    expect(game.fertilizers, f);
    expect(game.totalSeeds, seeds);
  });

  test('unverified modules get no reward', () {
    final s = game.shovels;
    expect(study.claimUploadReward(module(verified: false), UploadReward.shovel), isNull);
    expect(game.shovels, s);
  });

  test('rewards survive a save and reload', () async {
    final m = module();
    study.modules.add(m);
    study.claimUploadReward(m, UploadReward.fertilizer);
    final f = game.fertilizers;
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final store = await StorageService.create();
    final game2 = GameProvider(store);
    await game2.load('tester');
    final study2 = StudyProvider(store, game2);
    await study2.load('tester');
    expect(game2.fertilizers, f);
    expect(study2.modules.single.rewardClaimed, isTrue);
    expect(study2.modules.single.rewardChoice, 'fertilizer');
  });

  test('quiz coins are given on the first attempt only; retakes are free practice', () {
    final m = module();
    study.modules.add(m);
    final coins = game.coins, xp = game.xp;
    final first = study.recordAttempt(m, correct: 8, total: 10, flagged: 0);
    expect(first.coins, 50);
    expect(game.coins, coins + 50);
    final retake = study.recordAttempt(m, correct: 10, total: 10, flagged: 0);
    expect(retake.coins, 0);
    expect(game.coins, coins + 50);
    expect(game.xp, xp); // quizzes never give XP — XP comes from the garden
    expect(m.bestScore, 100); // retakes still improve the best score
    expect(m.attempts, 2);
  });

  test('old saves with coins/xp rewards still load', () {
    final j = module().toJson()
      ..['rewardClaimed'] = true
      ..['rewardChoice'] = 'coins';
    final m = StudyModule.fromJson(j);
    expect(StudyProvider.rewardLabel(m), 'Coins');
  });
}
