import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/pot.dart';
import '../../providers/feedback_bus.dart';
import '../../providers/game_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/sound_service.dart';
import '../../widgets/common.dart';
import '../../widgets/plant_widgets.dart';
import '../../widgets/profile_widgets.dart';
import '../../widgets/sheets.dart';
import 'plant_details_screen.dart';
import 'planting_sheets.dart';

/// Zen Garden: 18 pots on a wooden table (FR-4.1). The whole garden fits on
/// one screen — no scrolling.
///
/// Drag-and-drop: long-press a pot (or turn on Arrange mode for instant drag)
/// and drop it on another pot. The two pots — each with its plant — swap
/// places; the displaced pot glides into the empty spot.
class GardenScreen extends StatefulWidget {
  const GardenScreen({super.key});
  @override
  State<GardenScreen> createState() => _GardenScreenState();
}

class _GardenScreenState extends State<GardenScreen> {
  int? _draggingIndex;
  int? _hoverIndex;
  int? _droppedPot; // pot that was just dropped (no slide, bounce instead)
  int _dropTick = 0;

  void _endDrag() {
    setState(() {
      _draggingIndex = null;
      _hoverIndex = null;
    });
  }

  void _swap(GameProvider g, int from, int to) {
    HapticFeedback.mediumImpact();
    SoundService.instance.play(Sfx.swap);
    final moved = g.pots[from].number;
    g.swapPots(from, to);
    setState(() {
      _droppedPot = moved;
      _dropTick++;
      _draggingIndex = null;
      _hoverIndex = null;
    });
  }

  Future<void> _tapPot(BuildContext context, Pot pot) async {
    final g = context.read<GameProvider>();
    final now = GameClock.nowMs();
    if (pot.isEmpty) {
      await showChooseFlowerSheet(context, pot.number);
    } else if (pot.isReadyAt(now)) {
      await showHarvestSheet(context, pot);
    } else {
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlantDetailsScreen(potNumber: pot.number)));
    }
    if (mounted) setState(() {});
    g.refresh();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ClockTicker>();
    final g = context.watch<GameProvider>();
    final c = context.sf;
    final now = GameClock.nowMs();
    final empty = g.emptyCount();
    final growing = g.growingCount(now);
    final ready = g.readyCount(now);

    final showTip = !context.select<SettingsProvider, bool>((s) => s.gardenTipSeen);

    final topInset = MediaQuery.paddingOf(context).top;
    return Stack(children: [
      Positioned.fill(
        child: Image.asset(
          context.isDark ? 'assets/images/garden_night.webp' : 'assets/images/garden_day.webp',
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),
      ),
      // Same solid header as every other screen (covers the status bar too),
      // so the garden photo no longer shows through around a white strip.
      Column(children: [
          Container(color: c.bg, padding: EdgeInsets.only(top: topInset), child: const SfTopBar()),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: _GlassCard(
              dense: true,
              child: Row(children: [
                const Expanded(
                  child: Text('Your Garden', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                ),
                _MiniStat(label: 'Empty', value: empty),
                const SizedBox(width: 10),
                _MiniStat(label: 'Growing', value: growing),
                const SizedBox(width: 10),
                _MiniStat(label: 'Ready', value: ready, gold: ready > 0),
              ]),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              child: LayoutBuilder(builder: (context, box) {
                final cols = GameRules.gardenColumns;
                final rows = (GameRules.potCount / cols).ceil();
                // Table padding inside the wood frame
                const padX = 8.0, padTop = 10.0, padBottom = 12.0;
                final innerW = box.maxWidth - padX * 2;
                final innerH = box.maxHeight - padTop - padBottom;
                // Cell aspect ~1.15 (w:h); shrink to whichever side is tighter.
                var cellW = innerW / cols;
                var cellH = cellW / 1.15;
                if (cellH * rows > innerH) {
                  cellH = innerH / rows;
                  cellW = math.min(innerW / cols, cellH * 1.25);
                }
                final gridW = cellW * cols;
                final gridH = cellH * rows;
                return Align(
                  alignment: Alignment.center,
                  child: _WoodTable(
                    padding: const EdgeInsets.fromLTRB(padX, padTop, padX, padBottom),
                    child: SizedBox(
                      width: gridW,
                      height: gridH,
                      child: Stack(clipBehavior: Clip.none, children: [
                        for (var i = 0; i < GameRules.potCount; i++)
                          Positioned(
                            left: (i % cols) * cellW,
                            top: (i ~/ cols) * cellH,
                            width: cellW,
                            height: cellH,
                            child: _Coaster(highlight: _hoverIndex == i && _draggingIndex != i, origin: _draggingIndex == i),
                          ),
                        for (var i = 0; i < g.pots.length; i++)
                          AnimatedPositioned(
                            key: ValueKey('pot-${g.pots[i].number}'),
                            duration: g.pots[i].number == _droppedPot ? Duration.zero : const Duration(milliseconds: 480),
                            curve: Curves.easeOutBack,
                            left: (i % cols) * cellW,
                            top: (i ~/ cols) * cellH,
                            width: cellW,
                            height: cellH,
                            child: _buildPot(context, g, i, cellW, cellH, now),
                          ),
                      ]),
                    ),
                  ),
                );
              }),
            ),
          ),
          // First-time guide only; hidden for good once dismissed.
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            child: showTip
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                    child: _GlassCard(
                      dense: true,
                      child: Row(children: [
                        const Icon(Icons.touch_app_rounded, color: Color(0xFF7DF0B4), size: 20),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text('Tap a pot to plant or care for it.\nLong-press a pot, then drag it to move it.',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12.5, height: 1.35)),
                        ),
                        TextButton(
                          onPressed: () => context.read<SettingsProvider>().dismissGardenTip(),
                          style: TextButton.styleFrom(foregroundColor: const Color(0xFF7DF0B4)),
                          child: const Text('Got it', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ]),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
      ]),
    ]);
  }

  Widget _buildPot(BuildContext context, GameProvider g, int index, double w, double h, int now) {
    final pot = g.pots[index];
    final potH = h * 0.86;
    final visual = _PotVisual(
      pot: pot,
      now: now,
      potHeight: potH,
      wiggle: _draggingIndex != null && _draggingIndex != index, // pots wiggle while one is being moved
      bounceKey: pot.number == _droppedPot ? _dropTick : 0,
      dimmed: _hoverIndex == index && _draggingIndex != null && _draggingIndex != index,
    );

    final feedback = Material(
      color: Colors.transparent,
      child: SizedBox(
        width: w,
        height: h,
        child: Transform.scale(
          scale: 1.18,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.28), blurRadius: 24, offset: const Offset(0, 14))],
            ),
            child: _PotVisual(pot: pot, now: now, potHeight: potH, lifted: true),
          ),
        ),
      ),
    );

    final ghost = Opacity(opacity: 0.25, child: _PotVisual(pot: pot, now: now, potHeight: potH));

    void started() {
      HapticFeedback.lightImpact();
      setState(() {
        _draggingIndex = index;
        _droppedPot = null;
      });
    }

    final draggable = LongPressDraggable<int>(
            data: index,
            delay: const Duration(milliseconds: 280),
            feedback: feedback,
            childWhenDragging: ghost,
            onDragStarted: started,
            onDragEnd: (_) => _endDrag(),
            onDraggableCanceled: (_, __) => _endDrag(),
            child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => _tapPot(context, pot), child: visual),
          );

    return DragTarget<int>(
      onWillAcceptWithDetails: (d) {
        final ok = d.data != index;
        if (ok && _hoverIndex != index) {
          HapticFeedback.selectionClick();
          setState(() => _hoverIndex = index);
        }
        return ok;
      },
      onLeave: (_) {
        if (_hoverIndex == index) setState(() => _hoverIndex = null);
      },
      onAcceptWithDetails: (d) => _swap(g, d.data, index),
      builder: (_, __, ___) => draggable,
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value, this.gold = false});
  final String label;
  final int value;
  final bool gold;
  @override
  Widget build(BuildContext context) => Text.rich(
        TextSpan(children: [
          TextSpan(text: '$value ', style: TextStyle(fontWeight: FontWeight.w800, color: gold ? const Color(0xFFFFD36B) : Colors.white)),
          TextSpan(text: label, style: const TextStyle(color: Color(0xFFBFD8CB))),
        ]),
        style: const TextStyle(fontSize: 11.5),
      );
}

/// Pot + plant. Wiggles while another pot is being moved; bounces on drop.
class _PotVisual extends StatefulWidget {
  const _PotVisual({
    required this.pot,
    required this.now,
    required this.potHeight,
    this.wiggle = false,
    this.lifted = false,
    this.bounceKey = 0,
    this.dimmed = false,
  });
  final Pot pot;
  final int now;
  final double potHeight;
  final bool wiggle;
  final bool lifted;
  final int bounceKey;
  final bool dimmed;

  @override
  State<_PotVisual> createState() => _PotVisualState();
}

class _PotVisualState extends State<_PotVisual> with TickerProviderStateMixin {
  late final AnimationController _wiggle = AnimationController(vsync: this, duration: const Duration(milliseconds: 260));
  late final AnimationController _bounce = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
  final double _phase = math.Random().nextDouble();

  @override
  void initState() {
    super.initState();
    if (widget.wiggle) _wiggle.repeat(reverse: true);
    if (widget.bounceKey != 0) _bounce.forward(from: 0);
  }

  @override
  void didUpdateWidget(covariant _PotVisual old) {
    super.didUpdateWidget(old);
    if (widget.wiggle && !_wiggle.isAnimating) {
      _wiggle.value = _phase;
      _wiggle.repeat(reverse: true);
    } else if (!widget.wiggle && _wiggle.isAnimating) {
      _wiggle.stop();
      _wiggle.value = 0.5;
    }
    if (widget.bounceKey != old.bounceKey && widget.bounceKey != 0) _bounce.forward(from: 0);
  }

  @override
  void dispose() {
    _wiggle.dispose();
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pot;
    return AnimatedBuilder(
      animation: Listenable.merge([_wiggle, _bounce]),
      builder: (context, child) {
        final angle = widget.wiggle ? (_wiggle.value - 0.5) * 0.06 : 0.0;
        final b = _bounce.isAnimating ? math.sin(_bounce.value * math.pi) * (1 - _bounce.value) : 0.0;
        return Transform.rotate(
          angle: angle,
          child: Transform.scale(scale: (widget.dimmed ? 0.9 : 1.0) + b * 0.22, alignment: Alignment.bottomCenter, child: child),
        );
      },
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: PlantImage(pot: p, now: widget.now, height: widget.potHeight, showIndicators: !widget.lifted),
        ),
      ),
    );
  }
}

class _Coaster extends StatelessWidget {
  const _Coaster({this.highlight = false, this.origin = false});
  final bool highlight;
  final bool origin;
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const Alignment(0, 0.92),
      child: FractionallySizedBox(
        widthFactor: 0.8,
        heightFactor: 0.34,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFE2B062), Color(0xFFC98E3E)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: highlight ? const Color(0xFF7DF0B4) : (origin ? Colors.white70 : const Color(0xFFA06A28)),
              width: highlight ? 3 : 1.4,
            ),
            boxShadow: [
              if (highlight) BoxShadow(color: const Color(0xFF34D58D).withValues(alpha: 0.6), blurRadius: 18, spreadRadius: 2),
              const BoxShadow(color: Color(0x33000000), offset: Offset(0, 3), blurRadius: 3),
            ],
          ),
        ),
      ),
    );
  }
}

/// Light wooden potting table painted with planks.
class _WoodTable extends StatelessWidget {
  const _WoodTable({required this.child, required this.padding});
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 22, offset: Offset(0, 12))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: CustomPaint(
          painter: _PlankPainter(dark: dark),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class _PlankPainter extends CustomPainter {
  _PlankPainter({required this.dark});
  final bool dark;
  @override
  void paint(Canvas canvas, Size size) {
    final base = dark ? const Color(0xFF8B6B4E) : const Color(0xFFEFE3D3);
    final alt = dark ? const Color(0xFF81624A) : const Color(0xFFE7D8C5);
    final seam = dark ? const Color(0xFF5E4430) : const Color(0xFFC9B297);
    final grain = (dark ? Colors.black : const Color(0xFF9C7E5C)).withValues(alpha: 0.08);
    const plank = 46.0;
    var y = 0.0;
    var k = 0;
    while (y < size.height) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, plank), Paint()..color = k.isEven ? base : alt);
      for (var g = 0; g < 3; g++) {
        final gy = y + 10 + g * 12.0;
        final path = Path()..moveTo(0, gy);
        for (var x = 0.0; x <= size.width; x += 30) {
          path.lineTo(x, gy + math.sin((x + k * 37) / 40) * 1.6);
        }
        canvas.drawPath(path, Paint()
          ..color = grain
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
      }
      canvas.drawRect(Rect.fromLTWH(0, y + plank - 1.5, size.width, 1.5), Paint()..color = seam);
      final jx = (k.isEven ? 0.35 : 0.68) * size.width;
      canvas.drawRect(Rect.fromLTWH(jx, y, 1.5, plank), Paint()..color = seam.withValues(alpha: 0.6));
      y += plank;
      k++;
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(18)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = seam,
    );
  }

  @override
  bool shouldRepaint(covariant _PlankPainter old) => old.dark != dark;
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child, this.dense = false});
  final Widget child;
  final bool dense;
  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.all(dense ? 10 : 12),
        decoration: BoxDecoration(
          color: const Color(0xE6122A1F),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: child,
      );
}

/// FR-4.8 — tap a fully grown plant: claim XP or keep it on display.
Future<void> showHarvestSheet(BuildContext context, Pot pot) {
  final f = pot.flower!;
  return showSfSheet(
    context: context,
    builder: (ctx) {
      final c = ctx.sf;
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SheetHeader(title: 'Fully grown!', icon: Icons.local_florist_rounded),
          const SizedBox(height: 4),
          Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(shape: BoxShape.circle, color: c.goldSoft, border: Border.all(color: c.gold.withValues(alpha: 0.35), width: 10)),
            alignment: Alignment.center,
            child: Image.asset(f.bloomAsset, height: 150),
          ),
          const SizedBox(height: 14),
          Text(f.name, style: ctx.tt.headlineMedium),
          const SizedBox(height: 4),
          Text('Claim your XP now, or leave it displayed in your garden.', style: ctx.tt.bodySmall, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          StatusBadge('Harvest reward: +${f.harvestXp} XP', tone: Tone.gold, icon: Icons.emoji_events_outlined),
          const SizedBox(height: 22),
          PrimaryButton(
            label: 'Claim +${f.harvestXp} XP',
            icon: Icons.star_rounded,
            color: c.gold,
            onTap: () {
              ctx.read<GameProvider>().harvest(pot.number);
              Navigator.pop(ctx);
            },
          ),
          const SizedBox(height: 10),
          SecondaryButton(label: 'Keep it displayed', icon: Icons.visibility_outlined, onTap: () => Navigator.pop(ctx)),
        ]),
      );
    },
  );
}
