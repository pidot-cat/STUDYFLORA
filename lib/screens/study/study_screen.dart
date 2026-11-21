import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/study.dart';
import '../../providers/study_provider.dart';
import '../../widgets/common.dart';
import '../../widgets/profile_widgets.dart';
import '../../widgets/sheets.dart';
import 'history_screens.dart';
import 'module_screen.dart';
import 'upload_flow.dart';

/// Study Review (FR-2.x, FR-3.x): upload → extracted preview → archived
/// modules → quiz history. Layout follows the Study Reviewer mockup.
class StudyScreen extends StatelessWidget {
  const StudyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<StudyProvider>();
    final modules = s.allModules;
    final latest = modules.isEmpty ? null : modules.first;
    final attempts = s.recentAttempts;

    return SafeArea(
      bottom: false,
      child: Column(children: [
        const SfTopBar(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 28),
            children: [
              const SizedBox(height: 10),
              Text('Study Review', style: context.tt.headlineMedium),
              const SizedBox(height: 2),
              Text('Upload materials for instant summaries and quick quizzes.', style: context.tt.bodySmall),
              const SizedBox(height: 16),

              // ---- upload
              _UploadZone(onTap: () => runUploadFlow(context)),
              const SizedBox(height: 14),

              // ---- extracted content preview (latest upload)
              _PreviewCard(module: latest),

              // ---- archived modules (FR-2.6: every uploaded module can be reopened)
              SectionHeader(
                'Archived Modules',
                trailing: modules.isEmpty ? null : 'View All (${modules.length})',
                onTrailing: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ArchivedModulesScreen())),
              ),
              if (modules.isEmpty)
                const _InlineEmpty(icon: Icons.inventory_2_outlined, text: 'Modules you upload are saved here so you can reopen them anytime.')
              else
                // Modules with a reward to claim come first so the red dot is easy to follow.
                for (final m in [
                  ...modules.where(StudyProvider.hasRewardToClaim),
                  ...modules.where((m) => !StudyProvider.hasRewardToClaim(m)),
                ].take(2))
                  ModuleTile(module: m),

              const SizedBox(height: 6),
              _InfoNote(onTap: () => showRewardsInfo(context)),

              // ---- quiz history (FR-3.7)
              SectionHeader(
                'Quiz History',
                trailing: attempts.isEmpty ? null : 'See All',
                onTrailing: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const QuizHistoryScreen())),
              ),
              if (attempts.isEmpty)
                const _InlineEmpty(icon: Icons.assignment_outlined, text: 'Open a module and take a practice quiz. Your scores will show up here.')
              else
                SfCard(
                  padding: EdgeInsets.zero,
                  child: Column(children: [
                    for (var i = 0; i < attempts.length && i < 3; i++) ...[
                      if (i > 0) Divider(height: 1, color: context.sf.line),
                      QuizHistoryRow(attempt: attempts[i]),
                    ],
                  ]),
                ),
            ],
          ),
        ),
      ]),
    );
  }
}

class _UploadZone extends StatelessWidget {
  const _UploadZone({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final c = context.sf;
    return Pressable(
      onTap: onTap,
      child: CustomPaint(
        painter: _DashedBorder(color: c.accent.withValues(alpha: 0.45), radius: 24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
          decoration: BoxDecoration(color: c.surfaceAlt.withValues(alpha: 0.65), borderRadius: BorderRadius.circular(24)),
          child: Column(children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: c.line),
                boxShadow: [BoxShadow(color: c.shadow, blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Icon(Icons.upload_file_rounded, color: c.brand, size: 28),
            ),
            const SizedBox(height: 14),
            Text('Upload PDF, DOCX, or TXT', style: context.tt.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text('Max 25 MB • Internet connection needed', style: context.tt.bodySmall, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: c.line),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.create_new_folder_outlined, size: 18, color: c.brand),
                const SizedBox(width: 8),
                Text('Choose File', style: TextStyle(fontWeight: FontWeight.w700, color: c.ink)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _DashedBorder extends CustomPainter {
  _DashedBorder({required this.color, required this.radius});
  final Color color;
  final double radius;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)));
    for (final metric in path.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 12) {
        canvas.drawPath(metric.extractPath(d, d + 6), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorder old) => old.color != color;
}

/// Shows what was extracted from the most recent upload.
class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.module});
  final StudyModule? module;
  @override
  Widget build(BuildContext context) {
    final c = context.sf;
    final m = module;
    return SfCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.description_outlined, size: 20, color: c.brand),
          const SizedBox(width: 8),
          Expanded(child: Text('Extracted Content Preview', style: context.tt.titleSmall?.copyWith(fontSize: 15))),
          if (m != null)
            Pressable(
              onTap: () => _open(context, m),
              child: Text('View Details', style: TextStyle(color: c.brand, fontWeight: FontWeight.w700, fontSize: 12.5)),
            ),
        ]),
        const SizedBox(height: 12),
        if (m == null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: c.surfaceAlt.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(16), border: Border.all(color: c.line)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              IconTile(Icons.auto_awesome_outlined, size: 44, bg: c.brandSoft),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Your file will be processed here', style: context.tt.titleSmall),
                  const SizedBox(height: 3),
                  Text('After uploading, Study Flora pulls out the key concepts, saves a module and builds a practice quiz.',
                      style: context.tt.bodySmall),
                ]),
              ),
            ]),
          )
        else
          Pressable(
            onTap: () => _open(context, m),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: c.surfaceAlt.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(16), border: Border.all(color: c.line)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(m.title, style: context.tt.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('${m.fileName} • ${m.keyPoints.length} key points • ${m.wordCount} words',
                    style: context.tt.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 10),
                for (final k in m.keyPoints.take(3))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Container(width: 6, height: 6, decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text.rich(
                          TextSpan(children: [
                            TextSpan(text: '${k.title}: ', style: TextStyle(fontWeight: FontWeight.w700, color: c.ink)),
                            TextSpan(text: k.explanation),
                          ]),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.tt.bodySmall?.copyWith(height: 1.35),
                        ),
                      ),
                    ]),
                  ),
                if (m.keyPoints.length > 3)
                  Text('+${m.keyPoints.length - 3} more key points', style: TextStyle(color: c.brand, fontWeight: FontWeight.w600, fontSize: 12)),
              ]),
            ),
          ),
      ]),
    );
  }

  void _open(BuildContext context, StudyModule m) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => ModuleScreen(moduleId: m.id)));
}

class _InfoNote extends StatelessWidget {
  const _InfoNote({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final c = context.sf;
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.brandSoft.withValues(alpha: context.isDark ? 0.25 : 0.55),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.brandSoft),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.info_outline_rounded, size: 18, color: c.brand),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                const TextSpan(
                  text: 'Files are read offline on your phone. Each unique file gives one reward; '
                      're-uploading the same file just opens its saved module. ',
                ),
                TextSpan(text: 'How rewards work', style: TextStyle(color: c.brand, fontWeight: FontWeight.w700)),
              ]),
              style: context.tt.bodySmall?.copyWith(height: 1.4),
            ),
          ),
        ]),
      ),
    );
  }
}

class _InlineEmpty extends StatelessWidget {
  const _InlineEmpty({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) {
    final c = context.sf;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: c.line)),
      child: Row(children: [
        IconTile(icon, size: 40),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: context.tt.bodySmall)),
      ]),
    );
  }
}

/// FR-2.5 / FR-3.6 reward rules.
void showRewardsInfo(BuildContext context) {
  showSfSheet(
    context: context,
    builder: (ctx) {
      final c = ctx.sf;
      Widget row(String score, int coins) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(children: [
              Expanded(child: Text(score, style: ctx.tt.bodyMedium)),
              const CoinIcon(size: 16),
              const SizedBox(width: 6),
              Text('$coins', style: TextStyle(fontWeight: FontWeight.w700, color: c.ink)),
            ]),
          );
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          const SheetHeader(title: 'How rewards work', icon: Icons.card_giftcard_rounded),
          Text('Verified upload', style: ctx.tt.titleSmall),
          const SizedBox(height: 4),
          Text(
            'When a file passes every module check, pick one garden reward: a random seed, '
            'a fertilizer (2× growth speed) or a shovel (frees a pot). Once per unique file.',
            style: ctx.tt.bodySmall,
          ),
          const SizedBox(height: 16),
          Text('Practice quiz (first attempt)', style: ctx.tt.titleSmall),
          const SizedBox(height: 4),
          Text('Coins depend on your score the first time you take a module’s quiz. Retakes are free practice with no coins.', style: ctx.tt.bodySmall),
          const SizedBox(height: 6),
          for (final (score, coins) in const [
            ('8–10 correct', 50), ('5–7 correct', 30), ('0–4 correct', 5),
          ])
            row(score, coins),
          const SizedBox(height: 12),
          Row(children: [
            Icon(Icons.workspace_premium_rounded, size: 18, color: c.accent),
            const SizedBox(width: 8),
            Expanded(child: Text('A module is Mastered once your best score is 60% or higher.', style: ctx.tt.bodySmall)),
          ]),
          const SizedBox(height: 16),
          Text('Garden', style: ctx.tt.titleSmall),
          const SizedBox(height: 4),
          Text('XP comes from harvesting fully grown plants. Use XP to level up and unlock avatar borders.', style: ctx.tt.bodySmall),
        ]),
      );
    },
  );
}

/// One saved module (mockup "Plant Cell Biology.pdf · Previously Uploaded").
class ModuleTile extends StatelessWidget {
  const ModuleTile({super.key, required this.module});
  final StudyModule module;
  @override
  Widget build(BuildContext context) {
    final c = context.sf;
    final m = module;
    final icon = switch (m.fileType) { 'pdf' => Icons.picture_as_pdf_outlined, 'docx' => Icons.description_outlined, _ => Icons.article_outlined };
    final score = m.bestScore < 0
        ? 'No quiz yet'
        : (m.mastered ? 'Mastered • best ${m.bestScore}%' : 'Best score ${m.bestScore}%');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SfCard(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ModuleScreen(moduleId: m.id))),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Row(children: [
          IconTile(icon, size: 44, bg: c.brandSoft.withValues(alpha: 0.7)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(m.title, style: context.tt.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text('${m.keyPoints.length} key points • ${m.fileType.toUpperCase()} • $score',
                  style: context.tt.bodySmall?.copyWith(color: m.mastered ? c.accent : null), maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
          const SizedBox(width: 8),
          if (StudyProvider.hasRewardToClaim(m))
            ClaimPill(onTap: () => showUploadRewardSheet(context, m))
          else
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(color: c.surfaceAlt, borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.chevron_right_rounded, color: c.muted, size: 20),
            ),
        ]),
      ),
    );
  }
}
