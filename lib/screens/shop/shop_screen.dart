import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/cosmetics.dart';
import '../../models/flower.dart';
import '../../providers/game_provider.dart';
import '../../widgets/common.dart';
import '../../widgets/plant_widgets.dart';
import '../../widgets/profile_widgets.dart';
import 'purchase_sheet.dart';

/// Shop (FR-5.1, FR-5.2): Seeds (single / bundle of 5), Garden Tools, Borders.
/// Two-column grids keep the screen full and easy to scan.
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key, this.initialTab = 0});
  final int initialTab;
  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  late int _tab = widget.initialTab;
  bool _bundles = false;

  static const _subtitles = [
    'Plant seeds to grow flowers and earn XP.',
    'Tools to water, speed up and manage your garden.',
    'Frame your avatar — each border comes with a badge.',
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.sf;
    return SafeArea(
      bottom: false,
      child: Column(children: [
        const SfTopBar(),
        Expanded(
          child: CustomScrollView(slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Shop', style: context.tt.headlineMedium),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(_subtitles[_tab], key: ValueKey(_tab), style: context.tt.bodySmall),
                  ),
                  const SizedBox(height: 14),
                  _Segmented(
                    labels: const ['Seeds', 'Tools', 'Borders'],
                    icons: const [Icons.grass_rounded, Icons.handyman_outlined, Icons.blur_circular_rounded],
                    index: _tab,
                    onChanged: (i) => setState(() => _tab = i),
                  ),
                  if (_tab == 0) ...[
                    const SizedBox(height: 12),
                    Row(children: [
                      _SubPill(label: 'Single seed', selected: !_bundles, onTap: () => setState(() => _bundles = false)),
                      const SizedBox(width: 8),
                      _SubPill(label: 'Bundle ×5 · save 20%', selected: _bundles, onTap: () => setState(() => _bundles = true)),
                    ]),
                  ],
                  const SizedBox(height: 14),
                ]),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: switch (_tab) {
                0 => _grid([for (final f in Flower.all) _SeedCard(flower: f, bundle: _bundles)]),
                1 => _grid([for (final t in ToolDef.all) _ToolCard(tool: t)]),
                _ => _grid([for (final b in BorderDef.all) _BorderCard(border: b)], extent: 226),
              },
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Center(
                  child: Text(
                    _tab == 2 ? 'Borders are bought with XP.' : 'Seeds and tools are bought with coins.',
                    style: context.tt.bodySmall?.copyWith(color: c.muted),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  /// Fixed card height so cards stay compact on every screen width.
  Widget _grid(List<Widget> children, {double extent = 212}) => SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          mainAxisExtent: extent * MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.15),
        ),
        delegate: SliverChildListDelegate(children),
      );
}

class _Segmented extends StatelessWidget {
  const _Segmented({required this.labels, required this.icons, required this.index, required this.onChanged});
  final List<String> labels;
  final List<IconData> icons;
  final int index;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) {
    final c = context.sf;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.line)),
      child: Row(children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: Pressable(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                height: 42,
                decoration: BoxDecoration(color: i == index ? c.brand : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(icons[i], size: 17, color: i == index ? c.onBrand : c.muted),
                  const SizedBox(width: 6),
                  Text(labels[i], style: TextStyle(color: i == index ? c.onBrand : c.ink, fontWeight: FontWeight.w600, fontSize: 13.5)),
                ]),
              ),
            ),
          ),
      ]),
    );
  }
}

class _SubPill extends StatelessWidget {
  const _SubPill({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final c = context.sf;
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? c.brandSoft : c.surface,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: selected ? c.accent : c.line),
        ),
        child: Text(label, style: TextStyle(color: selected ? c.brand : c.muted, fontWeight: FontWeight.w700, fontSize: 12.5)),
      ),
    );
  }
}

/// Shared product card: art on top, name + detail, price + Buy at the bottom.
class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.art,
    required this.title,
    required this.detail,
    required this.priceLabel,
    required this.priceIcon,
    required this.action,
    required this.onTap,
    this.tag,
    this.actionEnabled = true,
  });
  final Widget art;
  final String title;
  final String detail;
  final String priceLabel;
  final Widget priceIcon;
  final String action;
  final VoidCallback onTap;
  final Widget? tag;
  final bool actionEnabled;

  @override
  Widget build(BuildContext context) {
    final c = context.sf;
    return SfCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Stack(children: [
            Center(child: art),
            if (tag != null) Positioned(left: 0, top: 0, child: tag!),
          ]),
        ),
        const SizedBox(height: 8),
        Text(title, style: context.tt.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(detail, style: context.tt.bodySmall?.copyWith(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 8),
        Row(children: [
          priceIcon,
          const SizedBox(width: 4),
          Expanded(
            child: Text(priceLabel,
                maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: c.ink)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: actionEnabled ? c.brand : c.brandSoft, borderRadius: BorderRadius.circular(99)),
            child: Text(action, style: TextStyle(color: actionEnabled ? c.onBrand : c.brand, fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ]),
      ]),
    );
  }
}

class _SeedCard extends StatelessWidget {
  const _SeedCard({required this.flower, required this.bundle});
  final Flower flower;
  final bool bundle;
  @override
  Widget build(BuildContext context) {
    final owned = context.select<GameProvider, int>((g) => g.seedCount(flower.id));
    return _ProductCard(
      art: SeedArt(asset: flower.seedAsset, tint: flower.tint, bundle: bundle, size: bundle ? 80 : 82),
      title: bundle ? '${flower.name} ×5' : flower.name,
      detail: '${flower.rarity.label} • +${flower.harvestXp} XP${owned > 0 ? ' • own $owned' : ''}',
      priceLabel: '${bundle ? flower.bundlePrice : flower.seedPrice}',
      priceIcon: const CoinIcon(size: 16),
      action: 'Buy',
      onTap: () => showSeedPurchaseSheet(context, flower, bundle: bundle),
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({required this.tool});
  final ToolDef tool;
  @override
  Widget build(BuildContext context) {
    final g = context.watch<GameProvider>();
    final owned = g.ownedTool(tool.kind);
    return _ProductCard(
      // Whole tool always visible: contained inside a soft tile (no cropping).
      art: Container(
        width: 88,
        height: 88,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: context.sf.brandSoft.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(22)),
        child: Image.asset(tool.asset, fit: BoxFit.contain),
      ),
      title: tool.name,
      detail: '${tool.effect} • ${tool.kind == ToolKind.water ? '$owned charges' : 'own $owned'}',
      priceLabel: '${tool.price}',
      priceIcon: const CoinIcon(size: 16),
      action: 'Buy',
      onTap: () => showToolPurchaseSheet(context, tool.kind),
    );
  }
}

class _BorderCard extends StatelessWidget {
  const _BorderCard({required this.border});
  final BorderDef border;
  @override
  Widget build(BuildContext context) {
    final g = context.watch<GameProvider>();
    final c = context.sf;
    final b = border;
    final owned = g.ownedBorders.contains(b.id);
    final equipped = g.equippedBorder == b.id;
    final badge = Badges.of(b.badgeId);
    return _ProductCard(
      art: AvatarWithBorder(avatarId: g.avatarId, borderId: b.id, size: 92),
      tag: StatusBadge(b.rarity, tone: b.priceXp >= 1000 ? Tone.gold : (b.priceXp >= 800 ? Tone.terracotta : Tone.neutral), dense: true),
      title: b.name,
      detail: '+ ${badge.name} badge',
      priceLabel: b.isFree ? 'Free' : '${b.priceXp}',
      priceIcon: b.isFree ? Icon(Icons.redeem_rounded, size: 16, color: c.accent) : const XpIcon(size: 16),
      action: equipped ? 'Equipped' : (owned ? 'Equip' : 'Buy'),
      actionEnabled: !equipped,
      onTap: () {
        if (equipped) return;
        if (owned) {
          g.equipBorder(b.id);
          showToast(context, '${b.name} equipped');
        } else {
          showBorderPurchaseSheet(context, b);
        }
      },
    );
  }
}
