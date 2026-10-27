import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../nav.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/app_header.dart';
import '../../widgets/common.dart';
import '../../widgets/visuals.dart';
import 'account_screens.dart';
import 'border_picker_screen.dart';
import 'legal_screens.dart';
import 'profile_screen.dart';
import 'sync_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = context.c;
    return Scaffold(
      backgroundColor: c.isDark ? c.bg : const Color(0xFFEFF6F1),
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          const AppHeader(),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 28), children: [
              Text('Settings', style: T.j(29, w: FontWeight.w800, c: c.isDark ? c.text : const Color(0xFF16302A))),
              const SizedBox(height: 16),
              SFCard(
                radius: 22,
                onTap: () => pushTab(context, const ProfileScreen()),
                padding: const EdgeInsets.fromLTRB(16, 18, 14, 18),
                child: Row(children: [
                  AvatarRing(avatarAsset: s.avatar.asset, border: s.border.kind, size: 80, showOuter: false),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Flexible(child: Text(s.displayName, style: T.j(18, w: FontWeight.w700, c: c.text))),
                        const SizedBox(width: 8),
                        Pill('Lv. ${s.level}',
                            jakarta: true,
                            fontSize: 12,
                            bg: c.isDark ? Colors.transparent : const Color(0xFFD7F5E2),
                            borderColor: c.isDark ? const Color(0xFF2B6B53) : const Color(0xFFB9EBCB),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2)),
                      ]),
                      Text(s.email, style: T.j(12.5, c: c.textMuted)),
                      const SizedBox(height: 8),
                      Row(children: [
                        Text('${s.xp} / ${s.nextLevelXp} XP', style: T.j(11.5, c: c.textMuted)),
                        const Spacer(),
                        Text('${(s.levelProgress * 100).round()}%',
                            style: T.j(11.5, w: FontWeight.w700, c: const Color(0xFF15924F))),
                      ]),
                      const SizedBox(height: 4),
                      SFProgress(
                          value: s.levelProgress,
                          height: 6,
                          color: const Color(0xFF10B981),
                          track: c.isDark ? c.border : const Color(0xFFD7F5E2)),
                    ]),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right, color: c.textMuted),
                ]),
              ),
              const SizedBox(height: 16),
              SFCard(
                radius: 22,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Row(children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: Stack(alignment: Alignment.center, children: [
                      CustomPaint(size: const Size.square(48), painter: BorderPainter(s.border.kind)),
                      Icon(Icons.filter_center_focus, size: 20, color: c.mintText),
                    ]),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Avatar Border', style: T.j(14.5, w: FontWeight.w600, c: c.text)),
                      Text(s.border.name, style: T.j(12.5, c: c.mintText)),
                    ]),
                  ),
                  Material(
                    color: Colors.transparent,
                    shape: StadiumBorder(
                        side: BorderSide(color: c.isDark ? const Color(0xFF2B6B53) : const Color(0xFF1B6B3F))),
                    child: InkWell(
                      customBorder: const StadiumBorder(),
                      onTap: () => pushTab(context, const BorderPickerScreen()),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        child: Row(children: [
                          Text('Change', style: T.j(13, w: FontWeight.w600, c: c.isDark ? c.accent : c.heading)),
                          const SizedBox(width: 4),
                          Icon(Icons.chevron_right, size: 17, color: c.isDark ? c.accent : c.heading),
                        ]),
                      ),
                    ),
                  ),
                ]),
              ),
              _sectionLabel(context, Icons.bolt, 'PREFERENCES'),
              _Group(children: [
                _ToggleRow(
                    Icons.music_note_outlined, 'Music', 'Background music for a calmer study', s.music, s.setMusic),
                _ToggleRow(Icons.volume_up_outlined, 'Sound', 'Sound effects and interactions', s.sound, s.setSound),
                _ToggleRow(Icons.notifications_none, 'Notifications', 'Study reminders, quiz alerts, and rewards',
                    s.notifications, s.setNotifications),
                _ToggleRow(
                    Icons.dark_mode_outlined, 'Dark Mode', 'Reduce eye strain and save battery', s.darkMode, s.setDark),
              ]),
              _sectionLabel(context, Icons.person_outline, 'ACCOUNT'),
              _Group(children: [
                _NavRow(Icons.manage_accounts_outlined, 'Switch Account', 'Sign in with a different account',
                    onTap: () => pushRoot(context, const SwitchAccountScreen())),
                _NavRow(Icons.logout, 'Log Out', 'Sign out from your account',
                    danger: true, onTap: () => pushTab(context, const LogoutScreen())),
              ]),
              _sectionLabel(context, Icons.cloud_outlined, 'CLOUD SYNC'),
              _Group(children: [
                _NavRow(Icons.sync, 'Sync Status',
                    s.lastSynced == null ? 'Not synced yet' : 'Last synced: ${fmtDateTime(s.lastSynced!)}',
                    badge: s.lastSynced == null ? 'Pending' : 'Synced',
                    onTap: () => pushTab(context, const SyncScreen())),
              ]),
              _sectionLabel(context, Icons.description_outlined, 'LEGAL'),
              _Group(children: [
                _NavRow(Icons.shield_outlined, 'Privacy Policy', 'Learn how we protect your data',
                    onTap: () => pushTab(context, const PrivacyPolicyScreen())),
                _NavRow(Icons.assignment_turned_in_outlined, 'Terms of Service', 'Our commitment to you',
                    onTap: () => pushTab(context, const TermsScreen())),
              ]),
              const SizedBox(height: 36),
              const StudyResponsiblyFooter(),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, IconData icon, String label) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 10),
      child: Row(children: [
        Icon(icon, size: 15, color: c.isDark ? c.accent : const Color(0xFF1B6B3F)),
        const SizedBox(width: 6),
        Text(label, style: T.j(12.5, w: FontWeight.w700, c: c.isDark ? c.textMuted : const Color(0xFF16302A), ls: .6)),
      ]),
    );
  }
}

class StudyResponsiblyFooter extends StatelessWidget {
  const StudyResponsiblyFooter({super.key});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(c.isDark ? Icons.lightbulb_outline : Icons.spa, size: 14, color: const Color(0xFF15924F)),
      const SizedBox(width: 6),
      Text('Study responsibly, grow together',
          style: T.j(12.5, w: FontWeight.w600, c: c.isDark ? c.accent : const Color(0xFF1B6B3F))),
      const SizedBox(width: 6),
      Icon(c.isDark ? Icons.lightbulb_outline : Icons.spa, size: 14, color: const Color(0xFF15924F)),
    ]);
  }
}

class _Group extends StatelessWidget {
  final List<Widget> children;
  const _Group({required this.children});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SFCard(
      radius: 22,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) Divider(height: 1, indent: 16, endIndent: 16, color: c.border),
          children[i],
        ],
      ]),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow(this.icon, this.title, this.subtitle, this.value, this.onChanged);
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(children: [
        IconTile(icon,
            size: 40,
            iconSize: 20,
            radius: 12,
            bg: c.isDark ? c.cardAlt : const Color(0xFFE6F4EA),
            fg: c.isDark ? c.accent : c.heading),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: T.j(14.5, w: FontWeight.w700, c: c.text)),
            Text(subtitle, style: T.j(11.5, c: c.textMuted)),
          ]),
        ),
        SFSwitch(value: value, onChanged: onChanged),
      ]),
    );
  }
}

class _NavRow extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final bool danger;
  final String? badge;
  final VoidCallback onTap;
  const _NavRow(this.icon, this.title, this.subtitle, {required this.onTap, this.danger = false, this.badge});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final red = c.isDark ? const Color(0xFFF87171) : const Color(0xFFE11D48);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
        child: Row(children: [
          IconTile(icon,
              size: 40,
              iconSize: 20,
              radius: 12,
              bg: danger
                  ? (c.isDark ? const Color(0xFF3A1519) : const Color(0xFFFDE2E6))
                  : (c.isDark ? c.cardAlt : const Color(0xFFE6F4EA)),
              fg: danger ? red : (c.isDark ? c.accent : c.heading)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(title, style: T.j(14.5, w: FontWeight.w700, c: danger ? red : c.text)),
                if (badge != null) ...[
                  const SizedBox(width: 8),
                  Pill(badge!,
                      jakarta: true,
                      fontSize: 10.5,
                      bg: c.isDark ? Colors.transparent : const Color(0xFFD7F5E2),
                      borderColor: c.isDark ? const Color(0xFF2B6B53) : const Color(0xFFB9EBCB),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2)),
                ],
              ]),
              Text(subtitle, style: T.j(11.5, c: c.textMuted)),
            ]),
          ),
          Icon(Icons.chevron_right, color: c.textMuted),
        ]),
      ),
    );
  }
}
