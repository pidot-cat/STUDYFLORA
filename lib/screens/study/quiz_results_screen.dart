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
import 'review_answers_screen.dart';
import 'study_widgets.dart';

String bracketLabel(int p) {
  if (p >= 100) return '100%';
  if (p >= 90) return '90 – 99%';
  if (p >= 80) return '80 – 89%';
  if (p >= 70) return '70 – 79%';
  if (p >= 60) return '60 – 69%';
  if (p >= 50) return '50 – 59%';
  return '0% – 49%';
}

class QuizResultsScreen extends StatelessWidget {
  final QuizAttempt attempt;
  final bool fromHistory;
  const QuizResultsScreen({super.key, required this.attempt, this.fromHistory = false});

  void _backToStudy(BuildContext context) => Navigator.of(context).popUntil((r) => r.isFirst);

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final s = context.watch<AppState>();
    final a = attempt;
    final module = s.moduleById(a.moduleId);
    final best = module?.bestScore ?? a.percent;
    return Scaffold(
      backgroundColor: c.isDark ? c.bg : const Color(0xFFF3F7F4),
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          AppHeader(back: fromHistory),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 28), children: [
              if (fromHistory) ...[
                const SyncStatusRow(compact: true, prefix: 'Synced:'),
                const SizedBox(height: 18),
                Row(children: [
                  Text('Quiz History', style: T.p(12.5, c: c.textMuted)),
                  Text('  /  ', style: T.p(12.5, c: c.textFaint)),
                  Text('Attempt Details', style: T.p(12.5, w: FontWeight.w600, c: c.heading)),
                  const Spacer(),
                  _studyModulePill(context, small: true),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Text('Quiz Results', style: T.serif(24, c: c.heading)),
                  const Spacer(),
                  Pill('Attempt #${a.attemptNo}',
                      icon: Icons.bookmark_border,
                      fontSize: 12.5,
                      bg: c.isDark ? c.mint : const Color(0xFFE3F5EA),
                      fg: c.heading,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5)),
                ]),
                Text('A little practice, a little more growth 🌱',
                    style: T.p(12.5, c: c.mintText, style: FontStyle.italic)),
                const SizedBox(height: 16),
                SFCard(
                  radius: 16,
                  padding: const EdgeInsets.all(16),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(a.title, style: T.p(16, w: FontWeight.w500, c: c.heading)),
                        const SizedBox(height: 4),
                        Row(children: [
                          Icon(Icons.insert_drive_file_outlined, size: 14, color: c.textMuted),
                          const SizedBox(width: 6),
                          Expanded(child: Text(a.fileName, style: T.p(12.5, c: c.text))),
                        ]),
                        const SizedBox(height: 4),
                        Text('Completed ${fmtDate(a.date)} • ${a.total} Questions Total',
                            style: T.p(11.5, c: c.textMuted)),
                      ]),
                    ),
                    Pill(a.mastered ? 'Mastered' : 'Not Mastered',
                        icon: a.mastered ? Icons.check : null,
                        bg: a.mastered ? (c.isDark ? c.mint : const Color(0xFFE3F8EA)) : c.blueTint,
                        fg: a.mastered ? c.mintText : const Color(0xFF283593),
                        borderColor: const Color(0xFFA7E3BD),
                        weight: FontWeight.w500,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                  ]),
                ),
                const SizedBox(height: 16),
              ] else ...[
                Align(alignment: Alignment.centerLeft, child: _studyModulePill(context)),
                const SizedBox(height: 10),
                Text('Quiz Results', style: T.p(24, w: FontWeight.w600, c: c.heading)),
                Text('A little practice, a little more growth.', style: T.p(12.5, c: c.textMuted)),
                const SizedBox(height: 4),
                Row(children: [
                  Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(color: Color(0xFFF59E0B), shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text('Best score $best% • ', style: T.p(12, c: c.text)),
                  Text(best >= 60 ? 'Mastered' : 'Not mastered',
                      style: T.p(12, c: best >= 60 ? const Color(0xFF15924F) : c.danger)),
                  Text(' (60% required)', style: T.p(12, c: c.text)),
                ]),
                const SizedBox(height: 16),
              ],
              _ScoreCard(attempt: a, showHeader: !fromHistory),
              const SizedBox(height: 18),
              _CoinsCard(attempt: a),
              const SizedBox(height: 26),
              PrimaryButton('Review Answers',
                  icon: Icons.fact_check_outlined,
                  radius: 14,
                  color: c.isDark ? c.primary : const Color(0xFF1B4332),
                  onTap: () => pushTab(context, ReviewAnswersScreen(attempt: a))),
              const SizedBox(height: 18),
              PrimaryButton(fromHistory ? 'Review Missed Concepts' : 'Flash Review',
                  icon: Icons.style_outlined,
                  radius: 14,
                  color: c.isDark ? c.mint : const Color(0xFFD5FAE7),
                  fg: c.isDark ? c.accent : const Color(0xFF1B4332),
                  fontSize: 14.5,
                  onTap: a.reviewIndices.isEmpty
                      ? () => showSnack(context, 'Perfect run — nothing to review!')
                      : () => pushTab(context, FlashReviewScreen(attempt: a))),
              const SizedBox(height: 18),
              OutlineButtonSF('Back to Study',
                  icon: Icons.arrow_back,
                  radius: 14,
                  borderColor: const Color(0xFFCDE3D6),
                  onTap: () => _backToStudy(context)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _studyModulePill(BuildContext context, {bool small = false}) {
    final c = context.c;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 8 : 10, vertical: 4),
      decoration:
          BoxDecoration(color: c.isDark ? c.mint : const Color(0xFFDDF5E6), borderRadius: BorderRadius.circular(6)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (!small) ...[Icon(Icons.article, size: 13, color: c.mintText), const SizedBox(width: 6)],
        Text('STUDY MODULE', style: T.p(small ? 10 : 11, w: FontWeight.w600, c: c.mintText, ls: .5)),
      ]),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final QuizAttempt attempt;
  final bool showHeader;
  const _ScoreCard({required this.attempt, required this.showHeader});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final a = attempt;
    final miss = a.incorrect + a.unanswered;
    final title = a.percent >= 80 ? 'Well done!' : (a.percent >= 60 ? 'Good effort!' : 'Keep growing!');
    final sub = miss == 0
        ? 'Perfect score — full mastery reached!'
        : '${_numWord(miss)} concept${miss == 1 ? '' : 's'} to revisit before your next quiz to reach full mastery.';
    return SFCard(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (showHeader) ...[
          Row(children: [
            Pill('Latest attempt',
                fontSize: 11.5,
                weight: FontWeight.w500,
                bg: c.isDark ? c.mint : const Color(0xFFDDF5E6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3)),
            const Spacer(),
            Text('Attempt ${a.attemptNo} • ${a.total} questions', style: T.p(11.5, c: c.textMuted)),
          ]),
          const SizedBox(height: 12),
          Divider(color: c.border, height: 1),
          const SizedBox(height: 14),
          Text(a.title, style: T.p(16, w: FontWeight.w600, c: c.heading)),
          Row(children: [
            Icon(Icons.insert_drive_file, size: 13, color: c.textMuted),
            const SizedBox(width: 4),
            Text(a.fileName, style: T.p(12.5, c: c.textMuted)),
          ]),
          const SizedBox(height: 12),
        ],
        Container(
          height: 130,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: c.isDark ? [c.mint, c.cardAlt] : const [Color(0xFFDDF7E9), Color(0xFFF2FCF6)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFB6EBCB)),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('${a.correct}/${a.total}', style: T.j(34, w: FontWeight.w700, c: c.heading)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFCDEBD8))),
              child: RichText(
                text: TextSpan(children: [
                  TextSpan(text: '${a.percent}% ', style: T.p(15, w: FontWeight.w600, c: c.mintText)),
                  TextSpan(text: 'accuracy', style: T.p(10.5, c: c.textMuted)),
                ]),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 4),
        SFProgress(
            value: a.percent / 100,
            height: 5,
            gradient: const LinearGradient(colors: [Color(0xFF34D399), Color(0xFF15803D)])),
        const SizedBox(height: 18),
        Center(child: Text(title, style: T.p(17, w: FontWeight.w600, c: c.heading))),
        const SizedBox(height: 4),
        Text(sub, textAlign: TextAlign.center, style: T.p(12, c: c.textMuted, h: 1.45)),
        const SizedBox(height: 10),
        Divider(color: c.border, height: 1),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
              child: _StatTile('✓', '${a.correct}', 'CORRECT', const Color(0xFFF0FDF6), const Color(0xFFBBF7D0),
                  const Color(0xFF15803D))),
          const SizedBox(width: 8),
          Expanded(
              child: _StatTile('✕', '${a.incorrect}', 'INCORRECT', const Color(0xFFFEF2F2), const Color(0xFFFECACA),
                  const Color(0xFFDC2626))),
          const SizedBox(width: 8),
          Expanded(
              child: _StatTile('—', '${a.unanswered}', 'UNANSWERED', const Color(0xFFF8FAFC), const Color(0xFFE2E8F0),
                  const Color(0xFF64748B))),
        ]),
        const SizedBox(height: 12),
        Center(
          child: Text('Unanswered questions count as incorrect in the total score.',
              style: T.p(10.5, c: c.textFaint, style: FontStyle.italic)),
        ),
      ]),
    );
  }

  static String _numWord(int n) => const [
        'Zero',
        'One',
        'Two',
        'Three',
        'Four',
        'Five',
        'Six',
        'Seven',
        'Eight',
        'Nine',
        'Ten'
      ][n.clamp(0, 10).toInt()];
}

class _StatTile extends StatelessWidget {
  final String glyph, value, label;
  final Color bg, border, fg;
  const _StatTile(this.glyph, this.value, this.label, this.bg, this.border, this.fg);
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      height: 78,
      decoration: BoxDecoration(
          color: c.isDark ? c.cardAlt : bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.isDark ? c.border : border)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(glyph, style: T.p(12, c: fg)),
        Text(value, style: T.p(16, w: FontWeight.w600, c: fg == const Color(0xFF64748B) ? c.text : fg)),
        Text(label, style: T.p(10.5, w: FontWeight.w600, c: fg, ls: .3)),
      ]),
    );
  }
}

class _CoinsCard extends StatelessWidget {
  final QuizAttempt attempt;
  const _CoinsCard({required this.attempt});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final p = attempt.percent;
    const left = [('100%', 100), ('90% – 99%', 75), ('80% – 89%', 50), ('70% – 79%', 30)];
    const right = [('60% – 69%', 20), ('50% – 59%', 10), ('0% – 49%', 5)];
    final current = coinsForPercent(p);
    Widget row((String, int) e) {
      final active = e.$2 == current;
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        decoration: BoxDecoration(
            color: active ? const Color(0xFFDDF7E9) : Colors.transparent, borderRadius: BorderRadius.circular(4)),
        child: Row(children: [
          if (active) const Icon(Icons.check, size: 11, color: Color(0xFF15803D)),
          if (active) const SizedBox(width: 4),
          Expanded(
              child: Text(e.$1,
                  style: T.p(11,
                      w: active ? FontWeight.w700 : FontWeight.w400,
                      c: active ? const Color(0xFF14532D) : const Color(0xFF3F3F46)))),
          Text('→ +${e.$2} coins',
              style: T.p(11, w: FontWeight.w700, c: active ? const Color(0xFF14532D) : const Color(0xFF27272A))),
        ]),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.isDark ? c.amberTint : const Color(0xFFFFFBEF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF6E3A6)),
      ),
      child: Column(children: [
        Row(children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFFBBF24),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A), width: 2),
            ),
            alignment: Alignment.center,
            child: const CoinGlyph(size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('+${attempt.coins} Coins earned',
                    style: T.p(15.5, w: FontWeight.w600, c: const Color(0xFF7C2D12))),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(color: const Color(0xFFFDE68A), borderRadius: BorderRadius.circular(4)),
                  child: Text('REWARD', style: T.p(9.5, w: FontWeight.w600, c: const Color(0xFF7C2D12))),
                ),
              ]),
              Text('${bracketLabel(p)} score reward • Attempt ${attempt.attemptNo}',
                  style: T.p(11.5, c: const Color(0xFFB45309))),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFCF5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFF6E3A6)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('SCORE BRACKET', style: T.p(9.5, w: FontWeight.w700, c: const Color(0xFFB45309), ls: .5)),
            const SizedBox(height: 6),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Column(children: [for (final e in left) row(e)])),
              const SizedBox(width: 6),
              Expanded(child: Column(children: [for (final e in right) row(e)])),
            ]),
          ]),
        ),
        const SizedBox(height: 10),
        Text(
            'Rewards are based on your final score. With 10 questions, scores increase in 10% increments (e.g., 60%, 70%, 80%, 90%, 100%).',
            textAlign: TextAlign.center,
            style: T.p(10, c: const Color(0xFFB45309), style: FontStyle.italic, h: 1.4)),
      ]),
    );
  }
}
