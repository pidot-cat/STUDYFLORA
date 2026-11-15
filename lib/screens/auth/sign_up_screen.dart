import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common.dart';
import 'auth_widgets.dart';
import 'verify_email_screen.dart';

/// Returned to the Login screen after a successful sign-up.
class SignUpResult {
  final String email;
  final String message;
  const SignUpResult(this.email, this.message);
}

/// Sign Up (FR-1.1). On success the user is sent back to Login.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pw = TextEditingController();
  final _pw2 = TextEditingController();
  bool _agree = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _email, _pw, _pw2]) {
      c.dispose();
    }
    super.dispose();
  }

  static String? _validateUsername(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Username is required';
    if (s.length < 3 || s.length > 20) return 'Use 3–20 characters';
    if (!RegExp(r'^[A-Za-z0-9_.]+$').hasMatch(s)) return 'Letters, numbers, _ and . only';
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return;
    if (!_agree) {
      setState(() => _error = 'Please agree to the Terms of Service and Privacy Policy.');
      return;
    }
    try {
      final email = _email.text.trim();
      final r = await context.read<AuthProvider>().signUp(_name.text, email, _pw.text);
      if (!mounted) return;
      if (!r.needsCode) {
        Navigator.of(context).pop(SignUpResult(email, r.message));
        return;
      }
      final verified = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => VerifyEmailScreen(email: email)));
      if (!mounted) return;
      Navigator.of(context).pop(SignUpResult(
        email,
        verified == true
            ? 'Email verified! Log in with your new account.'
            : 'Almost done! Log in and enter the code from your email to verify your account.',
      ));
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sf;
    final auth = context.watch<AuthProvider>();
    return AuthScaffold(
      showBack: true,
      title: 'Sign Up',
      subtitle: 'Create your free account to start studying, earning rewards and growing your garden.',
      children: [
        if (_error != null) InlineAlert(message: _error!),
        SfCard(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
          child: Form(
            key: _form,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const FieldLabel('Username', icon: Icons.alternate_email_rounded),
              TextFormField(
                controller: _name,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.username],
                validator: _validateUsername,
                decoration: const InputDecoration(hintText: 'e.g. flora_learner'),
              ),
              const SizedBox(height: 14),
              const FieldLabel('Email Address', icon: Icons.mail_outline_rounded),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: validateEmail,
                decoration: const InputDecoration(hintText: 'example@email.com'),
              ),
              const SizedBox(height: 14),
              const FieldLabel('Password', icon: Icons.lock_outline_rounded),
              PasswordField(controller: _pw, hint: 'At least 8 characters', validator: validatePassword),
              const SizedBox(height: 14),
              const FieldLabel('Confirm Password', icon: Icons.lock_reset_rounded),
              PasswordField(
                controller: _pw2,
                hint: 'Re-enter password',
                validator: (v) => v != _pw.text ? 'Passwords do not match' : null,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 8),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => setState(() => _agree = !_agree),
                child: Row(children: [
                  Checkbox(
                    value: _agree,
                    activeColor: c.brand,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                    onChanged: (v) => setState(() => _agree = v ?? false),
                  ),
                  Expanded(child: Text('I agree to the Terms of Service and Privacy Policy.', style: context.tt.bodySmall)),
                ]),
              ),
              const SizedBox(height: 10),
              PrimaryButton(label: 'Sign Up', icon: Icons.person_add_alt_1_rounded, busy: auth.busy, onTap: _submit),
            ]),
          ),
        ),
        const SizedBox(height: 18),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('Already have an account?', style: TextStyle(color: c.muted)),
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: Text('Login', style: TextStyle(color: c.brand, fontWeight: FontWeight.w700)),
          ),
        ]),
      ],
    );
  }
}
