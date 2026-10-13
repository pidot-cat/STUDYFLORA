import 'dart:math';

import '../models/quiz_models.dart';
import '../models/study_module.dart';

/// Builds multiple-choice questions from a [StudyModule]:
///  - "Which best describes X?"        (pick the explanation)
///  - "Which concept matches this?"    (pick the term)
///  - fill-in-the-blank from facts     (pick the missing word)
class QuizGenerator {
  const QuizGenerator._();

  static const maxQuestions = 10;

  static List<QuizQuestion> generate(StudyModule m, {Random? random}) {
    final rng = random ?? Random();
    final kps = m.keyPoints;
    final questions = <QuizQuestion>[];

    if (kps.length >= 2) {
      final order = List<int>.generate(kps.length, (i) => i)..shuffle(rng);
      for (var n = 0; n < order.length; n++) {
        questions.add(_conceptQuestion(kps, order[n], describe: n.isEven, rng: rng));
      }
      for (var n = 0; n < order.length; n++) {
        questions.add(_conceptQuestion(kps, order[n], describe: n.isOdd, rng: rng));
      }
    }

    final sentences = [...m.facts, ...kps.map((k) => k.detail)]..shuffle(rng);
    for (final s in sentences) {
      final q = _blankQuestion(s, m.vocab, rng);
      if (q != null) questions.add(q);
      if (questions.length > maxQuestions * 2) break;
    }

    final seenPrompts = <String>{};
    final unique = questions.where((q) => seenPrompts.add(q.prompt)).toList()
      ..shuffle(rng);
    return unique.take(maxQuestions).toList();
  }

  static QuizQuestion _conceptQuestion(
    List<KeyPoint> kps,
    int index, {
    required bool describe,
    required Random rng,
  }) {
    final target = kps[index];
    final others = [
      for (var i = 0; i < kps.length; i++)
        if (i != index) kps[i],
    ]..shuffle(rng);
    final picks = others.take(3).toList();

    final correctText = describe ? target.detail : target.title;
    final options = <String>[
      correctText,
      ...picks.map((k) => describe ? k.detail : k.title),
    ]..shuffle(rng);

    return QuizQuestion(
      prompt: describe
          ? 'Which of the following best describes ${target.title}?'
          : 'Which concept matches this description?\n"${target.detail}"',
      options: options,
      correctIndex: options.indexOf(correctText),
      insight: '${target.title}: ${target.detail}',
      keyTitle: target.title,
    );
  }

  static QuizQuestion? _blankQuestion(String sentence, List<String> vocab, Random rng) {
    final candidates = vocab.where((w) {
      return RegExp('\\b${RegExp.escape(w)}\\b', caseSensitive: false)
          .hasMatch(sentence);
    }).toList()
      ..shuffle(rng);
    if (candidates.isEmpty) return null;

    final answer = candidates.first;
    final match = RegExp('\\b${RegExp.escape(answer)}\\b', caseSensitive: false)
        .firstMatch(sentence)!;
    final capitalise = sentence[match.start] == sentence[match.start].toUpperCase();

    final distractors = vocab
        .where((w) =>
            w != answer &&
            !RegExp('\\b${RegExp.escape(w)}\\b', caseSensitive: false)
                .hasMatch(sentence))
        .toList()
      ..shuffle(rng);
    if (distractors.length < 3) return null;

    String fmt(String w) => capitalise ? w[0].toUpperCase() + w.substring(1) : w;
    final options = [answer, ...distractors.take(3)].map(fmt).toList()..shuffle(rng);

    return QuizQuestion(
      prompt: 'Fill in the blank:\n${sentence.replaceRange(match.start, match.end, '_____')}',
      options: options,
      correctIndex: options.indexOf(fmt(answer)),
      insight: sentence,
    );
  }

  /// Up to [count] cards; concepts the learner missed or flagged come first.
  static List<FlashCard> flashcards(StudyModule m, Set<String> priority, {int count = 5}) {
    final sorted = [...m.keyPoints]..sort((a, b) {
        final pa = priority.contains(a.title) ? 0 : 1;
        final pb = priority.contains(b.title) ? 0 : 1;
        return pa.compareTo(pb);
      });
    return sorted
        .take(count)
        .map((k) => FlashCard(front: k.title, back: k.detail))
        .toList();
  }
}
