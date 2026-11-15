import 'dart:math';

import '../core/constants.dart';
import '../models/study.dart';
import 'text_analyzer.dart';

/// FR-3.1 / FR-3.2 — builds exactly [GameRules.maxQuizQuestions] clean
/// questions from a module's key points (as long as the module has at least
/// two). Four kinds are mixed: describe-the-concept, name-the-concept,
/// fill-in-the-blank and true-or-false. Every option is a complete sentence or
/// a real concept name taken from the notes — never a cut-off fragment.
class QuizGenerator {
  static List<QuizQuestion> generate(StudyModule module, {int? seed}) {
    final rnd = Random(seed ?? DateTime.now().millisecondsSinceEpoch);
    final kps = module.keyPoints;
    if (kps.length < 2) return [];
    final target = GameRules.maxQuizQuestions;

    final vocabulary = <String>{};
    for (final k in kps) {
      for (final w in TextAnalyzer.words(k.explanation)) {
        final l = w.toLowerCase();
        if (l.length >= 5 && !TextAnalyzer.stopwords.contains(l) && RegExp(r'^[a-z]+$').hasMatch(l)) vocabulary.add(l);
      }
    }
    final vocab = vocabulary.toList();

    // Candidate questions per key point, in a rotating type order so the quiz
    // mixes kinds instead of repeating one.
    const kinds = [QuestionType.describeConcept, QuestionType.nameConcept, QuestionType.fillBlank, QuestionType.trueFalse];
    final perKp = <List<QuizQuestion>>[];
    for (var i = 0; i < kps.length; i++) {
      final list = <QuizQuestion>[];
      final start = (i + rnd.nextInt(kinds.length)) % kinds.length;
      for (var k = 0; k < kinds.length; k++) {
        final q = _build(kinds[(start + k) % kinds.length], i, kps, vocab, rnd, variant: 0);
        if (q != null) list.add(q);
      }
      // Extra variants, used only when the module is short.
      for (var v = 1; v <= 2; v++) {
        final f = _build(QuestionType.fillBlank, i, kps, vocab, rnd, variant: v);
        if (f != null) list.add(f);
      }
      final tf = _build(QuestionType.trueFalse, i, kps, vocab, rnd, variant: 1);
      if (tf != null) list.add(tf);
      perKp.add(list);
    }

    final order = List<int>.generate(kps.length, (i) => i)..shuffle(rnd);
    final picked = <QuizQuestion>[];
    final seen = <String>{};
    for (var round = 0; picked.length < target; round++) {
      var any = false;
      for (final i in order) {
        if (picked.length >= target) break;
        if (round >= perKp[i].length) continue;
        any = true;
        final q = perKp[i][round];
        if (seen.add(q.prompt)) picked.add(q);
      }
      if (!any) break;
    }
    picked.shuffle(rnd);
    return picked;
  }

  static QuizQuestion? _build(QuestionType type, int i, List<KeyPoint> kps, List<String> vocab, Random rnd, {int variant = 0}) {
    final kp = kps[i];
    final others = [for (var j = 0; j < kps.length; j++) if (j != i) kps[j]]..shuffle(rnd);
    final distract = others.take(3).toList();
    final own = _sentence(kp.explanation);

    switch (type) {
      case QuestionType.describeConcept:
        // Each option hides its own term so the right choice isn't given away.
        final opts = [
          _option(_maskTitle(own, kp.title)),
          ...distract.map((d) => _option(_maskTitle(_sentence(d.explanation), d.title))),
        ];
        return _shuffled(type, 'Which statement best describes “${kp.title}”?', opts, '“${kp.title}”: ${kp.explanation}', rnd);

      case QuestionType.nameConcept:
        final opts = [kp.title, ...distract.map((d) => d.title)];
        return _shuffled(type, 'Which term matches this description?\n\n“${_option(_maskTitle(own, kp.title), 220)}”', opts,
            'This describes “${kp.title}”. ${kp.explanation}', rnd);

      case QuestionType.fillBlank:
        final titleWords = TextAnalyzer.words(kp.title).map((w) => w.toLowerCase()).toSet();
        final candidates = <String>{
          for (final w in TextAnalyzer.words(own))
            if (w.length >= 5 &&
                RegExp(r'^[A-Za-z]+$').hasMatch(w) &&
                !TextAnalyzer.stopwords.contains(w.toLowerCase()) &&
                !titleWords.contains(w.toLowerCase()))
              w.toLowerCase(),
        }.toList()
          ..sort((a, b) => b.length.compareTo(a.length));
        if (candidates.length <= variant) return null;
        final answer = candidates[variant];
        final pool = vocab.where((v) => v != answer && !own.toLowerCase().contains(v)).toList()..shuffle(rnd);
        if (pool.length < 3) return null;
        final r = RegExp(r'\b' + RegExp.escape(answer) + r'\b', caseSensitive: false);
        final blanked = own.replaceFirst(r, '_____');
        if (!blanked.contains('_____')) return null;
        return _shuffled(type, 'Fill in the blank with the correct word.\n\n“${_option(blanked, 240)}”', [answer, ...pool.take(3)],
            'The missing word is “$answer”. ${kp.explanation}', rnd);

      case QuestionType.trueFalse:
        // variant 0 → the real statement (or a swapped one, at random);
        // variant 1 → the opposite of what variant 0 would give.
        final makeFalse = others.isNotEmpty && ((rnd.nextBool() ? 1 : 0) + variant) % 2 == 1;
        final source = makeFalse ? others.first : kp;
        final stmt = _option(_maskTitle(_sentence(source.explanation), source.title), 220);
        final prompt = 'True or False: this statement describes “${kp.title}”.\n\n“$stmt”';
        final insight = makeFalse
            ? 'False. That statement describes “${others.first.title}”, not “${kp.title}”. ${kp.title}: ${kp.explanation}'
            : 'True. “${kp.title}”: ${kp.explanation}';
        return QuizQuestion(type: type, prompt: prompt, options: const ['True', 'False'], answer: makeFalse ? 1 : 0, insight: insight);
    }
  }

  static QuizQuestion? _shuffled(QuestionType type, String prompt, List<String> options, String insight, Random rnd) {
    final correct = options.first;
    // Drop duplicate options so there is exactly one right answer.
    final unique = <String>[];
    for (final o in options) {
      if (!unique.any((u) => u.toLowerCase() == o.toLowerCase())) unique.add(o);
    }
    if (unique.length < 2) return null;
    final opts = [...unique]..shuffle(rnd);
    return QuizQuestion(type: type, prompt: prompt, options: opts, answer: opts.indexOf(correct), insight: insight);
  }

  /// First complete sentence of an explanation.
  static String _sentence(String s) {
    final m = RegExp(r'^(.{25,}?[.!?])(?=\s+[A-Z]|$)').firstMatch(s.trim());
    return (m?.group(1) ?? s).trim();
  }

  /// Hides the concept's own name (with its article) so the right answer is
  /// not given away: "A schematic diagram is…" → "This concept is…".
  static String _maskTitle(String text, String title) {
    final r = RegExp(r'\b(?:(?:a|an|the)\s+(?:[a-z]+\s+)?)?' + RegExp.escape(title) + r'(?:s|es)?\b', caseSensitive: false);
    var out = text.replaceAll(r, 'this term');
    if (out.startsWith('this term')) out = 'T${out.substring(1)}';
    return out;
  }

  /// Keeps an option readable: whole sentence, or cut at a word boundary.
  static String _option(String s, [int max = 170]) {
    s = s.trim();
    if (s.length <= max) return s;
    final cut = s.substring(0, max);
    final i = cut.lastIndexOf(' ');
    return '${cut.substring(0, i > 60 ? i : max).replaceFirst(RegExp(r'[,;:\s]+$'), '')}…';
  }
}
