import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/app_header.dart';
import '../../widgets/common.dart';

class ReviewAnswersScreen extends StatelessWidget {
  final QuizAttempt attempt;
  const ReviewAnswersScreen({super.key, required this.attempt});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final a = attempt;
    return Scaffold(
      backgroundColor: c.isDark ? c.bg : const Color(0xFFF7F8FE),
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          const AppHeader(divider: true),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(20, 14, 20, 28), children: [
              InkWell(
                onTap: () => Navigator.of(context).pop(),
                child: Row(children: [
                  Icon(Icons.arrow_back, size: 16, color: c.heading),
                  const SizedBox(width: 4),
                  Text('Quiz Results', style: T.j(13, w: FontWeight.w500, c: c.heading)),
                ]),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: Pill('STUDY MODULE',
                    icon: Icons.spa_outlined,
                    jakarta: true,
                    fontSize: 11,
                    bg: c.isDark ? c.mint : const Color(0xFFB9EDCA),
                    fg: c.isDark ? c.accent : const Color(0xFF1F5A3D),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2)),
              ),
              const SizedBox(height: 8),
              Text('Review Answers',
                  style: T.j(25, w: FontWeight.w600, c: c.isDark ? c.text : const Color(0xFF1F5A3D))),
              Text(a.title, style: T.j(17, c: c.text)),
              const SizedBox(height: 4),
              Text('Review your answers and learn from your mistakes.', style: T.j(13.5, c: c.textMuted)),
              const SizedBox(height: 18),
              _Summary(attempt: a),
              const SizedBox(height: 18),
              for (var i = 0; i < a.total; i++) ...[
                _QuestionCard(attempt: a, index: i),
                const SizedBox(height: 16),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  final QuizAttempt attempt;
  const _Summary({required this.attempt});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final a = attempt;
    Widget tile(String top, Widget icon, String value, String bottom, Color bg, Color fg) => Container(
          height: 74,
          decoration: BoxDecoration(color: c.isDark ? c.cardAlt : bg, borderRadius: BorderRadius.circular(8)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(top, style: T.j(12, w: FontWeight.w500, c: fg)),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              icon,
              const SizedBox(width: 4),
              Text(value, style: T.j(19, w: FontWeight.w600, c: c.text)),
            ]),
            Text(bottom, style: T.j(12, c: fg)),
          ]),
        );
    return SFCard(
      radius: 16,
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Row(children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: c.isDark ? c.mint : const Color(0xFFB9EDCA), shape: BoxShape.circle),
            child: Icon(Icons.insights, size: 17, color: c.mintText),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text('Performance Summary', style: T.j(18, w: FontWeight.w500, c: c.text))),
          Text('Attempt #${a.attemptNo}', style: T.j(12.5, c: c.textMuted)),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
              child: tile('Total', Icon(Icons.quiz_outlined, size: 15, color: c.text), '${a.total}', 'Questions',
                  const Color(0xFFE7EBFA), c.textMuted)),
          const SizedBox(width: 8),
          Expanded(
              child: tile('Accuracy', const Icon(Icons.check_circle, size: 15, color: Color(0xFF1F5A3D)),
                  '${a.correct}', 'Correct', const Color(0xFFCFF3DD), const Color(0xFF1F5A3D))),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
              child: tile('Needs Review', const Icon(Icons.cancel, size: 15, color: Color(0xFFDC2626)),
                  '${a.incorrect}', 'Incorrect', const Color(0xFFFDE2E2), const Color(0xFFB91C1C))),
          const SizedBox(width: 8),
          Expanded(
              child: tile('Omitted', Icon(Icons.radio_button_unchecked, size: 15, color: c.textMuted),
                  '${a.unanswered}', 'Unanswered', const Color(0xFFE7EEFB), c.textMuted)),
        ]),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: c.isDark ? c.cardAlt : const Color(0xFFE7EBFA), borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            Icon(Icons.stars_outlined, size: 18, color: c.mintText),
            const SizedBox(width: 8),
            Expanded(
                child: Text('Score: ${a.correct}/${a.total} (${a.percent}%)',
                    style: T.j(13.5, w: FontWeight.w500, c: c.mintText))),
            Text(a.percent >= 80 ? '— Well done!' : (a.percent >= 60 ? '— Good effort!' : '— Keep going!'),
                style: T.j(13, c: c.textMuted)),
            const SizedBox(width: 12),
            Text('+${a.coins}\nCoins', style: T.j(11, w: FontWeight.w600, c: c.mintText)),
          ]),
        ),
      ]),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final QuizAttempt attempt;
  final int index;
  const _QuestionCard({required this.attempt, required this.index});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final q = attempt.questions[index];
    final ans = attempt.answers[index];
    final correct = ans == q.answer;
    final unanswered = ans == null;
    final flagged = attempt.flagged[index];
    return SFCard(
      radius: 16,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Pill('Question ${two(index + 1)} of ${two(attempt.total)}',
              jakarta: true,
              fontSize: 12,
              weight: FontWeight.w500,
              bg: c.isDark ? c.cardAlt : const Color(0xFFE7EEFB),
              fg: c.text,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3)),
          const Spacer(),
          if (unanswered)
            Pill('— Unanswered',
                jakarta: true,
                fontSize: 12,
                weight: FontWeight.w500,
                bg: const Color(0xFFE0E7FF),
                fg: const Color(0xFF334155),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3))
          else
            Pill(correct ? '✓ Correct' : '✕ Incorrect',
                jakarta: true,
                fontSize: 12,
                weight: FontWeight.w500,
                bg: correct ? const Color(0xFFB9EDCA) : const Color(0xFFFFD9D9),
                fg: correct ? const Color(0xFF1F5A3D) : const Color(0xFFDC2626),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3)),
          if (flagged) ...[
            const SizedBox(width: 6),
            Pill('Flagged',
                icon: Icons.flag,
                jakarta: true,
                fontSize: 12,
                bg: const Color(0xFFFFF1C2),
                fg: const Color(0xFF92400E),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3)),
          ],
        ]),
        const SizedBox(height: 12),
        Text(q.prompt.replaceAll('______', '________'),
            style: T.j(17.5, w: FontWeight.w600, c: c.isDark ? c.accent : const Color(0xFF1F5A3D), h: 1.4)),
        if (unanswered) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
                color: c.isDark ? c.cardAlt : const Color(0xFFE7EEFB), borderRadius: BorderRadius.circular(4)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.info_outline, size: 12, color: c.textMuted),
              const SizedBox(width: 4),
              Text('Not answered during quiz', style: T.j(11.5, c: c.textMuted, style: FontStyle.italic)),
            ]),
          ),
        ],
        const SizedBox(height: 10),
        for (var o = 0; o < q.options.length; o++) ...[
          _AnswerRow(
            text: '${String.fromCharCode(65 + o)}. ${q.options[o]}',
            mode: o == ans
                ? (correct ? _Mode.yourCorrect : _Mode.yourWrong)
                : ((o == q.answer && !correct) ? _Mode.correctAnswer : _Mode.plain),
          ),
          const SizedBox(height: 6),
        ],
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: c.isDark ? c.cardAlt : const Color(0xFFE7EBFA), borderRadius: BorderRadius.circular(8)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(color: Color(0xFFB9EDCA), shape: BoxShape.circle),
              child: const Icon(Icons.lightbulb_outline, size: 15, color: Color(0xFF1F5A3D)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Correct Insight',
                    style: T.j(12, w: FontWeight.w700, c: c.isDark ? c.accent : const Color(0xFF1F5A3D))),
                const SizedBox(height: 2),
                Text(q.insight, style: T.j(12, c: c.text, h: 1.5)),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}

enum _Mode { plain, yourCorrect, yourWrong, correctAnswer }

class _AnswerRow extends StatelessWidget {
  final String text;
  final _Mode mode;
  const _AnswerRow({required this.text, required this.mode});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    Color? bg;
    Color fg = c.text;
    IconData icon = Icons.radio_button_unchecked;
    Color iconColor = c.textMuted;
    Widget? tag;
    switch (mode) {
      case _Mode.yourCorrect:
        bg = c.isDark ? c.mint : const Color(0xFFDDF7E6);
        fg = c.isDark ? c.accent : const Color(0xFF1F5A3D);
        icon = Icons.check_circle;
        iconColor = const Color(0xFF1F5A3D);
        tag = _tag('Your Choice', Colors.white, const Color(0xFF1F5A3D));
        break;
      case _Mode.yourWrong:
        bg = c.isDark ? c.dangerBg : const Color(0xFFFFD9D9);
        fg = const Color(0xFFB91C1C);
        icon = Icons.cancel;
        iconColor = const Color(0xFFDC2626);
        tag = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text('Your\nAnswer', style: T.j(10.5, w: FontWeight.w600, c: const Color(0xFFDC2626))),
            const SizedBox(width: 8),
            const Icon(Icons.close, size: 14, color: Color(0xFFDC2626)),
          ]),
        );
        break;
      case _Mode.correctAnswer:
        bg = c.isDark ? c.mint : const Color(0xFFDDF7E6);
        fg = c.isDark ? c.accent : const Color(0xFF1F5A3D);
        icon = Icons.check_circle;
        iconColor = const Color(0xFF1F5A3D);
        tag = _tag('Correct Answer', const Color(0xFF1F5A3D), Colors.white);
        break;
      case _Mode.plain:
        break;
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: T.j(14.5, w: bg != null ? FontWeight.w600 : FontWeight.w400, c: fg))),
        if (tag != null) tag,
      ]),
    );
  }

  Widget _tag(String t, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Text(t, style: T.j(11, w: FontWeight.w600, c: fg)),
      );
}
