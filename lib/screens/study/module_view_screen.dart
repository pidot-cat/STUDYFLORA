import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../nav.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header.dart';
import '../../widgets/common.dart';
import '../home/home_screen.dart';
import 'module_summary_screen.dart';
import 'quiz_screen.dart';

/// "View mod" – a saved module opened from Archived Modules.
class ModuleViewScreen extends StatelessWidget {
  final String moduleId;
  const ModuleViewScreen({super.key, required this.moduleId});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = context.c;
    final m = s.moduleById(moduleId);
    if (m == null) return const Scaffold();
    final last = s.history.where((h) => h.moduleId == m.id).toList();
    final attempt = last.isEmpty ? null : last.first;
    final score = attempt?.percent ?? (m.bestScore < 0 ? 0 : m.bestScore);
    return Scaffold(
      backgroundColor: c.isDark ? c.bg : const Color(0xFFF3F7F4),
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          const AppHeader(back: true),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 28), children: [
              Row(children: [
                Pill('Archived Modules',
                    fontSize: 12.5,
                    bg: c.isDark ? c.mint : const Color(0xFFDDF0E4),
                    fg: c.heading,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6)),
                const Spacer(),
                Icon(Icons.archive_outlined, size: 15, color: c.textMuted),
                const SizedBox(width: 4),
                Text('Archived View', style: T.p(12.5, c: c.textMuted)),
              ]),
              const SizedBox(height: 14),
              SFCard(
                radius: 22,
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    IconTile(moduleGlyph(m.iconKey),
                        size: 56, iconSize: 26, radius: 14, bg: c.isDark ? c.mint : const Color(0xFFE3F2E8)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Pill('SAVED MODULE',
                              dot: true,
                              fontSize: 10,
                              bg: c.isDark ? c.mint : const Color(0xFFE3F5EA),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2)),
                          const SizedBox(width: 6),
                          Text('Previously Processed', style: T.p(10.5, c: c.textMuted)),
                        ]),
                        const SizedBox(height: 4),
                        Text(m.title, style: T.serif(20, c: c.heading)),
                        Row(children: [
                          Icon(Icons.insert_drive_file_outlined, size: 13, color: c.textMuted),
                          const SizedBox(width: 4),
                          Flexible(
                              child: Text('${m.fileName}  •  ${m.ext.toUpperCase()} • Uploaded',
                                  overflow: TextOverflow.ellipsis, style: T.p(11.5, c: c.textMuted))),
                        ]),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: c.isDark ? c.cardAlt : const Color(0xFFF1F6F2), borderRadius: BorderRadius.circular(14)),
                    child: Column(children: [
                      Row(children: [
                        Pill(
                            attempt == null ? 'Not taken' : (score >= 60 ? 'Mastered $score%' : 'Not Mastered $score%'),
                            icon: Icons.check_circle,
                            fontSize: 12,
                            weight: FontWeight.w700,
                            bg: c.isDark ? c.mint : const Color(0xFFD7F5E2),
                            fg: c.heading,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                        const Spacer(),
                        if (attempt != null)
                          RichText(
                            text: TextSpan(children: [
                              TextSpan(
                                  text: '${attempt.correct}/${attempt.total} ',
                                  style: T.p(13, w: FontWeight.w700, c: c.text)),
                              TextSpan(text: 'Correct ', style: T.p(12, c: c.text)),
                              TextSpan(text: '(Pass: 60%)', style: T.p(12, c: c.textMuted)),
                            ]),
                          ),
                      ]),
                      const SizedBox(height: 10),
                      SFProgress(
                          value: score / 100,
                          height: 8,
                          color: const Color(0xFF2E9E64),
                          track: c.isDark ? c.border : const Color(0xFFE5E7EB)),
                      const SizedBox(height: 10),
                      Row(children: [
                        Text(attempt == null ? 'No attempts recorded' : 'Recorded Attempt #${attempt.attemptNo}',
                            style: T.p(11.5, c: c.textMuted)),
                        const Spacer(),
                        Text('Score Preserved', style: T.p(11.5, c: const Color(0xFF15924F))),
                      ]),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 16),
              SFCard(
                radius: 22,
                padding: const EdgeInsets.all(18),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    IconTile(Icons.auto_awesome,
                        size: 28,
                        iconSize: 15,
                        radius: 8,
                        bg: c.isDark ? c.cardAlt : const Color(0xFFEFF3F1),
                        fg: c.heading),
                    const SizedBox(width: 10),
                    Expanded(child: Text('Key Points Summary', style: T.p(14, w: FontWeight.w600, c: c.heading))),
                    Pill('Saved from ${m.ext.toUpperCase()}',
                        icon: Icons.cloud_done_outlined,
                        fontSize: 10.5,
                        weight: FontWeight.w500,
                        bg: c.isDark ? c.mint : const Color(0xFFEAF8EF),
                        borderColor: const Color(0xFFC9EED6),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3)),
                  ]),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: c.isDark ? c.cardAlt : const Color(0xFFF1F6F2), borderRadius: BorderRadius.circular(14)),
                    child: Column(children: [
                      for (final k in m.keyPoints)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 7),
                              child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(color: Color(0xFF2E9E64), shape: BoxShape.circle)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: RichText(
                                text: TextSpan(children: [
                                  TextSpan(
                                      text: '${k.term}: ', style: T.p(12.5, w: FontWeight.w700, c: c.text, h: 1.5)),
                                  TextSpan(text: k.detail, style: T.p(12.5, c: c.text, h: 1.5)),
                                ]),
                              ),
                            ),
                          ]),
                        ),
                    ]),
                  ),
                  if (m.id == 'plant_cell') ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset('assets/images/cell_diagram.png', width: double.infinity, fit: BoxFit.cover),
                    ),
                  ],
                ]),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: c.isDark ? c.card : const Color(0xFFEDF3EF),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: c.border),
                ),
                child: Column(children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(Icons.history, size: 20, color: c.heading),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Text('Previous quiz score: $score%', style: T.p(13, w: FontWeight.w600, c: c.text)),
                          const SizedBox(width: 8),
                          Pill('Saved',
                              fontSize: 10.5,
                              bg: c.card,
                              fg: c.text,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2)),
                        ]),
                        const SizedBox(height: 4),
                        Text(
                            'Your previous score of $score% is saved. Retaking this quiz will record a new separate attempt in Quiz History without overwriting your past mastery record.',
                            style: T.p(12, c: c.textMuted, h: 1.45)),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(12)),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Icon(Icons.info_outline, size: 16, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                            'Reopening this module does not earn coins. Quiz rewards are based on your score in a completed attempt.',
                            style: T.p(11.5, c: c.textMuted, h: 1.45)),
                      ),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 20),
              PrimaryButton('Retake Quiz',
                  icon: Icons.refresh,
                  radius: 12,
                  color: c.isDark ? c.primary : const Color(0xFF1B4332),
                  onTap: () => pushTab(context, QuizScreen(moduleId: m.id))),
              const SizedBox(height: 10),
              OutlineButtonSF('Review Full Summary',
                  icon: Icons.menu_book_outlined,
                  radius: 12,
                  height: 46,
                  borderColor: Colors.transparent,
                  onTap: () => pushTab(context, ModuleSummaryScreen(moduleId: m.id))),
              const SizedBox(height: 12),
              Center(
                child: Text('Quiz contains ${m.questions.length} questions based on ${m.title} notes.',
                    style: T.p(11.5, c: c.textMuted)),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
