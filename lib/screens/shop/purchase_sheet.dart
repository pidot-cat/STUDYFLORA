import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/cosmetics.dart';
import '../../models/flower.dart';
import '../../providers/game_provider.dart';
import '../../widgets/common.dart';
import '../../widgets/plant_widgets.dart';
import '../../widgets/profile_widgets.dart';
import '../../widgets/sheets.dart';

/// Shared "Buy …" bottom sheet (mockups: Garden tools purchase, Border
/// Purchase failed, Single/Bundle purchase).
class _PurchaseSpec {
  final String title;
  final String name;
  final String description;
  final Widget art;
  final String ownedLabel;
  final List<(IconData, String)> chips;
  final String unitLabel;
  final String unitName;
  final int unitPrice;
  final bool xp; // price in XP instead of coins
  final bool allowQuantity;
  final int maxQty;
  final String footnote;
  final IconData footIcon;
  final ActionResult Function(GameProvider g, int qty) buy;
  final String successText;

  const _PurchaseSpec({
    required this.title,
    required this.name,
    required this.description,
    required this.art,
    required this.ownedLabel,
    required this.chips,
    required this.unitLabel,
    required this.unitName,
    required this.unitPrice,
    required this.buy,
    required this.successText,
    this.xp = false,
    this.allowQuantity = true,
    this.maxQty = 10,
    this.footnote = '',
    this.footIcon = Icons.local_shipping_outlined,
  });
}

Future<void> showSeedPurchaseSheet(BuildContext context, Flower f, {required bool bundle}) {
  final g = context.read<GameProvider>();
  return _show(
    context,
    _PurchaseSpec(
      title: bundle ? 'Buy Seed Bundle' : 'Buy Seed',
      name: bundle ? '${f.name} Bundle ×5' : '${f.name} Seed',
      description: f.blurb,
      art: SeedArt(asset: f.seedAsset, tint: f.tint, bundle: bundle, size: bundle ? 78 : 84),
      ownedLabel: 'Currently owned: x${g.seedCount(f.id)}',
      chips: [(Icons.auto_awesome_outlined, 'Rarity: ${f.rarity.label}'), (Icons.emoji_events_outlined, 'Harvest: +${f.harvestXp} XP')],
      unitLabel: 'PACKETS',
      unitName: bundle ? 'Bundle (5 seeds)' : 'Seed packet (1 seed)',
      unitPrice: bundle ? f.bundlePrice : f.seedPrice,
      footnote: 'Purchased seeds go straight to your Garden Inventory, ready to plant.',
      buy: (g, q) => g.buySeeds(f.id, q, bundle: bundle),
      successText: bundle ? '${f.name} bundle added' : '${f.name} seed added',
    ),
  );
}

Future<void> showToolPurchaseSheet(BuildContext context, ToolKind kind) {
  final t = ToolDef.of(kind);
  final g = context.read<GameProvider>();
  return _show(
    context,
    _PurchaseSpec(
      title: 'Buy ${t.name}',
      name: t.name,
      description: t.description,
      art: SizedBox(width: 84, height: 84, child: Image.asset(t.asset, fit: BoxFit.contain)),
      ownedLabel: kind == ToolKind.water ? 'Charges: ${g.ownedTool(kind)}' : 'Currently owned: x${g.ownedTool(kind)}',
      chips: [(Icons.bolt_rounded, 'Effect: ${t.effect}'), (Icons.check_circle_rounded, 'Usage: ${t.usage}')],
      unitLabel: 'UNITS',
      unitName: t.unit,
      unitPrice: t.price,
      maxQty: kind == ToolKind.water ? 3 : 10,
      footnote: 'Purchased ${t.name.toLowerCase()} will be deposited directly into your Garden Inventory ready to use.',
      buy: (g, q) => g.buyTool(kind, q),
      successText: '${t.name} added to inventory',
    ),
  );
}

Future<void> showBorderPurchaseSheet(BuildContext context, BorderDef b) {
  final badge = Badges.of(b.badgeId);
  final g = context.read<GameProvider>();
  return _show(
    context,
    _PurchaseSpec(
      title: 'Buy ${b.name}',
      name: b.name,
      description: '${b.description} Includes the “${badge.name}” badge.',
      art: AvatarWithBorder(avatarId: g.avatarId, borderId: b.id, size: 92),
      ownedLabel: 'Not Owned',
      chips: [(Icons.auto_awesome_outlined, 'Rarity: ${b.rarity}'), (Icons.military_tech_outlined, 'Badge: ${badge.name}')],
      unitLabel: 'PURCHASE TYPE',
      unitName: 'Permanent Unlock (1×)',
      unitPrice: b.priceXp,
      xp: true,
      allowQuantity: false,
      footnote: 'Earn XP by harvesting plants, verified uploads and achievements.',
      footIcon: Icons.school_outlined,
      buy: (g, _) => g.buyBorder(b.id),
      successText: '${b.name} equipped + ${badge.name} badge',
    ),
  );
}

Future<void> _show(BuildContext context, _PurchaseSpec spec) async {
  final ok = await showSfSheet<bool>(context: context, builder: (_) => _PurchaseBody(spec: spec));
  if (ok == true && context.mounted) {
    await _showSuccess(context, spec);
  }
}

class _PurchaseBody extends StatefulWidget {
  const _PurchaseBody({required this.spec});
  final _PurchaseSpec spec;
  @override
  State<_PurchaseBody> createState() => _PurchaseBodyState();
}

class _PurchaseBodyState extends State<_PurchaseBody> {
  int _qty = 1;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final c = context.sf;
    final s = widget.spec;
    final g = context.watch<GameProvider>();
    final balance = s.xp ? g.xp : g.coins;
    final total = s.unitPrice * _qty;
    final after = balance - total;
    final short = after < 0;
    final unit = s.xp ? 'XP' : 'Coins';
    Widget icon([double size = 18]) => s.xp ? XpIcon(size: size) : CoinIcon(size: size);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SheetHeader(title: s.title, icon: Icons.shopping_basket_outlined),
        const Divider(),
        const SizedBox(height: 12),
        // ---- item card
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: c.surfaceAlt.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: c.brandSoft),
          ),
          child: Column(children: [
            Align(alignment: Alignment.centerRight, child: StatusBadge(s.ownedLabel, icon: s.xp ? Icons.lock_outline_rounded : Icons.inventory_2_outlined, dense: true)),
            const SizedBox(height: 4),
            Container(
              constraints: const BoxConstraints(minWidth: 104),
              height: 104,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: c.brandSoft,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: c.accent.withValues(alpha: 0.4), width: 2),
              ),
              alignment: Alignment.center,
              child: s.art,
            ),
            const SizedBox(height: 10),
            Text(s.name, style: context.tt.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(s.description, style: context.tt.bodySmall, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 10),
            Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 6, children: [
              for (final (i, label) in s.chips) StatusBadge(label, icon: i, tone: Tone.neutral, dense: true),
            ]),
          ]),
        ),
        const SizedBox(height: 12),
        // ---- quantity / details
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: c.bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: c.line)),
          child: Column(children: [
            Row(children: [
              Expanded(child: Text(s.allowQuantity ? 'Select Quantity' : 'Item Details', style: context.tt.titleSmall)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: c.line, borderRadius: BorderRadius.circular(99)),
                child: Row(children: [
                  Text('Price: ', style: TextStyle(color: c.muted, fontSize: 12)),
                  icon(14),
                  const SizedBox(width: 4),
                  Text('${fmtNumber(s.unitPrice)} $unit', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                ]),
              ),
            ]),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
              decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.unitLabel, style: context.tt.labelSmall?.copyWith(color: c.muted)),
                    const SizedBox(height: 2),
                    Text(s.unitName, style: TextStyle(fontWeight: FontWeight.w700, color: c.brand)),
                  ]),
                ),
                if (s.allowQuantity) ...[
                  _StepBtn(icon: Icons.remove_rounded, onTap: _qty > 1 ? () => setState(() => _qty--) : null),
                  SizedBox(
                    width: 36,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
                      child: Text('$_qty', key: ValueKey(_qty), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                    ),
                  ),
                  _StepBtn(icon: Icons.add_rounded, primary: true, onTap: _qty < s.maxQty ? () => setState(() => _qty++) : null),
                ] else
                  const StatusBadge('Single Unlock', icon: Icons.check_rounded, tone: Tone.neutral, dense: true),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        // ---- totals
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: c.line)),
          child: Column(children: [
            _Row(label: 'Subtotal ($_qty×):', value: '${fmtNumber(total)} $unit', icon: icon()),
            const SizedBox(height: 8),
            _Row(label: 'Current Balance:', value: '${fmtNumber(balance)} $unit', icon: icon()),
            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: Text('Balance After Purchase:',
                    style: TextStyle(fontWeight: FontWeight.w700, color: short ? c.danger : c.ink, fontSize: 13.5)),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Container(
                  key: ValueKey(short),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: short ? c.dangerSoft : c.brandSoft,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: short ? c.danger.withValues(alpha: 0.5) : Colors.transparent),
                  ),
                  child: Row(children: [
                    Icon(short ? Icons.warning_amber_rounded : Icons.savings_outlined, size: 15, color: short ? c.danger : c.brand),
                    const SizedBox(width: 4),
                    Text(short ? 'Needed: ${fmtNumber(-after)} more $unit' : '${fmtNumber(after)} $unit',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: short ? c.danger : c.brand)),
                  ]),
                ),
              ),
            ]),
            if (short) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: c.dangerSoft, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.danger.withValues(alpha: 0.35))),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.error_outline_rounded, color: c.danger, size: 19),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.xp
                          ? 'You do not have enough XP to unlock this avatar border. Harvest plants and complete study goals to earn more XP.'
                          : 'You do not have enough coins. Upload verified modules and finish quizzes to earn more coins.',
                      style: TextStyle(color: c.danger, fontSize: 12.5, height: 1.35),
                    ),
                  ),
                ]),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: TextStyle(color: c.danger, fontWeight: FontWeight.w600)),
            ],
          ]),
        ),
        const SizedBox(height: 10),
        if (s.footnote.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(s.footIcon, size: 16, color: c.muted),
              const SizedBox(width: 8),
              Expanded(child: Text(s.footnote, style: context.tt.bodySmall)),
            ]),
          ),
        const SizedBox(height: 16),
        PrimaryButton(
          icon: short ? Icons.lock_outline_rounded : Icons.spa_rounded,
          label: short ? 'Insufficient $unit • ${fmtNumber(total)} $unit Needed' : 'Confirm Purchase • ${fmtNumber(total)} $unit',
          onTap: short
              ? null
              : () {
                  final r = s.buy(g, _qty);
                  if (r.ok) {
                    HapticFeedback.mediumImpact();
                    Navigator.pop(context, true);
                  } else {
                    HapticFeedback.heavyImpact();
                    setState(() => _error = r.message);
                  }
                },
        ),
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: TextStyle(color: c.muted))),
      ]),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final Widget icon;
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(child: Text(label, style: TextStyle(color: context.sf.muted, fontSize: 13.5))),
        icon,
        const SizedBox(width: 6),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      ]);
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({required this.icon, required this.onTap, this.primary = false});
  final IconData icon;
  final VoidCallback? onTap;
  final bool primary;
  @override
  Widget build(BuildContext context) {
    final c = context.sf;
    return Pressable(
      onTap: onTap,
      scale: 0.88,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: onTap == null ? c.line : (primary ? c.brand : c.brandSoft),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: onTap == null ? c.muted.withValues(alpha: 0.5) : (primary ? c.onBrand : c.brand)),
      ),
    );
  }
}

Future<void> _showSuccess(BuildContext context, _PurchaseSpec s) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'success',
    barrierColor: Colors.black45,
    transitionDuration: const Duration(milliseconds: 380),
    pageBuilder: (ctx, _, __) {
      final c = ctx.sf;
      return Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 300,
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 16),
            decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(26)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(color: c.brandSoft, shape: BoxShape.circle),
                child: Icon(Icons.check_rounded, size: 40, color: c.brand),
              ),
              const SizedBox(height: 14),
              Text('Purchase complete!', style: ctx.tt.titleLarge),
              const SizedBox(height: 4),
              Text(s.successText, style: ctx.tt.bodySmall, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              PrimaryButton(label: 'Nice!', height: 46, onTap: () => Navigator.pop(ctx)),
            ]),
          ),
        ),
      );
    },
    transitionBuilder: (_, a, __, child) => ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack), child: child),
  );
}
