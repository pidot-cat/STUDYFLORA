import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../nav.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header.dart';
import '../../widgets/common.dart';
import '../../widgets/visuals.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _rename(BuildContext context) async {
    final s = context.read<AppState>();
    final ctl = TextEditingController(text: s.displayName);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Name', style: T.p(17, w: FontWeight.w600)),
        content:
            TextField(controller: ctl, autofocus: true, decoration: const InputDecoration(hintText: 'Display name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctl.text), child: const Text('Save')),
        ],
      ),
    );
    if (name != null) s.rename(name);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = context.c;
    final pct = (s.levelProgress * 100).round();
    final remaining = s.nextLevelXp - s.xp;
    return Scaffold(
      backgroundColor: c.isDark ? c.bg : const Color(0xFFEFF6F1),
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          const AppHeader(back: true),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 28), children: [
              Text('Profile & Progress',
                  style: T.p(27, w: FontWeight.w700, c: c.isDark ? c.text : const Color(0xFF16302A))),
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Container(
                  color: c.card,
                  child: Stack(children: [
                    Positioned(
                      right: -30,
                      top: -40,
                      child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                              color: c.isDark ? c.cardAlt : const Color(0xFFEAF5EE), shape: BoxShape.circle)),
                    ),
                    Positioned(
                      left: -30,
                      bottom: -40,
                      child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                              color: c.isDark ? c.cardAlt : const Color(0xFFF1F8F3), shape: BoxShape.circle)),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 26, 16, 26),
                      child: Column(children: [
                        Center(child: AvatarRing(avatarAsset: s.avatar.asset, border: s.border.kind, size: 132)),
                        const SizedBox(height: 10),
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text(s.displayName, style: T.p(19, w: FontWeight.w600, c: c.text)),
                          const SizedBox(width: 8),
                          Pill('Lv. ${s.level}',
                              fontSize: 12,
                              bg: c.isDark ? c.mint : const Color(0xFFDDF0E4),
                              fg: c.heading,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2)),
                        ]),
                        const SizedBox(height: 6),
                        Text(s.email, style: T.p(12.5, c: c.textMuted)),
                        const SizedBox(height: 16),
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          _chipBtn(
                              context,
                              Icons.palette_outlined,
                              'Change Avatar',
                              c.isDark ? c.mint : const Color(0xFFDDF0E4),
                              () => pushTab(context, const AvatarPickerScreen())),
                          const SizedBox(width: 12),
                          _chipBtn(context, Icons.edit_outlined, 'Edit Name',
                              c.isDark ? c.cardAlt : const Color(0xFFEEF1F6), () => _rename(context)),
                        ]),
                      ]),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 22),
              SFCard(
                radius: 28,
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
                child: Column(children: [
                  Row(children: [
                    IconTile(Icons.attach_money,
                        size: 34,
                        iconSize: 18,
                        circle: true,
                        bg: c.isDark ? c.cardAlt : const Color(0xFFEAF5EE),
                        fg: c.heading),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Level & Experience', style: T.p(14, w: FontWeight.w500, c: c.text)),
                        Text('Overall botanical learning status', style: T.p(11, c: c.textMuted)),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: c.isDark ? c.cardAlt : const Color(0xFFF1F7F3), borderRadius: BorderRadius.circular(16)),
                    child: Column(children: [
                      Row(children: [
                        Text('Level ${s.level}', style: T.p(16, w: FontWeight.w700, c: c.text)),
                        const SizedBox(width: 6),
                        Text(Levels.name(s.xp), style: T.p(12.5, c: c.textMuted)),
                        const Spacer(),
                        Text('${s.xp} / ${s.nextLevelXp} XP', style: T.p(12.5, w: FontWeight.w600, c: c.text)),
                        const SizedBox(width: 8),
                        Pill('$pct%',
                            fontSize: 11,
                            bg: c.isDark ? c.mint : const Color(0xFFDDF0E4),
                            fg: c.heading,
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2)),
                      ]),
                      const SizedBox(height: 12),
                      SFProgress(
                          value: s.levelProgress,
                          height: 8,
                          color: c.isDark ? c.accent : const Color(0xFF2E6B4C),
                          track: c.isDark ? c.border : const Color(0xFFE2E8F0)),
                      const SizedBox(height: 10),
                      Row(children: [
                        Text('$remaining XP needed to reach Level ${s.level + 1}', style: T.p(11, c: c.textMuted)),
                        const Spacer(),
                        const Icon(Icons.spa, size: 13, color: Color(0xFF15924F)),
                        const SizedBox(width: 4),
                        Text(pct >= 50 ? 'Halfway there' : 'Keep growing',
                            style: T.p(11, w: FontWeight.w600, c: const Color(0xFF15924F))),
                      ]),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 50),
              const StudyResponsiblyFooter(),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _chipBtn(BuildContext context, IconData icon, String label, Color bg, VoidCallback onTap) {
    final c = context.c;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(children: [
            Icon(icon, size: 15, color: c.heading),
            const SizedBox(width: 6),
            Text(label, style: T.p(12.5, w: FontWeight.w600, c: c.heading)),
          ]),
        ),
      ),
    );
  }
}

class AvatarPickerScreen extends StatefulWidget {
  const AvatarPickerScreen({super.key});
  @override
  State<AvatarPickerScreen> createState() => _AvatarPickerScreenState();
}

class _AvatarPickerScreenState extends State<AvatarPickerScreen> {
  late String _sel = context.read<AppState>().avatarId;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = context.c;
    final current = AvatarOption.byId(_sel);
    return Scaffold(
      backgroundColor: c.isDark ? c.bg : const Color(0xFFEFF6F1),
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          const AppHeader(showProfile: false),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(20, 14, 20, 28), children: [
              Text('Choose Your Avatar',
                  style: T.p(23, w: FontWeight.w700, c: c.isDark ? c.text : const Color(0xFF16302A))),
              const SizedBox(height: 4),
              Text('Select an avatar that represents you across your study garden.', style: T.p(12.5, c: c.textMuted)),
              const SizedBox(height: 16),
              SFCard(
                radius: 24,
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  AvatarRing(avatarAsset: current.asset, border: s.border.kind, size: 84, showOuter: false),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Pill(_sel == s.avatarId ? 'Current Avatar' : 'Preview',
                          dot: true,
                          fontSize: 11.5,
                          bg: c.isDark ? c.mint : const Color(0xFFE3F5EA),
                          borderColor: const Color(0xFFBFE6CE)),
                      const SizedBox(height: 6),
                      Text(current.name, style: T.p(17, w: FontWeight.w600, c: c.text)),
                      const SizedBox(height: 2),
                      Text(current.description, style: T.p(11.5, c: c.textMuted, h: 1.45)),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 18),
              Row(children: [
                Text('SELECTABLE AVATARS', style: T.p(11.5, w: FontWeight.w600, c: c.textMuted, ls: .5)),
                const Spacer(),
                Text('6 botanical companions', style: T.p(11, c: c.textMuted)),
              ]),
              const SizedBox(height: 10),
              GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12, mainAxisExtent: 124),
                children: [
                  for (final a in AvatarOption.all)
                    _AvatarTile(
                      option: a,
                      selected: a.id == _sel,
                      equipped: a.id == s.avatarId,
                      onTap: () => setState(() => _sel = a.id),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              const InfoBanner(
                  'Your avatar appears on your study desk, quiz summary headers, and community leaderboard. You can change your avatar at any time for free.',
                  fontSize: 12),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                    child:
                        OutlineButtonSF('Cancel', height: 48, fontSize: 14, onTap: () => Navigator.of(context).pop())),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton('Apply Avatar',
                      icon: Icons.check,
                      height: 48,
                      fontSize: 14,
                      color: c.isDark ? c.primary : const Color(0xFF1B3A2E), onTap: () {
                    s.setAvatar(_sel);
                    showSnack(context, '${current.name} equipped.');
                    Navigator.of(context).pop();
                  }),
                ),
              ]),
              const SizedBox(height: 40),
              const StudyResponsiblyFooter(),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _AvatarTile extends StatelessWidget {
  final AvatarOption option;
  final bool selected, equipped;
  final VoidCallback onTap;
  const _AvatarTile({required this.option, required this.selected, required this.equipped, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Stack(clipBehavior: Clip.none, children: [
      SFCard(
        onTap: onTap,
        radius: 16,
        color: selected ? (c.isDark ? c.mint : const Color(0xFFE8F8EE)) : null,
        borderColor: selected ? const Color(0xFF1B6B3F) : null,
        borderWidth: selected ? 2 : 1,
        padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ClipOval(child: Image.asset(option.asset, width: 54, height: 54, fit: BoxFit.cover)),
            const SizedBox(height: 8),
            Text(option.name, style: T.p(12.5, w: FontWeight.w600, c: c.text)),
            Text(equipped ? 'Equipped' : option.tag,
                style: T.p(10.5,
                    w: equipped ? FontWeight.w600 : FontWeight.w400,
                    c: equipped ? const Color(0xFF15924F) : c.textMuted)),
          ]),
        ),
      ),
      if (selected)
        Positioned(
          right: -4,
          top: -6,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
                color: const Color(0xFF1B6B3F),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2)),
            child: const Icon(Icons.check, size: 11, color: Colors.white),
          ),
        ),
    ]);
  }
}
