import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/formatters.dart';
import '../../models/study_module.dart';
import '../../providers/study_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/pill.dart';

class ReviewView extends StatelessWidget {
  const ReviewView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final study = context.watch<StudyProvider>();
    final module = study.current;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Row(
          children: [
            Icon(Icons.auto_awesome, size: 16, color: p.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(dark ? 'STUDY REVIEWER' : 'AI STUDY REVIEWER',
                  style: TextStyle(
                      color: p.primary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8)),
            ),
            Pill(
              label: '+10 Coins per upload',
              icon: Icons.monetization_on_outlined,
              background: p.warmSoft,
              foreground: p.warmText,
              fontSize: 12,
              borderColor: p.warmText.withAlpha(70),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Study Review', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text('Upload materials for instant summaries and quick quizzes.',
            style: TextStyle(color: p.textMuted, fontSize: 15, height: 1.4)),
        const SizedBox(height: 16),
        const _UploadCard(),
        const SizedBox(height: 16),
        if (module != null) ...[
          _ModuleCard(module: module),
          const SizedBox(height: 24),
          if (study.archived.isNotEmpty) _ArchivedSection(modules: study.archived),
        ] else
          const _EmptyHint(),
        const SizedBox(height: 16),
        const _FloraTip(),
      ],
    );
  }
}

class _UploadCard extends StatelessWidget {
  const _UploadCard();

  Future<void> _choose(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final outcome = await context.read<StudyProvider>().pickAndAnalyze();
    String? msg;
    switch (outcome.status) {
      case UploadStatus.success:
        msg = 'Reviewer ready! +10 coins earned.';
        break;
      case UploadStatus.cancelled:
        break;
      default:
        msg = outcome.message;
    }
    if (msg != null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final busy = context.select<StudyProvider, bool>((s) => s.processing);

    final content = Padding(
      padding: const EdgeInsets.fromLTRB(16, 26, 16, 26),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: dark ? p.primarySoft : const Color(0xFFBDEBD0),
              shape: BoxShape.circle,
            ),
            child: busy
                ? Padding(
                    padding: const EdgeInsets.all(15),
                    child: CircularProgressIndicator(strokeWidth: 3, color: p.primary),
                  )
                : Icon(Icons.upload_file, color: p.primary, size: 28),
          ),
          const SizedBox(height: 12),
          const Text('Upload Lecture Notes or Slides',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('PDF, DOCX, or TXT up to 25MB • Earn +10 Coins',
              textAlign: TextAlign.center,
              style: TextStyle(color: p.textMuted, fontSize: 14)),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: p.primary,
              foregroundColor: p.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: const StadiumBorder(),
            ),
            onPressed: busy ? null : () => _choose(context),
            icon: const Icon(Icons.add, size: 20),
            label: Text(busy ? 'Analyzing…' : 'Choose File (+10 Coins)',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          ),
        ],
      ),
    );

    if (dark) {
      return CustomPaint(
        foregroundPainter: _DashedBorderPainter(color: p.border.withAlpha(255), radius: 22),
        child: Container(
          decoration: BoxDecoration(
            color: p.surface.withAlpha(120),
            borderRadius: BorderRadius.circular(22),
          ),
          child: content,
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: p.neutralChip.withAlpha(150),
        borderRadius: BorderRadius.circular(22),
      ),
      child: content,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Offset.zero & size, Radius.circular(radius)));
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 7), paint);
        d += 12;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.module});

  final StudyModule module;

  Future<void> _download(BuildContext context) async {
    final study = context.read<StudyProvider>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final bytes = Uint8List.fromList(utf8.encode(study.summarySheet(module)));
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save summary sheet',
        fileName: '${module.displayName}_summary.txt',
        bytes: bytes,
        type: FileType.custom,
        allowedExtensions: const ['txt'],
      );
      if (path != null) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Summary sheet saved.')));
      }
    } catch (_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Could not save the file.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final isPdf = module.extension == 'pdf';
    final tileBg = isPdf
        ? (dark ? const Color(0xFF2E1416) : const Color(0xFFFFD9D6))
        : p.primarySoft;
    final tileFg = isPdf ? const Color(0xFFE5534B) : p.onPrimarySoft;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                    color: tileBg, borderRadius: BorderRadius.circular(14)),
                child: Icon(isPdf ? Icons.picture_as_pdf_outlined : Icons.description_outlined,
                    color: tileFg),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(module.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text('Processed\n& Ready',
                            style: TextStyle(color: p.textMuted, fontSize: 9.5, height: 1.2)),
                        const SizedBox(width: 6),
                        Icon(Icons.circle, size: 6, color: p.primary),
                        const SizedBox(width: 6),
                        Text(formatBytes(module.sizeBytes),
                            style: TextStyle(
                                color: p.textMuted,
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
              if (module.rewarded)
                Pill(
                  label: '+10 Coins Awarded',
                  icon: Icons.monetization_on_outlined,
                  background: p.warmSoft,
                  foreground: p.coin,
                  fontSize: 10,
                  borderColor: p.coin.withAlpha(90),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: p.neutralChip.withAlpha(dark ? 160 : 190),
              borderRadius: BorderRadius.circular(18),
              border: dark ? Border.all(color: p.border) : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.menu_book_outlined, size: 20, color: p.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Key Points Summary',
                          style: TextStyle(
                              color: p.primary,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800)),
                    ),
                    Pill(
                      label: '${module.keyPoints.length} Topics',
                      background: p.primarySoft,
                      foreground: p.onPrimarySoft,
                      fontSize: 11,
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < module.keyPoints.length; i++) ...[
                  _KeyPointTile(number: i + 1, point: module.keyPoints[i]),
                  if (i < module.keyPoints.length - 1) const SizedBox(height: 10),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: p.primary,
              foregroundColor: p.onPrimary,
              minimumSize: const Size.fromHeight(52),
              shape: const StadiumBorder(),
            ),
            onPressed: () {
              final study = context.read<StudyProvider>();
              final ok = study.startQuiz();
              if (!ok) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(const SnackBar(
                      content: Text('Not enough material to build a quiz from this file.')));
                return;
              }
              study.showAiHub();
            },
            icon: const Icon(Icons.play_arrow_outlined, size: 22),
            label: const Text('Launch Practice Quiz',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            style: TextButton.styleFrom(
              backgroundColor: p.neutralChip.withAlpha(dark ? 160 : 190),
              foregroundColor: p.text,
              minimumSize: const Size.fromHeight(50),
              shape: const StadiumBorder(),
            ),
            onPressed: () => _download(context),
            icon: const Icon(Icons.download_outlined, size: 20),
            label: const Text('Download Summary Sheet',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          ),
        ],
      ),
    );
  }
}

class _KeyPointTile extends StatelessWidget {
  const _KeyPointTile({required this.number, required this.point});

  final int number;
  final KeyPoint point;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: dark ? p.surface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: p.primarySoft,
              shape: BoxShape.circle,
              border: dark ? Border.all(color: p.onPrimarySoft.withAlpha(90)) : null,
            ),
            child: Text('$number',
                style: TextStyle(
                    color: p.onPrimarySoft, fontSize: 11, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${point.title}: ',
                    style: TextStyle(
                        color: dark ? p.onPrimarySoft : p.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800),
                  ),
                  TextSpan(
                    text: point.detail,
                    style: TextStyle(color: p.text, fontSize: 14.5, height: 1.45),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArchivedSection extends StatelessWidget {
  const _ArchivedSection({required this.modules});

  final List<StudyModule> modules;

  void _viewAll(BuildContext context) {
    final p = AppPalette.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: p.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          children: [
            Text('Archived Modules', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            for (final m in modules) ...[
              _ArchivedRow(
                module: m,
                onOpen: () {
                  Navigator.pop(sheetCtx);
                  context.read<StudyProvider>().selectModule(m.id);
                },
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final shown = modules.take(2).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('Archived Modules',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700)),
            ),
            GestureDetector(
              onTap: () => _viewAll(context),
              child: Text('View All (${modules.length}) >',
                  style: TextStyle(
                      color: p.primary, fontSize: 13.5, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (final m in shown) ...[
          _ArchivedRow(
            module: m,
            onOpen: () => context.read<StudyProvider>().selectModule(m.id),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _ArchivedRow extends StatelessWidget {
  const _ArchivedRow({required this.module, required this.onOpen});

  final StudyModule module;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final kp = module.keyPoints.length;
    return AppCard(
      onTap: onOpen,
      padding: const EdgeInsets.all(12),
      color: dark ? p.surface : p.neutralChip.withAlpha(150),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: p.neutralChip,
              borderRadius: BorderRadius.circular(12),
              border: dark ? Border.all(color: p.border) : null,
            ),
            child: Icon(
                module.extension == 'pdf'
                    ? Icons.picture_as_pdf_outlined
                    : Icons.description_outlined,
                color: p.textMuted,
                size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(module.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                if (module.mastered)
                  Row(
                    children: [
                      Text('$kp key takeaways • ',
                          style: TextStyle(color: p.textMuted, fontSize: 13)),
                      Icon(Icons.check_circle_outline, size: 14, color: p.onPrimarySoft),
                      const SizedBox(width: 3),
                      Text('Mastered',
                          style: TextStyle(
                              color: p.onPrimarySoft,
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                    ],
                  )
                else
                  Text(
                      '$kp key takeaways • ${module.attempts} ${module.attempts == 1 ? 'quiz' : 'quizzes'}',
                      style: TextStyle(color: p.textMuted, fontSize: 13)),
              ],
            ),
          ),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: dark ? p.neutralChip : Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.arrow_forward, size: 18, color: p.text),
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return AppCard(
      child: Row(
        children: [
          Icon(Icons.menu_book_outlined, color: p.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No reviewers yet. Upload your first file to get a key-points summary and a practice quiz.',
              style: TextStyle(color: p.textMuted, fontSize: 14.5, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloraTip extends StatelessWidget {
  const _FloraTip();

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? p.onPrimarySoft : p.primary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: dark ? p.primarySoft.withAlpha(110) : const Color(0xFFD8F2E2),
        borderRadius: BorderRadius.circular(18),
        border: dark ? Border.all(color: p.border) : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: dark ? p.neutralChip : p.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.lightbulb_outline,
                size: 18, color: dark ? p.onPrimarySoft : p.onPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Flora Tip: Active Recall',
                    style: TextStyle(color: fg, fontWeight: FontWeight.w800),
                  ),
                  TextSpan(
                    text:
                        ' — Quizzing immediately after processing module slides boosts memory retention up to 40% and yields bonus garden nectar.',
                    style: TextStyle(color: fg, height: 1.45),
                  ),
                ],
              ),
              style: const TextStyle(fontSize: 14.5),
            ),
          ),
        ],
      ),
    );
  }
}
