import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/study.dart';
import '../../providers/study_provider.dart';
import '../../services/quiz_generator.dart';
import '../../services/sound_service.dart';
import '../../widgets/common.dart';
import '../../widgets/sheets.dart';

/// Practice quiz (FR-3.1 … FR-3.6): 30 s per question, instant
/// feedback with an insight and running score.
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.moduleId});
  final String moduleId;
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late final StudyModule _module;
  late final List<QuizQuestion> _qs;
  int _i = 0;
  int? _picked; // -1 = timed out
  int _correct = 0;
  final Map<int, int> _answers = {};
  Timer? _timer;
  int _msLeft = GameRules.secondsPerQuestion * 1000;

  bool get _answered => _picked != null;

  @override
  void initState() {
    super.initState();
    _module = context.read<StudyProvider>().byId(widget.moduleId)!;
    _qs = QuizGenerator.generate(_module);
    // No questions (module with too few key points) → no timer, or it would
    // fire on an empty list.
    if (_qs.isNotEmpty) _startTimer();
  }

  void _startTimer({bool reset = true}) {
    _timer?.cancel();
    if (reset) _msLeft = GameRules.secondsPerQuestion * 1000;
    _timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (!mounted) return;
      setState(() => _msLeft -= 100);
      if (_msLeft <= 0) {
        t.cancel();
        _answer(-1);
      }
    });
  }

  void _answer(int idx) {
    if (_answered || _i >= _qs.length) return;
    _timer?.cancel();
    final q = _qs[_i];
    final ok = idx == q.answer;
    if (ok) {
      _correct++;
      HapticFeedback.lightImpact();
      SoundService.instance.play(Sfx.correct);
    } else if (idx != -1) {
      // A wrong pick. Running out of time is "No answer", not a wrong answer.
      HapticFeedback.heavyImpact();
      SoundService.instance.play(Sfx.wrong);
    }
    setState(() {
      _picked = idx;
      _answers[_i] = idx;
    });
  }

  void _next() {
    if (_i < _qs.length - 1) {
      setState(() {
        _i++;
        _picked = null;
      });
      _startTimer();
    } else {
      _finish();
    }
  }

  void _finish() {
    final study = context.read<StudyProvider>();
    final attempt = study.recordAttempt(_module, correct: _correct, total: _qs.length, flagged: 0);
    SoundService.instance.play(attempt.percent >= GameRules.masteredPercent ? Sfx.success : Sfx.tap);
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => QuizResultScreen(attempt: attempt, questions: _qs, answers: _answers, flagged: const {}, module: _module),
    ));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// The timer is paused while the dialog is open so a question can't time
  /// out behind it.
  Future<bool> _confirmLeave() async {
    final running = !_answered;
    _timer?.cancel();
    final leave = await confirmDialog(
      context,
      title: 'Leave the quiz?',
      message: 'Your progress in this attempt will not be saved.',
      confirm: 'Leave',
      danger: true,
      icon: Icons.logout_rounded,
    );
    if (!leave && running && mounted) _startTimer(reset: false);
    return leave;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sf;
    if (_qs.isEmpty) {
      return Scaffold(
        appBar: AppBar(backgroundColor: c.bg),
        body: const Padding(
          padding: EdgeInsets.all(20),
          child: EmptyState(icon: Icons.quiz_outlined, title: 'Not enough content', message: 'This module needs at least two key points to build a quiz.'),
        ),
      );
    }
    final q = _qs[_i];
    final secs = (_msLeft / 1000).ceil().clamp(0, GameRules.secondsPerQuestion);
    final frac = (_msLeft / (GameRules.secondsPerQuestion * 1000)).clamp(0.0, 1.0);
    final urgent = secs <= 10;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmLeave() && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 16, 0),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () async {
                    if (await _confirmLeave() && context.mounted) Navigator.of(context).pop();
                  },
                ),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Question ${_i + 1}/${_qs.length}', style: context.tt.titleSmall),
                    Text(_module.title, style: context.tt.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ]),
                ),
                SizedBox(
                  width: 52,
                  height: 52,
                  child: Stack(alignment: Alignment.center, children: [
                    SizedBox(
                      width: 52,
                      height: 52,
                      child: CircularProgressIndicator(
                        value: frac,
                        strokeWidth: 5,
                        backgroundColor: c.line,
                        color: urgent ? c.danger : c.accent,
                      ),
                    ),
                    Text('$secs', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: urgent ? c.danger : c.ink)),
                  ]),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Row(children: [
                for (var k = 0; k < _qs.length; k++)
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: _answers.containsKey(k)
                            ? (_answers[k] == _qs[k].answer ? c.accent : c.danger)
                            : (k == _i ? c.brand.withValues(alpha: 0.5) : c.line),
                      ),
                    ),
                  ),
              ]),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                transitionBuilder: (child, a) => FadeTransition(
                  opacity: a,
                  child: SlideTransition(position: Tween(begin: const Offset(0.06, 0), end: Offset.zero).animate(a), child: child),
                ),
                child: ListView(
                  key: ValueKey(_i),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  children: [
                    Row(children: [
                      StatusBadge(q.typeLabel, tone: Tone.blue, dense: true),
                      const Spacer(),
                      Text('Score: $_correct', style: context.tt.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: c.brand)),
                    ]),
                    const SizedBox(height: 12),
                    SfCard(
                      padding: const EdgeInsets.all(18),
                      child: Text(q.prompt, style: context.tt.titleMedium?.copyWith(height: 1.45, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 14),
                    for (var k = 0; k < q.options.length; k++) _OptionTile(
                      letter: String.fromCharCode(65 + k),
                      text: q.options[k],
                      state: !_answered
                          ? _OptState.idle
                          : k == q.answer
                              ? _OptState.correct
                              : (k == _picked ? _OptState.wrong : _OptState.dim),
                      onTap: () => _answer(k),
                    ),
                    if (_answered) _Feedback(correct: _picked == q.answer, timedOut: _picked == -1, insight: q.insight),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              child: _answered
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                      child: PrimaryButton(
                        label: _i < _qs.length - 1 ? 'Next Question' : 'See Results',
                        icon: _i < _qs.length - 1 ? Icons.arrow_forward_rounded : Icons.emoji_events_outlined,
                        onTap: _next,
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ]),
        ),
      ),
    );
  }
}

enum _OptState { idle, correct, wrong, dim }

class _OptionTile extends StatelessWidget {
  const _OptionTile({required this.letter, required this.text, required this.state, required this.onTap});
  final String letter;
  final String text;
  final _OptState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.sf;
    final (bg, border, fg) = switch (state) {
      _OptState.idle => (c.surface, c.line, c.ink),
      _OptState.correct => (c.brandSoft, c.accent, c.ink),
      _OptState.wrong => (c.dangerSoft, c.danger, c.ink),
      _OptState.dim => (c.surface, c.line, c.muted),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Pressable(
        onTap: state == _OptState.idle ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(18), border: Border.all(color: border, width: 1.6)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: state == _OptState.correct ? c.accent : (state == _OptState.wrong ? c.danger : c.surfaceAlt),
                shape: BoxShape.circle,
              ),
              child: state == _OptState.correct
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                  : state == _OptState.wrong
                      ? const Icon(Icons.close_rounded, color: Colors.white, size: 18)
                      : Text(letter, style: TextStyle(fontWeight: FontWeight.w800, color: c.brand)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Padding(padding: const EdgeInsets.only(top: 4), child: Text(text, style: TextStyle(color: fg, fontSize: 14, height: 1.4)))),
          ]),
        ),
      ),
    );
  }
}

class _Feedback extends StatelessWidget {
  const _Feedback({required this.correct, required this.timedOut, required this.insight});
  final bool correct;
  final bool timedOut;
  final String insight;
  @override
  Widget build(BuildContext context) {
    final c = context.sf;
    final color = correct ? c.accent : (timedOut ? c.ink : c.danger);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 12 * (1 - v)), child: child)),
      child: Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: correct ? c.brandSoft : (timedOut ? c.surfaceAlt : c.dangerSoft),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(correct ? Icons.celebration_rounded : (timedOut ? Icons.timer_off_outlined : Icons.lightbulb_outline_rounded), color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                correct ? 'Correct! Nice work.' : (timedOut ? 'Time’s up — No answer. The right answer is in green.' : 'Incorrect — the right answer is in green.'),
                style: TextStyle(fontWeight: FontWeight.w800, color: color),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Text('Explanation', style: TextStyle(fontWeight: FontWeight.w700, color: c.ink, fontSize: 12)),
          const SizedBox(height: 2),
          Text(insight, style: TextStyle(color: c.ink, fontSize: 13, height: 1.4)),
        ]),
      ),
    );
  }
}

/// Results (FR-3.6 coins table, FR-3.8 mastered) — layout from the
/// "Quiz Results" mockup.
class QuizResultScreen extends StatefulWidget {
  const QuizResultScreen({super.key, required this.attempt, required this.questions, required this.answers, required this.flagged, required this.module});
  final QuizAttempt attempt;
  final List<QuizQuestion> questions;
  final Map<int, int> answers; // -1 = timed out
  final Set<int> flagged;
  final StudyModule module;

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  bool _showAnswers = false;

  // Score out of 10 → coins (GameRules.quizCoins).
  static const _brackets = [
    (80, 100, '8–10 correct', 50),
    (50, 79, '5–7 correct', 30),
    (0, 49, '0–4 correct', 5),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.sf;
    final a = widget.attempt;
    final qs = widget.questions;
    final p = a.percent;
    final unanswered = [for (var i = 0; i < qs.length; i++) if ((widget.answers[i] ?? -1) == -1) i];
    final incorrect = [for (var i = 0; i < qs.length; i++) if (widget.answers[i] != null && widget.answers[i] != -1 && widget.answers[i] != qs[i].answer) i];
    // Flash Review order: flagged first, then incorrect, then unanswered.
    final review = [
      for (var i = 0; i < qs.length; i++) if (widget.flagged.contains(i)) i,
      for (final i in incorrect) if (!widget.flagged.contains(i)) i,
      for (final i in unanswered) if (!widget.flagged.contains(i)) i,
    ];
    final missed = incorrect.length + unanswered.length;
    final (headline, note) = switch (p) {
      100 => ('Perfect score!', 'You know every concept in this module.'),
      >= 80 => ('Well done!', missed == 1 ? 'One concept to revisit before your next quiz.' : '$missed concepts to revisit before your next quiz.'),
      >= 60 => ('Good job!', 'You passed. Review the missed concepts to reach full mastery.'),
      _ => ('Keep practicing', 'Review the key points, then try again — 60% masters the module.'),
    };
    final bracket = _brackets.firstWhere((b) => p >= b.$1 && p <= b.$2);

    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(backgroundColor: c.bg, surfaceTintColor: Colors.transparent, title: Text('Quiz Results', style: context.tt.titleMedium)),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
          children: [
            Row(children: [
              Expanded(child: Text('A little practice, a little more growth 🌱', style: context.tt.bodySmall?.copyWith(fontStyle: FontStyle.italic))),
              StatusBadge('Attempt #${a.attempt}', tone: Tone.neutral, icon: Icons.bookmark_outline_rounded, dense: true),
            ]),
            const SizedBox(height: 12),
            // ---- module card
            SfCard(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(widget.module.title, style: context.tt.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(widget.module.fileName, style: context.tt.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('Completed ${fmtShortDate(DateTime.fromMillisecondsSinceEpoch(a.takenAt))} • ${qs.length} questions', style: context.tt.bodySmall),
                  ]),
                ),
                if (widget.module.mastered) const StatusBadge('Mastered', icon: Icons.check_rounded, dense: true),
              ]),
            ),
            const SizedBox(height: 12),
            // ---- score card
            SfCard(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: (p >= 60 ? c.brandSoft : c.terracottaSoft).withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: p >= 60 ? c.brandSoft : c.terracottaSoft),
                  ),
                  child: Column(children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: a.correct.toDouble()),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, __) => Text('${v.round()}/${a.total}', style: TextStyle(fontSize: 44, fontWeight: FontWeight.w800, color: c.ink, height: 1.1)),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(99), border: Border.all(color: c.line)),
                      child: Text.rich(TextSpan(children: [
                        TextSpan(text: '$p% ', style: TextStyle(fontWeight: FontWeight.w800, color: p >= 60 ? c.brand : c.terracotta)),
                        TextSpan(text: 'accuracy', style: TextStyle(color: c.muted, fontSize: 12)),
                      ])),
                    ),
                  ]),
                ),
                const SizedBox(height: 10),
                SfProgressBar(value: p / 100, color: p >= 60 ? c.accent : c.terracotta, height: 6),
                const SizedBox(height: 14),
                Text(headline, style: context.tt.titleLarge),
                const SizedBox(height: 2),
                Text(note, style: context.tt.bodySmall, textAlign: TextAlign.center),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: _CountTile(value: a.correct, label: 'Correct', icon: Icons.check_rounded, fg: c.accent, bg: c.brandSoft)),
                  const SizedBox(width: 8),
                  Expanded(child: _CountTile(value: incorrect.length, label: 'Incorrect', icon: Icons.close_rounded, fg: c.danger, bg: c.dangerSoft)),
                  const SizedBox(width: 8),
                  Expanded(child: _CountTile(value: unanswered.length, label: 'No answer', icon: Icons.timer_off_outlined, fg: c.muted, bg: c.surfaceAlt)),
                ]),
                const SizedBox(height: 10),
                Text('“No answer” means time ran out before you picked. It does not add to your score.',
                    style: context.tt.bodySmall?.copyWith(fontSize: 11, fontStyle: FontStyle.italic), textAlign: TextAlign.center),
              ]),
            ),
            const SizedBox(height: 12),
            // ---- reward card (FR-3.6): coins on the first attempt only
            if (a.attempt > 1)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: c.line)),
                child: Row(children: [
                  IconTile(Icons.replay_rounded, size: 42),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Practice retake', style: context.tt.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        'Coins are earned on your first attempt only. Retakes are free practice and still improve your best score.',
                        style: context.tt.bodySmall,
                      ),
                    ]),
                  ),
                ]),
              )
            else
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: c.goldSoft.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(20), border: Border.all(color: c.gold.withValues(alpha: 0.35))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const CoinIcon(size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('+${a.coins} coins earned', style: context.tt.titleMedium),
                      Text('First-attempt reward for ${bracket.$3}', style: context.tt.bodySmall),
                    ]),
                  ),
                ]),
                const SizedBox(height: 12),
                Text('SCORE BRACKET', style: context.tt.labelSmall?.copyWith(color: c.gold)),
                const SizedBox(height: 6),
                Wrap(spacing: 6, runSpacing: 6, children: [
                  for (final b in _brackets)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: b == bracket ? c.brandSoft : c.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: b == bracket ? c.accent : c.line),
                      ),
                      child: Text('${b.$3} → ${b.$4}',
                          style: TextStyle(fontSize: 11.5, fontWeight: b == bracket ? FontWeight.w800 : FontWeight.w500, color: b == bracket ? c.brand : c.ink)),
                    ),
                ]),
              ]),
            ),
            const SizedBox(height: 16),
            // ---- actions
            PrimaryButton(
              label: _showAnswers ? 'Hide Answers' : 'Review Answers',
              icon: Icons.fact_check_outlined,
              onTap: () => setState(() => _showAnswers = !_showAnswers),
            ),
            if (_showAnswers) ...[
              const SizedBox(height: 12),
              for (var i = 0; i < qs.length; i++) _AnswerCard(index: i, q: qs[i], picked: widget.answers[i] ?? -1, flagged: widget.flagged.contains(i)),
            ],
            const SizedBox(height: 10),
            _MintButton(
              label: review.isEmpty ? 'Nothing to review — great job!' : 'Flash Review (${review.length > 5 ? 5 : review.length} cards)',
              icon: Icons.style_outlined,
              onTap: review.isEmpty
                  ? null
                  : () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => FlashReviewScreen(cards: [for (final i in review.take(5)) (q: qs[i], picked: widget.answers[i] ?? -1, flagged: widget.flagged.contains(i))]),
                      )),
            ),
            if (review.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('Built from the questions you missed or ran out of time on.', style: context.tt.bodySmall?.copyWith(fontSize: 11), textAlign: TextAlign.center),
              ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: SecondaryButton(
                  label: 'Retake (practice)',
                  icon: Icons.replay_rounded,
                  onTap: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => QuizScreen(moduleId: widget.module.id))),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SecondaryButton(
                  label: 'Back to Study',
                  icon: Icons.arrow_back_rounded,
                  onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _CountTile extends StatelessWidget {
  const _CountTile({required this.value, required this.label, required this.icon, required this.fg, required this.bg});
  final int value;
  final String label;
  final IconData icon;
  final Color fg;
  final Color bg;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(color: bg.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(16), border: Border.all(color: fg.withValues(alpha: 0.25))),
        child: Column(children: [
          Icon(icon, size: 16, color: fg),
          Text('$value', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: fg)),
          FittedBox(fit: BoxFit.scaleDown, child: Text(label.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: fg))),
        ]),
      );
}

class _MintButton extends StatelessWidget {
  const _MintButton({required this.label, required this.icon, this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final c = context.sf;
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(color: c.brandSoft, borderRadius: BorderRadius.circular(18)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: c.brand, size: 20),
          const SizedBox(width: 8),
          Flexible(child: Text(label, style: TextStyle(color: c.brand, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
        ]),
      ),
    );
  }
}

class _AnswerCard extends StatelessWidget {
  const _AnswerCard({required this.index, required this.q, required this.picked, required this.flagged});
  final int index;
  final QuizQuestion q;
  final int picked;
  final bool flagged;
  @override
  Widget build(BuildContext context) {
    final c = context.sf;
    final ok = picked == q.answer;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SfCard(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            StatusBadge('Q${index + 1}', tone: ok ? Tone.green : (picked == -1 ? Tone.neutral : Tone.red), dense: true),
            const SizedBox(width: 6),
            Text(ok ? 'Correct' : (picked == -1 ? 'No answer' : 'Incorrect'),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ok ? c.accent : (picked == -1 ? c.muted : c.danger))),
            const Spacer(),
            if (flagged) const StatusBadge('Flagged', tone: Tone.gold, icon: Icons.flag_rounded, dense: true),
          ]),
          const SizedBox(height: 8),
          Text(q.prompt, style: context.tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          if (!ok && picked >= 0)
            Text('Your answer: ${q.options[picked]}', style: TextStyle(color: c.danger, fontSize: 13)),
          Text('Correct answer: ${q.options[q.answer]}', style: TextStyle(color: c.accent, fontWeight: FontWeight.w600, fontSize: 13)),
        ]),
      ),
    );
  }
}

/// FR-3.5 — post-quiz flashcards from incorrect, unanswered and flagged
/// questions (up to five). Tap a card to flip it.
class FlashReviewScreen extends StatefulWidget {
  const FlashReviewScreen({super.key, required this.cards});
  final List<({QuizQuestion q, int picked, bool flagged})> cards;
  @override
  State<FlashReviewScreen> createState() => _FlashReviewScreenState();
}

class _FlashReviewScreenState extends State<FlashReviewScreen> {
  int _i = 0;
  bool _back = false;

  @override
  Widget build(BuildContext context) {
    final c = context.sf;
    final card = widget.cards[_i];
    final last = _i == widget.cards.length - 1;
    return Scaffold(
      appBar: AppBar(backgroundColor: c.bg, surfaceTintColor: Colors.transparent, title: Text('Flash Review', style: context.tt.titleMedium)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Column(children: [
            Row(children: [
              Text('Card ${_i + 1} of ${widget.cards.length}', style: context.tt.titleSmall),
              const Spacer(),
              if (card.flagged) const StatusBadge('Flagged', tone: Tone.gold, icon: Icons.flag_rounded, dense: true),
              if (card.picked == -1) ...[const SizedBox(width: 6), const StatusBadge('No answer', tone: Tone.neutral, dense: true)],
              if (card.picked >= 0 && card.picked != card.q.answer) ...[const SizedBox(width: 6), const StatusBadge('Missed', tone: Tone.red, dense: true)],
            ]),
            const SizedBox(height: 8),
            SfProgressBar(value: (_i + 1) / widget.cards.length, height: 5),
            const SizedBox(height: 16),
            Expanded(
              child: Pressable(
                onTap: () => setState(() => _back = !_back),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  transitionBuilder: (child, a) => ScaleTransition(scale: Tween(begin: 0.94, end: 1.0).animate(a), child: FadeTransition(opacity: a, child: child)),
                  child: Container(
                    key: ValueKey('$_i-$_back'),
                    width: double.infinity,
                    height: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: _back ? c.brandSoft : c.surface,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: _back ? c.accent : c.line, width: 1.5),
                      boxShadow: [BoxShadow(color: c.shadow, blurRadius: 20, offset: const Offset(0, 8))],
                    ),
                    child: SingleChildScrollView(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_back ? 'ANSWER' : 'QUESTION', style: context.tt.labelSmall?.copyWith(color: _back ? c.brand : c.muted)),
                        const SizedBox(height: 10),
                        if (!_back)
                          Text(card.q.prompt, style: context.tt.titleMedium?.copyWith(height: 1.45))
                        else ...[
                          Text(card.q.options[card.q.answer], style: context.tt.titleLarge),
                          // Description questions already show the explanation as the answer.
                          if (card.q.type != QuestionType.describeConcept) ...[
                            const SizedBox(height: 12),
                            Text(card.q.insight, style: context.tt.bodyMedium?.copyWith(height: 1.45)),
                          ],
                          if (card.picked >= 0 && card.picked != card.q.answer) ...[
                            const SizedBox(height: 12),
                            Text('You answered: ${card.q.options[card.picked]}', style: TextStyle(color: c.danger, fontSize: 13)),
                          ],
                        ],
                      ]),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(_back ? 'Tap the card to see the question again' : 'Tap the card to reveal the answer', style: context.tt.bodySmall),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: SecondaryButton(
                  label: 'Previous',
                  icon: Icons.arrow_back_rounded,
                  onTap: _i == 0 ? null : () => setState(() {
                        _i--;
                        _back = false;
                      }),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PrimaryButton(
                  label: last ? 'Done' : 'Next',
                  icon: last ? Icons.check_rounded : Icons.arrow_forward_rounded,
                  onTap: () {
                    if (last) {
                      Navigator.of(context).pop();
                    } else {
                      setState(() {
                        _i++;
                        _back = false;
                      });
                    }
                  },
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}
