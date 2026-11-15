import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/cosmetics.dart';
import '../../models/flower.dart';
import '../../models/study.dart';
import '../../providers/feedback_bus.dart';
import '../../providers/study_provider.dart';
import '../../services/module_validator.dart';
import '../../services/net.dart';
import '../../widgets/common.dart';
import '../../widgets/sheets.dart';
import 'module_screen.dart';

bool _uploadRunning = false;

/// Upload → extract → analyze → validate → (verified) choose reward.
/// Ignores extra taps while one upload is already in progress (a second file
/// picker would throw).
Future<void> runUploadFlow(BuildContext context) async {
  if (_uploadRunning) return;
  _uploadRunning = true;
  try {
    await _runUploadFlow(context);
  } finally {
    _uploadRunning = false;
  }
}

Future<void> _runUploadFlow(BuildContext context) async {
  final study = context.read<StudyProvider>();
  // Uploading needs internet (rewards and modules are synced to your account).
  if (!await Net.online()) {
    if (context.mounted) {
      await confirmDialog(
        context,
        title: 'No internet connection',
        message: 'Connect to Wi-Fi or mobile data to upload a file, then try again.',
        confirm: 'OK',
        icon: Icons.wifi_off_rounded,
      );
    }
    return;
  }
  if (!context.mounted) return;
  PickedStudyFile? file;
  try {
    file = await study.pickFile();
  } on FileTooLargeException catch (e) {
    if (context.mounted) {
      await showSfSheet(
        context: context,
        builder: (_) => _ReportSheet(outcome: UploadOutcome(UploadKind.rejected, message: e.message)),
      );
    }
    return;
  } catch (_) {
    if (context.mounted) showToast(context, 'That file could not be opened. Please try another file.', error: true);
    return;
  }
  if (file == null || !context.mounted) return;

  celebrationHold.value++;
  try {
    await _processAndReport(context, study, file);
  } finally {
    celebrationHold.value--;
  }
}

Future<void> _processAndReport(BuildContext context, StudyProvider study, PickedStudyFile file) async {
  final future = study.process(file);
  final outcome = await showDialog<UploadOutcome>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(canPop: false, child: _ProcessingDialog(fileName: file.name, work: future)),
  );
  if (outcome == null || !context.mounted) return;

  switch (outcome.kind) {
    case UploadKind.duplicate:
      await confirmDialog(
        context,
        title: 'Already uploaded',
        message: outcome.message,
        confirm: 'Open module',
        icon: Icons.content_copy_rounded,
      ).then((open) {
        if (open && context.mounted) _openModule(context, outcome.module!);
      });
    case UploadKind.rejected:
      await showSfSheet(context: context, builder: (_) => _ReportSheet(outcome: outcome));
    case UploadKind.accepted:
      await showSfSheet(context: context, builder: (_) => _ReportSheet(outcome: outcome));
      if (context.mounted) _openModule(context, outcome.module!);
  }
}

/// Lets the user claim a verified module's reward later (e.g. if they closed
/// the sheet right after uploading).
Future<void> showUploadRewardSheet(BuildContext context, StudyModule m) {
  return showSfSheet(
    context: context,
    builder: (_) => _ReportSheet(outcome: UploadOutcome(UploadKind.accepted, module: m), fromModule: true),
  );
}

void _openModule(BuildContext context, StudyModule m) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => ModuleScreen(moduleId: m.id)));
}

class _ProcessingDialog extends StatefulWidget {
  const _ProcessingDialog({required this.fileName, required this.work});
  final String fileName;
  final Future<UploadOutcome> work;
  @override
  State<_ProcessingDialog> createState() => _ProcessingDialogState();
}

class _ProcessingDialogState extends State<_ProcessingDialog> {
  int _step = 0;
  Timer? _t;
  Timer? _slow;
  bool _takingLong = false;
  static const _steps = ['Reading file on device', 'Extracting key points', 'Checking module requirements'];

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(milliseconds: 650), (_) {
      if (_step < _steps.length - 1) setState(() => _step++);
    });
    _slow = Timer(const Duration(seconds: 8), () {
      if (mounted) setState(() => _takingLong = true);
    });
    _run();
  }

  Future<void> _run() async {
    final minTime = Future<void>.delayed(const Duration(milliseconds: 2000));
    UploadOutcome result;
    try {
      result = await widget.work.timeout(const Duration(seconds: 90));
    } on TimeoutException {
      result = const UploadOutcome(UploadKind.rejected,
          message: 'This file is taking too long to read. Try a smaller file, or a PDF whose text can be selected (not a scanned image).');
    } catch (e) {
      result = UploadOutcome(UploadKind.rejected, message: e.toString());
    }
    await minTime;
    _t?.cancel();
    _slow?.cancel();
    if (mounted) Navigator.of(context).pop(result);
  }

  @override
  void dispose() {
    _t?.cancel();
    _slow?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sf;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 30),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            width: 70,
            height: 70,
            child: Stack(alignment: Alignment.center, children: [
              SizedBox(width: 70, height: 70, child: CircularProgressIndicator(strokeWidth: 4, color: c.accent, backgroundColor: c.brandSoft)),
              Icon(Icons.auto_stories_rounded, color: c.brand, size: 30),
            ]),
          ),
          const SizedBox(height: 16),
          Text('Analyzing your notes', style: context.tt.titleLarge),
          const SizedBox(height: 4),
          Text(widget.fileName, style: context.tt.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 16),
          for (var i = 0; i < _steps.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: i < _step
                      ? Icon(Icons.check_circle_rounded, key: const ValueKey('d'), color: c.accent, size: 20)
                      : i == _step
                          ? SizedBox(key: const ValueKey('r'), width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: c.accent))
                          : Icon(Icons.radio_button_unchecked_rounded, key: const ValueKey('p'), color: c.line, size: 20),
                ),
                const SizedBox(width: 10),
                Text(_steps[i], style: TextStyle(color: i <= _step ? c.ink : c.muted, fontWeight: i == _step ? FontWeight.w700 : FontWeight.w500)),
              ]),
            ),
          const SizedBox(height: 6),
          Text(
            _takingLong ? 'Big files take a little longer. Please keep the app open…' : 'This usually takes a few seconds.',
            style: context.tt.bodySmall,
            textAlign: TextAlign.center,
          ),
        ]),
      ),
    );
  }
}

/// Requirement checklist + (if verified) the reward picker.
class _ReportSheet extends StatefulWidget {
  const _ReportSheet({required this.outcome, this.fromModule = false});
  final UploadOutcome outcome;

  /// Opened from the module screen itself → the button just closes the sheet.
  final bool fromModule;
  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  UploadReward? _choice;
  UploadRewardResult? _result;

  @override
  Widget build(BuildContext context) {
    final c = context.sf;
    final o = widget.outcome;
    final report = o.report;
    final accepted = o.kind == UploadKind.accepted;
    final m = o.module;
    final verified = report?.verified ?? m?.verified ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
        SheetHeader(
          title: !accepted ? 'Upload rejected' : (verified ? 'Verified module!' : 'Module saved'),
          icon: !accepted ? Icons.block_rounded : (verified ? Icons.verified_rounded : Icons.bookmark_added_outlined),
        ),
        if (!accepted)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: c.dangerSoft, borderRadius: BorderRadius.circular(16)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.error_outline_rounded, color: c.danger),
              const SizedBox(width: 10),
              Expanded(child: Text(o.message, style: TextStyle(color: c.danger, fontWeight: FontWeight.w500, height: 1.35))),
            ]),
          ),
        if (accepted && m != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              verified
                  ? '“${m.title}” passed every module check. ${m.keyPoints.length} key points are ready for review.'
                  : '“${m.title}” was saved with ${m.keyPoints.length} key points, but it did not pass every module check, so it is not eligible for an upload reward.',
              style: context.tt.bodyMedium?.copyWith(color: c.muted),
            ),
          ),
        if (report != null) ...[
          Text('MODULE REQUIREMENTS', style: context.tt.labelSmall?.copyWith(color: c.muted)),
          const SizedBox(height: 8),
          SfCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Column(children: [for (final ch in report.checks) _CheckRow(item: ch)]),
          ),
          const SizedBox(height: 16),
        ],
        if (accepted && verified && m != null && !m.rewardClaimed && _result == null) ...[
          Text('CHOOSE YOUR REWARD', style: context.tt.labelSmall?.copyWith(color: c.gold)),
          const SizedBox(height: 4),
          Text('One reward per unique file. Re-uploading the same file gives no second reward.', style: context.tt.bodySmall),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: _RewardCard(
                selected: _choice == UploadReward.seed,
                art: Image.asset(Flower.of('tulip').seedAsset, height: 46),
                title: 'Random Seed',
                caption: 'Rare ones too!',
                onTap: () => setState(() => _choice = UploadReward.seed),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _RewardCard(
                selected: _choice == UploadReward.fertilizer,
                art: Image.asset(ToolDef.of(ToolKind.fertilizer).asset, height: 46),
                title: 'Fertilizer',
                caption: '2× growth speed',
                onTap: () => setState(() => _choice = UploadReward.fertilizer),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _RewardCard(
                selected: _choice == UploadReward.shovel,
                art: Image.asset(ToolDef.of(ToolKind.shovel).asset, height: 46),
                title: 'Shovel',
                caption: 'Frees a pot',
                onTap: () => setState(() => _choice = UploadReward.shovel),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          PrimaryButton(
            label: _choice == null ? 'Pick a reward' : 'Claim reward',
            icon: Icons.card_giftcard_rounded,
            onTap: _choice == null
                ? null
                : () {
                    HapticFeedback.mediumImpact();
                    final r = context.read<StudyProvider>().claimUploadReward(m, _choice!);
                    if (r == null) {
                      Navigator.pop(context); // already claimed elsewhere
                      return;
                    }
                    setState(() => _result = r);
                  },
          ),
        ] else if (_result != null) ...[
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.5, end: 1),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: c.goldSoft, borderRadius: BorderRadius.circular(20)),
              child: Row(children: [
                Image.asset(_result!.asset, height: 52, width: 52, fit: BoxFit.contain),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('You received: ${_result!.label}!', style: context.tt.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      switch (_result!.kind) {
                        UploadReward.seed => 'Plant it in an empty pot in your Garden.',
                        UploadReward.fertilizer => 'Use it on a growing plant to double its growth speed.',
                        UploadReward.shovel => 'Use it to clear a pot so you can plant something new.',
                      },
                      style: context.tt.bodySmall,
                    ),
                  ]),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 14),
          PrimaryButton(
            label: widget.fromModule ? 'Done' : 'Open module',
            icon: widget.fromModule ? Icons.check_rounded : Icons.menu_book_rounded,
            onTap: () => Navigator.pop(context),
          ),
        ] else
          PrimaryButton(
            label: !accepted ? 'OK, got it' : (widget.fromModule ? 'Done' : 'Open module'),
            onTap: () => Navigator.pop(context),
          ),
      ]),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({required this.item});
  final CheckItem item;
  @override
  Widget build(BuildContext context) {
    final c = context.sf;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(children: [
        Icon(item.passed ? Icons.check_circle_rounded : Icons.cancel_rounded, color: item.passed ? c.accent : c.danger, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(item.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5))),
        const SizedBox(width: 8),
        // Fixed right column so every detail lines up on the same edge.
        SizedBox(
          width: 112,
          child: Text(item.detail, textAlign: TextAlign.right, style: context.tt.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ]),
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({required this.selected, required this.art, required this.title, required this.caption, required this.onTap});
  final bool selected;
  final Widget art;
  final String title;
  final String caption;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final c = context.sf;
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        height: 136,
        padding: const EdgeInsets.fromLTRB(6, 12, 6, 10),
        decoration: BoxDecoration(
          color: selected ? c.brandSoft : c.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? c.accent : c.line, width: selected ? 2.2 : 1.3),
          boxShadow: selected ? [BoxShadow(color: c.accent.withValues(alpha: 0.25), blurRadius: 14)] : null,
        ),
        child: Column(children: [
          SizedBox(height: 50, child: Center(child: art)),
          const SizedBox(height: 8),
          Text(title, style: context.tt.titleSmall, textAlign: TextAlign.center, maxLines: 1),
          Text(caption, style: context.tt.bodySmall?.copyWith(fontSize: 10.5), textAlign: TextAlign.center, maxLines: 2),
        ]),
      ),
    );
  }
}
