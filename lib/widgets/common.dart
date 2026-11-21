import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme.dart';
import '../providers/feedback_bus.dart';
import '../services/sound_service.dart';

/// Scale-down-on-press micro-interaction used by every tappable card/button.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.onTap, this.onLongPress, this.scale = 0.97, this.haptic = true});
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final bool haptic;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;
  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null || widget.onLongPress != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapUp: enabled ? (_) => _set(false) : null,
      onTapCancel: enabled ? () => _set(false) : null,
      onTap: widget.onTap == null
          ? null
          : () {
              if (widget.haptic && FeedbackPrefs.sound) {
                // The tap sound itself comes from TapSound (app-wide).
                HapticFeedback.selectionClick();
              }
              widget.onTap!();
            },
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class SfCard extends StatelessWidget {
  const SfCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.color, this.onTap, this.border, this.radius = 20});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final VoidCallback? onTap;
  final Color? border;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = context.sf;
    final box = AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? c.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border ?? (context.isDark ? c.line : Colors.transparent)),
        boxShadow: [BoxShadow(color: c.shadow, blurRadius: 18, offset: const Offset(0, 6))],
      ),
      child: child,
    );
    return onTap == null ? box : Pressable(onTap: onTap, child: box);
  }
}

enum Tone { green, gold, red, blue, neutral, terracotta }

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.label, {super.key, this.tone = Tone.green, this.icon, this.dense = false});
  final String label;
  final Tone tone;
  final IconData? icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = toneColors(context, tone);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 8 : 11, vertical: dense ? 3 : 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: dense ? 12 : 14, color: fg), const SizedBox(width: 4)],
        Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: dense ? 10.5 : 11.5)),
      ]),
    );
  }
}

(Color, Color) toneColors(BuildContext context, Tone t) {
  final c = context.sf;
  return switch (t) {
    Tone.green => (c.brandSoft, context.isDark ? c.brand : c.brand),
    Tone.gold => (c.goldSoft, context.isDark ? c.gold : const Color(0xFF9A6400)),
    Tone.red => (c.dangerSoft, c.danger),
    Tone.blue => (c.infoSoft, c.info),
    Tone.neutral => (c.line, c.muted),
    Tone.terracotta => (c.terracottaSoft, c.terracotta),
  };
}

class SfProgressBar extends StatelessWidget {
  const SfProgressBar({super.key, required this.value, this.color, this.height = 8, this.background});
  final double value;
  final Color? color;
  final Color? background;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.sf;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Container(
        height: height,
        color: background ?? c.line,
        alignment: Alignment.centerLeft,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: value.clamp(0.0, 1.0)),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          builder: (_, v, __) => FractionallySizedBox(
            widthFactor: v,
            child: Container(decoration: BoxDecoration(color: color ?? c.accent, borderRadius: BorderRadius.circular(height))),
          ),
        ),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, this.onTap, this.icon, this.busy = false, this.color, this.height = 54});
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool busy;
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.sf;
    final enabled = onTap != null && !busy;
    final bg = enabled ? (color ?? c.brand) : c.line;
    final fg = enabled ? (color == null ? c.onBrand : Colors.white) : c.muted;
    return Pressable(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: height,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(height / 2),
          boxShadow: enabled ? [BoxShadow(color: bg.withValues(alpha: 0.28), blurRadius: 16, offset: const Offset(0, 6))] : null,
        ),
        alignment: Alignment.center,
        child: busy
            ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: fg))
            : Row(mainAxisSize: MainAxisSize.min, children: [
                if (icon != null) ...[Icon(icon, color: fg, size: 20), const SizedBox(width: 8)],
                Flexible(
                  child: Text(label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ]),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({super.key, required this.label, this.onTap, this.icon, this.height = 54, this.danger = false});
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final double height;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = context.sf;
    final fg = danger ? c.danger : c.ink;
    return Pressable(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(height / 2),
          border: Border.all(color: danger ? c.danger.withValues(alpha: 0.4) : c.line, width: 1.4),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        // Shrinks (never wraps or overflows) when two buttons share a row.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[Icon(icon, color: fg, size: 19), const SizedBox(width: 8)],
            Text(label, maxLines: 1, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 15)),
          ]),
        ),
      ),
    );
  }
}

/// Red notification dot ("something to claim here"). Shows a number when
/// [count] is above 1.
class RedDot extends StatelessWidget {
  const RedDot({super.key, this.count = 1, this.size = 16});
  final int count;
  final double size;
  @override
  Widget build(BuildContext context) {
    final c = context.sf;
    return Container(
      constraints: BoxConstraints(minWidth: size, minHeight: size),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: c.danger,
        borderRadius: BorderRadius.circular(size),
        border: Border.all(color: c.surface, width: 1.6),
      ),
      alignment: Alignment.center,
      child: count > 1
          ? Text(count > 9 ? '9+' : '$count',
              textScaler: TextScaler.noScaling,
              style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w800, height: 1.1))
          : null,
    );
  }
}

/// Solid red "Claim" pill used wherever a reward is waiting.
class ClaimPill extends StatelessWidget {
  const ClaimPill({super.key, this.label = 'Claim', this.onTap, this.dense = false});
  final String label;
  final VoidCallback? onTap;
  final bool dense;
  @override
  Widget build(BuildContext context) {
    final pill = Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 9 : 14, vertical: dense ? 3 : 6),
      decoration: BoxDecoration(color: context.sf.danger, borderRadius: BorderRadius.circular(99)),
      child: Text(label, maxLines: 1, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: dense ? 10.5 : 12.5)),
    );
    return onTap == null ? pill : Pressable(onTap: onTap, child: pill);
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing, this.onTrailing});
  final String title;
  final String? trailing;
  final VoidCallback? onTrailing;

  @override
  Widget build(BuildContext context) {
    final c = context.sf;
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 22, 2, 10),
      child: Row(children: [
        Expanded(child: Text(title, style: context.tt.titleLarge)),
        if (trailing != null)
          Pressable(
            onTap: onTrailing,
            child: Row(children: [
              Text(trailing!, style: TextStyle(color: c.brand, fontWeight: FontWeight.w700, fontSize: 12.5)),
              Icon(Icons.chevron_right_rounded, size: 18, color: c.brand),
            ]),
          ),
      ]),
    );
  }
}

class CapsLabel extends StatelessWidget {
  const CapsLabel(this.text, {super.key, this.icon});
  final String text;
  final IconData? icon;
  @override
  Widget build(BuildContext context) {
    final c = context.sf;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 22, 4, 10),
      child: Row(children: [
        if (icon != null) ...[Icon(icon, size: 15, color: c.brand), const SizedBox(width: 6)],
        Text(text.toUpperCase(), style: context.tt.labelSmall?.copyWith(color: context.isDark ? c.muted : c.brand)),
      ]),
    );
  }
}

class IconTile extends StatelessWidget {
  const IconTile(this.icon, {super.key, this.size = 46, this.color, this.bg, this.iconSize});
  final IconData icon;
  final double size;
  final Color? color;
  final Color? bg;
  final double? iconSize;
  @override
  Widget build(BuildContext context) {
    final c = context.sf;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg ?? c.surfaceAlt, borderRadius: BorderRadius.circular(size * 0.3)),
      child: Icon(icon, color: color ?? c.brand, size: iconSize ?? size * 0.48),
    );
  }
}

/// Circle behind seed/plant images (mockup "seed in tinted circle").
class TintedCircle extends StatelessWidget {
  const TintedCircle({super.key, required this.child, required this.color, this.size = 54});
  final Widget child;
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) {
    final bg = context.isDark ? Color.alphaBlend(color.withValues(alpha: 0.18), context.sf.surfaceAlt) : color;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      padding: EdgeInsets.all(size * 0.1),
      child: child,
    );
  }
}

class CoinIcon extends StatelessWidget {
  const CoinIcon({super.key, this.size = 20});
  final double size;
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: [Color(0xFFFFC23D), Color(0xFFF29A0C)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        alignment: Alignment.center,
        child: Text('\$', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: size * 0.6, height: 1)),
      );
}

class XpIcon extends StatelessWidget {
  const XpIcon({super.key, this.size = 20});
  final double size;
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF34D58D)),
        alignment: Alignment.center,
        child: Text('XP', style: TextStyle(color: const Color(0xFF07402A), fontWeight: FontWeight.w800, fontSize: size * 0.4, height: 1)),
      );
}

/// Animated number (counts up/down when coins or XP change).
class AnimatedCount extends StatelessWidget {
  const AnimatedCount(this.value, {super.key, this.style, this.suffix = ''});
  final int value;
  final TextStyle? style;
  final String suffix;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(end: value.toDouble()),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (_, v, __) => Text('${v.round()}$suffix', style: style),
      );
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.message, this.action, this.onAction});
  final IconData icon;
  final String title;
  final String message;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) {
    return SfCard(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(children: [
        IconTile(icon, size: 56),
        const SizedBox(height: 12),
        Text(title, style: context.tt.titleMedium, textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(message, style: context.tt.bodySmall, textAlign: TextAlign.center),
        if (action != null) ...[
          const SizedBox(height: 16),
          PrimaryButton(label: action!, onTap: onAction, height: 46),
        ],
      ]),
    );
  }
}

void showToast(BuildContext context, String message, {bool error = false}) {
  if (error) SoundService.instance.play(Sfx.error);
  final c = context.sf;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Row(children: [
        Icon(error ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded, color: error ? c.danger : c.brand, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(message)),
      ]),
      duration: const Duration(milliseconds: 2600),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 90),
    ));
}
