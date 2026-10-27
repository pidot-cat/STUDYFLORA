import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// Flip-card review of up to 5 incorrect / unanswered / flagged questions.
class FlashReviewScreen extends StatefulWidget {
  final QuizAttempt attempt;
  const FlashReviewScreen({super.key, required this.attempt});
  @override
  State<FlashReviewScreen> createState() => _FlashReviewScreenState();
}

class _FlashReviewScreenState extends State<FlashReviewScreen> with SingleTickerProviderStateMixin {
  late final List<int> _cards = widget.attempt.reviewIndices;
  int _i = 0;
  late final AnimationController _flip = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  void _go(int d) {
    final n = (_i + d).clamp(0, _cards.length - 1).toInt();
    if (n == _i) return;
    setState(() => _i = n);
    _flip.value = 0;
  }

  void _toggle() => _flip.isCompleted || _flip.value > .5 ? _flip.reverse() : _flip.forward();

  void _backToStudy() => Navigator.of(context).popUntil((r) => r.isFirst);

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final a = widget.attempt;
    final total = _cards.length;
    return Scaffold(
      backgroundColor: c.isDark ? c.bg : const Color(0xFFF3F7F4),
      body: SafeArea(
        bottom: false,
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 28), children: [
          Row(children: [
            const CircleBackButton(size: 36, outlined: true),
            const SizedBox(width: 14),
            Text('Flash Review', style: T.j(19, w: FontWeight.w700, c: c.heading)),
          ]),
          Padding(
            padding: const EdgeInsets.only(left: 30, top: 8),
            child: Text('Review up to 5 flashcards per session.', style: T.j(13, c: c.text, style: FontStyle.italic)),
          ),
          const SizedBox(height: 14),
          SFCard(
            radius: 16,
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              IconTile(Icons.description_outlined,
                  size: 44, iconSize: 22, bg: c.isDark ? c.mint : const Color(0xFFE3F5EA)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(a.title, style: T.j(14.5, w: FontWeight.w700, c: c.text)),
                  Text('Quiz Score: ${a.percent}%  •  ${a.correct}/${a.total} correct', style: T.j(12, c: c.textMuted)),
                ]),
              ),
              Pill(a.mastered ? 'Mastered' : 'Not Mastered',
                  jakarta: true,
                  fontSize: 12,
                  weight: FontWeight.w500,
                  bg: c.isDark ? c.mint : const Color(0xFFD4F5E2),
                  fg: c.mintText,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5)),
            ]),
          ),
          const SizedBox(height: 14),
          Row(children: [
            _roundNav(Icons.chevron_left, () => _go(-1)),
            Expanded(
              child: Column(children: [
                Text('Card ${_i + 1} of $total', style: T.j(12.5, w: FontWeight.w500, c: c.text)),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: SFProgress(
                      value: (_i + 1) / total,
                      height: 5,
                      color: c.isDark ? c.accent : const Color(0xFF1F5A3D),
                      track: c.isDark ? c.border : const Color(0xFFD5F5E3)),
                ),
              ]),
            ),
            _roundNav(Icons.chevron_right, () => _go(1)),
          ]),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: _toggle,
            child: AnimatedBuilder(
              animation: _flip,
              builder: (_, __) {
                final v = _flip.value;
                final showBack = v > .5;
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, .001)
                    ..rotateY(math.pi * v),
                  child: showBack
                      ? Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()..rotateY(math.pi),
                          child: _back(context))
                      : _front(context),
                );
              },
            ),
          ),
          const SizedBox(height: 22),
          Row(children: [
            Expanded(
                child: OutlineButtonSF('Previous',
                    icon: Icons.chevron_left, height: 50, jakarta: true, onTap: () => _go(-1))),
            const SizedBox(width: 12),
            Expanded(
              child: PrimaryButton('Next',
                  trailingIcon: Icons.chevron_right,
                  height: 50,
                  jakarta: true,
                  shadow: false,
                  color: c.isDark ? c.primary : const Color(0xFF1B4D3E),
                  onTap: _i < total - 1 ? () => _go(1) : null),
            ),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: c.isDark ? c.cardAlt : const Color(0xFFEAF8EF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.isDark ? c.border : const Color(0xFFCDEBD8)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(color: c.isDark ? c.mint : const Color(0xFFCDEFD9), shape: BoxShape.circle),
                child: Icon(Icons.push_pin_outlined, size: 15, color: c.mintText),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Reviewing $total flashcard${total == 1 ? '' : 's'}',
                      style: T.j(12.5, w: FontWeight.w700, c: c.text)),
                  Text(
                      'These flashcards are based on concepts you answered incorrectly, left unanswered, or flagged during your quiz.',
                      style: T.j(12, c: c.textMuted, h: 1.4)),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 18),
          PrimaryButton('Finish Review',
              icon: Icons.outlined_flag,
              height: 46,
              radius: 12,
              jakarta: true,
              shadow: false,
              color: c.isDark ? c.primary : const Color(0xFF1B4D3E), onTap: () {
            showSnack(context, 'Flash review complete. Keep growing! 🌱');
            Navigator.of(context).pop();
          }),
          const SizedBox(height: 12),
          OutlineButtonSF('Back to Study',
              icon: Icons.arrow_back, height: 46, radius: 12, jakarta: true, onTap: _backToStudy),
        ]),
      ),
    );
  }

  Widget _roundNav(IconData icon, VoidCallback onTap) {
    final c = context.c;
    return Material(
      color: c.card,
      shape: CircleBorder(side: BorderSide(color: c.border)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 28, height: 28, child: Icon(icon, size: 18, color: c.text)),
      ),
    );
  }

  Widget _front(BuildContext context) {
    final c = context.c;
    final qi = _cards[_i];
    final q = widget.attempt.questions[qi];
    return Container(
      height: 240,
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: c.isDark ? c.border : const Color(0xFFCDEFD9)),
      ),
      child: Column(children: [
        Row(children: [
          Pill('Concept',
              jakarta: true,
              fontSize: 12,
              weight: FontWeight.w500,
              bg: c.isDark ? c.mint : const Color(0xFFE3F8EA),
              borderColor: const Color(0xFFB9EBCB),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2)),
          const Spacer(),
          Text('Question No. ${qi + 1}', style: T.j(13, w: FontWeight.w500, c: c.text)),
          const Spacer(flex: 2),
        ]),
        const SizedBox(height: 12),
        Expanded(
          child: Center(
            child: Text(q.prompt,
                textAlign: TextAlign.center,
                style: T.j(18, w: FontWeight.w500, c: c.isDark ? c.accent : const Color(0xFF1F5A3D), h: 1.35)),
          ),
        ),
        const Icon(Icons.eco, size: 34, color: Color(0xFF2E6B4C)),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.sync, size: 15, color: c.textMuted),
          const SizedBox(width: 6),
          Text('Tap to flip', style: T.j(12.5, c: c.textMuted)),
        ]),
      ]),
    );
  }

  Widget _back(BuildContext context) {
    final c = context.c;
    final qi = _cards[_i];
    final q = widget.attempt.questions[qi];
    return Container(
      constraints: const BoxConstraints(minHeight: 240),
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 12),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: c.isDark ? c.border : const Color(0xFFCDEFD9)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Pill('✓ CORRECT ANSWER',
              jakarta: true,
              fontSize: 12,
              weight: FontWeight.w500,
              bg: c.isDark ? c.mint : const Color(0xFFE3F8EA),
              fg: c.text,
              borderColor: const Color(0xFFB9EBCB),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3)),
          const Spacer(),
          Flexible(
            child: Pill(widget.attempt.title,
                jakarta: true,
                fontSize: 11,
                weight: FontWeight.w400,
                bg: c.isDark ? c.cardAlt : const Color(0xFFF2F7F3),
                fg: c.textMuted,
                borderColor: c.border,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3)),
          ),
        ]),
        const SizedBox(height: 14),
        Text('ANSWER', style: T.j(11.5, w: FontWeight.w500, c: c.textMuted, ls: .4)),
        const SizedBox(height: 4),
        Text('${String.fromCharCode(65 + q.answer)}. ${q.options[q.answer]}',
            style: T.j(21, w: FontWeight.w600, c: c.isDark ? c.accent : const Color(0xFF1F5A3D))),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.isDark ? c.mint : const Color(0xFFE8F7EE),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFC9EED6)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.lightbulb_outline, size: 16, color: c.mintText),
              const SizedBox(width: 6),
              Text('Key Insight', style: T.j(12.5, w: FontWeight.w600, c: c.text)),
            ]),
            const SizedBox(height: 8),
            Text(q.insight, style: T.j(12, c: c.text, h: 1.55)),
          ]),
        ),
        const SizedBox(height: 6),
        Center(
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.sync, size: 15, color: c.textMuted),
            const SizedBox(width: 4),
            Text('Tap to flip', style: T.j(12.5, c: c.textMuted)),
          ]),
        ),
      ]),
    );
  }
}
