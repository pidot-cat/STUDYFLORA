import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:studyflora/core/utils/coin_rewards.dart';
import 'package:studyflora/models/study_module.dart';
import 'package:studyflora/services/quiz_generator.dart';
import 'package:studyflora/services/study_analyzer.dart';

const _sample = '''
Cellular Respiration Notes
Glycolysis: Anaerobic breakdown of glucose into 2 pyruvate molecules yielding net 2 ATP.
The Krebs cycle is the mitochondrial matrix reaction producing CO2, NADH, and FADH2 from acetyl-CoA.
Oxidative phosphorylation refers to chemiosmosis across the cristae membrane generating 30-32 ATP.
Fermentation is the process of regenerating NAD+ when oxygen is unavailable, producing lactic acid or ethanol.
ATP synthase produces ATP using the proton gradient across the inner mitochondrial membrane.
The electron transport chain consists of protein complexes embedded in the inner mitochondrial membrane.
''';

void main() {
  test('coin tiers stay within 5..100 and match the mockups', () {
    expect(coinsForScore(10, 10), 100);
    expect(coinsForScore(8, 10), 50);
    expect(coinsForScore(0, 10), 5);
    for (var c = 0; c <= 10; c++) {
      final v = coinsForScore(c, 10);
      expect(v >= 5 && v <= 100, isTrue);
    }
  });

  test('analyzer finds the definition-style key points', () {
    final r = StudyAnalyzer.analyze(_sample);
    final titles = r.keyPoints.map((k) => k.title).toList();
    expect(titles, containsAll(['Glycolysis', 'Krebs Cycle', 'Oxidative Phosphorylation']));
    expect(r.keyPoints.length, lessThanOrEqualTo(StudyAnalyzer.maxKeyPoints));
  });

  test('quiz questions always have the correct answer in range', () {
    final r = StudyAnalyzer.analyze(_sample);
    final m = StudyModule(
      id: 'x',
      fileName: 'bio.txt',
      extension: 'txt',
      sizeBytes: 100,
      keyPoints: r.keyPoints,
      facts: r.facts,
      vocab: r.vocab,
      createdAt: DateTime(2026),
    );
    final qs = QuizGenerator.generate(m, random: Random(1));
    expect(qs, isNotEmpty);
    for (final q in qs) {
      expect(q.options.length, greaterThanOrEqualTo(2));
      expect(q.correctIndex, inInclusiveRange(0, q.options.length - 1));
    }
  });
}
