import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Auth screens are designed only in light mode – colours are fixed here.
class AuthColors {
  static const bg = Color(0xFFF9F9FF);
  static const fill = Color(0xFFEFF2FF);
  static const title = Color(0xFF1E293B);
  static const body = Color(0xFF475569);
  static const green = Color(0xFF1F5A3D);
  static const signIn = Color(0xFF3E7B54);
  static const create = Color(0xFF236640);
  static const link = Color(0xFF1F5A3D);
  static const red = Color(0xFFE11D48);
}

/// Labelled text field used on Sign In / Create Account / reset screens.
class AuthField extends StatelessWidget {
  final String label;
  final IconData? labelIcon; // small icon left of label (Create Account style)
  final IconData? trailingLabelIcon; // icon at the far right of the label row (Sign In style)
  final IconData? prefixIcon; // icon inside the field
  final String hint;
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback? onToggleObscure;
  final bool showEye;
  final String? error;
  final String? rightLabel; // e.g. "Already in use"
  final TextInputType? keyboard;
  final bool whiteFill;
  final ValueChanged<String>? onChanged;
  final Widget? labelAction;
  final bool boldValue;

  const AuthField({
    super.key,
    required this.label,
    required this.controller,
    this.labelIcon,
    this.trailingLabelIcon,
    this.prefixIcon,
    this.hint = '',
    this.obscure = false,
    this.onToggleObscure,
    this.showEye = false,
    this.error,
    this.rightLabel,
    this.keyboard,
    this.whiteFill = false,
    this.onChanged,
    this.labelAction,
    this.boldValue = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = error != null || rightLabel != null;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        if (labelIcon != null) ...[Icon(labelIcon, size: 15, color: AuthColors.green), const SizedBox(width: 6)],
        Expanded(child: Text(label, style: T.j(labelIcon != null ? 13 : 15, w: FontWeight.w500, c: AuthColors.title))),
        if (rightLabel != null) Text(rightLabel!, style: T.j(11.5, w: FontWeight.w500, c: AuthColors.red)),
        if (labelAction != null) labelAction!,
        if (trailingLabelIcon != null) Icon(trailingLabelIcon, size: 17, color: AuthColors.title),
      ]),
      const SizedBox(height: 8),
      TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboard,
        onChanged: onChanged,
        style: T.j(15, w: boldValue ? FontWeight.w600 : FontWeight.w400, c: AuthColors.title, ls: obscure ? 2 : .5),
        cursorColor: AuthColors.green,
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          hintStyle: T.j(15, c: const Color(0xFF94A3B8)),
          filled: true,
          fillColor: (whiteFill || hasError) ? Colors.white : AuthColors.fill,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 20, color: const Color(0xFF64748B)),
          suffixIcon: hasError
              ? const Icon(Icons.error_outline, color: AuthColors.red, size: 20)
              : (showEye
                  ? IconButton(
                      onPressed: onToggleObscure,
                      icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: const Color(0xFF475569), size: 21),
                    )
                  : null),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: hasError
                ? const BorderSide(color: AuthColors.red)
                : (whiteFill ? const BorderSide(color: Color(0xFFE2E8F0)) : BorderSide.none),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: hasError ? AuthColors.red : AuthColors.green, width: 1.2),
          ),
        ),
      ),
      if (error != null) ...[
        const SizedBox(height: 6),
        Text(error!, style: T.j(12, c: AuthColors.red)),
      ],
    ]);
  }
}

/// Mint ring + white disc + sprout and the small badge (Sign In header).
class AuthHeaderIcon extends StatelessWidget {
  const AuthHeaderIcon({super.key});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 86,
      height: 86,
      child: Stack(clipBehavior: Clip.none, children: [
        Container(
          width: 82,
          height: 82,
          decoration: const BoxDecoration(color: Color(0xFFDDF5E6), shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.eco_outlined, size: 20, color: AuthColors.green),
          ),
        ),
        Positioned(
          right: -4,
          top: -4,
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: const Color(0xFF9BE3B7),
              shape: BoxShape.circle,
              border: Border.all(color: AuthColors.bg, width: 2),
            ),
            child: const Icon(Icons.spa, size: 13, color: AuthColors.green),
          ),
        ),
      ]),
    );
  }
}

/// "Quiet Consistency" tip card.
class QuietConsistencyCard extends StatelessWidget {
  const QuietConsistencyCard({super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F4FD),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8ECF8)),
        ),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(color: Color(0xFFB9EDCA), shape: BoxShape.circle),
            child: const Icon(Icons.eco, size: 18, color: AuthColors.green),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Quiet Consistency', style: T.j(13, w: FontWeight.w700, c: AuthColors.title)),
              const SizedBox(height: 2),
              Text('Every calm session helps your flora flourish.', style: T.j(12.5, c: AuthColors.body)),
            ]),
          ),
        ]),
      );
}

/// White rounded container that wraps form fields.
class AuthCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const AuthCard({super.key, required this.child, this.padding = const EdgeInsets.fromLTRB(24, 24, 24, 24)});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 2))],
        ),
        child: child,
      );
}

class AuthButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final IconData? trailingIcon;
  final VoidCallback? onTap;
  final bool loading;
  final String? loadingLabel;
  final Color color;
  final FontWeight weight;
  const AuthButton(this.label,
      {super.key,
      this.icon,
      this.trailingIcon,
      this.onTap,
      this.loading = false,
      this.loadingLabel,
      this.color = AuthColors.signIn,
      this.weight = FontWeight.w500});

  @override
  Widget build(BuildContext context) {
    final bg = loading ? color.withValues(alpha: .72) : color;
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [BoxShadow(color: color.withValues(alpha: .3), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(40),
          onTap: loading ? null : onTap,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (loading) ...[
              const SizedBox(
                  width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE2E8F0))),
              const SizedBox(width: 10),
              Text(loadingLabel ?? label, style: T.j(15, w: weight, c: Colors.white)),
            ] else ...[
              if (icon != null) ...[Icon(icon, size: 20, color: Colors.white), const SizedBox(width: 10)],
              Text(label, style: T.j(15, w: weight, c: Colors.white)),
              if (trailingIcon != null) ...[
                const SizedBox(width: 8),
                Icon(trailingIcon, size: 17, color: Colors.white)
              ],
            ],
          ]),
        ),
      ),
    );
  }
}

class AuthLinkRow extends StatelessWidget {
  final String text;
  final String link;
  final VoidCallback onTap;
  const AuthLinkRow({super.key, required this.text, required this.link, required this.onTap});
  @override
  Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(text, style: T.j(14, c: AuthColors.body)),
        const SizedBox(width: 6),
        GestureDetector(onTap: onTap, child: Text(link, style: T.j(14, w: FontWeight.w700, c: AuthColors.link))),
      ]);
}
