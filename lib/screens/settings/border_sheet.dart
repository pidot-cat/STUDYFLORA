import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/cosmetics.dart';
import '../../providers/game_provider.dart';
import '../../widgets/common.dart';
import '../../widgets/profile_widgets.dart';
import '../../widgets/sheets.dart';
import '../shop/purchase_sheet.dart';

/// Change avatar + equip owned borders (locked ones open the XP purchase).
Future<void> showBorderSheet(BuildContext context) {
  return showSfSheet(
    context: context,
    builder: (ctx) {
      final g = ctx.watch<GameProvider>();
      final c = ctx.sf;
      return Column(mainAxisSize: MainAxisSize.min, children: [
        const SheetHeader(title: 'Avatar & Border', icon: Icons.face_retouching_natural_rounded),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
            children: [
              Center(child: AvatarWithBorder(avatarId: g.avatarId, borderId: g.equippedBorder, size: 130, badgeId: g.avatarBadge)),
              const SizedBox(height: 8),
              Center(child: Text(BorderDef.nameOf(g.equippedBorder), style: ctx.tt.titleMedium)),
              const CapsLabel('Avatar', icon: Icons.pets_rounded),
              Wrap(spacing: 12, runSpacing: 12, alignment: WrapAlignment.center, children: [
                for (final a in Avatar.all)
                  Pressable(
                    onTap: () => g.setAvatar(a.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: g.avatarId == a.id ? c.accent : Colors.transparent, width: 3),
                      ),
                      child: ClipOval(child: Image.asset(a.asset, width: 58, height: 58)),
                    ),
                  ),
              ]),
              const CapsLabel('Borders', icon: Icons.blur_circular_rounded),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.74,
                children: [
                  _BorderTile(
                    selected: g.equippedBorder == BorderDef.noneId,
                    preview: (s) => AvatarWithBorder(avatarId: g.avatarId, borderId: BorderDef.noneId, size: s),
                    name: 'No border',
                    status: g.equippedBorder == BorderDef.noneId
                        ? const StatusBadge('Equipped', dense: true)
                        : const StatusBadge('Plain', tone: Tone.neutral, dense: true),
                    onTap: () => g.equipBorder(BorderDef.noneId),
                  ),
                  for (final b in BorderDef.all)
                    Pressable(
                      onTap: () {
                        if (g.ownedBorders.contains(b.id)) {
                          g.equipBorder(b.id);
                        } else {
                          showBorderPurchaseSheet(ctx, b);
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: g.equippedBorder == b.id ? c.brandSoft : c.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: g.equippedBorder == b.id ? c.accent : c.line, width: 1.5),
                        ),
                        child: Column(children: [
                          Expanded(
                            child: LayoutBuilder(
                              builder: (_, box) => Center(
                                child: Opacity(
                                  opacity: g.ownedBorders.contains(b.id) ? 1 : 0.6,
                                  child: AvatarWithBorder(
                                    avatarId: g.avatarId,
                                    borderId: b.id,
                                    size: box.maxWidth < box.maxHeight ? box.maxWidth : box.maxHeight,
                                    badgeId: g.avatarBadge,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(b.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 3),
                          g.equippedBorder == b.id
                              ? const StatusBadge('Equipped', dense: true)
                              : g.ownedBorders.contains(b.id)
                                  ? const StatusBadge('Owned', tone: Tone.blue, dense: true)
                                  : StatusBadge('${b.priceXp} XP', tone: Tone.neutral, icon: Icons.lock_outline_rounded, dense: true),
                        ]),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Every border comes with a badge of the same theme.', style: ctx.tt.bodySmall, textAlign: TextAlign.center),
            ],
          ),
        ),
      ]);
    },
  );
}

class _BorderTile extends StatelessWidget {
  const _BorderTile({required this.selected, required this.preview, required this.name, required this.status, required this.onTap});
  final bool selected;
  final Widget Function(double size) preview;
  final String name;
  final Widget status;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final c = context.sf;
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected ? c.brandSoft : c.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? c.accent : c.line, width: 1.5),
        ),
        child: Column(children: [
          Expanded(child: LayoutBuilder(builder: (_, box) => Center(child: preview(box.maxWidth < box.maxHeight ? box.maxWidth : box.maxHeight)))),
          const SizedBox(height: 4),
          Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 3),
          status,
        ]),
      ),
    );
  }
}
