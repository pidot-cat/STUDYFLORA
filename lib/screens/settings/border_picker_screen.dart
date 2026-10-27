import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header.dart';
import '../../widgets/common.dart';
import '../../widgets/visuals.dart';
import '../shop/purchase_sheets.dart';

class BorderPickerScreen extends StatefulWidget {
  const BorderPickerScreen({super.key});
  @override
  State<BorderPickerScreen> createState() => _BorderPickerScreenState();
}

class _BorderPickerScreenState extends State<BorderPickerScreen> {
  late String _sel = context.read<AppState>().borderId;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = context.c;
    final preview = BorderOption.byId(_sel);
    final unlocked = BorderOption.all.where((b) => s.ownedBorders.contains(b.id)).length;
    return Scaffold(
      backgroundColor: c.isDark ? c.bg : const Color(0xFFEFF6F1),
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          const AppHeader(back: true, showXp: true),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 28), children: [
              Text('Choose Your Avatar Border',
                  style: T.p(21.5, w: FontWeight.w700, c: c.isDark ? c.text : const Color(0xFF16302A))),
              const SizedBox(height: 8),
              Text('Customize your profile avatar frame across your study garden and leaderboard.',
                  style: T.p(12.5, c: c.textMuted, h: 1.5)),
              const SizedBox(height: 18),
              SFCard(
                radius: 28,
                padding: const EdgeInsets.fromLTRB(16, 22, 16, 20),
                child: Column(children: [
                  AvatarRing(avatarAsset: s.avatar.asset, border: preview.kind, size: 132),
                  const SizedBox(height: 12),
                  Text('PREVIEWING BORDER', style: T.p(11.5, w: FontWeight.w600, c: c.textFaint, ls: .5)),
                  const SizedBox(height: 4),
                  Pill('${preview.name}${preview.id == s.borderId ? ' (Equipped)' : ''}',
                      dot: true,
                      fontSize: 12,
                      bg: c.isDark ? c.mint : const Color(0xFFE3F5EA),
                      fg: c.heading,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4)),
                ]),
              ),
              const SizedBox(height: 22),
              Row(children: [
                Text('BORDERS ($unlocked UNLOCKED)', style: T.p(13.5, w: FontWeight.w700, c: c.heading, ls: .4)),
                const Spacer(),
                Text('Tap to test & equip', style: T.p(11, c: c.textMuted)),
              ]),
              const SizedBox(height: 12),
              for (final b in BorderOption.all) ...[
                _BorderTile(
                  border: b,
                  owned: s.ownedBorders.contains(b.id),
                  active: s.borderId == b.id,
                  selected: _sel == b.id,
                  onTap: () => setState(() => _sel = b.id),
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 6),
              Row(children: [
                Expanded(child: OutlineButtonSF('Cancel', height: 48, onTap: () => Navigator.of(context).pop())),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: PrimaryButton(
                    s.ownedBorders.contains(_sel) ? 'Apply Border' : 'Unlock Border',
                    icon: s.ownedBorders.contains(_sel) ? Icons.check : Icons.lock_open,
                    height: 48,
                    radius: 14,
                    color: c.isDark ? c.primary : const Color(0xFF1B3A2E),
                    onTap: () {
                      if (s.ownedBorders.contains(_sel)) {
                        s.equipBorder(_sel);
                        showSnack(context, '${preview.name} applied.');
                        Navigator.of(context).pop();
                      } else {
                        showBorderPurchase(context, preview);
                      }
                    },
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              Center(
                child:
                    Text('Border updates automatically across all your garden rooms.', style: T.p(11, c: c.textMuted)),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _BorderTile extends StatelessWidget {
  final BorderOption border;
  final bool owned, active, selected;
  final VoidCallback onTap;
  const _BorderTile(
      {required this.border, required this.owned, required this.active, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final b = border;
    final locked = !owned;
    final highlight = selected;
    return Material(
      color: highlight
          ? (c.isDark ? c.mint : const Color(0xFFE5F6EB))
          : (locked ? (c.isDark ? c.card : const Color(0xFFF3F8F5)) : c.card),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: highlight ? const Color(0xFF1B4D3E) : c.border, width: highlight ? 2 : 1),
            gradient: highlight
                ? const LinearGradient(
                    stops: [0, .018, .018, 1],
                    colors: [Color(0xFF1B4D3E), Color(0xFF1B4D3E), Colors.transparent, Colors.transparent])
                : null,
          ),
          child: Row(children: [
            BorderSwatch(b.kind, size: 56, locked: locked, active: active),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(child: Text(b.name, style: T.p(14, w: FontWeight.w600, c: locked ? c.textMuted : c.text))),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                        color: active ? const Color(0xFF16A34A) : (c.isDark ? c.cardAlt : const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(4)),
                    child: Text(active ? 'Active' : (locked ? 'Locked' : 'Owned'),
                        style: T.p(9.5, w: FontWeight.w600, c: active ? Colors.white : c.textMuted)),
                  ),
                ]),
                Row(children: [
                  b.rarity == 'Basic' && b.xpCost > 0
                      ? Icon(Icons.crop_square, size: 12, color: c.textMuted)
                      : Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                              color: b.xpCost == 0 ? const Color(0xFF16A34A) : c.textFaint, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(b.detail,
                      style: T.p(11.5,
                          w: b.xpCost == 0 ? FontWeight.w600 : FontWeight.w400,
                          c: b.xpCost == 0 ? const Color(0xFF15803D) : c.textMuted)),
                ]),
                const SizedBox(height: 2),
                b.xpCost == 0
                    ? Text('Free', style: T.p(12, w: FontWeight.w700, c: const Color(0xFF15803D)))
                    : Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(color: c.textFaint, borderRadius: BorderRadius.circular(3)),
                          child: Text('XP', style: T.p(9, w: FontWeight.w700, c: Colors.white)),
                        ),
                        const SizedBox(width: 6),
                        Text('${b.xpCost}', style: T.p(12, w: FontWeight.w700, c: c.textMuted)),
                      ]),
              ]),
            ),
            if (active)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: Row(children: [
                  const Icon(Icons.check, size: 14, color: Color(0xFF15803D)),
                  const SizedBox(width: 6),
                  Text('Selected', style: T.p(12.5, w: FontWeight.w600, c: const Color(0xFF15803D))),
                ]),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: c.isDark ? c.cardAlt : const Color(0xFFEFF2F0), borderRadius: BorderRadius.circular(20)),
                child: Row(children: [
                  Icon(locked ? Icons.lock_outline : Icons.touch_app_outlined, size: 14, color: c.textFaint),
                  const SizedBox(width: 6),
                  Text(locked ? 'Locked' : 'Equip', style: T.p(12.5, w: FontWeight.w500, c: c.textFaint)),
                ]),
              ),
          ]),
        ),
      ),
    );
  }
}
