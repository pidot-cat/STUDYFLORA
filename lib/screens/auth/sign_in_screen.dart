import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/common.dart';
import 'auth_widgets.dart';
import 'forgot_password_screen.dart';
import 'sign_up_screen.dart';
import 'verify_email_screen.dart';

/// Login (FR-1.2). Right after signing up the screen says the new account is
/// ready; otherwise new users on this phone see "Welcome to StudyFlora!" and
/// returning users see "Welcome back!".
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});
  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pw = TextEditingController();
  String? _error;
  String? _info;
  bool _needsConfirm = false;
  bool _newAccount = false; // came back here from Sign Up

  @override
  void dispose() {
    _email.dispose();
    _pw.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _error = null;
      _info = null;
      _needsConfirm = false;
    });
    if (!_form.currentState!.validate()) return;
    final settings = context.read<SettingsProvider>();
    try {
      await context.read<AuthProvider>().signIn(_email.text, _pw.text);
      settings.markReturning();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _needsConfirm = _error!.contains('confirm your email');
        });
      }
    }
  }

  /// Unconfirmed account: send a fresh code and open the verify screen.
  Future<void> _confirmEmail() async {
    final auth = context.read<AuthProvider>();
    final email = _email.text.trim();
    var sent = true;
    try {
      await auth.resendSignupCode(email);
    } catch (e) {
      sent = false; // e.g. rate-limited: the earlier code may still work
      if (mounted) showToast(context, e.toString(), error: true);
    }
    if (!mounted) return;
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => VerifyEmailScreen(email: email, justSent: sent)),
    );
    if (ok == true && mounted) {
      setState(() {
        _error = null;
        _needsConfirm = false;
        _info = 'Email verified! You can log in now.';
        _newAccount = true;
      });
    }
  }

  Future<void> _openSignUp() async {
    final result = await Navigator.of(context).push<SignUpResult>(MaterialPageRoute(builder: (_) => const SignUpScreen()));
    if (result == null || !mounted) return;
    setState(() {
      _email.text = result.email;
      _pw.clear();
      _error = null;
      _info = result.message;
      _newAccount = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sf;
    final auth = context.watch<AuthProvider>();
    final returning = context.select<SettingsProvider, bool>((s) => s.returningUser);
    final offline = auth.demoMode && Env.hasSupabase; // keys set, but the cloud could not be reached at launch

    return AuthScaffold(
      title: _newAccount
          ? 'Your account is ready!'
          : returning
              ? 'Welcome back!'
              : 'Welcome to StudyFlora!',
      subtitle: _newAccount
          ? 'Log in with your new account to plant your first seed and start studying.'
          : returning
              ? 'Log in to pick up where you left off and keep your garden growing.'
              : 'Log in to start studying, earning rewards and growing your garden.',
      children: [
        if (_info != null) InlineAlert(message: _info!, error: false, icon: Icons.mark_email_read_outlined),
        if (offline && _error == null)
          const InlineAlert(
            icon: Icons.wifi_off_rounded,
            message: 'Can’t reach the server right now. Check your internet connection, then reopen the app.',
          ),
        if (_error != null) InlineAlert(message: _error!, icon: _error!.contains('internet') ? Icons.wifi_off_rounded : null),
        if (_needsConfirm) ...[
          SecondaryButton(label: 'Enter Verification Code', icon: Icons.pin_outlined, onTap: _confirmEmail),
          const SizedBox(height: 14),
        ],
        SfCard(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
          child: Form(
            key: _form,
            child: AutofillGroup(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
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
                PasswordField(
                  controller: _pw,
                  validator: (v) => (v ?? '').isEmpty ? 'Password is required' : null,
                  onSubmitted: (_) => _submit(),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ForgotPasswordScreen(initialEmail: _email.text.trim()))),
                    child: Text('Forgot Password?', style: TextStyle(color: c.brand, fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ),
                const SizedBox(height: 4),
                PrimaryButton(label: 'Login', icon: Icons.login_rounded, busy: auth.busy, onTap: _submit),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 22),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text("Don't have an account?", style: TextStyle(color: c.muted)),
          TextButton(
            onPressed: _openSignUp,
            child: Text('Sign Up', style: TextStyle(color: c.brand, fontWeight: FontWeight.w700)),
          ),
        ]),
      ],
    );
  }
}
