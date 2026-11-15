import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/flower.dart';
import '../../providers/auth_provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/study_provider.dart';
import '../../widgets/common.dart';
import '../../widgets/profile_widgets.dart';
import '../../widgets/sheets.dart';

/// FR-1.6 / FR-5.6 — view and manage account information.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final g = context.watch<GameProvider>();
    final s = context.watch<StudyProvider>();
    final c = context.sf;
    final u = auth.user;
    return Scaffold(
      appBar: AppBar(backgroundColor: c.bg, surfaceTintColor: Colors.transparent, title: Text('Account', style: context.tt.titleMedium)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          Center(child: AvatarWithBorder(avatarId: g.avatarId, borderId: g.equippedBorder, size: 128, badgeId: g.avatarBadge)),
          const SizedBox(height: 10),
          Center(child: Text(u?.displayName ?? '', style: context.tt.headlineMedium?.copyWith(fontSize: 24))),
          Center(child: Text(u?.email ?? '', style: context.tt.bodySmall)),
          const SizedBox(height: 8),
          Center(
            child: Wrap(spacing: 6, children: [
              StatusBadge('Level ${g.level}', icon: Icons.trending_up_rounded, dense: true),
              StatusBadge('${g.xp} XP', tone: Tone.blue, icon: Icons.bolt_rounded, dense: true),
            ]),
          ),
          const SizedBox(height: 16),
          SfCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              _Info(label: 'Username', value: u?.displayName ?? '', action: 'Edit', onTap: () => _editName(context, auth)),
              const Divider(indent: 16),
              _Info(label: 'Email', value: u?.email ?? ''),
            ]),
          ),
          const CapsLabel('Your progress', icon: Icons.insights_rounded),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.45,
            children: [
              _Stat(value: '${g.lifetimeXp}', label: 'Lifetime XP'),
              _Stat(value: '${g.harvests}', label: 'Harvests'),
              _Stat(value: '${g.harvestedKinds.length}/${Flower.all.length}', label: 'Flowers'),
              _Stat(value: '${s.modules.length}', label: 'Modules'),
              _Stat(value: '${s.masteredCount}', label: 'Mastered'),
              _Stat(value: '${s.attempts.length}', label: 'Quizzes'),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _editName(BuildContext context, AuthProvider auth) async {
    final name = await showTextPromptSheet(
      context,
      title: 'Edit username',
      icon: Icons.badge_outlined,
      initial: auth.user?.displayName ?? '',
      capitalization: TextCapitalization.none,
    );
    if (name == null) return;
    if (!RegExp(r'^[A-Za-z0-9_.]{3,20}$').hasMatch(name)) {
      if (context.mounted) showToast(context, 'Username must be 3–20 characters: letters, numbers, _ or .', error: true);
      return;
    }
    try {
      await auth.updateName(name);
      if (context.mounted) showToast(context, 'Username updated');
    } catch (e) {
      if (context.mounted) showToast(context, e.toString(), error: true);
    }
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.label, required this.value, this.action, this.onTap});
  final String label;
  final String value;
  final String? action;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final c = context.sf;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: context.tt.bodySmall),
              Text(value, style: context.tt.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
          if (action != null) Text(action!, style: TextStyle(color: c.brand, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => SfCard(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          FittedBox(fit: BoxFit.scaleDown, child: Text(value, maxLines: 1, style: context.tt.titleLarge)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label, maxLines: 1, style: context.tt.bodySmall?.copyWith(fontSize: 11)),
          ),
        ]),
      );
}
