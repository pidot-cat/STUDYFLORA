import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common.dart';
import 'auth_widgets.dart';

/// Big centered field for the 6-digit code sent by email.
class CodeField extends StatelessWidget {
  const CodeField({super.key, required this.controller, this.onSubmitted});
  final TextEditingController controller;
  final void Function(String)? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      autofillHints: const [AutofillHints.oneTimeCode],
      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: 8),
      validator: (v) => RegExp(r'^\d{6}$').hasMatch(v ?? '') ? null : 'Enter the 6-digit code from your email',
      onFieldSubmitted: onSubmitted,
      decoration: const InputDecoration(hintText: '••••••', counterText: ''),
    );
  }
}

/// "Resend code" text button with a cooldown so users can't spam emails.
class ResendCodeButton extends StatefulWidget {
  const ResendCodeButton({super.key, required this.onResend, this.startCoolingDown = true});
  final Future<void> Function() onResend;
  final bool startCoolingDown;
  @override
  State<ResendCodeButton> createState() => _ResendCodeButtonState();
}

class _ResendCodeButtonState extends State<ResendCodeButton> {
  static const _cooldown = 60;
  int _left = 0;
  bool _busy = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.startCoolingDown) _start();
  }

  void _start() {
    _timer?.cancel();
    setState(() => _left = _cooldown);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _left--);
      if (_left <= 0) t.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _tap() async {
    setState(() => _busy = true);
    try {
      await widget.onResend();
      if (mounted) {
        showToast(context, 'New code sent. Check your inbox.');
        _start();
      }
    } catch (e) {
      if (mounted) showToast(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sf;
    final waiting = _left > 0 || _busy;
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text("Didn't get the code?", style: TextStyle(color: c.muted)),
      TextButton(
        onPressed: waiting ? null : _tap,
        child: Text(
          _left > 0 ? 'Resend in ${_left}s' : 'Resend',
          style: TextStyle(color: waiting ? c.muted : c.brand, fontWeight: FontWeight.w700),
        ),
      ),
    ]);
  }
}

/// Confirms a new account with the code from the email. Pops `true` when the
/// email is verified.
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key, required this.email, this.justSent = true});
  final String email;
  final bool justSent;
  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _form = GlobalKey<FormState>();
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    FocusScope.of(context).unfocus();
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await context.read<AuthProvider>().verifySignupCode(widget.email, _code.text);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sf;
    return AuthScaffold(
      showBack: true,
      icon: Icons.mark_email_unread_outlined,
      title: 'Verify Your Email',
      subtitle: 'Enter the 6-digit code we sent to ${widget.email}.',
      children: [
        if (_error != null) InlineAlert(message: _error!),
        SfCard(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
          child: Form(
            key: _form,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const FieldLabel('Verification Code', icon: Icons.pin_outlined),
              CodeField(controller: _code, onSubmitted: (_) => _verify()),
              const SizedBox(height: 18),
              PrimaryButton(label: 'Verify', icon: Icons.verified_outlined, busy: _busy, onTap: _verify),
            ]),
          ),
        ),
        const SizedBox(height: 14),
        ResendCodeButton(
          startCoolingDown: widget.justSent,
          onResend: () => context.read<AuthProvider>().resendSignupCode(widget.email),
        ),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.info_outline_rounded, size: 15, color: c.muted),
          const SizedBox(width: 6),
          Flexible(child: Text('Check your Spam folder if you can’t find it.', style: context.tt.bodySmall)),
        ]),
      ],
    );
  }
}
