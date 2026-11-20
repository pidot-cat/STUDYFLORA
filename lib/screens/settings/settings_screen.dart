import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/cosmetics.dart';
import '../../providers/auth_provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/garden_notifications.dart';
import '../../widgets/common.dart';
import '../../widgets/profile_widgets.dart';
import '../../widgets/sheets.dart';
import '../auth/auth_widgets.dart';
import '../shell.dart';
import 'account_screen.dart';
import 'badges_screen.dart';
import 'border_sheet.dart';
import 'feedback_screen.dart';
import 'legal_screen.dart';

/// Settings / Profile (FR-5.3 … FR-5.6). Cloud sync runs automatically in the
/// background, so it has no controls here.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.sf;
    final g = context.watch<GameProvider>();
    final s = context.watch<SettingsProvider>();
    final user = context.select<AuthProvider, ({String name, String email})?>(
      (a) => a.user == null ? null : (name: a.user!.displayName, email: a.user!.email),
    );
    final showcase = g.showcaseBadge == null ? null : Badges.of(g.showcaseBadge!);

    return SafeArea(
      bottom: false,
      child: Column(children: [
        const SfTopBar(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
            children: [
              Text('Settings', style: context.tt.headlineMedium),
              const SizedBox(height: 14),

              // ---- profile
              SfCard(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  AvatarWithBorder(avatarId: g.avatarId, borderId: g.equippedBorder, size: 84, badgeId: g.avatarBadge),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(user?.name ?? 'Gardener', style: context.tt.titleLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(user?.email ?? '', style: context.tt.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 8),
                      Row(children: [
                        StatusBadge('Lv. ${g.level}', dense: true),
                        if (showcase != null) ...[
                          const SizedBox(width: 6),
                          Flexible(child: StatusBadge(showcase.name, tone: Tone.gold, icon: showcase.icon, dense: true)),
                        ],
                      ]),
                      const SizedBox(height: 8),
                      SfProgressBar(value: g.levelProgress, height: 6),
                      const SizedBox(height: 4),
                      Text('${g.xpIntoLevel} / ${GameRules.xpPerLevel} XP to Lv. ${g.level + 1}', style: context.tt.bodySmall?.copyWith(fontSize: 11)),
                    ]),
                  ),
                ]),
              ),

              // ---- profile customisation
              const CapsLabel('Profile', icon: Icons.face_outlined),
              _Group(children: [
                _NavRow(
                  leading: AvatarWithBorder(avatarId: g.avatarId, borderId: g.equippedBorder, size: 44, badgeId: g.avatarBadge),
                  title: 'Avatar & Border',
                  subtitle: BorderDef.nameOf(g.equippedBorder),
                  onTap: () => showBorderSheet(context),
                ),
                _NavRow(
                  leading: IconTile(Icons.military_tech_outlined, size: 44),
                  title: 'Badges & Achievements',
                  subtitle: '${g.badges.length} of ${Badges.all.length} unlocked',
                  trailing: g.unclaimedBadges > 0 ? StatusBadge('${g.unclaimedBadges} to claim', tone: Tone.gold, dense: true) : null,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BadgesScreen())),
                ),
              ]),

              // ---- preferences
              const CapsLabel('Preferences', icon: Icons.tune_rounded),
              _Group(children: [
                _ToggleRow(icon: Icons.music_note_outlined, title: 'Music', subtitle: 'Calm background music', value: s.music, onChanged: s.setMusic),
                _ToggleRow(icon: Icons.volume_up_outlined, title: 'Sounds', subtitle: 'Tap sounds and vibration', value: s.sound, onChanged: s.setSound),
                _ToggleRow(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notifications',
                  subtitle: 'Pop-ups and garden reminders',
                  value: s.notifications,
                  onChanged: (v) {
                    s.setNotifications(v);
                    if (v) GardenNotifications.instance.requestPermission();
                  },
                ),
                _ToggleRow(icon: Icons.dark_mode_outlined, title: 'Dark Mode', subtitle: 'Easier on the eyes at night', value: s.darkMode, onChanged: s.setDark),
              ]),

              // ---- account
              const CapsLabel('Account', icon: Icons.person_outline_rounded),
              _Group(children: [
                _NavRow(
                  leading: IconTile(Icons.manage_accounts_outlined, size: 44),
                  title: 'Account Information',
                  subtitle: 'View and edit your profile',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AccountScreen())),
                ),
                _NavRow(
                  leading: IconTile(Icons.logout_rounded, size: 44, color: c.danger, bg: c.dangerSoft),
                  title: 'Log Out',
                  subtitle: 'Sign out of your account',
                  danger: true,
                  onTap: () => _logout(context),
                ),
                _NavRow(
                  leading: IconTile(Icons.delete_forever_outlined, size: 44, color: c.danger, bg: c.dangerSoft),
                  title: 'Delete Account',
                  subtitle: 'Permanently remove your account and data',
                  danger: true,
                  onTap: () => _deleteAccount(context),
                ),
              ]),

              // ---- legal
              const CapsLabel('Legal', icon: Icons.description_outlined),
              _Group(children: [
                _NavRow(
                  leading: IconTile(Icons.shield_outlined, size: 44),
                  title: 'Privacy Policy',
                  subtitle: 'How your data is protected',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LegalScreen(privacy: true))),
                ),
                _NavRow(
                  leading: IconTile(Icons.fact_check_outlined, size: 44),
                  title: 'Terms of Service',
                  subtitle: 'Rules for using StudyFlora',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LegalScreen(privacy: false))),
                ),
                _NavRow(
                  leading: IconTile(Icons.rate_review_outlined, size: 44),
                  title: 'Report Feedback',
                  subtitle: 'Share comments or report a problem',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FeedbackScreen())),
                ),
              ]),
              const SizedBox(height: 24),
              Center(child: Text('Study Flora v1.0', style: context.tt.bodySmall)),
            ],
          ),
        ),
      ]),
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final nav = context.read<NavState>();
    final deleted = await showSfSheet<bool>(context: context, builder: (_) => const _DeleteAccountSheet());
    if (deleted != true) return;
    nav.go(0);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(
        content: Text('Your account has been deleted.'),
        margin: EdgeInsets.fromLTRB(16, 0, 16, 24),
      ));
  }

  Future<void> _logout(BuildContext context) async {
    final ok = await confirmDialog(
      context,
      title: 'Log out?',
      message: 'Your progress is saved on this phone${context.read<AuthProvider>().demoMode ? '' : ' and backed up to the cloud'}.',
      confirm: 'Log Out',
      danger: true,
      icon: Icons.logout_rounded,
    );
    if (!ok || !context.mounted) return;
    context.read<NavState>().go(0);
    await context.read<AuthProvider>().signOut();
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    return SfCard(
      padding: EdgeInsets.zero,
      child: Column(children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) Divider(indent: 70, color: context.sf.line),
          children[i],
        ],
      ]),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({required this.icon, required this.title, required this.subtitle, required this.value, required this.onChanged});
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        child: Row(children: [
          IconTile(icon, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: context.tt.titleSmall),
              Text(subtitle, style: context.tt.bodySmall),
            ]),
          ),
          Switch(value: value, onChanged: onChanged),
        ]),
      );
}

class _NavRow extends StatelessWidget {
  const _NavRow({required this.leading, required this.title, required this.subtitle, required this.onTap, this.trailing, this.danger = false});
  final Widget leading;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool danger;
  @override
  Widget build(BuildContext context) {
    final c = context.sf;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Row(children: [
          SizedBox(width: 44, height: 44, child: Center(child: leading)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: context.tt.titleSmall?.copyWith(color: danger ? c.danger : null)),
              Text(subtitle, style: context.tt.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
          if (trailing != null) ...[trailing!, const SizedBox(width: 4)],
          Icon(Icons.chevron_right_rounded, color: c.muted),
        ]),
      ),
    );
  }
}

/// Confirms Delete Account with the user's password. Pops `true` once the
/// account is gone.
class _DeleteAccountSheet extends StatefulWidget {
  const _DeleteAccountSheet();
  @override
  State<_DeleteAccountSheet> createState() => _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends State<_DeleteAccountSheet> {
  final _pw = TextEditingController();
  bool _understood = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _pw.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (_busy || !_understood) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().deleteAccount(_pw.text);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sf;
    final email = context.select<AuthProvider, String>((a) => a.user?.email ?? '');
    Widget item(IconData icon, String text) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(children: [
            Icon(icon, size: 18, color: c.danger),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: context.tt.bodyMedium)),
          ]),
        );
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
        const SheetHeader(title: 'Delete Account', icon: Icons.delete_forever_outlined),
        Text('This permanently deletes $email. It cannot be undone.', style: context.tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        item(Icons.local_florist_outlined, 'Your garden, seeds, tools, coins and XP'),
        item(Icons.menu_book_outlined, 'Your uploaded modules and quiz history'),
        item(Icons.emoji_events_outlined, 'Your badges and avatar borders'),
        item(Icons.person_off_outlined, 'Your login — you will need to sign up again'),
        const SizedBox(height: 10),
        if (_error != null) InlineAlert(message: _error!),
        const FieldLabel('Enter your password to confirm', icon: Icons.lock_outline_rounded),
        PasswordField(controller: _pw, hint: 'Your password', onSubmitted: (_) => _delete()),
        const SizedBox(height: 8),
        CheckboxListTile(
          value: _understood,
          onChanged: _busy ? null : (v) => setState(() => _understood = v ?? false),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: c.danger,
          title: Text('I understand this cannot be undone.', style: context.tt.bodyMedium),
        ),
        const SizedBox(height: 8),
        PrimaryButton(
          label: 'Delete My Account',
          icon: Icons.delete_forever_rounded,
          color: c.danger,
          busy: _busy,
          onTap: _understood ? _delete : null,
        ),
        const SizedBox(height: 6),
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: Text('Cancel', style: TextStyle(color: c.muted, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }
}
