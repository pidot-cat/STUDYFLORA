import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/shop_catalog.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/formatters.dart';
import '../../models/purchase_result.dart';
import '../../models/seed_item.dart';
import '../../models/tool_item.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/avatar_border_tile.dart';
import '../../widgets/coin_amount.dart';
import '../../widgets/pill.dart';
import '../../widgets/safe_asset_image.dart';
import '../../widgets/section_header.dart';

enum _ShopTab { seeds, tools, borders }

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  _ShopTab _tab = _ShopTab.seeds;

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _buySeed(SeedItem seed, {required bool bundle}) {
    final r = context.read<InventoryProvider>().buySeed(seed, bundle: bundle);
    _toast(r == PurchaseResult.success
        ? 'Bought ${bundle ? SeedItem.bundleSize : 1}× ${seed.name}'
        : 'Not enough coins.');
  }

  void _buyTool(ToolItem tool) {
    final r = context.read<InventoryProvider>().buyTool(tool);
    _toast(r == PurchaseResult.success ? 'Bought ${tool.name}' : 'Not enough coins.');
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        const _HeroCard(),
        const SizedBox(height: 16),
        _Tabs(
          selected: _tab,
          onChanged: (t) => setState(() => _tab = t),
        ),
        const SizedBox(height: 20),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: KeyedSubtree(key: ValueKey(_tab), child: _content()),
        ),
      ],
    );
  }

  Widget _content() {
    switch (_tab) {
      case _ShopTab.seeds:
        return Column(
          children: [
            const SectionHeader(
                title: 'Seed Packets & Bundles', trailing: 'COINS ONLY', leading: Icons.spa_outlined),
            const SizedBox(height: 12),
            for (final s in ShopCatalog.seeds) ...[
              _SeedCard(
                seed: s,
                onBuyOne: () => _buySeed(s, bundle: false),
                onBuyBundle: () => _buySeed(s, bundle: true),
              ),
              const SizedBox(height: 14),
            ],
          ],
        );
      case _ShopTab.tools:
        return Column(
          children: [
            const SectionHeader(
                title: 'Garden Tools', trailing: 'COINS ONLY', leading: Icons.build_outlined),
            const SizedBox(height: 12),
            for (final t in ShopCatalog.tools) ...[
              _ToolCard(tool: t, onBuy: () => _buyTool(t)),
              const SizedBox(height: 14),
            ],
          ],
        );
      case _ShopTab.borders:
        return Column(
          children: [
            const SectionHeader(
                title: 'Avatar Borders',
                trailing: 'XP ONLY',
                leading: Icons.emoji_events_outlined),
            const SizedBox(height: 12),
            for (final b in ShopCatalog.borders) ...[
              AvatarBorderTile(border: b),
              const SizedBox(height: 12),
            ],
          ],
        );
    }
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final user = context.watch<UserProvider>();
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text('FOCUS SANCTUARY\nBAZAAR',
                    style: TextStyle(
                        color: p.textMuted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        height: 1.5)),
              ),
              Pill(
                label: '${formatNumber(user.coins)} Coins',
                icon: Icons.monetization_on_outlined,
                background: p.warmSoft,
                foreground: p.warmText,
                borderColor: p.warmText.withAlpha(70),
              ),
              const SizedBox(width: 8),
              Pill(
                label: '${formatNumber(user.xp)} XP',
                icon: Icons.emoji_events_outlined,
                background: p.primarySoft,
                foreground: p.onPrimarySoft,
                borderColor: p.onPrimarySoft.withAlpha(70),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text('Botanical Supplies & Honors',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 10),
          Text(
            'Acquire seed packs and garden tools with Focus Coins, or exchange harvested Plant XP for exclusive avatar borders.',
            style: TextStyle(color: p.textMuted, fontSize: 15, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.selected, required this.onChanged});

  final _ShopTab selected;
  final ValueChanged<_ShopTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    const tabs = <(_ShopTab, String, IconData)>[
      (_ShopTab.seeds, 'Seeds', Icons.spa_outlined),
      (_ShopTab.tools, 'Tools', Icons.build_outlined),
      (_ShopTab.borders, 'Avatar Borders', Icons.emoji_events_outlined),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final t in tabs) ...[
            GestureDetector(
              onTap: () => onChanged(t.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                decoration: BoxDecoration(
                  color: selected == t.$1 ? p.primary : p.neutralChip,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                      color: selected == t.$1 ? p.primary : p.border),
                ),
                child: Row(
                  children: [
                    Icon(t.$3,
                        size: 18,
                        color: selected == t.$1 ? p.onPrimary : p.text),
                    const SizedBox(width: 7),
                    Text(t.$2,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: selected == t.$1 ? p.onPrimary : p.text)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}

class _SeedCard extends StatelessWidget {
  const _SeedCard({required this.seed, required this.onBuyOne, required this.onBuyBundle});

  final SeedItem seed;
  final VoidCallback onBuyOne;
  final VoidCallback onBuyBundle;

  Color _rarityColor(bool dark) => switch (seed.rarity) {
        SeedRarity.common => dark ? const Color(0xFF3DDC84) : const Color(0xFF2E6B50),
        SeedRarity.rareGlow => dark ? const Color(0xFF3A3F82) : const Color(0xFF2B5F5A),
        SeedRarity.vibrant => dark ? const Color(0xFF5A2430) : const Color(0xFF7A5430),
      };

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final badgeText = seed.rarity == SeedRarity.common && dark
        ? const Color(0xFF0B1F15)
        : Colors.white;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 82,
            height: 82,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SafeAssetImage(
                    path: seed.imageAsset,
                    fallbackIcon: Icons.spa_outlined,
                    fallbackBackground: p.primarySoft,
                    fallbackForeground: p.onPrimarySoft,
                    alignment: Alignment.topCenter,
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: _rarityColor(dark),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(seed.rarityLabel,
                        style: TextStyle(
                            color: badgeText,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(seed.name,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  '${seed.growthHours}h Growth • +${seed.borderXp} Border XP upon harvest',
                  style: TextStyle(color: p.textMuted, fontSize: 14, height: 1.35),
                ),
                const SizedBox(height: 12),
                _PriceButton(
                  onTap: onBuyOne,
                  background: p.neutralChip,
                  border: p.border,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('1 pc: ',
                          style: TextStyle(
                              color: p.textMuted,
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                      CoinAmount(amount: seed.unitPrice),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _PriceButton(
                  onTap: onBuyBundle,
                  background: p.primary,
                  border: p.primary,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 17, color: p.onPrimary),
                      const SizedBox(width: 6),
                      Text('Bundle (x${SeedItem.bundleSize}): ',
                          style: TextStyle(
                              color: p.onPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 14)),
                      CoinAmount(amount: seed.bundlePrice, color: p.onPrimary),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({required this.tool, required this.onBuy});

  final ToolItem tool;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final owned =
        context.select<InventoryProvider, int>((inv) => inv.count(tool.id));
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: p.primarySoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(tool.icon, size: 36, color: p.onPrimarySoft),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tool.name,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(tool.description,
                    style: TextStyle(color: p.textMuted, fontSize: 14, height: 1.35)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _PriceButton(
                      onTap: onBuy,
                      background: p.primary,
                      border: p.primary,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Buy: ',
                              style: TextStyle(
                                  color: p.onPrimary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14)),
                          CoinAmount(amount: tool.price, color: p.onPrimary),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('Owned: $owned',
                        style: TextStyle(
                            color: p.textMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceButton extends StatelessWidget {
  const _PriceButton({
    required this.child,
    required this.onTap,
    required this.background,
    required this.border,
  });

  final Widget child;
  final VoidCallback onTap;
  final Color background;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: StadiumBorder(side: BorderSide(color: border)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: child,
        ),
      ),
    );
  }
}
