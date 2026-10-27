import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../nav.dart';
import '../../services/module_processor.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/app_header.dart';
import '../../widgets/common.dart';
import 'archived_modules_screen.dart';
import 'export_summary_screen.dart';
import 'module_view_screen.dart';
import 'quiz_screen.dart';
import 'study_widgets.dart';

class StudyReviewScreen extends StatefulWidget {
  const StudyReviewScreen({super.key});
  @override
  State<StudyReviewScreen> createState() => _StudyReviewScreenState();
}

class _StudyReviewScreenState extends State<StudyReviewScreen> {
  String? _moduleId; // last processed module
  String? _uploadName;
  int _uploadSize = 0;
  bool _awarded = false;
  bool _busy = false;

  Future<void> _pick() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'docx', 'txt']);
    if (res == null || res.files.single.path == null) return;
    final pf = res.files.single;
    if (pf.size > ModuleProcessor.maxBytes) {
      if (mounted) showSnack(context, 'File is larger than 25 MB.');
      return;
    }
    setState(() => _busy = true);
    try {
      final out = await ModuleProcessor.process(File(pf.path!), pf.name);
      if (!mounted) return;
      final st = context.read<AppState>();
      final unique = st.addModule(out.module, out.hash);
      final saved = st.modules.firstWhere((m) => m.fileName == out.module.fileName, orElse: () => out.module);
      setState(() {
        _moduleId = saved.id;
        _uploadName = pf.name;
        _uploadSize = pf.size;
        _awarded = unique;
      });
      if (!unique) showSnack(context, 'Already uploaded — opened the saved module without another reward.');
    } catch (e) {
      if (mounted) showSnack(context, 'Could not process this file: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = context.c;
    final module = _moduleId == null ? null : s.moduleById(_moduleId!);
    final archived = s.modules.where((m) => m.id != _moduleId).toList();
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          const AppHeader(),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(16, 6, 16, 24), children: [
              Row(children: [
                const Expanded(child: SyncStatusRow()),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: c.isDark ? c.mint : const Color(0xFFD7F5E2),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: c.isDark ? const Color(0xFF2B6B53) : const Color(0xFFB9EBCB)),
                  ),
                  child: Row(children: [
                    Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(color: Color(0xFFF59E0B), shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text('+10 coins /\nunique file', style: T.p(11.5, w: FontWeight.w600, c: c.mintText, h: 1.2)),
                  ]),
                ),
              ]),
              const SizedBox(height: 18),
              Text('Study Review', style: T.p(25, w: FontWeight.w700, c: c.heading)),
              Text('Upload materials for instant summaries and quick quizzes.', style: T.p(12, c: c.textMuted)),
              const SizedBox(height: 18),
              if (module == null)
                _UploadArea(busy: _busy, onPick: _pick)
              else
                _UploadedCard(name: _uploadName!, size: _uploadSize, awarded: _awarded, onPick: _pick),
              const SizedBox(height: 16),
              if (module == null) const _PreviewPlaceholder() else _ProcessedCard(module: module, awarded: _awarded),
              const SizedBox(height: 22),
              Row(children: [
                Expanded(child: Text('Archived Modules', style: T.p(16, w: FontWeight.w600, c: c.heading))),
                InkWell(
                  onTap: () => pushTab(context, const ArchivedModulesScreen()),
                  child: Row(children: [
                    Text('View All (${s.modules.length})', style: T.p(13, c: c.textMuted)),
                    Icon(Icons.chevron_right, size: 18, color: c.textMuted),
                  ]),
                ),
              ]),
              const SizedBox(height: 12),
              for (final m in archived.take(2)) ...[
                ArchivedRow(module: m, onTap: () => pushTab(context, ModuleViewScreen(moduleId: m.id))),
                const SizedBox(height: 12),
              ],
              const InfoBanner(
                  'Upload PDF, DOCX, or TXT (max 25 MB). Offline parsing uses on-device rules. Re-upload opens the saved module without another reward. Reopen archived modules to review.',
                  icon: Icons.info_outline,
                  fontSize: 11.5),
              const SizedBox(height: 26),
              const QuizHistoryHeader(),
              const SizedBox(height: 12),
              const QuizHistoryCard(),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _UploadArea extends StatelessWidget {
  final bool busy;
  final VoidCallback onPick;
  const _UploadArea({required this.busy, required this.onPick});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return CustomPaint(
      painter: _Dashed(color: c.isDark ? const Color(0xFF2B6B53) : const Color(0xFFC6E3CF), radius: 22),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        decoration: BoxDecoration(
          color: c.isDark ? c.card : const Color(0xFFEAF6EE),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
                color: c.isDark ? c.cardAlt : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: c.border)),
            child: Icon(Icons.upload_file_outlined, color: c.mintText, size: 24),
          ),
          const SizedBox(height: 14),
          Text('Upload PDF, DOCX, or TXT', style: T.p(16, w: FontWeight.w600, c: c.heading)),
          const SizedBox(height: 4),
          Text('PDF, DOCX, TXT • Max 25 MB', style: T.p(12, c: c.textMuted)),
          const SizedBox(height: 14),
          Material(
            color: c.isDark ? c.cardAlt : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: c.border)),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: busy ? null : onPick,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 10),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  busy
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(Icons.create_new_folder_outlined, size: 18, color: c.heading),
                  const SizedBox(width: 8),
                  Text(busy ? 'Processing...' : 'Choose File', style: T.p(13, w: FontWeight.w500, c: c.heading)),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Dashed extends CustomPainter {
  final Color color;
  final double radius;
  _Dashed({required this.color, required this.radius});
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)));
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 6), p);
        d += 11;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _Dashed old) => old.color != color;
}

class _UploadedCard extends StatelessWidget {
  final String name;
  final int size;
  final bool awarded;
  final VoidCallback onPick;
  const _UploadedCard({required this.name, required this.size, required this.awarded, required this.onPick});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SFCard(
      onTap: onPick,
      radius: 24,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
      child: Column(children: [
        SizedBox(
          width: 72,
          height: 72,
          child: Stack(children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                  color: c.isDark ? c.mint : const Color(0xFFD7F5E2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFB9EBCB))),
              child: Icon(Icons.description_outlined, size: 30, color: c.mintText),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                    color: const Color(0xFF1B6B3F),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2)),
                child: const Icon(Icons.check, size: 12, color: Colors.white),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        Text('File Uploaded Successfully!', style: T.p(17, w: FontWeight.w600, c: c.heading)),
        const SizedBox(height: 8),
        Pill('$name (${fmtSize(size)})',
            bg: c.isDark ? c.cardAlt : const Color(0xFFF2F7F3),
            fg: c.textMuted,
            borderColor: c.border,
            weight: FontWeight.w400,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5)),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
              color: c.isDark ? c.mint : const Color(0xFFD7F5E2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFB9EBCB))),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(awarded ? Icons.check : Icons.history, size: 15, color: c.mintText),
            const SizedBox(width: 6),
            Text(awarded ? '+10 coins earned!' : 'Saved module reopened',
                style: T.p(12.5, w: FontWeight.w500, c: c.mintText)),
          ]),
        ),
      ]),
    );
  }
}

class _PreviewPlaceholder extends StatelessWidget {
  const _PreviewPlaceholder();
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SFCard(
      radius: 20,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      child: Column(children: [
        Row(children: [
          Icon(Icons.description_outlined, size: 18, color: c.heading),
          const SizedBox(width: 8),
          Expanded(child: Text('Extracted Content Preview', style: T.p(15, w: FontWeight.w600, c: c.heading))),
          Text('View Details',
              style: T.p(12.5, w: c.isDark ? FontWeight.w700 : FontWeight.w500, c: c.isDark ? c.accent : c.heading)),
        ]),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: c.isDark ? c.cardAlt : const Color(0xFFEFF6F1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.border)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            IconTile(Icons.note_alt_outlined, size: 42, iconSize: 20, bg: c.isDark ? c.mint : const Color(0xFFD7F0E0)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Your file will be processed here', style: T.p(13.5, w: FontWeight.w600, c: c.heading)),
                const SizedBox(height: 4),
                Text("After uploading, we'll extract key concepts, create a structured module, and generate quizzes.",
                    style: T.p(12, c: c.textMuted, h: 1.45)),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _ProcessedCard extends StatelessWidget {
  final StudyModule module;
  final bool awarded;
  const _ProcessedCard({required this.module, required this.awarded});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final kp = module.keyPoints.take(2).toList();
    return SFCard(
      radius: 20,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          IconTile(Icons.description_outlined, size: 40, iconSize: 20, bg: c.isDark ? c.mint : const Color(0xFFE3F2E8)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(module.fileName, style: T.p(13, w: FontWeight.w600, c: c.heading)),
              Text('Processed', style: T.p(11.5, c: c.textMuted)),
              Text(fmtSize(module.sizeBytes), style: T.p(11.5, c: c.textMuted)),
            ]),
          ),
          if (awarded)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: c.isDark ? c.mint : const Color(0xFFE3F8EA),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFB9EBCB))),
              child: Row(children: [
                const CoinGlyph(size: 12),
                const SizedBox(width: 4),
                Text('+10 coins awarded', style: T.p(10.5, w: FontWeight.w500, c: c.mintText)),
              ]),
            ),
        ]),
        const SizedBox(height: 12),
        Divider(color: c.border, height: 1),
        const SizedBox(height: 12),
        Row(children: [
          Icon(Icons.check_box_outlined, size: 17, color: c.heading),
          const SizedBox(width: 8),
          Expanded(child: Text('Key Points Summary', style: T.p(13, w: FontWeight.w600, c: c.heading))),
          Pill('${kp.length} TOPICS',
              fontSize: 10.5,
              bg: c.isDark ? c.mint : const Color(0xFFDDF5E6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3)),
        ]),
        const SizedBox(height: 10),
        for (var i = 0; i < kp.length; i++) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: c.isDark ? c.cardAlt : const Color(0xFFF2F7F3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.border)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: c.card, borderRadius: BorderRadius.circular(6), border: Border.all(color: c.border)),
                child: Text('${i + 1}', style: T.p(11.5, w: FontWeight.w600, c: c.text)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: RichText(
                  text: TextSpan(children: [
                    TextSpan(text: '${kp[i].term}: ', style: T.p(12.5, w: FontWeight.w600, c: c.mintText, h: 1.5)),
                    TextSpan(text: kp[i].detail, style: T.p(12.5, c: c.text, h: 1.5)),
                  ]),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 6),
        PrimaryButton('Launch Practice Quiz',
            icon: Icons.play_arrow_outlined,
            height: 42,
            radius: 12,
            fontSize: 13.5,
            shadow: false,
            color: c.isDark ? c.primary : const Color(0xFF2B6648),
            onTap: () => pushTab(context, QuizScreen(moduleId: module.id))),
        const SizedBox(height: 10),
        OutlineButtonSF('Download Summary (.txt)',
            icon: Icons.download_outlined,
            height: 40,
            radius: 12,
            fontSize: 13,
            weight: FontWeight.w500,
            fg: c.mintText,
            onTap: () => pushTab(context, ExportSummaryScreen(moduleId: module.id))),
      ]),
    );
  }
}
