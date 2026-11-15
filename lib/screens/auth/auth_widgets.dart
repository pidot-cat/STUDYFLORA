import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../widgets/common.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.title, required this.subtitle, required this.children, this.icon, this.showBack = false});
  final String title;
  final String subtitle;
  final List<Widget> children;
  final IconData? icon;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final c = context.sf;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            SizedBox(
              height: 44,
              child: showBack
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: Pressable(
                        onTap: () => Navigator.of(context).maybePop(),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(color: c.surface, shape: BoxShape.circle, boxShadow: [BoxShadow(color: c.shadow, blurRadius: 10)]),
                          child: Icon(Icons.chevron_left_rounded, color: c.ink),
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 18),
            Center(
              child: icon == null
                  // Clean logo, no frame (Login / Sign Up).
                  ? Image.asset('assets/images/logo_mark.webp', width: 116, height: 106, fit: BoxFit.contain)
                  : Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(color: c.brandSoft, shape: BoxShape.circle),
                      child: Icon(icon, size: 40, color: c.brand),
                    ),
            ),
            const SizedBox(height: 16),
            Text(title, style: context.tt.headlineMedium, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(subtitle, style: context.tt.bodyMedium?.copyWith(color: c.muted), textAlign: TextAlign.center),
            const SizedBox(height: 22),
            ...children,
          ],
        ),
      ),
    );
  }
}

class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.icon});
  final String text;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Row(children: [
          Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
          if (icon != null) Icon(icon, size: 18, color: context.sf.muted),
        ]),
      );
}

class PasswordField extends StatefulWidget {
  const PasswordField({super.key, required this.controller, this.hint = 'Enter your password', this.validator, this.onSubmitted});
  final TextEditingController controller;
  final String hint;
  final String? Function(String?)? validator;
  final void Function(String)? onSubmitted;
  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _hidden = true;
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _hidden,
      validator: widget.validator,
      onFieldSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        hintText: widget.hint,
        suffixIcon: IconButton(
          icon: Icon(_hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: context.sf.muted),
          onPressed: () => setState(() => _hidden = !_hidden),
        ),
      ),
    );
  }
}

/// Red / blue inline alert used for auth failures, offline, and info.
class InlineAlert extends StatelessWidget {
  const InlineAlert({super.key, required this.message, this.error = true, this.icon});
  final String message;
  final bool error;
  final IconData? icon;
  @override
  Widget build(BuildContext context) {
    final c = context.sf;
    final fg = error ? c.danger : c.info;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: error ? c.dangerSoft : c.infoSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: fg.withValues(alpha: 0.35)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon ?? (error ? Icons.error_outline_rounded : Icons.info_outline_rounded), color: fg, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(message, style: TextStyle(color: fg, fontWeight: FontWeight.w500, fontSize: 13, height: 1.35))),
      ]),
    );
  }
}

String? validateEmail(String? v) {
  final s = (v ?? '').trim();
  if (s.isEmpty) return 'Email is required';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)) return 'Enter a valid email address';
  return null;
}

String? validatePassword(String? v) {
  final s = v ?? '';
  if (s.isEmpty) return 'Password is required';
  if (s.length < 8) return 'Use at least 8 characters';
  return null;
}
