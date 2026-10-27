import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// White rounded card used across almost every screen.
class SFCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final Color? borderColor;
  final double borderWidth;
  final VoidCallback? onTap;
  final bool shadow;
  final EdgeInsetsGeometry? margin;
  const SFCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 18,
    this.color,
    this.borderColor,
    this.borderWidth = 1,
    this.onTap,
    this.shadow = true,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final box = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? c.card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? c.border, width: borderWidth),
        boxShadow:
            shadow && !c.isDark ? [BoxShadow(color: c.shadow, blurRadius: 14, offset: const Offset(0, 4))] : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
    return box;
  }
}

/// Small rounded pill / badge.
class Pill extends StatelessWidget {
  final String text;
  final Color? bg;
  final Color? fg;
  final IconData? icon;
  final double fontSize;
  final FontWeight weight;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final bool dot;
  final bool jakarta;
  const Pill(this.text,
      {super.key,
      this.bg,
      this.fg,
      this.icon,
      this.fontSize = 12,
      this.weight = FontWeight.w600,
      this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      this.borderColor,
      this.dot = false,
      this.jakarta = false});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final color = fg ?? c.mintText;
    final style = jakarta ? T.j(fontSize, w: weight, c: color) : T.p(fontSize, w: weight, c: color);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg ?? c.mint,
        borderRadius: BorderRadius.circular(40),
        border: borderColor == null ? null : Border.all(color: borderColor!),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (dot) ...[
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
        ],
        if (icon != null) ...[Icon(icon, size: fontSize + 2, color: color), const SizedBox(width: 4)],
        Text(text, style: style),
      ]),
    );
  }
}

/// Rounded square icon tile (e.g. list leading icons).
class IconTile extends StatelessWidget {
  final IconData icon;
  final double size;
  final double iconSize;
  final Color? bg;
  final Color? fg;
  final double radius;
  final bool circle;
  final Color? borderColor;
  const IconTile(this.icon,
      {super.key,
      this.size = 44,
      this.iconSize = 22,
      this.bg,
      this.fg,
      this.radius = 12,
      this.circle = false,
      this.borderColor});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg ?? c.mint,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(radius),
        border: borderColor != null ? Border.all(color: borderColor!) : (c.isDark ? Border.all(color: c.border) : null),
      ),
      child: Icon(icon, size: iconSize, color: fg ?? c.mintText),
    );
  }
}

class SFProgress extends StatelessWidget {
  final double value;
  final Color? color;
  final Color? track;
  final double height;
  final Gradient? gradient;
  const SFProgress({super.key, required this.value, this.color, this.track, this.height = 8, this.gradient});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Container(
        height: height,
        color: track ?? c.track,
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: value.clamp(0.0, 1.0).toDouble(),
          heightFactor: 1,
          child: Container(
            decoration: BoxDecoration(
              color: gradient == null ? (color ?? c.accent) : null,
              gradient: gradient,
              borderRadius: BorderRadius.circular(height),
            ),
          ),
        ),
      ),
    );
  }
}

/// Big pill-shaped filled button.
class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final IconData? trailingIcon;
  final VoidCallback? onTap;
  final Color? color;
  final Color? fg;
  final double height;
  final bool loading;
  final double radius;
  final double fontSize;
  final bool jakarta;
  final bool shadow;
  final Gradient? gradient;
  const PrimaryButton(this.label,
      {super.key,
      this.icon,
      this.trailingIcon,
      this.onTap,
      this.color,
      this.fg,
      this.height = 52,
      this.loading = false,
      this.radius = 40,
      this.fontSize = 15,
      this.jakarta = false,
      this.shadow = true,
      this.gradient});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final bg = color ?? c.primary;
    final textColor = fg ?? c.primaryText;
    final disabled = onTap == null && !loading;
    final style =
        jakarta ? T.j(fontSize, w: FontWeight.w600, c: textColor) : T.p(fontSize, w: FontWeight.w600, c: textColor);
    return Opacity(
      opacity: disabled ? .55 : 1,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: gradient == null ? (loading ? bg.withValues(alpha: .75) : bg) : null,
          gradient: gradient,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: shadow && !disabled && !c.isDark
              ? [BoxShadow(color: bg.withValues(alpha: .28), blurRadius: 14, offset: const Offset(0, 6))]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(radius),
            onTap: loading ? null : onTap,
            child: Center(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (loading) ...[
                  SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: textColor.withValues(alpha: .8))),
                  const SizedBox(width: 10),
                ] else if (icon != null) ...[
                  Icon(icon, size: 19, color: textColor),
                  const SizedBox(width: 10),
                ],
                Flexible(child: Text(label, style: style, overflow: TextOverflow.ellipsis)),
                if (trailingIcon != null && !loading) ...[
                  const SizedBox(width: 8),
                  Icon(trailingIcon, size: 18, color: textColor),
                ],
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// White / outlined pill button.
class OutlineButtonSF extends StatelessWidget {
  final String label;
  final IconData? icon;
  final IconData? trailingIcon;
  final VoidCallback? onTap;
  final Color? fg;
  final Color? bg;
  final Color? borderColor;
  final double height;
  final double radius;
  final double fontSize;
  final bool jakarta;
  final FontWeight weight;
  const OutlineButtonSF(this.label,
      {super.key,
      this.icon,
      this.trailingIcon,
      this.onTap,
      this.fg,
      this.bg,
      this.borderColor,
      this.height = 52,
      this.radius = 40,
      this.fontSize = 15,
      this.jakarta = false,
      this.weight = FontWeight.w600});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final color = fg ?? c.heading;
    final style = jakarta ? T.j(fontSize, w: weight, c: color) : T.p(fontSize, w: weight, c: color);
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: bg ?? c.card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? c.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onTap,
          child: Center(
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (icon != null) ...[Icon(icon, size: 18, color: color), const SizedBox(width: 8)],
              Text(label, style: style),
              if (trailingIcon != null) ...[const SizedBox(width: 8), Icon(trailingIcon, size: 18, color: color)],
            ]),
          ),
        ),
      ),
    );
  }
}

/// White circular back button (top-left on sub screens).
class CircleBackButton extends StatelessWidget {
  final VoidCallback? onTap;
  final double size;
  final bool outlined;
  const CircleBackButton({super.key, this.onTap, this.size = 40, this.outlined = false});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: c.card,
      shape: CircleBorder(side: BorderSide(color: outlined ? c.mint : c.border)),
      elevation: c.isDark ? 0 : 1,
      shadowColor: c.shadow,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap ?? () => Navigator.of(context).maybePop(),
        child: SizedBox(
            width: size, height: size, child: Icon(Icons.chevron_left_rounded, color: c.heading, size: size * .6)),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final Widget? trailing;
  final double size;
  const SectionHeader(this.title, {super.key, this.action, this.onAction, this.trailing, this.size = 17});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Row(children: [
      Expanded(child: Text(title, style: T.p(size, w: FontWeight.w700, c: c.heading))),
      if (trailing != null) trailing!,
      if (action != null)
        InkWell(
          onTap: onAction,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(action!, style: T.p(12, w: FontWeight.w700, c: c.isDark ? c.accent : c.heading)),
          ),
        ),
    ]);
  }
}

/// Mint info box with leading (i) icon.
class InfoBanner extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color? bg;
  final Color? border;
  final Color? iconColor;
  final double fontSize;
  final Widget? rich;
  const InfoBanner(this.text,
      {super.key, this.icon = Icons.info, this.bg, this.border, this.iconColor, this.fontSize = 12.5, this.rich});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg ?? (c.isDark ? c.cardAlt : const Color(0xFFE6F5EC)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border ?? (c.isDark ? c.border : const Color(0xFFC9EBD6))),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 18, color: iconColor ?? c.mintText),
        const SizedBox(width: 10),
        Expanded(
            child:
                rich ?? Text(text, style: T.p(fontSize, c: c.isDark ? c.textMuted : const Color(0xFF2F4F3F), h: 1.45))),
      ]),
    );
  }
}

/// Styled switch matching the Settings mock-up.
class SFSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const SFSwitch({super.key, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final on = c.isDark ? const Color(0xFF34D399) : const Color(0xFF10B981);
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 52,
        height: 30,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? on : (c.isDark ? c.border : const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(30),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 180),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: c.isDark && value ? const Color(0xFF0B1A14) : Colors.white,
              shape: BoxShape.circle,
              boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 3, offset: Offset(0, 1))],
            ),
          ),
        ),
      ),
    );
  }
}

/// Circle with a flower – emoji (as used on Home / Inventory) or the illustrated asset.
class FlowerIcon extends StatelessWidget {
  final Flower flower;
  final double size;
  final bool useEmoji;
  final bool tinted;
  const FlowerIcon(this.flower, {super.key, this.size = 48, this.useEmoji = false, this.tinted = true});

  static const _emojiIds = {'sunflower', 'tulip', 'rose', 'daisy', 'cosmos'};

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final emoji = useEmoji && _emojiIds.contains(flower.id);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tinted ? (c.isDark ? c.cardAlt : flower.tint) : null,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: emoji
          ? Text(flower.emoji, style: TextStyle(fontSize: size * .48))
          : ClipOval(child: Image.asset(flower.asset, width: size * .92, height: size * .92, fit: BoxFit.cover)),
    );
  }
}

/// The orange "$" coin glyph.
class CoinGlyph extends StatelessWidget {
  final double size;
  const CoinGlyph({super.key, this.size = 18});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(color: Color(0xFFF59E0B), shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Text('\$', style: T.p(size * .6, w: FontWeight.w700, c: Colors.white, h: 1)),
      );
}

/// Green round "XP" glyph.
class XpGlyph extends StatelessWidget {
  final double size;
  const XpGlyph({super.key, this.size = 18});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
            color: const Color(0xFFD1FAE5),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF1B6B3F), width: .8)),
        alignment: Alignment.center,
        child: Text('XP', style: T.p(size * .42, w: FontWeight.w700, c: const Color(0xFF1B6B3F), h: 1)),
      );
}

String plural(int n, String one, [String? many]) => n == 1 ? one : (many ?? '${one}s');

/// Bullet row "✓ text" used in tool screens.
class CheckLine extends StatelessWidget {
  final String text;
  const CheckLine(this.text, {super.key});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 16,
          height: 16,
          margin: const EdgeInsets.only(top: 1),
          decoration: BoxDecoration(color: c.isDark ? c.mint : const Color(0xFFCDEFD9), shape: BoxShape.circle),
          child: Icon(Icons.check, size: 11, color: c.mintText),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: T.p(12.5, c: c.text, h: 1.4))),
      ]),
    );
  }
}

void showSnack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(msg, style: T.p(13, c: Colors.white)),
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF1B4D3E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      duration: const Duration(seconds: 2),
    ));
}
