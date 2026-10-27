import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header.dart';
import '../../widgets/common.dart';
import '../../widgets/visuals.dart';
import 'purchase_sheets.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});
  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  int _tab = 0; // 0 seeds, 1 tools, 2 borders
  bool _bundles = false;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.isDark ? c.bg : const Color(0xFFEEF5F0),
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          const AppHeader(showXp: true),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(16, 6, 16, 24), children: [
              const _ShopHero(),
              const SizedBox(height: 12),
              _Tabs(index: _tab, onTap: (i) => setState(() => _tab = i)),
              const SizedBox(height: 14),
              if (_tab == 0) ...[
                Row(children: [
                  _seg('Single Seeds', !_bundles, () => setState(() => _bundles = false)),
                  const SizedBox(width: 10),
                  _seg('Bundles', _bundles, () => setState(() => _bundles = true)),
                ]),
                const SizedBox(height: 18),
                for (final f in Flowers.all) ...[
                  _SeedRow(flower: f, bundle: _bundles),
                  const SizedBox(height: 12),
                ],
              ] else if (_tab == 1) ...[
                const SizedBox(height: 12),
                for (final t in ToolInfo.all) ...[
                  _ToolRow(info: t),
                  const SizedBox(height: 20),
                ],
              ] else ...[
                for (final b in BorderOption.all) ...[
                  _BorderRow(border: b),
                  const SizedBox(height: 12),
                ],
              ],
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _seg(String label, bool active, VoidCallback onTap) {
    final c = context.c;
    return Material(
      color:
          active ? (c.isDark ? c.mintStrong : const Color(0xFF1F6B45)) : (c.isDark ? Colors.transparent : Colors.white),
      shape: StadiumBorder(side: BorderSide(color: active ? Colors.transparent : c.border)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Container(
          width: c.isDark ? null : 110,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          alignment: Alignment.center,
          child: Text(label,
              style: T.p(12.5, w: FontWeight.w500, c: active ? (c.isDark ? c.text : Colors.white) : c.textMuted)),
        ),
      ),
    );
  }
}

class _ShopHero extends StatelessWidget {
  const _ShopHero();
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        gradient: c.isDark
            ? const LinearGradient(colors: [Color(0xFF10231B), Color(0xFF143326)])
            : const LinearGradient(
                colors: [Color(0xFFE4F6EA), Color(0xFFF8FCF9)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.isDark ? c.border : const Color(0xFFCDEBD8)),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Pill('SHOP',
                fontSize: 10.5,
                bg: c.isDark ? c.mint : const Color(0xFFD7EDDF),
                fg: c.isDark ? c.accent : const Color(0xFF3F5E50),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2)),
            const SizedBox(height: 8),
            Text('Grow Your Garden!',
                style: T.p(19, w: FontWeight.w600, c: c.isDark ? c.text : const Color(0xFF1B4D3E))),
            const SizedBox(height: 4),
            Text('Buy seeds, tools, and avatar borders with Coins or XP. Build your garden and make it bloom!',
                style: T.p(12, c: c.textMuted, h: 1.4)),
          ]),
        ),
        const SizedBox(width: 12),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(color: c.isDark ? c.cardAlt : const Color(0xFFCDEFD9), shape: BoxShape.circle),
          child: Stack(alignment: Alignment.center, children: [
            Positioned(top: 10, child: Icon(Icons.spa, size: 22, color: c.isDark ? c.accent : const Color(0xFF2E9E64))),
            Positioned(bottom: 12, child: SizedBox(width: 24, height: 20, child: CustomPaint(painter: PotPainter()))),
          ]),
        ),
      ]),
    );
  }
}

class _Tabs extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const _Tabs({required this.index, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final labels = [
      (Icons.eco_outlined, 'Seeds'),
      (Icons.edit_outlined, index == 0 ? 'Tools' : 'Garden Tools'),
      (Icons.radio_button_checked, 'Borders'),
    ];
    return Container(
      padding: c.isDark ? const EdgeInsets.all(6) : EdgeInsets.zero,
      decoration: c.isDark
          ? BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.border))
          : null,
      child: Row(children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Material(
              color: i == index
                  ? (c.isDark ? c.mintStrong : const Color(0xFF1B4D3E))
                  : (c.isDark ? Colors.transparent : Colors.white),
              borderRadius: BorderRadius.circular(12),
              elevation: i == index || c.isDark ? 0 : 1,
              shadowColor: c.shadow,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onTap(i),
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: i == index || c.isDark ? Colors.transparent : c.border),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(labels[i].$1,
                        size: 14, color: i == index ? (c.isDark ? c.accent : Colors.white) : c.textMuted),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(labels[i].$2,
                          overflow: TextOverflow.ellipsis,
                          style: T.p(13,
                              w: i == index ? FontWeight.w600 : FontWeight.w400,
                              c: i == index ? (c.isDark ? c.text : Colors.white) : c.text)),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ],
      ]),
    );
  }
}

class _BuyButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool big;
  const _BuyButton({this.label = 'Buy', this.onTap, this.big = false});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: c.isDark ? Colors.transparent : const Color(0xFF1B5E44),
      shape: big
          ? const StadiumBorder()
          : RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(c.isDark ? 10 : 20),
              side: c.isDark ? const BorderSide(color: Color(0xFF2B6B53)) : BorderSide.none),
      child: InkWell(
        customBorder: big ? const StadiumBorder() : RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: big ? 22 : 16, vertical: big ? 11 : 7),
          child: Text(label, style: T.p(big ? 15 : 13, w: FontWeight.w600, c: c.isDark ? c.accent : Colors.white)),
        ),
      ),
    );
  }
}

class _SeedRow extends StatelessWidget {
  final Flower flower;
  final bool bundle;
  const _SeedRow({required this.flower, required this.bundle});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final price = bundle ? AppState.bundlePrice : AppState.seedPrice;
    return SFCard(
      radius: 16,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      onTap: () => showSeedPurchase(context, flower, bundle),
      child: Row(children: [
        FlowerIcon(flower, size: c.isDark ? 40 : 48),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(
                child: Text('${flower.name} Seed',
                    overflow: TextOverflow.ellipsis, style: T.p(14.5, w: FontWeight.w600, c: c.text)),
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right, size: 16, color: c.textMuted),
              const SizedBox(width: 8),
              Pill(bundle ? 'x5' : 'x1',
                  fontSize: 10.5,
                  bg: c.isDark ? Colors.transparent : const Color(0xFFD7F5E2),
                  borderColor: c.isDark ? c.border : null,
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1)),
            ]),
            Text(flower.shopBlurb, style: T.p(11.5, c: c.textMuted, h: 1.35)),
            const SizedBox(height: 2),
            Row(children: [
              const CoinGlyph(size: 14),
              const SizedBox(width: 5),
              Text('$price', style: T.p(13, w: FontWeight.w700, c: c.isDark ? c.coin : c.text)),
            ]),
          ]),
        ),
        const SizedBox(width: 8),
        _BuyButton(onTap: () => showSeedPurchase(context, flower, bundle)),
      ]),
    );
  }
}

class _ToolRow extends StatelessWidget {
  final ToolInfo info;
  const _ToolRow({required this.info});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SFCard(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      onTap: () => showToolPurchase(context, info),
      child: Row(children: [
        Container(
          width: 64,
          height: 64,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFCDEBD8), width: 2)),
          child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.asset(info.asset, fit: BoxFit.cover)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(info.name, style: T.p(16.5, w: FontWeight.w600, c: c.text)),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right, size: 18, color: c.textMuted),
            ]),
            Text(info.shopBlurb, style: T.p(11, c: c.textMuted, h: 1.35)),
            const SizedBox(height: 6),
            Row(children: [
              const CoinGlyph(size: 16),
              const SizedBox(width: 6),
              Text('${info.price} Coins', style: T.p(13, w: FontWeight.w600, c: c.text)),
            ]),
          ]),
        ),
        const SizedBox(width: 10),
        _BuyButton(big: true, onTap: () => showToolPurchase(context, info)),
      ]),
    );
  }
}

class _BorderRow extends StatelessWidget {
  final BorderOption border;
  const _BorderRow({required this.border});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final s = context.watch<AppState>();
    final b = border;
    final owned = s.ownedBorders.contains(b.id);
    final equipped = s.borderId == b.id;
    final rarityColor =
        b.rarity == 'Rare' ? const Color(0xFF3EA06A) : (b.rarity == 'Epic' ? const Color(0xFFC0904A) : c.textMuted);
    return SFCard(
      radius: 16,
      padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
      onTap: owned ? null : () => showBorderPurchase(context, b),
      child: Row(children: [
        BorderSwatch(b.kind, size: 60),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(b.name, style: T.p(14.5, w: FontWeight.w600, c: c.text)),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right, size: 16, color: c.textMuted),
            ]),
            Row(children: [
              b.rarity == 'Basic'
                  ? Icon(Icons.crop_square, size: 13, color: c.textMuted)
                  : Container(
                      width: 8, height: 8, decoration: BoxDecoration(color: rarityColor, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(b.rarity,
                  style: T.p(11.5, w: b.rarity == 'Basic' ? FontWeight.w400 : FontWeight.w600, c: rarityColor)),
            ]),
            const SizedBox(height: 2),
            b.xpCost == 0
                ? Text('Free', style: T.p(12.5, w: FontWeight.w700, c: const Color(0xFF15924F)))
                : Row(children: [
                    const XpGlyph(size: 16),
                    const SizedBox(width: 6),
                    Text('${b.xpCost}', style: T.p(12.5, w: FontWeight.w700, c: c.text)),
                  ]),
          ]),
        ),
        if (equipped)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: c.isDark ? c.cardAlt : const Color(0xFFE5ECE8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFCBD8D0)),
            ),
            child: Row(children: [
              Icon(Icons.check, size: 13, color: c.heading),
              const SizedBox(width: 6),
              Text('Equipped', style: T.p(12.5, w: FontWeight.w600, c: c.heading)),
            ]),
          )
        else if (owned)
          _BuyButton(
              label: 'Equip',
              onTap: () {
                s.equipBorder(b.id);
                showSnack(context, '${b.name} equipped.');
              })
        else
          _BuyButton(onTap: () => showBorderPurchase(context, b)),
      ]),
    );
  }
}
