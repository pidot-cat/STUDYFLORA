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
import '../home/home_screen.dart';
import 'quiz_results_screen.dart';
import 'study_widgets.dart';

class QuizHistoryScreen extends StatelessWidget {
  const QuizHistoryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = context.c;
    final h = s.history;
    final avg = h.isEmpty ? 0 : (h.map((e) => e.percent).reduce((a, b) => a + b) / h.length).round();
    final mastered = h.where((e) => e.mastered).length;
    final coins = h.fold<int>(0, (a, e) => a + e.coins);
    return Scaffold(
      backgroundColor: c.isDark ? c.bg : const Color(0xFFF3F7F4),
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          const AppHeader(back: true),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(20, 6, 20, 28), children: [
              const SyncStatusRow(compact: true, prefix: 'Synced:'),
              const SizedBox(height: 18),
              Row(children: [
                Text('Study', style: T.j(12, w: FontWeight.w500, c: c.mintText)),
                Icon(Icons.chevron_right, size: 14, color: c.textMuted),
                Text('Quiz History', style: T.j(12, c: c.text)),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                Text('Quiz History', style: T.j(25, w: FontWeight.w800, c: c.heading)),
                const Spacer(),
                Pill('${h.length} Attempts',
                    jakarta: true,
                    fontSize: 12,
                    bg: c.isDark ? c.mint : const Color(0xFFD7F5E2),
                    borderColor: const Color(0xFFB9EBCB),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
              ]),
              const SizedBox(height: 6),
              Text('Review your previous quiz attempts, mastery scores, and earned rewards.',
                  style: T.j(13.5, c: c.textMuted, h: 1.45)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: c.isDark ? c.cardAlt : const Color(0xFFE8EFEA),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: c.border)),
                child: Row(children: [
                  Expanded(child: _stat(context, 'AVG SCORE', '$avg%', c.heading)),
                  const SizedBox(width: 8),
                  Expanded(child: _stat(context, 'MASTERED', '$mastered / ${h.length}', c.heading)),
                  const SizedBox(width: 8),
                  Expanded(child: _stat(context, 'COINS WON', '+$coins', const Color(0xFFD97706))),
                ]),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                    child: Text('RECORDED ATTEMPTS (NEWEST FIRST)',
                        style: T.j(11.5, w: FontWeight.w700, c: c.textFaint, ls: .3))),
                Text('Sorted by Date', style: T.j(11.5, w: FontWeight.w500, c: c.mintText)),
              ]),
              const SizedBox(height: 10),
              for (final a in h) ...[
                _AttemptCard(attempt: a),
                const SizedBox(height: 14),
              ],
              const SizedBox(height: 4),
              InfoBanner('',
                  icon: Icons.info_outline,
                  rich: RichText(
                    text: TextSpan(
                        style: T.j(13, c: c.isDark ? c.textMuted : const Color(0xFF14532D), h: 1.5),
                        children: [
                          TextSpan(
                              text: 'Quiz Attempts Policy: ',
                              style: T.j(13, w: FontWeight.w700, c: c.isDark ? c.text : const Color(0xFF14532D))),
                          const TextSpan(
                              text:
                                  'Each quiz is generated from its archived study document. Retaking a quiz creates a new attempt without overwriting previous history. Viewing past results does not award duplicate coins. Passing threshold: 60%.'),
                        ]),
                  )),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _stat(BuildContext context, String label, String value, Color color) {
    final c = context.c;
    return Container(
      height: 62,
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(10)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(label, style: T.j(10.5, w: FontWeight.w500, c: c.textMuted, ls: .4)),
        Text(value, style: T.j(17, w: FontWeight.w700, c: color)),
      ]),
    );
  }
}

class _AttemptCard extends StatelessWidget {
  final QuizAttempt attempt;
  const _AttemptCard({required this.attempt});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final a = attempt;
    final module = context.read<AppState>().moduleById(a.moduleId);
    final topics = module?.overview.join(', ') ?? '';
    return SFCard(
      radius: 18,
      borderColor: const Color(0xFFD5EEDD),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          IconTile(moduleGlyph(module?.iconKey ?? 'file'),
              size: 40,
              iconSize: 20,
              radius: 10,
              bg: c.isDark ? c.mint : const Color(0xFFEAF8EF),
              borderColor: const Color(0xFFC9EED6)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a.title, style: T.j(15.5, w: FontWeight.w700, c: c.text)),
              Row(children: [
                Icon(Icons.insert_drive_file, size: 12, color: c.mintText),
                const SizedBox(width: 4),
                Flexible(child: Text(a.fileName, style: T.j(12, c: c.text))),
              ]),
              if (topics.isNotEmpty) Text('Topics: $topics', style: T.j(11, c: c.textMuted, h: 1.4)),
              Text('${fmtDate(a.date)} • Attempt #${a.attemptNo}', style: T.j(11.5, c: c.textFaint)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${a.percent}%', style: T.j(18, w: FontWeight.w800, c: c.heading)),
            Text('${a.correct} / ${a.total} correct', style: T.j(10.5, c: c.textMuted)),
          ]),
        ]),
        const SizedBox(height: 14),
        SFProgress(
            value: a.percent / 100,
            height: 6,
            color: c.isDark ? c.accent : const Color(0xFF1B6B3F),
            track: c.isDark ? c.border : const Color(0xFFE8ECF0)),
        const SizedBox(height: 12),
        Divider(color: c.border, height: 1),
        const SizedBox(height: 10),
        Row(children: [
          Pill(a.mastered ? 'Mastered' : 'Not Mastered',
              icon: a.mastered ? Icons.check : null,
              jakarta: true,
              fontSize: 11,
              weight: FontWeight.w500,
              bg: a.mastered ? const Color(0xFFE3F8EA) : const Color(0xFFE0E7FF),
              fg: a.mastered ? const Color(0xFF15803D) : const Color(0xFF283593),
              borderColor: a.mastered ? const Color(0xFFA7E3BD) : null,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3)),
          const SizedBox(width: 6),
          Pill('+${a.coins} coins',
              dot: true,
              jakarta: true,
              fontSize: 11,
              weight: FontWeight.w500,
              bg: const Color(0xFFFFF6DD),
              fg: const Color(0xFFB45309),
              borderColor: const Color(0xFFF7DB8A),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3)),
          const Spacer(),
          InkWell(
            onTap: () => pushTab(context, QuizResultsScreen(attempt: a, fromHistory: true)),
            child: Row(children: [
              Text('View Results', style: T.j(13, w: FontWeight.w700, c: c.heading)),
              Icon(Icons.chevron_right, size: 18, color: c.heading),
            ]),
          ),
        ]),
      ]),
    );
  }
}
