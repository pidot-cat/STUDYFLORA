import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../nav.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/app_header.dart';
import '../../widgets/common.dart';
import 'flash_review_screen.dart';
import 'quiz_results_screen.dart';
import 'study_widgets.dart';

class QuizScreen extends StatefulWidget {
  final String moduleId;
  const QuizScreen({super.key, required this.moduleId});
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  static const perQuestion = 30;
  late final StudyModule _m;
  late final List<int?> _answers;
  late final List<bool> _flagged;
  int _i = 0;
  bool _timedOut = false;
  int _left = perQuestion;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _m = context.read<AppState>().moduleById(widget.moduleId)!;
    _answers = List<int?>.filled(_m.questions.length, null);
    _flagged = List<bool>.filled(_m.questions.length, false);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _left = perQuestion;
    _timedOut = false;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        _left--;
        if (_left <= 0) {
          _timedOut = true;
          t.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  QuizQuestion get _q => _m.questions[_i];
  bool get _answered => _answers[_i] != null;
  int get _score {
    var n = 0;
    for (var k = 0; k < _answers.length; k++) {
      if (_answers[k] == _m.questions[k].answer) n++;
    }
    return n;
  }

  void _select(int o) {
    if (_answered || _timedOut) return;
    _timer?.cancel();
    setState(() => _answers[_i] = o);
  }

  void _next() {
    if (_i == _m.questions.length - 1) {
      _timer?.cancel();
      final attempt = context.read<AppState>().recordAttempt(_m, _answers, _flagged);
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => QuizResultsScreen(attempt: attempt)));
      return;
    }
    setState(() => _i++);
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final s = context.watch<AppState>();
    final total = _m.questions.length;
    final last = _i == total - 1;
    final canNext = _answered || _timedOut;
    final correct = _answered && _answers[_i] == _q.answer;
    final lastAttempt =
        s.history.where((h) => h.moduleId == _m.id).cast<QuizAttempt?>().firstWhere((_) => true, orElse: () => null);
    return Scaffold(
      backgroundColor: c.isDark ? c.bg : const Color(0xFFF7F8FE),
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          const AppHeader(),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
              const PracticeQuizBanner(),
              const SizedBox(height: 16),
              SFCard(
                radius: 16,
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(children: [
                    Icon(Icons.science_outlined, size: 17, color: c.heading),
                    const SizedBox(width: 6),
                    Expanded(child: Text(_m.title, style: T.j(14, w: FontWeight.w500, c: c.heading))),
                    Pill('Q${two(_i + 1)} of $total',
                        jakarta: true,
                        fontSize: 12.5,
                        bg: c.isDark ? c.mint : const Color(0xFFD7F5E2),
                        fg: c.mintText,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                  ]),
                  const SizedBox(height: 10),
                  SFProgress(
                      value: (_i + 1) / total,
                      height: 5,
                      color: c.isDark ? c.accent : const Color(0xFF1F5A3D),
                      track: c.isDark ? c.border : const Color(0xFFE2E8F0)),
                  const SizedBox(height: 14),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: c.isDark ? c.mint : const Color(0xFFE6F8EC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFC9EED6)),
                      ),
                      child: Row(children: [
                        Icon(Icons.check_circle, size: 15, color: c.mintText),
                        const SizedBox(width: 6),
                        Text('Score: ${two(_score)}/$total', style: T.j(12.5, w: FontWeight.w500, c: c.heading)),
                      ]),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: c.isDark ? c.cardAlt : const Color(0xFFF2F4FA),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: c.border),
                      ),
                      child: Row(children: [
                        Icon(Icons.schedule, size: 15, color: _left <= 5 ? c.danger : c.heading),
                        const SizedBox(width: 6),
                        Text('00:${two(_left < 0 ? 0 : _left)}s',
                            style: T.j(12.5, w: FontWeight.w500, c: _left <= 5 ? c.danger : c.heading)),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  Text(_q.fillBlank ? '● ACTIVE PROMPT • FILL IN THE BLANK' : 'ACTIVE PROMPT',
                      style: T.j(11, w: FontWeight.w700, c: c.mintText, ls: .6)),
                  const SizedBox(height: 6),
                  _Prompt(question: _q, revealed: correct),
                  const SizedBox(height: 16),
                  for (var o = 0; o < _q.options.length; o++) ...[
                    _OptionTile(
                      letter: String.fromCharCode(65 + o),
                      text: _q.options[o],
                      state: !_answered
                          ? (_timedOut && o == _q.answer ? _Opt.reveal : _Opt.idle)
                          : (o == _answers[_i]
                              ? (correct ? _Opt.correct : _Opt.wrong)
                              : (correct ? _Opt.dim : _Opt.idle)),
                      onTap: () => _select(o),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (correct) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: c.isDark ? c.mint : const Color(0xFFDDF5E6),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Icon(Icons.eco, size: 15, color: c.mintText),
                          const SizedBox(width: 6),
                          Expanded(child: Text('Correct Insight', style: T.j(12.5, w: FontWeight.w700, c: c.mintText))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(10)),
                            child: Row(children: [
                              Icon(Icons.check_circle_outline, size: 12, color: c.textMuted),
                              const SizedBox(width: 4),
                              Text('Answer checked', style: T.j(11, c: c.textMuted)),
                            ]),
                          ),
                        ]),
                        const SizedBox(height: 6),
                        Text(_q.insight, style: T.j(12.5, c: c.text, h: 1.5)),
                      ]),
                    ),
                    const SizedBox(height: 14),
                  ] else
                    const SizedBox(height: 10),
                  Row(children: [
                    Material(
                      color: _flagged[_i] ? const Color(0xFFFFF1C2) : (c.isDark ? c.cardAlt : const Color(0xFFEEF0FB)),
                      shape: StadiumBorder(
                          side: BorderSide(color: _flagged[_i] ? const Color(0xFFF5D06A) : Colors.transparent)),
                      child: InkWell(
                        customBorder: const StadiumBorder(),
                        onTap: () => setState(() => _flagged[_i] = !_flagged[_i]),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          child: Row(children: [
                            Icon(_flagged[_i] ? Icons.flag : Icons.outlined_flag,
                                size: 18, color: _flagged[_i] ? const Color(0xFFB45309) : c.text),
                            const SizedBox(width: 6),
                            Text(_flagged[_i] ? 'Flagged' : 'Flag',
                                style: T.j(14.5,
                                    w: _flagged[_i] ? FontWeight.w700 : FontWeight.w500,
                                    c: _flagged[_i] ? const Color(0xFFB45309) : c.text)),
                          ]),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: PrimaryButton(
                        last ? 'Finish Quiz' : 'Next Question',
                        trailingIcon: Icons.arrow_forward,
                        jakarta: true,
                        height: 52,
                        color: canNext ? (c.isDark ? c.primary : const Color(0xFF1F5A3D)) : const Color(0xFFDCE6FA),
                        fg: canNext ? null : const Color(0xFF8592AD),
                        shadow: canNext,
                        onTap: canNext ? _next : null,
                      ),
                    ),
                  ]),
                  if (_flagged[_i]) ...[
                    const SizedBox(height: 10),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.bookmark_border, size: 14, color: c.textMuted),
                      const SizedBox(width: 6),
                      Text('Marked for review in your post-quiz flashcards', style: T.j(11.5, c: c.textMuted)),
                    ]),
                  ],
                ]),
              ),
              const SizedBox(height: 24),
              const QuizHistoryHeader(),
              const SizedBox(height: 12),
              const QuizHistoryCard(),
              const SizedBox(height: 18),
              FlashReviewPromo(onTap: () {
                if (lastAttempt == null || lastAttempt.reviewIndices.isEmpty) {
                  showSnack(context, 'Finish a quiz first — missed or flagged questions become flashcards.');
                } else {
                  pushTab(context, FlashReviewScreen(attempt: lastAttempt));
                }
              }),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Prompt extends StatelessWidget {
  final QuizQuestion question;
  final bool revealed;
  const _Prompt({required this.question, required this.revealed});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final style = T.j(18.5, w: FontWeight.w600, c: c.text, h: 1.45);
    if (!question.fillBlank || !question.prompt.contains('______')) {
      return Text(question.prompt, style: style);
    }
    final parts = question.prompt.split('______');
    return RichText(
      text: TextSpan(style: style, children: [
        TextSpan(text: parts.first),
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: revealed ? const Color(0xFFCDF2DA) : const Color(0xFFE3ECFB),
              borderRadius: BorderRadius.circular(8),
              border: revealed ? null : const Border(bottom: BorderSide(color: Color(0xFF94A3B8))),
            ),
            child: Text(revealed ? question.options[question.answer] : '______',
                style: T.j(18.5,
                    w: revealed ? FontWeight.w600 : FontWeight.w500,
                    c: revealed ? const Color(0xFF1F5A3D) : const Color(0xFF475569))),
          ),
        ),
        TextSpan(text: parts.sublist(1).join('______')),
      ]),
    );
  }
}

enum _Opt { idle, correct, wrong, dim, reveal }

class _OptionTile extends StatelessWidget {
  final String letter;
  final String text;
  final _Opt state;
  final VoidCallback onTap;
  const _OptionTile({required this.letter, required this.text, required this.state, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    Color bg = c.isDark ? c.cardAlt : const Color(0xFFEEF2FD);
    Color fg = c.text;
    Color letterBg = c.card;
    Color letterFg = c.text;
    Widget? trail;
    Border? border;
    switch (state) {
      case _Opt.correct:
      case _Opt.reveal:
        bg = c.isDark ? c.mint : const Color(0xFFD7F5E2);
        fg = c.isDark ? c.accent : const Color(0xFF14432E);
        letterBg = const Color(0xFF1F5A3D);
        letterFg = Colors.white;
        border = Border.all(color: const Color(0xFFB9E5C8));
        trail = Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(color: Color(0xFF1F5A3D), shape: BoxShape.circle),
          child: const Icon(Icons.check, size: 15, color: Colors.white),
        );
        break;
      case _Opt.wrong:
        bg = c.isDark ? c.dangerBg : const Color(0xFFFDECEC);
        fg = const Color(0xFFDC2626);
        letterBg = const Color(0xFFDC2626);
        letterFg = Colors.white;
        trail = const Icon(Icons.close, size: 20, color: Color(0xFFDC2626));
        break;
      case _Opt.dim:
        fg = c.textMuted;
        letterFg = c.textMuted;
        break;
      case _Opt.idle:
        break;
    }
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 58),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: border),
          child: Row(children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: letterBg, borderRadius: BorderRadius.circular(8)),
              child: Text(letter, style: T.j(13, w: FontWeight.w600, c: letterFg)),
            ),
            const SizedBox(width: 16),
            Expanded(
                child:
                    Text(text, style: T.j(14.5, w: state == _Opt.correct ? FontWeight.w600 : FontWeight.w400, c: fg))),
            if (trail != null) trail,
          ]),
        ),
      ),
    );
  }
}
