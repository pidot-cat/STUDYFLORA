import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common.dart';
import 'auth_widgets.dart';
import 'verify_email_screen.dart';

/// FR-1.4 — Forgot Password with a one-time code (OTP), one clear step at a
/// time:
///   1) enter email → a code is emailed
///   2) enter the code
///   3) choose a new password
///   4) done → back to login
/// In demo mode (no Supabase) there is no email, so step 2 is skipped.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});
  final String initialEmail;
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

enum _Step { email, code, password, done }

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailForm = GlobalKey<FormState>();
  final _codeForm = GlobalKey<FormState>();
  final _pwForm = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail);
  final _code = TextEditingController();
  final _pw = TextEditingController();
  final _pw2 = TextEditingController();
  late final AuthProvider _auth = context.read<AuthProvider>();
  _Step _step = _Step.email;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    // Closed after the code was accepted but before saving a password:
    // drop the temporary recovery session.
    if (_step == _Step.password) _auth.service.cancelRecovery();
    for (final c in [_email, _code, _pw, _pw2]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _go(_Step s) => setState(() {
        _step = s;
        _error = null;
      });

  void _sendCode() {
    if (!_emailForm.currentState!.validate()) return;
    _run(() async {
      await _auth.sendReset(_email.text);
      _code.clear();
      if (mounted) _go(_auth.demoMode ? _Step.password : _Step.code);
    });
  }

  void _verifyCode() {
    if (!_codeForm.currentState!.validate()) return;
    _run(() async {
      await _auth.verifyResetCode(_email.text, _code.text);
      if (mounted) _go(_Step.password);
    });
  }

  void _savePassword() {
    if (!_pwForm.currentState!.validate()) return;
    _run(() async {
      if (_auth.demoMode) {
        await _auth.service.setLocalPassword(_email.text, _pw.text);
      } else {
        await _auth.setNewPassword(_pw.text);
      }
      if (mounted) _go(_Step.done);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sf;
    final demo = context.watch<AuthProvider>().demoMode;
    final email = _email.text.trim();
    final total = demo ? 2 : 3;

    Widget stepLabel(int n) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var i = 1; i <= total; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == n ? 26 : 10,
                height: 6,
                decoration: BoxDecoration(color: i <= n ? c.brand : c.line, borderRadius: BorderRadius.circular(99)),
              ),
            const SizedBox(width: 8),
            Text('Step $n of $total', style: context.tt.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
          ]),
        );

    switch (_step) {
      case _Step.done:
        return AuthScaffold(
          icon: Icons.verified_rounded,
          title: 'Password Updated',
          subtitle: 'Your new password is saved. Log in with it to continue.',
          children: [
            PrimaryButton(label: 'Back to Login', icon: Icons.login_rounded, onTap: () => Navigator.of(context).popUntil((r) => r.isFirst)),
          ],
        );

      case _Step.password:
        return AuthScaffold(
          showBack: true,
          icon: Icons.lock_reset_rounded,
          title: 'Set New Password',
          subtitle: 'Choose a new password for $email.',
          children: [
            stepLabel(total),
            if (_error != null) InlineAlert(message: _error!),
            SfCard(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
              child: Form(
                key: _pwForm,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const FieldLabel('New Password', icon: Icons.lock_outline_rounded),
                  PasswordField(controller: _pw, hint: 'At least 8 characters', validator: validatePassword),
                  const SizedBox(height: 14),
                  const FieldLabel('Confirm Password', icon: Icons.lock_reset_rounded),
                  PasswordField(
                    controller: _pw2,
                    hint: 'Re-enter password',
                    validator: (v) => v != _pw.text ? 'Passwords do not match' : null,
                    onSubmitted: (_) => _savePassword(),
                  ),
                  const SizedBox(height: 18),
                  PrimaryButton(label: 'Save Password', icon: Icons.check_rounded, busy: _busy, onTap: _savePassword),
                ]),
              ),
            ),
          ],
        );

      case _Step.code:
        return AuthScaffold(
          showBack: true,
          icon: Icons.mark_email_unread_outlined,
          title: 'Enter Your Code',
          subtitle: 'We sent a reset code to $email. Type it below.',
          children: [
            stepLabel(2),
            if (_error != null) InlineAlert(message: _error!),
            SfCard(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
              child: Form(
                key: _codeForm,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const FieldLabel('Reset Code', icon: Icons.pin_outlined),
                  CodeField(controller: _code, onSubmitted: (_) => _verifyCode()),
                  const SizedBox(height: 18),
                  PrimaryButton(label: 'Verify Code', icon: Icons.verified_outlined, busy: _busy, onTap: _verifyCode),
                ]),
              ),
            ),
            const SizedBox(height: 14),
            ResendCodeButton(onResend: () => _auth.sendReset(email)),
            TextButton(
              onPressed: _busy ? null : () => _go(_Step.email),
              child: Text('Use a different email', style: TextStyle(color: c.brand, fontWeight: FontWeight.w600)),
            ),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.info_outline_rounded, size: 15, color: c.muted),
              const SizedBox(width: 6),
              Flexible(child: Text('No email? Check Spam, and make sure this is the email you signed up with.', style: context.tt.bodySmall)),
            ]),
          ],
        );

      case _Step.email:
        return AuthScaffold(
          showBack: true,
          icon: Icons.key_rounded,
          title: 'Forgot Password?',
          subtitle: demo
              ? 'Enter the email you registered with to choose a new password.'
              : 'Enter the email you registered with. We will email you a code to reset your password.',
          children: [
            stepLabel(1),
            if (_error != null) InlineAlert(message: _error!),
            SfCard(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
              child: Form(
                key: _emailForm,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const FieldLabel('Email Address', icon: Icons.mail_outline_rounded),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    validator: validateEmail,
                    onFieldSubmitted: (_) => _sendCode(),
                    decoration: const InputDecoration(hintText: 'example@email.com'),
                  ),
                  const SizedBox(height: 18),
                  PrimaryButton(label: demo ? 'Continue' : 'Send Code', icon: Icons.send_rounded, busy: _busy, onTap: _sendCode),
                ]),
              ),
            ),
            const SizedBox(height: 14),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.shield_outlined, size: 15, color: c.muted),
              const SizedBox(width: 6),
              Text('Codes expire after a short time for your security.', style: context.tt.bodySmall),
            ]),
          ],
        );
    }
  }
}
