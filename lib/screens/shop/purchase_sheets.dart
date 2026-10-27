import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../nav.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/visuals.dart';

Future<T?> _sheet<T>(BuildContext context, Widget child) => showModalBottomSheet<T>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x8899C2AA),
      builder: (_) => BackdropFilter(filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3), child: child),
    );

void showSeedPurchase(BuildContext context, Flower f, bool bundle) =>
    _sheet(context, _PurchaseSheet(flower: f, bundle: bundle));

void showToolPurchase(BuildContext context, ToolInfo t) => _sheet(context, _PurchaseSheet(tool: t));

void showBorderPurchase(BuildContext context, BorderOption b) => _sheet(context, _BorderSheet(border: b));

class _SheetFrame extends StatelessWidget {
  final Widget child;
  const _SheetFrame({required this.child});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * .9),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 10),
          Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(color: const Color(0xFFD9DDE2), borderRadius: BorderRadius.circular(3))),
          Flexible(child: child),
        ]),
      ),
    );
  }
}

Widget _sheetHeader(BuildContext context, String title) {
  final c = context.c;
  return Padding(
    padding: const EdgeInsets.fromLTRB(20, 14, 16, 12),
    child: Row(children: [
      Icon(Icons.shopping_basket_outlined, size: 22, color: c.heading),
      const SizedBox(width: 10),
      Expanded(child: Text(title, style: T.p(18, w: FontWeight.w600, c: c.heading))),
      _CloseButton(onTap: () => Navigator.of(context).pop()),
    ]),
  );
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CloseButton({required this.onTap});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: c.isDark ? c.cardAlt : const Color(0xFFEEF0F2),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 34, height: 34, child: Icon(Icons.close, size: 18, color: c.textMuted)),
      ),
    );
  }
}

/// Seed (single / bundle) and garden tool purchase.
class _PurchaseSheet extends StatefulWidget {
  final Flower? flower;
  final bool bundle;
  final ToolInfo? tool;
  const _PurchaseSheet({this.flower, this.bundle = false, this.tool});
  @override
  State<_PurchaseSheet> createState() => _PurchaseSheetState();
}

class _PurchaseSheetState extends State<_PurchaseSheet> {
  int _qty = 1;

  bool get _isTool => widget.tool != null;
  int get _unit => _isTool ? widget.tool!.price : (widget.bundle ? AppState.bundlePrice : AppState.seedPrice);

  void _confirm() {
    final s = context.read<AppState>();
    final before = s.coins;
    final ok =
        _isTool ? s.buyTool(widget.tool!.type, _qty) : s.buySeeds(widget.flower!.id, bundle: widget.bundle, qty: _qty);
    if (!ok) {
      showSnack(context, 'Not enough coins. Complete quizzes to earn more!');
      return;
    }
    final rootCtx = Navigator.of(context, rootNavigator: true).context;
    Navigator.of(context).pop();
    _sheet(
      rootCtx,
      _SuccessSheet(
        flower: widget.flower,
        tool: widget.tool,
        bundle: widget.bundle,
        qty: _qty,
        spent: before - s.coins,
        before: before,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final s = context.watch<AppState>();
    final f = widget.flower;
    final t = widget.tool;
    final owned = _isTool ? s.toolCount(t!.type) : s.seedCount(f!.id);
    final total = _unit * _qty;
    final after = s.coins - total;
    final title = _isTool ? 'Buy ${t!.name}' : (widget.bundle ? 'Buy ${f!.name} Seed Bundle' : 'Buy ${f!.name} Seed');
    final itemName = _isTool ? t!.name : (widget.bundle ? '${f!.name} Seed Bundle (x5)' : '${f!.name} Seed');
    final blurb =
        _isTool ? t!.shopBlurb : 'Nurture your garden with ${f!.shopBlurb.toLowerCase().replaceAll('.', '')}.';
    return _SheetFrame(
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _sheetHeader(context, title),
          Divider(height: 1, color: c.border),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                decoration: BoxDecoration(
                  gradient: c.isDark
                      ? null
                      : const LinearGradient(
                          colors: [Color(0xFFEAF7EE), Color(0xFFF8FCF9)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter),
                  color: c.isDark ? c.cardAlt : null,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: c.border),
                ),
                child: Column(children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: Pill('Currently owned: x$owned',
                        icon: Icons.inventory_2_outlined,
                        fontSize: 11,
                        bg: c.isDark ? c.mint : const Color(0xFFCDEFD9),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2)),
                  ),
                  if (_isTool)
                    Container(
                      width: 80,
                      height: 80,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                          color: const Color(0xFFCDEFD9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFA7E3BD))),
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(12), child: Image.asset(t!.asset, fit: BoxFit.cover)),
                    )
                  else
                    Container(
                      width: 80,
                      height: 80,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                          shape: BoxShape.circle, border: Border.all(color: const Color(0xFFF5E1A4), width: 2)),
                      child: FlowerIcon(f!, size: 72),
                    ),
                  const SizedBox(height: 10),
                  Text(itemName, style: T.p(17, w: FontWeight.w600, c: c.heading)),
                  const SizedBox(height: 4),
                  Text(blurb, textAlign: TextAlign.center, style: T.p(12.5, c: c.text, h: 1.4)),
                  const SizedBox(height: 10),
                  Divider(height: 1, color: c.border),
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, alignment: WrapAlignment.center, children: [
                    Pill(
                        _isTool
                            ? 'Effect: ${t!.type == ToolType.fertilizer ? '2× Growth Speed' : (t.type == ToolType.wateringCan ? '+1 Water Charge' : 'Frees 1 Pot')}'
                            : 'Bloom Time: 6h',
                        icon: _isTool ? Icons.bolt : Icons.hourglass_bottom,
                        fontSize: 11,
                        bg: c.isDark ? c.card : const Color(0xFFF0F2F0),
                        fg: c.text,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                    Pill(
                        _isTool
                            ? 'Usage: ${t!.type == ToolType.fertilizer ? '1 Use / Plant' : '1 Use'}'
                            : 'Rewards: +${widget.bundle ? f!.rewardXp * 5 : f!.rewardXp} XP',
                        icon: _isTool ? Icons.check_circle : Icons.auto_awesome,
                        fontSize: 11,
                        bg: c.isDark ? c.mint : const Color(0xFFD7F5E2),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                  ]),
                ]),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: c.isDark ? c.cardAlt : const Color(0xFFF3F4F3),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: c.border)),
                child: Column(children: [
                  Row(children: [
                    Text('Select Quantity', style: T.p(14, w: FontWeight.w600, c: c.text)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: c.isDark ? c.card : const Color(0xFFE7E9E8),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: c.border)),
                      child: Row(children: [
                        Text('Price: ', style: T.p(12, c: c.textMuted)),
                        const CoinGlyph(size: 13),
                        const SizedBox(width: 4),
                        Text(_isTool ? '$_unit Coins' : '$_unit / ${widget.bundle ? 'bundle' : 'seed'}',
                            style: T.p(12, w: FontWeight.w600, c: c.text)),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                    decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(14)),
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('UNITS', style: T.p(10, w: FontWeight.w500, c: c.textMuted, ls: .4)),
                          Text(
                              _isTool
                                  ? (t!.type == ToolType.fertilizer ? 'Fertilizer (Bottle)' : '${t.name} (Unit)')
                                  : (widget.bundle ? 'Bundle (x5 Seeds)' : 'Single Planting'),
                              style: T.p(12.5, w: FontWeight.w600, c: c.heading)),
                        ]),
                      ),
                      _stepBtn(Icons.remove, _qty > 1 ? () => setState(() => _qty--) : null, false),
                      SizedBox(
                          width: 40,
                          child: Center(child: Text('$_qty', style: T.p(18, w: FontWeight.w500, c: c.text)))),
                      _stepBtn(
                          Icons.add, (s.coins - _unit * (_qty + 1)) >= 0 ? () => setState(() => _qty++) : null, true),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: c.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: c.border)),
                child: Column(children: [
                  _sumRow(context, 'Subtotal (${_qty}x):', '$total Coins'),
                  const SizedBox(height: 10),
                  _sumRow(context, 'Current Balance:', '${s.coins} Coins'),
                  const SizedBox(height: 10),
                  Divider(height: 1, color: c.border),
                  const SizedBox(height: 10),
                  Row(children: [
                    Text('Balance After Purchase:',
                        style: T.p(12.5, w: FontWeight.w600, c: after < 0 ? c.danger : c.heading)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                          color: after < 0 ? c.dangerBg : const Color(0xFFD7F5E2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: after < 0 ? c.dangerBorder : const Color(0xFFA7E3BD))),
                      child: Row(children: [
                        Icon(Icons.savings_outlined, size: 13, color: after < 0 ? c.danger : const Color(0xFF15803D)),
                        const SizedBox(width: 4),
                        Text(after < 0 ? 'Need ${-after} more' : '$after Coins',
                            style: T.p(12, w: FontWeight.w500, c: after < 0 ? c.danger : const Color(0xFF15803D))),
                      ]),
                    ),
                  ]),
                ]),
              ),
              const SizedBox(height: 16),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.local_shipping_outlined, size: 16, color: c.mintText),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                      _isTool
                          ? 'Purchased ${t!.name.toLowerCase()} will be deposited directly into your Garden Inventory ready to use.'
                          : 'Purchased seeds will be deposited directly into your Inventory ready to plant.',
                      style: T.p(11.5, c: c.textMuted, h: 1.4)),
                ),
              ]),
            ]),
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: c.border),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: PrimaryButton('Confirm Purchase • $total Coins',
                icon: Icons.spa,
                radius: 30,
                color: c.isDark ? c.primary : const Color(0xFF1B4D3E),
                onTap: after < 0 ? null : _confirm),
          ),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: T.p(13, c: c.textMuted)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback? onTap, bool primary) {
    final c = context.c;
    return Material(
      color: primary ? const Color(0xFF9EEDBF) : (c.isDark ? c.cardAlt : const Color(0xFFF0F1F2)),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
            width: 32,
            height: 32,
            child: Icon(icon,
                size: 18, color: onTap == null ? c.textFaint : (primary ? const Color(0xFF14532D) : c.textMuted))),
      ),
    );
  }
}

Widget _sumRow(BuildContext context, String label, String value) {
  final c = context.c;
  return Row(children: [
    Text(label, style: T.p(13, c: c.text)),
    const Spacer(),
    const CoinGlyph(size: 14),
    const SizedBox(width: 6),
    Text(value, style: T.p(13, w: FontWeight.w600, c: c.text)),
  ]);
}

class _SuccessSheet extends StatelessWidget {
  final Flower? flower;
  final ToolInfo? tool;
  final bool bundle;
  final int qty;
  final int spent;
  final int before;
  const _SuccessSheet(
      {this.flower, this.tool, required this.bundle, required this.qty, required this.spent, required this.before});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final s = context.watch<AppState>();
    final isTool = tool != null;
    final added = isTool ? qty : (bundle ? 5 * qty : qty);
    final inv = isTool ? s.toolCount(tool!.type) : s.seedCount(flower!.id);
    final title = isTool
        ? '${tool!.name} Acquired!'
        : (bundle ? '${flower!.name} Seeds (x$added) Acquired!' : '${flower!.name} Seed Acquired!');
    final body = isTool
        ? '${tool!.name} has been added to your Garden Inventory and is ready to use.'
        : (bundle
            ? '$added ${flower!.name} Seeds have been added to your Garden Inventory and are ready to plant.'
            : 'Your ${flower!.name} Seed has been added to your Inventory and is ready to plant.');
    final itemTitle = isTool
        ? (tool!.type == ToolType.fertilizer ? 'Growth Fertilizer' : tool!.name)
        : (bundle ? '${flower!.name} Seed Bundle (5×)' : '${flower!.name} Seed');
    final unit = isTool
        ? (tool!.type == ToolType.fertilizer ? (inv == 1 ? 'Bottle' : 'Bottles') : (inv == 1 ? 'Unit' : 'Units'))
        : (inv == 1 ? 'Seed' : 'Seeds');
    final tag = isTool ? 'Special Care' : (bundle ? 'Value Bundle' : 'Standard Pack');
    return _SheetFrame(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Column(children: [
          Stack(children: [
            const Positioned(left: 0, top: 20, child: Icon(Icons.eco, size: 18, color: Color(0xFF86D9A5))),
            const Positioned(left: 0, top: 90, child: Icon(Icons.blur_circular, size: 12, color: Color(0xFFB7E4C7))),
            const Positioned(right: 4, top: 90, child: Icon(Icons.spa, size: 14, color: Color(0xFF9BE3B7))),
            Positioned(right: 0, top: 0, child: _CloseButton(onTap: () => Navigator.of(context).pop())),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 18),
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(clipBehavior: Clip.none, children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c.card,
                        border: Border.all(color: const Color(0xFFDDF5E6), width: 3),
                        boxShadow: [BoxShadow(color: const Color(0xFFFFC98A).withValues(alpha: .5), blurRadius: 18)],
                      ),
                      alignment: Alignment.center,
                      child: isTool
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset(tool!.asset, width: 52, height: 52))
                          : FlowerIcon(flower!, size: 70),
                    ),
                    if (bundle || isTool)
                      Positioned(
                        right: 6,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                              color: isTool ? const Color(0xFF1F6B45) : const Color(0xFF3B2A12),
                              borderRadius: BorderRadius.circular(8)),
                          child:
                              Text(isTool ? '+$added' : 'x$added', style: T.p(10, w: FontWeight.w600, c: Colors.white)),
                        ),
                      ),
                    Positioned(
                      right: 2,
                      bottom: 4,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                            color: const Color(0xFF1B4D3E),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2)),
                        child: const Icon(Icons.check, size: 17, color: Colors.white),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          Pill('PURCHASE SUCCESSFUL',
              icon: Icons.verified,
              fontSize: 11.5,
              bg: c.isDark ? c.mint : const Color(0xFFDDF5E6),
              borderColor: const Color(0xFFA7E3BD),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
          const SizedBox(height: 8),
          Text(title, textAlign: TextAlign.center, style: T.serif(23, c: c.heading)),
          const SizedBox(height: 8),
          Text(body, textAlign: TextAlign.center, style: T.p(12.5, c: c.text, h: 1.5)),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: c.isDark ? c.cardAlt : const Color(0xFFF3F4F3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.border)),
            child: Row(children: [
              Stack(clipBehavior: Clip.none, children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                      color: isTool || bundle ? const Color(0xFFA7EBC3) : const Color(0xFFE4F3E2),
                      borderRadius: BorderRadius.circular(12)),
                  child: isTool
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12), child: Image.asset(tool!.asset, fit: BoxFit.cover))
                      : Icon(bundle ? Icons.spa : Icons.wb_sunny,
                          color: bundle ? const Color(0xFF14532D) : const Color(0xFFF59E0B), size: 28),
                ),
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(color: const Color(0xFF1B4D3E), borderRadius: BorderRadius.circular(8)),
                    child: Text('x${isTool ? qty : added}', style: T.p(9.5, w: FontWeight.w600, c: Colors.white)),
                  ),
                ),
              ]),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(itemTitle, style: T.p(15, w: FontWeight.w500, c: c.text)),
                  Row(children: [
                    Icon(isTool ? Icons.bolt : Icons.schedule, size: 13, color: c.mintText),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                          isTool
                              ? (tool!.type == ToolType.fertilizer ? '2× Growth Speed' : 'Garden Tool')
                              : 'Bloom: 6h',
                          style: T.p(11, c: c.textMuted)),
                    ),
                    const SizedBox(width: 6),
                    Container(
                        width: 4, height: 4, decoration: BoxDecoration(color: c.textFaint, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Icon(isTool ? Icons.eco : Icons.spa, size: 12, color: c.mintText),
                    const SizedBox(width: 3),
                    Text(
                        isTool
                            ? (tool!.type == ToolType.fertilizer ? '1 Use / Plant' : '1 Use')
                            : '+${flower!.rewardXp * added} XP',
                        style: T.p(11, w: FontWeight.w500, c: c.mintText)),
                  ]),
                ]),
              ),
              Column(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: const Color(0xFFFFF4DC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFF7DB8A))),
                  child: Row(children: [
                    const CoinGlyph(size: 13),
                    const SizedBox(width: 4),
                    Text('-$spent', style: T.p(12.5, w: FontWeight.w600, c: const Color(0xFF3B2A12))),
                  ]),
                ),
                const SizedBox(height: 4),
                Text(tag, style: T.p(10, c: c.textMuted)),
              ]),
            ]),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: _miniStat(context, Icons.savings, const Color(0xFFFFF0E0), const Color(0xFF7C3A12), 'NEW BALANCE',
                  '${s.coins}', 'Coins', 'was $before',
                  strike: true),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _miniStat(context, Icons.inventory_2, const Color(0xFFD7F5E2), const Color(0xFF15803D),
                  'INVENTORY', '$inv $unit', '', '+$added Added',
                  green: true),
            ),
          ]),
          const SizedBox(height: 18),
          PrimaryButton(isTool ? 'Go to Garden & Use' : 'Go to Garden & Plant',
              icon: Icons.yard_outlined,
              height: 46,
              color: c.isDark ? c.primary : const Color(0xFF1B4D3E),
              onTap: () => goTab(context, 1)),
          const SizedBox(height: 10),
          OutlineButtonSF('Continue Shopping',
              icon: Icons.storefront_outlined,
              height: 42,
              bg: c.isDark ? c.cardAlt : const Color(0xFFF1F3F1),
              fontSize: 13,
              onTap: () => Navigator.of(context).pop()),
          if (isTool) ...[
            const SizedBox(height: 12),
            Text('Items are synced with your study cloud garden automatically.', style: T.p(11, c: c.textMuted)),
          ],
        ]),
      ),
    );
  }

  Widget _miniStat(
      BuildContext context, IconData icon, Color bg, Color fg, String label, String value, String unit, String sub,
      {bool strike = false, bool green = false}) {
    final c = context.c;
    return Container(
      height: 80,
      padding: const EdgeInsets.all(12),
      decoration:
          BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.border)),
      child: Row(children: [
        Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 18, color: fg)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: T.p(10, w: FontWeight.w500, c: c.textMuted, ls: .4)),
                RichText(
                  text: TextSpan(children: [
                    TextSpan(
                        text: value, style: T.p(15, w: FontWeight.w600, c: green ? const Color(0xFF15803D) : c.text)),
                    if (unit.isNotEmpty) TextSpan(text: ' $unit', style: T.p(10.5, c: c.textMuted)),
                  ]),
                ),
                Text(sub,
                    style: T
                        .p(10.5, c: green ? const Color(0xFF15803D) : c.textMuted)
                        .copyWith(decoration: strike ? TextDecoration.lineThrough : null)),
              ]),
        ),
      ]),
    );
  }
}

class _BorderSheet extends StatelessWidget {
  final BorderOption border;
  const _BorderSheet({required this.border});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final s = context.watch<AppState>();
    final b = border;
    final enough = s.xp >= b.xpCost;
    final needed = b.xpCost - s.xp;
    return _SheetFrame(
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _sheetHeader(context, 'Buy ${b.name}'),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                decoration: BoxDecoration(
                  color: c.isDark ? c.cardAlt : const Color(0xFFF0F9F3),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: c.border),
                ),
                child: Column(children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: Pill('Not Owned',
                        icon: Icons.lock_outline,
                        fontSize: 11,
                        bg: c.isDark ? c.card : const Color(0xFFEEF0F2),
                        fg: c.textMuted,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2)),
                  ),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                        color: const Color(0xFFCDEFD9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFA7E3BD))),
                    child: Center(child: BorderSwatch(b.kind, size: 64)),
                  ),
                  const SizedBox(height: 10),
                  Text(b.name, style: T.p(17, w: FontWeight.w600, c: c.heading)),
                  const SizedBox(height: 4),
                  Text(b.description, textAlign: TextAlign.center, style: T.p(12.5, c: c.text, h: 1.4)),
                  const SizedBox(height: 10),
                  Divider(height: 1, color: c.border),
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, alignment: WrapAlignment.center, children: [
                    Pill('Rarity: ${b.rarity}',
                        icon: Icons.auto_awesome,
                        fontSize: 11,
                        bg: c.isDark ? c.card : const Color(0xFFF0F2F0),
                        fg: c.text,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                    Pill('Category: Avatar Border',
                        icon: Icons.account_circle_outlined,
                        fontSize: 11,
                        bg: c.isDark ? c.mint : const Color(0xFFD7F5E2),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                  ]),
                ]),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: c.isDark ? c.cardAlt : const Color(0xFFF3F4F3),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: c.border)),
                child: Column(children: [
                  Row(children: [
                    Text('Item Details', style: T.p(14, w: FontWeight.w600, c: c.text)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: c.isDark ? c.card : const Color(0xFFE7E9E8),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: c.border)),
                      child: Row(children: [
                        Text('Price: ', style: T.p(12, c: c.textMuted)),
                        const XpGlyph(size: 15),
                        const SizedBox(width: 4),
                        Text('${b.xpCost} XP', style: T.p(12, w: FontWeight.w600, c: c.text)),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                    decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(14)),
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('PURCHASE TYPE', style: T.p(10, w: FontWeight.w500, c: c.textMuted, ls: .4)),
                          Text('Permanent Unlock (1×)', style: T.p(12.5, w: FontWeight.w600, c: c.heading)),
                        ]),
                      ),
                      Pill('Single Unlock',
                          icon: Icons.check,
                          fontSize: 10.5,
                          bg: c.isDark ? c.cardAlt : const Color(0xFFEEF0F2),
                          fg: c.textMuted,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3)),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: c.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: c.border)),
                child: Column(children: [
                  _xpRow(context, 'Subtotal:', '${b.xpCost} XP'),
                  const SizedBox(height: 10),
                  _xpRow(context, 'Current Balance:', '${s.xp} XP'),
                  const SizedBox(height: 10),
                  Divider(height: 1, color: c.border),
                  const SizedBox(height: 10),
                  Row(children: [
                    Text('Balance After Purchase:',
                        style: T.p(12.5, w: FontWeight.w600, c: enough ? c.heading : const Color(0xFFE11D48))),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                          color: enough ? const Color(0xFFD7F5E2) : const Color(0xFFFFF0F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: enough ? const Color(0xFFA7E3BD) : const Color(0xFFFBA4B4))),
                      child: Row(children: [
                        Icon(enough ? Icons.check : Icons.warning_amber_rounded,
                            size: 13, color: enough ? const Color(0xFF15803D) : const Color(0xFFE11D48)),
                        const SizedBox(width: 4),
                        Text(enough ? '${s.xp - b.xpCost} XP' : 'Needed: $needed more XP',
                            style: T.p(12,
                                w: FontWeight.w500, c: enough ? const Color(0xFF15803D) : const Color(0xFFE11D48))),
                      ]),
                    ),
                  ]),
                  if (!enough) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: const Color(0xFFFFEEF0),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFBC4CC))),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Icon(Icons.info_outline, size: 16, color: Color(0xFFE11D48)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                              'You do not have enough XP to unlock this avatar border. Complete study sessions to earn more XP.',
                              style: T.p(12, c: const Color(0xFFE11D48), h: 1.4)),
                        ),
                      ]),
                    ),
                  ],
                ]),
              ),
              const SizedBox(height: 10),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.school_outlined, size: 16, color: c.mintText),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Earn XP by completing focused study sessions and caring for your plants.',
                      style: T.p(11.5, c: c.textMuted, h: 1.4)),
                ),
              ]),
              const SizedBox(height: 18),
              enough
                  ? PrimaryButton('Unlock & Equip • ${b.xpCost} XP',
                      icon: Icons.lock_open, color: c.isDark ? c.primary : const Color(0xFF1B4D3E), onTap: () {
                      if (s.buyBorder(b.id)) {
                        s.equipBorder(b.id);
                        showSnack(context, '${b.name} unlocked and equipped!');
                        Navigator.of(context).pop();
                      }
                    })
                  : Container(
                      height: 52,
                      decoration: BoxDecoration(
                          color: c.isDark ? c.cardAlt : const Color(0xFFF1F1F1),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: c.border)),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.lock_outline, size: 18, color: c.textFaint),
                        const SizedBox(width: 8),
                        Text('Insufficient XP • ${b.xpCost} XP Needed',
                            style: T.p(14, w: FontWeight.w600, c: c.textFaint)),
                      ]),
                    ),
              const SizedBox(height: 16),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _xpRow(BuildContext context, String label, String value) {
    final c = context.c;
    return Row(children: [
      Text(label, style: T.p(13, c: c.text)),
      const Spacer(),
      const XpGlyph(size: 17),
      const SizedBox(width: 6),
      Text(value, style: T.p(13, w: FontWeight.w600, c: c.text)),
    ]);
  }
}
