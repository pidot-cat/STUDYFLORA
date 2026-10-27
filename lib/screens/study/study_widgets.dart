import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../nav.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import 'quiz_history_screen.dart';
import 'quiz_results_screen.dart';

/// "● Online · Last synced: …  ⟳" capsule.
class SyncStatusRow extends StatefulWidget {
  final bool compact; // single line "Synced: ..." variant
  final String prefix;
  const SyncStatusRow({super.key, this.compact = false, this.prefix = 'Last synced:'});
  @override
  State<SyncStatusRow> createState() => _SyncStatusRowState();
}

class _SyncStatusRowState extends State<SyncStatusRow> {
  bool _busy = false;
  bool? _online;

  @override
  void initState() {
    super.initState();
    context.read<AppState>().isOnline().then((v) {
      if (mounted) setState(() => _online = v);
    });
  }

  Future<void> _sync() async {
    setState(() => _busy = true);
    final ok = await context.read<AppState>().sync();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _online = ok;
    });
    showSnack(context, ok ? 'Synced successfully.' : 'Sync failed. Check your connection.');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final s = context.watch<AppState>();
    final online = _online ?? true;
    final last = s.lastSynced ?? DateTime.now();
    return Container(
      padding: EdgeInsets.fromLTRB(14, widget.compact ? 10 : 8, 10, widget.compact ? 10 : 8),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: c.border),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: online ? const Color(0xFF22C55E) : c.danger, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(online ? 'Online' : 'Offline', style: T.p(12, w: FontWeight.w600, c: c.text)),
        const SizedBox(width: 6),
        Text('•', style: T.p(12, c: c.textFaint)),
        const SizedBox(width: 6),
        Flexible(
          child: Text('${widget.prefix} ${fmtDateTime(last)}',
              maxLines: widget.compact ? 1 : 2,
              overflow: TextOverflow.ellipsis,
              style: T.p(widget.compact ? 11.5 : 11, c: c.textMuted, h: 1.3)),
        ),
        const SizedBox(width: 6),
        InkWell(
          onTap: _busy ? null : _sync,
          child: _busy
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(Icons.sync, size: 18, color: widget.compact ? const Color(0xFF15803D) : c.textMuted),
        ),
      ]),
    );
  }
}

/// White card containing up to N quiz attempts.
class QuizHistoryCard extends StatelessWidget {
  final int max;
  const QuizHistoryCard({super.key, this.max = 2});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = context.c;
    final items = s.history.take(max).toList();
    if (items.isEmpty) {
      return SFCard(child: Text('No quiz attempts yet. Launch a practice quiz!', style: T.p(13, c: c.textMuted)));
    }
    return SFCard(
      radius: 22,
      padding: EdgeInsets.zero,
      child: Column(children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) Divider(height: 1, color: c.border),
          InkWell(
            onTap: () => pushTab(context, QuizResultsScreen(attempt: items[i], fromHistory: true)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
              child: Row(children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: c.isDark ? c.cardAlt : (i == 0 ? const Color(0xFFE8EFFA) : const Color(0xFFF1F1F1)),
                    shape: c.isDark ? BoxShape.rectangle : BoxShape.circle,
                    borderRadius: c.isDark ? BorderRadius.circular(10) : null,
                    border: Border.all(color: c.isDark ? c.border : const Color(0xFFD8DEE8)),
                  ),
                  child:
                      Icon(Icons.assignment_outlined, size: 19, color: c.isDark ? c.accent : const Color(0xFF475569)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(items[i].title, style: T.p(c.isDark ? 13.5 : 15.5, w: FontWeight.w600, c: c.heading)),
                    Text('${items[i].percent}% • ${fmtDateCompact(items[i].date)}', style: T.p(12.5, c: c.textMuted)),
                  ]),
                ),
                if (c.isDark || i == 0)
                  c.isDark
                      ? Pill('+${items[i].coins} coins',
                          bg: Colors.transparent,
                          borderColor: const Color(0xFF2B6B53),
                          fontSize: 12,
                          weight: FontWeight.w700,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5))
                      : Text('+${items[i].coins} coins',
                          style: T.p(12.5, w: FontWeight.w500, c: const Color(0xFF15803D))),
              ]),
            ),
          ),
        ],
      ]),
    );
  }
}

class QuizHistoryHeader extends StatelessWidget {
  const QuizHistoryHeader({super.key});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Row(children: [
      Expanded(child: Text('Quiz History', style: T.p(17, w: FontWeight.w600, c: c.heading))),
      InkWell(
        onTap: () => pushTab(context, const QuizHistoryScreen()),
        child: Row(children: [
          Text('See All', style: T.p(13, c: c.textMuted)),
          Icon(Icons.chevron_right, size: 18, color: c.textMuted),
        ]),
      ),
    ]);
  }
}

/// Card for archived modules list on Study Review.
class ArchivedRow extends StatelessWidget {
  final StudyModule module;
  final VoidCallback onTap;
  const ArchivedRow({super.key, required this.module, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SFCard(
      onTap: onTap,
      radius: 16,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Row(children: [
        IconTile(Icons.insert_drive_file_outlined,
            size: 38, iconSize: 18, radius: 10, bg: c.isDark ? c.cardAlt : const Color(0xFFE3F2E8)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(module.fileName,
                maxLines: 1, overflow: TextOverflow.ellipsis, style: T.p(13, w: FontWeight.w600, c: c.heading)),
            Text('Previously Uploaded•${module.ext}', style: T.p(11.5, c: c.textMuted)),
          ]),
        ),
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
              color: c.isDark ? c.cardAlt : const Color(0xFFF2F4F7), borderRadius: BorderRadius.circular(8)),
          child: Icon(Icons.chevron_right, size: 18, color: c.textMuted),
        ),
      ]),
    );
  }
}

/// "Need Flash Review?" promo card shown under the quiz.
class FlashReviewPromo extends StatelessWidget {
  final VoidCallback onTap;
  const FlashReviewPromo({super.key, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SFCard(
      onTap: onTap,
      radius: 16,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: c.isDark ? c.mint : const Color(0xFFDDF5E6), borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.psychology_alt_outlined, color: c.mintText, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('Need Flash Review?', style: T.p(13.5, w: FontWeight.w600, c: c.heading)),
              const SizedBox(width: 4),
              Icon(Icons.bolt, size: 15, color: c.mintText),
            ]),
            Text('Review up to 5 cards from incorrectly answered, unanswered, or flagged questions.',
                style: T.p(11.5, c: c.textMuted, h: 1.35)),
          ]),
        ),
      ]),
    );
  }
}

/// Green "Practice Quiz — Earn 5-100 coins" banner.
class PracticeQuizBanner extends StatelessWidget {
  const PracticeQuizBanner({super.key});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: c.isDark ? c.card : const Color(0xFFD7F5E2),
        borderRadius: BorderRadius.circular(16),
        border: c.isDark ? Border.all(color: c.border) : null,
      ),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: c.isDark ? c.cardAlt : const Color(0xFFBDE9CF), shape: BoxShape.circle),
          child: Icon(Icons.psychology_outlined, size: 22, color: c.mintText),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Practice Quiz', style: T.j(18, w: FontWeight.w600, c: c.heading)),
            Text('Earn 5–100 Coins based on score', style: T.j(11.5, c: c.textMuted)),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            const CoinGlyph(size: 14),
            const SizedBox(width: 4),
            Text('Up to 100', style: T.j(12, w: FontWeight.w600, c: c.heading)),
          ]),
        ),
      ]),
    );
  }
}
