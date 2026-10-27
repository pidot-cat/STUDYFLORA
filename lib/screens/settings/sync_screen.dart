import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import 'settings_screen.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});
  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  bool _busy = false;

  Future<void> _sync() async {
    setState(() => _busy = true);
    final ok = await context.read<AppState>().sync();
    if (!mounted) return;
    setState(() => _busy = false);
    showSnack(context, ok ? 'Everything is up to date.' : 'Sync failed. Check your connection and retry.');
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = context.c;
    final lastOk = s.syncEvents.isEmpty || s.syncEvents.first.success;
    return Scaffold(
      backgroundColor: c.isDark ? c.bg : const Color(0xFFEFF7F1),
      body: SafeArea(
        bottom: false,
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 28), children: [
          Row(children: [
            const CircleBackButton(size: 36),
            Expanded(
              child: Column(children: [
                Text('STUDYFLORA VAULT', style: T.j(12, w: FontWeight.w600, c: const Color(0xFF15924F), ls: 1)),
                Text('Cloud Sync & Data', style: T.j(16.5, w: FontWeight.w700, c: c.text)),
              ]),
            ),
            Material(
              color: c.card,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => showSnack(context, 'Sync keeps your progress backed up when you are online.'),
                child: SizedBox(width: 38, height: 38, child: Icon(Icons.help_outline, size: 20, color: c.text)),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            decoration: BoxDecoration(
              gradient: c.isDark
                  ? null
                  : const LinearGradient(
                      colors: [Colors.white, Color(0xFFE6F7EC)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter),
              color: c.isDark ? c.card : null,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: c.border),
            ),
            child: Column(children: [
              SizedBox(
                width: 90,
                height: 90,
                child: Stack(children: [
                  Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: lastOk ? const Color(0xFF22B573) : c.danger, width: 5)),
                    alignment: Alignment.center,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration:
                          BoxDecoration(color: c.isDark ? c.mint : const Color(0xFFD7F5E2), shape: BoxShape.circle),
                      child: _busy
                          ? const Padding(padding: EdgeInsets.all(14), child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(Icons.cloud_done_outlined, size: 22, color: c.heading),
                    ),
                  ),
                  Positioned(
                    right: 2,
                    top: 0,
                    child: Container(
                        width: 12,
                        height: 12,
                        decoration:
                            BoxDecoration(color: lastOk ? const Color(0xFF15924F) : c.danger, shape: BoxShape.circle)),
                  ),
                ]),
              ),
              const SizedBox(height: 10),
              Pill(lastOk ? 'Everything Up to Date' : 'Sync Needs Attention',
                  icon: lastOk ? Icons.check_circle_outline : Icons.error_outline,
                  jakarta: true,
                  fontSize: 12.5,
                  bg: lastOk ? (c.isDark ? c.mint : const Color(0xFFD7F5E2)) : c.dangerBg,
                  fg: lastOk ? c.heading : c.danger,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5)),
              const SizedBox(height: 10),
              Text('Flora Cloud Synced', style: T.j(19, w: FontWeight.w600, c: c.text)),
              const SizedBox(height: 10),
              Text('Synchronizes your account info, study quiz history, and garden progress across devices.',
                  textAlign: TextAlign.center, style: T.j(13, c: c.textMuted, h: 1.5)),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.schedule, size: 14, color: c.textFaint),
                const SizedBox(width: 4),
                Text('Last synced: ${s.lastSynced == null ? 'Never' : fmtRelativeDay(s.lastSynced!)}',
                    style: T.j(12, c: c.textFaint)),
              ]),
              const SizedBox(height: 16),
              PrimaryButton('Sync Now',
                  icon: Icons.sync,
                  radius: 16,
                  jakarta: true,
                  loading: _busy,
                  color: c.isDark ? c.primary : const Color(0xFF14533C),
                  onTap: _sync),
            ]),
          ),
          const SizedBox(height: 16),
          SFCard(
            radius: 24,
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.fact_check_outlined, size: 18, color: c.heading),
                const SizedBox(width: 8),
                Text('What gets synced?', style: T.j(15, w: FontWeight.w700, c: c.text)),
              ]),
              const SizedBox(height: 12),
              _item(context, 'Account Profile & Level', 'Avatar, student info & level XP'),
              _item(context, 'Study Progress & Quiz History', 'Quiz scores and completed module reviews'),
              _item(context, 'Garden Data', 'Planted flowers, seed inventory & coins'),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: c.isDark ? c.mint : const Color(0xFFE3F8EA), borderRadius: BorderRadius.circular(12)),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.lock_outline, size: 16, color: c.heading),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Stored on this device', style: T.j(12, w: FontWeight.w700, c: c.text)),
                      Text(
                          'Original uploaded documents (PDF, DOCX, TXT) and extracted note text remain private in local device storage and are never uploaded to cloud servers.',
                          style: T.j(11.5, c: c.textMuted, h: 1.45)),
                    ]),
                  ),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          SFCard(
            radius: 24,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
            child: Column(children: [
              Row(children: [
                Icon(Icons.history, size: 18, color: c.heading),
                const SizedBox(width: 8),
                Expanded(child: Text('Sync History', style: T.j(15, w: FontWeight.w700, c: c.text))),
                Text('Past 7 days', style: T.j(11.5, c: c.textFaint)),
              ]),
              const SizedBox(height: 8),
              if (s.syncEvents.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text('No sync attempts yet. Tap Sync Now.', style: T.j(12.5, c: c.textMuted)),
                ),
              for (var i = 0; i < s.syncEvents.length && i < 5; i++) ...[
                if (i > 0) Divider(height: 1, color: c.border),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(children: [
                    Icon(s.syncEvents[i].success ? Icons.check_circle_outline : Icons.error_outline,
                        size: 22, color: s.syncEvents[i].success ? const Color(0xFF15924F) : const Color(0xFFEA580C)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(s.syncEvents[i].success ? 'Successful Sync' : 'Failed Sync',
                            style: T.j(13, w: FontWeight.w600, c: c.text)),
                        Text(
                            s.syncEvents[i].success
                                ? (s.syncEvents[i].manual ? 'Manual trigger' : 'Automatic cloud update')
                                : fmtDateTime(s.syncEvents[i].at),
                            style: T.j(11, c: s.syncEvents[i].success ? c.textFaint : const Color(0xFFEA580C))),
                      ]),
                    ),
                    s.syncEvents[i].success
                        ? Pill(fmtRelativeDay(s.syncEvents[i].at),
                            jakarta: true,
                            fontSize: 11,
                            bg: i == 0
                                ? (c.isDark ? c.mint : const Color(0xFFDDF5E6))
                                : (c.isDark ? c.cardAlt : const Color(0xFFEEF1F6)),
                            fg: i == 0 ? c.heading : c.text,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3))
                        : InkWell(
                            onTap: _busy ? null : _sync,
                            child: Pill('Retry',
                                icon: Icons.refresh,
                                jakarta: true,
                                fontSize: 11,
                                bg: const Color(0xFFFFF4E5),
                                fg: const Color(0xFFEA580C),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3)),
                          ),
                  ]),
                ),
              ],
            ]),
          ),
          const SizedBox(height: 26),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                  color: c.isDark ? c.mint : const Color(0xFFDDF5E6), borderRadius: BorderRadius.circular(20)),
              child: const StudyResponsiblyFooter(),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _item(BuildContext context, String title, String sub) {
    final c = context.c;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration:
          BoxDecoration(color: c.isDark ? c.cardAlt : const Color(0xFFF6F8FB), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(color: c.isDark ? c.mint : const Color(0xFFD7F5E2), shape: BoxShape.circle),
          child: Icon(Icons.check, size: 15, color: c.heading),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: T.j(13, w: FontWeight.w600, c: c.text)),
            Text(sub, style: T.j(11.5, c: c.textFaint)),
          ]),
        ),
      ]),
    );
  }
}
