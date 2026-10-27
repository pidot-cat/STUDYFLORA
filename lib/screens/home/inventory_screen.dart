import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../nav.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header.dart';
import '../../widgets/common.dart';
import '../garden/planting_screens.dart';

/// Opens Confirm Planting for the first empty pot.
void plantFromInventory(BuildContext context, String flowerId) {
  final s = context.read<AppState>();
  for (var pot = 1; pot <= GardenRules.potCount; pot++) {
    if (s.plantAt(pot) == null) {
      pushRoot(context, ConfirmPlantingScreen(pot: pot, flowerId: flowerId));
      return;
    }
  }
  showSnack(context, 'All 18 pots are in use. Harvest or shovel a plant first.');
}

/// Header row used by Inventory and All Seeds: back • title • coins • profile.
class _InvHeader extends StatelessWidget {
  final String title;
  const _InvHeader(this.title);
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Row(children: [
        const CircleBackButton(),
        const SizedBox(width: 24),
        Text(title, style: T.p(19, w: FontWeight.w600, c: c.heading)),
        const Spacer(),
        CoinPill(s.coins),
        const SizedBox(width: 10),
        const ProfileButton(),
      ]),
    );
  }
}

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  bool _tools = false;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = context.c;
    final seeds =
        s.ownedSeedIds.map(Flowers.byId).where((f) => f.name.toLowerCase().contains(_query.toLowerCase())).toList();
    final tools = ToolInfo.all
        .where((t) => s.toolCount(t.type) > 0 && t.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          const _InvHeader('Inventory'),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), children: [
              Text('Botanical Vault', style: T.p(25, w: FontWeight.w700, c: c.heading)),
              const SizedBox(height: 2),
              Text('Manage your flower seeds and garden supplies.', style: T.p(13, c: c.textMuted)),
              const SizedBox(height: 12),
              SFCard(
                padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                child: Row(children: [
                  IconTile(Icons.inventory_2_outlined,
                      size: 38, iconSize: 18, bg: c.isDark ? c.cardAlt : const Color(0xFFE6F2EA)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Storage Vault', style: T.p(13, w: FontWeight.w600, c: c.text)),
                      Text('Botanical inventory items', style: T.p(10.5, c: c.textMuted)),
                    ]),
                  ),
                  _vaultChip(context, 'Seeds', '${s.totalSeeds} Packets'),
                  const SizedBox(width: 6),
                  _vaultChip(context, 'Garden Tools', '${s.totalTools} Tools'),
                ]),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                        color: c.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: c.border)),
                    child: TextField(
                      onChanged: (v) => setState(() => _query = v),
                      style: T.p(13, c: c.text),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.search, size: 20, color: c.textMuted),
                        hintText: 'Search seeds or tools...',
                        hintStyle: T.p(13, c: c.textFaint),
                        contentPadding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                      color: c.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: c.border)),
                  child: Icon(Icons.filter_alt_outlined, size: 19, color: c.text),
                ),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                _tab('Seeds', !_tools, () => setState(() => _tools = false)),
                const SizedBox(width: 8),
                _tab('Garden Tools', _tools, () => setState(() => _tools = true)),
              ]),
              const SizedBox(height: 18),
              if (!_tools) ...[
                Row(children: [
                  Expanded(child: Text('Owned Seed Packets', style: T.p(14.5, w: FontWeight.w600, c: c.heading))),
                  InkWell(
                    onTap: () => pushTab(context, const AllSeedsScreen()),
                    child: Row(children: [
                      Text('See all seeds', style: T.p(12.5, c: c.textMuted)),
                      Icon(Icons.chevron_right, size: 18, color: c.textMuted),
                    ]),
                  ),
                ]),
                const SizedBox(height: 12),
                if (seeds.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('No seeds found.', style: T.p(13, c: c.textMuted))),
                  ),
                GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, mainAxisSpacing: 14, crossAxisSpacing: 12, mainAxisExtent: 164),
                  children: [
                    for (final f in seeds) _OwnedSeedCard(flower: f, count: s.seedCount(f.id)),
                  ],
                ),
                const SizedBox(height: 18),
                const InfoBanner(
                    'Plants grow in real-time over 6 hours while hydrated. Harvesting claims XP and frees the pot for replanting.'),
              ] else ...[
                Row(children: [
                  Expanded(child: Text('Owned Garden Tools', style: T.p(14.5, w: FontWeight.w600, c: c.heading))),
                  Text('Available', style: T.p(12.5, c: c.textMuted)),
                  const SizedBox(width: 16),
                ]),
                const SizedBox(height: 12),
                for (final t in tools) ...[
                  _ToolCard(info: t, count: s.toolCount(t.type)),
                  const SizedBox(height: 40),
                ],
                if (tools.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('No tools yet. Buy some in the Shop.', style: T.p(13, c: c.textMuted))),
                  ),
                const InfoBanner(
                    'Garden tools help you care for your 18 garden pots. Shoveling frees up pots, while fertilizer accelerates growth cycles.'),
              ],
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _vaultChip(BuildContext context, String label, String value) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.isDark ? c.mint : const Color(0xFFE7FBF0),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.isDark ? c.border : const Color(0xFFB9EBD0)),
      ),
      child: Column(children: [
        Text(label, style: T.p(9.5, c: c.textMuted)),
        Text(value, style: T.p(10.5, w: FontWeight.w700, c: c.mintText)),
      ]),
    );
  }

  Widget _tab(String label, bool active, VoidCallback onTap) {
    final c = context.c;
    return Material(
      color: active ? (c.isDark ? c.mintStrong : const Color(0xFF1B3A2E)) : c.card,
      shape: StadiumBorder(side: BorderSide(color: active ? Colors.transparent : c.border)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          child: Text(label,
              style: T.p(13, w: FontWeight.w600, c: active ? (c.isDark ? c.accent : Colors.white) : c.textMuted)),
        ),
      ),
    );
  }
}

class _OwnedSeedCard extends StatelessWidget {
  final Flower flower;
  final int count;
  const _OwnedSeedCard({required this.flower, required this.count});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SFCard(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      radius: 16,
      child: Column(children: [
        Align(alignment: Alignment.topRight, child: _CountBadge('x$count')),
        FlowerIcon(flower, size: 40, useEmoji: true),
        const SizedBox(height: 6),
        Text(flower.name, style: T.p(13, w: FontWeight.w600, c: c.text)),
        Text('6h Growth', style: T.p(11, c: c.textMuted)),
        const Spacer(),
        _SmallButton('Plant', onTap: () => plantFromInventory(context, flower.id)),
      ]),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final String text;
  const _CountBadge(this.text);
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration:
          BoxDecoration(color: c.isDark ? c.cardAlt : const Color(0xFFE8F1EB), borderRadius: BorderRadius.circular(10)),
      child: Text(text, style: T.p(10.5, w: FontWeight.w700, c: c.text)),
    );
  }
}

class _SmallButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool soft;
  const _SmallButton(this.label, {required this.onTap, this.soft = false});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SizedBox(
      width: double.infinity,
      height: 30,
      child: Material(
        color:
            soft ? (c.isDark ? c.mint : const Color(0xFFDDF3E5)) : (c.isDark ? c.mintStrong : const Color(0xFF1D5B42)),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Center(
            child: Text(label,
                style: T.p(12, w: FontWeight.w600, c: soft ? c.mintText : (c.isDark ? c.accent : Colors.white))),
          ),
        ),
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final ToolInfo info;
  final int count;
  const _ToolCard({required this.info, required this.count});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SFCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(info.asset, width: 56, height: 56, fit: BoxFit.cover),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(info.name, style: T.p(15, w: FontWeight.w700, c: c.text)),
              Text(info.subtitle, style: T.p(12, c: c.mintText)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: c.cardAlt, borderRadius: BorderRadius.circular(4), border: Border.all(color: c.border)),
                child: Text('Tool Count: $count', style: T.p(10.5, c: c.textMuted)),
              ),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
                color: c.isDark ? c.cardAlt : const Color(0xFFEEF2F7), borderRadius: BorderRadius.circular(12)),
            child: Text('x$count', style: T.p(12, w: FontWeight.w500, c: c.text)),
          ),
        ]),
        const SizedBox(height: 10),
        Divider(color: c.border, height: 1),
        const SizedBox(height: 10),
        Text(info.inventoryBlurb, style: T.p(12, c: c.textMuted, h: 1.5)),
      ]),
    );
  }
}

class AllSeedsScreen extends StatelessWidget {
  const AllSeedsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = context.c;
    final owned = Flowers.all.where((f) => s.seedCount(f.id) > 0).toList();
    final notOwned = Flowers.all.where((f) => s.seedCount(f.id) == 0).toList();
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          const _InvHeader('Inventory'),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), children: [
              Text('All Seeds', style: T.p(28, w: FontWeight.w700, c: c.heading)),
              const SizedBox(height: 6),
              Text('Discover all 12 flower types and grow your collection.', style: T.p(13.5, c: c.textMuted, h: 1.5)),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Pill('All Seeds',
                    bg: c.isDark ? c.mintStrong : const Color(0xFF1B3A2E),
                    fg: c.isDark ? c.accent : Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8)),
              ),
              const SizedBox(height: 22),
              GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12, mainAxisExtent: 196),
                children: [
                  for (final f in [...owned, ...notOwned]) _AllSeedCard(flower: f, count: s.seedCount(f.id)),
                ],
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _AllSeedCard extends StatelessWidget {
  final Flower flower;
  final int count;
  const _AllSeedCard({required this.flower, required this.count});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final owned = count > 0;
    return SFCard(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      radius: 16,
      child: Column(children: [
        Align(
          alignment: Alignment.topRight,
          child: owned
              ? _CountBadge('x$count')
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: c.isDark ? c.mint : const Color(0xFFE6F6EC), borderRadius: BorderRadius.circular(10)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.lock_open_outlined, size: 10, color: c.textMuted),
                    const SizedBox(width: 2),
                    Text('Not Owned', style: T.p(9.5, c: c.textMuted)),
                  ]),
                ),
        ),
        FlowerIcon(flower, size: 46),
        const SizedBox(height: 8),
        Text(flower.name, style: T.p(13, w: FontWeight.w700, c: c.heading)),
        const SizedBox(height: 2),
        Text(
            'Plant in an empty pot to grow a${'aeiou'.contains(flower.name[0].toLowerCase()) ? 'n' : ''} ${flower.name}.',
            textAlign: TextAlign.center,
            maxLines: 3,
            style: T.p(10, c: c.textFaint, h: 1.35)),
        const Spacer(),
        owned
            ? _SmallButton('Plant', onTap: () => plantFromInventory(context, flower.id))
            : _SmallButton('Get Seeds', soft: true, onTap: () => goTab(context, 3)),
      ]),
    );
  }
}
