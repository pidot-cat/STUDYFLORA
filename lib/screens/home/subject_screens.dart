import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/app_header.dart';
import '../../widgets/common.dart';
import 'home_screen.dart';

/// Colour family for a mastery percentage (Study "See All" list).
(Color bg, Color fg, Color badgeBg, Color badgeFg) masteryPalette(int pct) {
  if (pct >= 60)
    return (const Color(0xFFD7F0E1), const Color(0xFF1D7A4C), const Color(0xFFD4F5E2), const Color(0xFF15803D));
  if (pct >= 40)
    return (const Color(0xFFDDE5FB), const Color(0xFF2563EB), const Color(0xFFE0E7FF), const Color(0xFF3346A8));
  if (pct >= 20)
    return (const Color(0xFFFDE2E6), const Color(0xFFE11D48), const Color(0xFFE0E7FF), const Color(0xFF3346A8));
  return (const Color(0xFFFDF0C4), const Color(0xFFD97706), const Color(0xFFE0E7FF), const Color(0xFF3346A8));
}

class SubjectsListScreen extends StatefulWidget {
  const SubjectsListScreen({super.key});
  @override
  State<SubjectsListScreen> createState() => _SubjectsListScreenState();
}

class _SubjectsListScreenState extends State<SubjectsListScreen> {
  String _cat = 'All';

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = context.c;
    final mods = s.modules.where((m) => m.bestScore >= 0).toList();
    final cats = <String>{for (final m in mods) m.category}.toList();
    final shown = _cat == 'All' ? mods : mods.where((m) => m.category == _cat).toList();
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(children: [
              const CircleBackButton(size: 36, outlined: true),
              const SizedBox(width: 16),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: c.isDark ? c.mint : const Color(0xFFD7EEDF), shape: BoxShape.circle),
                child: Icon(Icons.eco, size: 17, color: c.mintText),
              ),
              const SizedBox(width: 10),
              Text('Study', style: T.p(20, w: FontWeight.w700, c: c.heading)),
            ]),
          ),
          SizedBox(
            height: 40,
            child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _chip('All', mods.length),
                  for (final cat in cats) _chip(cat, null),
                ]),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: shown.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (_, i) {
                final m = shown[i];
                final pal = masteryPalette(m.bestScore);
                return SFCard(
                  onTap: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => SubjectProgressScreen(moduleId: m.id))),
                  padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
                  child: Row(children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(color: pal.$1, borderRadius: BorderRadius.circular(12)),
                      child: Icon(moduleGlyph(m.iconKey), color: pal.$2, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(
                              child: Text(m.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: T.p(13, w: FontWeight.w600, c: c.text))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: pal.$3, borderRadius: BorderRadius.circular(10)),
                            child: Text('${m.bestScore}% ${m.mastered ? 'MASTERED' : 'NOT MASTERED'}',
                                style: T.p(8.5, w: FontWeight.w700, c: pal.$4)),
                          ),
                        ]),
                        const SizedBox(height: 4),
                        Text('(Uploaded • ${fmtAgo(m.uploadedAt)})', style: T.p(11, c: c.textMuted)),
                        const SizedBox(height: 8),
                        SFProgress(
                            value: m.bestScore / 100,
                            height: 6,
                            color: pal.$2,
                            track: c.isDark ? c.border : const Color(0xFFF1F1F4)),
                      ]),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.chevron_right, color: c.textFaint),
                  ]),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  Widget _chip(String label, int? count) {
    final c = context.c;
    final active = _cat == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: active ? (c.isDark ? c.mintStrong : const Color(0xFF1B3A2E)) : c.card,
        shape: StadiumBorder(side: BorderSide(color: active ? Colors.transparent : c.border)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => setState(() => _cat = label),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(children: [
              Text(label,
                  style: T.p(13, w: active ? FontWeight.w600 : FontWeight.w400, c: active ? Colors.white : c.mintText)),
              if (count != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                  child: Text('$count', style: T.p(11, w: FontWeight.w600, c: Colors.white)),
                ),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

/// Big round icon used on the subject detail screens.
class _SubjectHero extends StatelessWidget {
  final IconData icon;
  const _SubjectHero(this.icon);
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      width: 82,
      height: 82,
      decoration: BoxDecoration(shape: BoxShape.circle, color: c.isDark ? c.mint : const Color(0xFFE2F3E8)),
      alignment: Alignment.center,
      child: Container(
        width: 66,
        height: 66,
        decoration: BoxDecoration(shape: BoxShape.circle, color: c.isDark ? c.mintStrong : const Color(0xFFC9EED6)),
        child: Icon(icon, size: 30, color: c.isDark ? c.accent : const Color(0xFF1B4D3E)),
      ),
    );
  }
}

class SubjectProgressScreen extends StatelessWidget {
  final String moduleId;
  const SubjectProgressScreen({super.key, required this.moduleId});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = context.c;
    final m = s.moduleById(moduleId);
    if (m == null) return const Scaffold();
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(children: [
          TitleBar(m.title, fontSize: 19),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(24, 20, 24, 24), children: [
              Center(child: _SubjectHero(moduleGlyph(m.iconKey))),
              const SizedBox(height: 14),
              Center(child: Text(m.title, style: T.p(18, w: FontWeight.w700, c: c.heading))),
              const SizedBox(height: 22),
              SFCard(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Best Score', style: T.p(12, c: c.textMuted)),
                  Row(children: [
                    Text('${m.bestScore < 0 ? 0 : m.bestScore}%', style: T.p(22, w: FontWeight.w700, c: c.heading)),
                    const Spacer(),
                    Pill(m.mastered ? 'Mastered' : 'Not Mastered',
                        bg: m.mastered ? (c.isDark ? c.mintStrong : const Color(0xFF1B3A2E)) : const Color(0xFFDDE3FB),
                        fg: m.mastered ? (c.isDark ? c.accent : Colors.white) : const Color(0xFF283593),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4)),
                  ]),
                  const SizedBox(height: 10),
                  SFProgress(
                      value: (m.bestScore < 0 ? 0 : m.bestScore) / 100,
                      height: 9,
                      color: c.isDark ? c.accent : const Color(0xFF2E6B4C),
                      track: c.isDark ? c.border : const Color(0xFFF1F1F4)),
                ]),
              ),
              const SizedBox(height: 20),
              Text('Progress Details', style: T.p(14.5, w: FontWeight.w700, c: c.heading)),
              const SizedBox(height: 10),
              _DetailRow(
                  icon: Icons.menu_book_outlined,
                  title: 'Study Material',
                  subtitle: 'PDF, DOCX, TXT',
                  onTap: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => StudyMaterialScreen(moduleId: m.id)))),
              const SizedBox(height: 14),
              _DetailRow(
                  icon: Icons.description_outlined,
                  title: 'View Summary',
                  subtitle: 'Generated study summary',
                  onTap: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => LessonSummaryScreen(moduleId: m.id)))),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _DetailRow({required this.icon, required this.title, required this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SFCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
      child: Row(children: [
        IconTile(icon, size: 48, iconSize: 20, bg: c.isDark ? c.cardAlt : const Color(0xFFEDF6F0), fg: c.mintText),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: T.p(15, w: FontWeight.w700, c: c.heading)),
            Text(subtitle, style: T.p(12.5, c: c.textMuted)),
          ]),
        ),
        Icon(Icons.chevron_right, color: c.textFaint),
      ]),
    );
  }
}

class StudyMaterialScreen extends StatelessWidget {
  final String moduleId;
  const StudyMaterialScreen({super.key, required this.moduleId});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = context.c;
    final m = s.moduleById(moduleId);
    if (m == null) return const Scaffold();
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(children: [
          const TitleBar('Study Material', fontSize: 19),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(36, 30, 36, 24), children: [
              Center(child: _SubjectHero(moduleGlyph(m.iconKey))),
              const SizedBox(height: 14),
              Center(
                  child: Text(m.title,
                      style: T.p(21, w: FontWeight.w700, c: c.isDark ? c.text : const Color(0xFF1B4D3E)))),
              const SizedBox(height: 10),
              Text("Here's the content you previously uploaded for this lesson.",
                  textAlign: TextAlign.center, style: T.p(13.5, c: c.textMuted, h: 1.6)),
              const SizedBox(height: 46),
              SFCard(
                onTap: () =>
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => LessonSummaryScreen(moduleId: m.id))),
                radius: 14,
                padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
                child: Row(children: [
                  IconTile(Icons.description_outlined,
                      size: 44, iconSize: 20, bg: c.isDark ? c.cardAlt : const Color(0xFFEDF6F0)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Lesson Content', style: T.p(15, w: FontWeight.w700, c: c.heading)),
                      Text('${m.ext.toUpperCase()} • ${fmtSize(m.sizeBytes)}', style: T.p(11.5, c: c.textMuted)),
                    ]),
                  ),
                  Icon(Icons.chevron_right, color: c.textFaint),
                ]),
              ),
              const SizedBox(height: 46),
              Text('Topic Overview',
                  style: T.p(15, w: FontWeight.w700, c: c.isDark ? c.text : const Color(0xFF1B4D3E))),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
                decoration: BoxDecoration(
                  color: c.isDark ? c.card : const Color(0xFFEFF5F1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: c.isDark ? c.border : const Color(0xFFDDEBE2)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(Icons.energy_savings_leaf, size: 16, color: c.heading),
                    const SizedBox(width: 10),
                    Text("What You'll Find", style: T.p(13, w: FontWeight.w700, c: c.heading)),
                  ]),
                  const SizedBox(height: 10),
                  for (final o in m.overview)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(children: [
                        Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                                color: c.isDark ? c.accent : const Color(0xFF4C7A60), shape: BoxShape.circle)),
                        const SizedBox(width: 12),
                        Expanded(child: Text(o, style: T.p(13, c: c.isDark ? c.textMuted : const Color(0xFF334155)))),
                      ]),
                    ),
                ]),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class LessonSummaryScreen extends StatelessWidget {
  final String moduleId;
  const LessonSummaryScreen({super.key, required this.moduleId});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = context.c;
    final m = s.moduleById(moduleId);
    if (m == null) return const Scaffold();
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(children: [
          const TitleBar('Summary', fontSize: 19),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(20, 30, 20, 24), children: [
              Center(child: _SubjectHero(moduleGlyph(m.iconKey))),
              const SizedBox(height: 22),
              Center(child: Text(m.title, style: T.p(18, w: FontWeight.w700, c: c.heading))),
              const SizedBox(height: 6),
              Center(child: Text('Key concepts and summary of the lesson.', style: T.p(12.5, c: c.textMuted))),
              const SizedBox(height: 30),
              Text('Summary', style: T.p(14, w: FontWeight.w700, c: c.heading)),
              const SizedBox(height: 10),
              for (var i = 0; i < m.keyPoints.length; i++) ...[
                SFCard(
                  radius: 14,
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      width: 24,
                      height: 24,
                      margin: const EdgeInsets.only(top: 2),
                      decoration: BoxDecoration(
                          color: c.isDark ? c.mintStrong : const Color(0xFF2E6B4C), shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child:
                          Text('${i + 1}', style: T.p(11, w: FontWeight.w700, c: c.isDark ? c.accent : Colors.white)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(m.keyPoints[i].term, style: T.p(13.5, w: FontWeight.w700, c: c.heading)),
                        const SizedBox(height: 2),
                        Text(m.keyPoints[i].detail, style: T.p(12.5, c: c.textMuted, h: 1.4)),
                      ]),
                    ),
                  ]),
                ),
                const SizedBox(height: 12),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}
