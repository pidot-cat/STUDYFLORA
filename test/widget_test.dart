import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_application_project/core/constants.dart';
import 'package:mobile_application_project/models/pot.dart';
import 'package:mobile_application_project/services/text_analyzer.dart';

/// Unit tests for the SRS garden rules (FR-4.3 … FR-4.6) and analyzer (FR-2.3).
void main() {
  const h = 3600 * 1000;

  test('a planted seed does not grow until watered', () {
    final p = Pot(number: 1)..plant('rose', 0);
    expect(p.progressAt(2 * h), 0);
    expect(p.needsWaterAt(2 * h), isTrue);
  });

  test('watering gives 2h of growth, then growth pauses', () {
    final p = Pot(number: 1)..plant('rose', 0);
    p.water(0);
    expect(p.progressAt(1 * h), closeTo(1 / 6, 1e-9));
    expect(p.progressAt(5 * h), closeTo(2 / 6, 1e-9)); // paused after 2h
    expect(p.isWiltedAt(5 * h), isTrue);
  });

  test('three stages: seed → sprout → bloom', () {
    final p = Pot(number: 1)..plant('tulip', 0);
    p.water(0);
    expect(p.stageAt(1 * h), PlantStage.seed);
    p.water(2 * h);
    expect(p.stageAt(3 * h), PlantStage.sprout);
    p.water(4 * h);
    expect(p.stageAt(6 * h), PlantStage.bloom);
    expect(p.isReadyAt(6 * h), isTrue);
  });

  test('fertilizer halves remaining time without jumping the percentage', () {
    final p = Pot(number: 1)..plant('daisy', 0);
    p.water(0);
    p.water(0);
    p.water(0); // 6h of water
    final before = p.progressAt(2 * h);
    expect(p.remainingAt(2 * h), const Duration(hours: 4));
    p.fertilize(2 * h);
    expect(p.progressAt(2 * h), closeTo(before, 1e-9));
    expect(p.remainingAt(2 * h), const Duration(hours: 2));
    expect(p.isReadyAt(4 * h), isTrue);
  });

  test('quiz coin table matches FR-3.6', () {
    expect(GameRules.quizCoins(100), 100);
    expect(GameRules.quizCoins(95), 75);
    expect(GameRules.quizCoins(85), 50);
    expect(GameRules.quizCoins(72), 30);
    expect(GameRules.quizCoins(60), 20);
    expect(GameRules.quizCoins(55), 10);
    expect(GameRules.quizCoins(10), 5);
  });

  test('analyzer finds "Term: explanation" key points', () {
    const text = '''
Photosynthesis: the process plants use to turn light energy into chemical energy.
Chlorophyll: the green pigment that absorbs light inside the chloroplast.
Stomata: tiny openings on leaves that allow gas exchange with the air.
''';
    final kps = TextAnalyzer.analyze(text);
    expect(kps.length, greaterThanOrEqualTo(3));
    expect(kps.first.title, 'Photosynthesis');
  });
}
