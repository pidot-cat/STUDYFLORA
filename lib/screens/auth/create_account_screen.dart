import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import 'account_status_screens.dart';
import 'auth_widgets.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});
  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  bool _ob1 = true, _ob2 = true;
  bool _emailInUse = false;
  String? _emailError;
  String? _passError;
  String? _confirmError;

  @override
  void dispose() {
    for (final c in [_name, _email, _pass, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    final st = context.read<AppState>();
    setState(() {
      _emailInUse = false;
      _emailError = AppState.validEmail(_email.text) ? null : 'Please enter a valid email address.';
      _passError = _pass.text.length >= 8 ? null : 'Password must be at least 8 characters.';
      _confirmError = _pass.text == _confirm.text ? null : 'Passwords do not match.';
    });
    if (_emailError != null || _passError != null || _confirmError != null) return;
    if (st.emailExists(_email.text)) {
      setState(() => _emailInUse = true);
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AccountCreatingScreen(
        name: _name.text,
        email: _email.text,
        password: _pass.text,
        confirm: _confirm.text,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(children: [
            SizedBox(height: _emailInUse ? 40 : 88),
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(color: Color(0xFFDDF5E6), shape: BoxShape.circle),
              child: const Icon(Icons.spa_outlined, size: 28, color: AuthColors.green),
            ),
            const SizedBox(height: 18),
            Text('Create Account', style: T.j(26, w: FontWeight.w600, c: AuthColors.title)),
            const SizedBox(height: 6),
            Text('Join Study Flora to cultivate your focus', style: T.j(14.5, c: AuthColors.body)),
            const SizedBox(height: 22),
            if (_emailInUse) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEEF1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFF7A8B8)),
                ),
                child: Row(children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(color: AuthColors.red, shape: BoxShape.circle),
                    child: const Icon(Icons.priority_high_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('This email is already registered.',
                          style: T.j(13.5, w: FontWeight.w700, c: const Color(0xFF9F1239))),
                      const SizedBox(height: 4),
                      Text('Please sign in or use a different email.', style: T.j(12, c: const Color(0xFFBE123C))),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 22),
            ],
            AuthCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                AuthField(
                  label: 'Username',
                  labelIcon: Icons.person_outline,
                  hint: 'Jane Doe',
                  controller: _name,
                ),
                const SizedBox(height: 16),
                AuthField(
                  label: 'Email Address',
                  labelIcon: Icons.mail_outline,
                  hint: 'you@example.com',
                  controller: _email,
                  keyboard: TextInputType.emailAddress,
                  rightLabel: _emailInUse ? 'Already in use' : null,
                  error: _emailError,
                  onChanged: (_) {
                    if (_emailInUse || _emailError != null) {
                      setState(() {
                        _emailInUse = false;
                        _emailError = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                AuthField(
                  label: 'Password',
                  labelIcon: Icons.lock_outline,
                  hint: 'Create a secure password',
                  controller: _pass,
                  obscure: _ob1,
                  showEye: true,
                  error: _passError,
                  onToggleObscure: () => setState(() => _ob1 = !_ob1),
                ),
                const SizedBox(height: 16),
                AuthField(
                  label: 'Confirm Password',
                  labelIcon: Icons.lock_outline,
                  hint: 'Confirm your password',
                  controller: _confirm,
                  obscure: _ob2,
                  showEye: true,
                  error: _confirmError,
                  onToggleObscure: () => setState(() => _ob2 = !_ob2),
                ),
                const SizedBox(height: 28),
                AuthButton('Create Account',
                    trailingIcon: Icons.spa_outlined,
                    color: AuthColors.create,
                    weight: FontWeight.w600,
                    onTap: _submit),
              ]),
            ),
            const SizedBox(height: 22),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const _Dot(),
              const SizedBox(width: 10),
              Text('MINDFUL STUDY SANCTUARY', style: T.j(11, w: FontWeight.w600, c: const Color(0xFF64748B), ls: .5)),
              const SizedBox(width: 10),
              const _Dot(),
            ]),
            const SizedBox(height: 12),
            AuthLinkRow(text: 'Already have an account?', link: 'Sign In', onTap: () => Navigator.of(context).pop()),
          ]),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();
  @override
  Widget build(BuildContext context) =>
      Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF86D9A5), shape: BoxShape.circle));
}
