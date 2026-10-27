import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../nav.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../onboarding/onboarding_screen.dart';
import '../shell/main_shell.dart';
import 'auth_widgets.dart';
import 'create_account_screen.dart';
import 'forgot_password_screen.dart';
import 'no_internet_screen.dart';

class SignInScreen extends StatefulWidget {
  /// When true (Add Another Account flow) a successful sign-in pops back.
  const SignInScreen({super.key});
  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _emailError;
  bool _authFailed = false;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final st = context.read<AppState>();
    setState(() {
      _emailError = AppState.validEmail(_email.text) ? null : 'Please enter a valid email address.';
      _authFailed = false;
    });
    if (_emailError != null) return;
    setState(() => _loading = true);
    if (!await st.isOnline()) {
      if (!mounted) return;
      setState(() => _loading = false);
      final retry = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const NoInternetScreen()));
      if (retry == true) _submit();
      return;
    }
    final r = await st.signIn(_email.text, _pass.text);
    if (!mounted) return;
    setState(() => _loading = false);
    switch (r) {
      case AuthResult.ok:
        MainShell.controller.value = ShellRequest(0, true);
        goRoot(context, st.onboardingDone ? const MainShell() : const OnboardingScreen());
        break;
      case AuthResult.invalidEmail:
        setState(() => _emailError = 'Please enter a valid email address.');
        break;
      default:
        setState(() => _authFailed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(children: [
            SizedBox(height: _authFailed ? 64 : 86),
            if (_authFailed)
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(color: Color(0xFFD7F0E0), shape: BoxShape.circle),
                child: const Icon(Icons.eco_outlined, size: 34, color: AuthColors.green),
              )
            else
              const AuthHeaderIcon(),
            SizedBox(height: _authFailed ? 22 : 18),
            Text('Welcome Back',
                style: T.j(_authFailed || _emailError != null ? 22 : 26,
                    w: _authFailed || _emailError != null ? FontWeight.w800 : FontWeight.w600, c: AuthColors.title)),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                  _authFailed
                      ? 'Sign in to continue your mindful study journey.'
                      : 'Sign in to continue your mindful study sessions and nurture your focus garden.',
                  textAlign: TextAlign.center,
                  style: T.j(14.5, c: _authFailed ? const Color(0xFF64748B) : AuthColors.body, h: 1.5)),
            ),
            SizedBox(height: _authFailed ? 18 : 22),
            if (_authFailed) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEDEA),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFAD0C9)),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.error, color: Color(0xFFE53935), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Incorrect email or password.\nPlease try again.',
                        style: T.j(13.5, c: const Color(0xFFDC2626), h: 1.4)),
                  ),
                ]),
              ),
              const SizedBox(height: 14),
            ],
            _form(),
            const SizedBox(height: 24),
            const QuietConsistencyCard(),
            const SizedBox(height: 32),
            AuthLinkRow(
              text: "Don't have an account?",
              link: 'Create Account',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateAccountScreen())),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _form() {
    final errorStyle = _emailError != null || _authFailed;
    final fields = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      AuthField(
        label: 'Email Address',
        trailingLabelIcon: errorStyle ? null : Icons.mail_outline,
        prefixIcon: errorStyle ? Icons.mail_outline : null,
        controller: _email,
        keyboard: TextInputType.emailAddress,
        whiteFill: errorStyle,
        error: _emailError,
        onChanged: (_) {
          if (_emailError != null) setState(() => _emailError = null);
        },
      ),
      const SizedBox(height: 18),
      AuthField(
        label: 'Password',
        trailingLabelIcon: errorStyle ? null : Icons.lock_outline,
        prefixIcon: errorStyle ? Icons.lock_outline : null,
        controller: _pass,
        obscure: _obscure,
        showEye: true,
        whiteFill: errorStyle,
        onToggleObscure: () => setState(() => _obscure = !_obscure),
      ),
      const SizedBox(height: 14),
      Align(
        alignment: Alignment.centerRight,
        child: GestureDetector(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
          child: Text('Forgot Password?', style: T.j(12.5, w: FontWeight.w700, c: AuthColors.link)),
        ),
      ),
      const SizedBox(height: 18),
      AuthButton('Sign In',
          icon: Icons.login_rounded, loading: _loading, loadingLabel: 'Signing In...', onTap: _submit),
    ]);
    if (errorStyle) return fields;
    return AuthCard(child: fields);
  }
}
