import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/study.dart';
import '../../providers/study_provider.dart';
import '../../services/net.dart';
import '../../widgets/common.dart';
import '../../widgets/sheets.dart';
import 'quiz_screen.dart';
import 'upload_flow.dart';

/// Key Points Summary (FR-2.4), export (FR-2.7), archive (FR-2.6), start quiz.
class ModuleScreen extends StatelessWidget {
  const ModuleScreen({super.key, required this.moduleId});
  final String moduleId;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<StudyProvider>();
    final m = s.byId(moduleId);
    final c = context.sf;
    if (m == null) {
      return const Scaffold(body: Center(child: Text('Module not found')));
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: c.bg,
        surfaceTintColor: Colors.transparent,
        title: Text('Key Points Summary', style: context.tt.titleMedium),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: 'More',
            onSelected: (v) async {
              if (v == 'rename') await _rename(context, s, m);
              if (v == 'export' && context.mounted) await _export(context, s, m);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'rename', child: Text('Rename module')),
              PopupMenuItem(value: 'export', child: Text('Save summary as .txt')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 120),
        children: [
          SfCard(
            child: Row(children: [
              IconTile(Icons.menu_book_rounded, size: 52),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(m.title, style: context.tt.titleLarge),
                  const SizedBox(height: 2),
                  Text('${m.fileName} · ${fmtBytes(m.fileBytes)} · ${m.wordCount} words', style: context.tt.bodySmall, maxLines: 2),
                  const SizedBox(height: 8),
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    StatusBadge(
                      m.bestScore < 0 ? 'Quiz not taken yet' : 'Best score: ${m.bestScore}%',
                      tone: m.bestScore < 0 ? Tone.neutral : (m.mastered ? Tone.green : Tone.blue),
                      icon: m.bestScore < 0 ? Icons.quiz_outlined : Icons.insights_rounded,
                      dense: true,
                    ),
                    if (m.mastered) const StatusBadge('Mastered', tone: Tone.gold, icon: Icons.workspace_premium_rounded, dense: true),
                  ]),
                ]),
              ),
            ]),
          ),
          if (m.verified && !m.rewardClaimed)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: SfCard(
                color: c.goldSoft,
                onTap: () => showUploadRewardSheet(context, m),
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  Icon(Icons.card_giftcard_rounded, color: c.gold),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Verified module — claim your upload reward', style: context.tt.titleSmall)),
                  Icon(Icons.chevron_right_rounded, color: c.muted),
                ]),
              ),
            ),
          if (m.verified && m.rewardClaimed && m.rewardChoice != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(children: [
                Icon(Icons.card_giftcard_rounded, size: 16, color: c.muted),
                const SizedBox(width: 6),
                Expanded(child: Text('Upload reward claimed: ${StudyProvider.rewardLabel(m)}', style: context.tt.bodySmall)),
              ]),
            ),
          SectionHeader('Key Points (${m.keyPoints.length})'),
          for (var i = 0; i < m.keyPoints.length; i++) _KeyPointCard(index: i + 1, kp: m.keyPoints[i]),
          const SizedBox(height: 8),
          SecondaryButton(
            label: 'Save summary as .txt',
            icon: Icons.file_download_outlined,
            onTap: () => _export(context, s, m),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                m.attempts == 0
                    ? 'Your first quiz earns coins and needs internet.'
                    : 'Retakes are free practice (no coins) and work offline.',
                style: context.tt.bodySmall?.copyWith(fontSize: 11.5),
                textAlign: TextAlign.center,
              ),
            ),
            PrimaryButton(
              label: m.attempts == 0 ? 'Start Practice Quiz' : 'Retake Practice Quiz',
              icon: m.attempts == 0 ? Icons.play_arrow_rounded : Icons.replay_rounded,
              onTap: () => _startQuiz(context, m),
            ),
          ]),
        ),
      ),
    );
  }

  /// The first quiz of a module is generated online (it gives the coin
  /// reward); retakes are allowed offline.
  Future<void> _startQuiz(BuildContext context, StudyModule m) async {
    if (m.attempts == 0 && !await Net.online()) {
      if (context.mounted) {
        await confirmDialog(
          context,
          title: 'No internet connection',
          message: 'Connect to Wi-Fi or mobile data to take your first quiz for this module. After that, you can retake it offline.',
          confirm: 'OK',
          icon: Icons.wifi_off_rounded,
        );
      }
      return;
    }
    if (!context.mounted) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => QuizScreen(moduleId: m.id)));
  }

  Future<void> _export(BuildContext context, StudyProvider s, StudyModule m) async {
    try {
      final ok = await s.exportSummary(m);
      if (context.mounted && ok) showToast(context, 'Summary saved as a .txt file');
    } catch (_) {
      if (context.mounted) showToast(context, 'The summary could not be saved. Please try again.', error: true);
    }
  }

  Future<void> _rename(BuildContext context, StudyProvider s, StudyModule m) async {
    final title = await showTextPromptSheet(context, title: 'Rename module', icon: Icons.edit_outlined, initial: m.title, hint: 'Module title');
    if (title != null && title.isNotEmpty) s.rename(m, title);
  }
}

class _KeyPointCard extends StatefulWidget {
  const _KeyPointCard({required this.index, required this.kp});
  final int index;
  final KeyPoint kp;
  @override
  State<_KeyPointCard> createState() => _KeyPointCardState();
}

class _KeyPointCardState extends State<_KeyPointCard> {
  bool _open = true;
  @override
  Widget build(BuildContext context) {
    final c = context.sf;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SfCard(
        onTap: () => setState(() => _open = !_open),
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(color: c.brandSoft, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text('${widget.index}', style: TextStyle(color: c.brand, fontWeight: FontWeight.w800, fontSize: 13)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(widget.kp.title, style: context.tt.titleSmall)),
            AnimatedRotation(
              turns: _open ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(Icons.expand_more_rounded, color: c.muted),
            ),
          ]),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: _open ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.only(top: 8, left: 38),
              child: Text(widget.kp.explanation, style: context.tt.bodyMedium?.copyWith(color: c.muted)),
            ),
            secondChild: const SizedBox(width: double.infinity),
          ),
        ]),
      ),
    );
  }
}
