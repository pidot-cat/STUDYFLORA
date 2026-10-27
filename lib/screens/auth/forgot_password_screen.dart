import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../nav.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import 'auth_widgets.dart';
import 'sign_in_screen.dart';

const _cardBlue = Color(0xFFF1F4FD);

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  String? _error;
  bool _loading = false;

  Future<void> _send() async {
    if (!AppState.validEmail(_email.text)) {
      setState(() => _error = 'Please enter a valid email address.');
      return;
    }
    if (!context.read<AppState>().emailExists(_email.text)) {
      setState(() => _error = 'No StudyFlora account uses this email.');
      return;
    }
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ResetLinkSentScreen(email: _email.text.trim())));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthColors.bg,
      body: SafeArea(
        child: Column(children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF9F9FF),
              boxShadow: [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))],
            ),
            child: Row(children: [
              IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back, color: AuthColors.title)),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.eco_outlined, size: 16, color: AuthColors.green),
              ),
              const SizedBox(width: 12),
              Text('Sign In', style: T.j(17, w: FontWeight.w600, c: AuthColors.title)),
            ]),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 34, 20, 24),
              child: Column(children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(color: Color(0xFFD7F0E0), shape: BoxShape.circle),
                  child: const Icon(Icons.eco_outlined, size: 34, color: AuthColors.green),
                ),
                const SizedBox(height: 18),
                Text('Reset your key', style: T.j(26, w: FontWeight.w700, c: AuthColors.title)),
                const SizedBox(height: 10),
                Text("Enter your registered email address and we'll send you a link to reset your password.",
                    textAlign: TextAlign.center, style: T.j(14.5, c: AuthColors.body, h: 1.6)),
                const SizedBox(height: 22),
                AuthCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    AuthField(
                      label: 'Email Address',
                      hint: 'florastudy@gmail.com',
                      prefixIcon: Icons.mail_outline,
                      controller: _email,
                      keyboard: TextInputType.emailAddress,
                      error: _error,
                      onChanged: (_) => setState(() => _error = null),
                    ),
                    const SizedBox(height: 24),
                    AuthButton('Send Reset Link',
                        icon: Icons.send_outlined,
                        color: AuthColors.create,
                        loading: _loading,
                        loadingLabel: 'Sending...',
                        onTap: _send),
                  ]),
                ),
                const SizedBox(height: 24),
                _tip(Icons.info_outline, 'Make sure to use the same email associated with your account.'),
                const SizedBox(height: 32),
                _tip(Icons.spa_outlined,
                    'Take a mindful breath. Account access can always be nurtured back into bloom.'),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _tip(IconData icon, String text) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: _cardBlue, borderRadius: BorderRadius.circular(12)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 18, color: AuthColors.green),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: T.j(13, c: AuthColors.body, h: 1.55))),
        ]),
      );
}

class ResetLinkSentScreen extends StatelessWidget {
  final String email;
  const ResetLinkSentScreen({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(color: const Color(0xFFCDEFD9), borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.local_florist, size: 14, color: AuthColors.green),
                const SizedBox(width: 6),
                Text('Study Flora Account Security', style: T.j(12, w: FontWeight.w600, c: AuthColors.green)),
              ]),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 140),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: const BoxDecoration(color: Color(0xFFCDF2DA), shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: const BoxDecoration(color: Color(0xFFA8E6BE), shape: BoxShape.circle),
                        child: const Icon(Icons.mail, size: 34, color: AuthColors.green),
                      ),
                    ),
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                            color: const Color(0xFF3E7B54),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2)),
                        child: const Icon(Icons.check, size: 15, color: Colors.white),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 18),
                Text('Reset Link Sent', style: T.j(25, w: FontWeight.w600, c: AuthColors.title)),
                const SizedBox(height: 10),
                Text(
                    'A password reset link has been sent to your email address. Please check your inbox and follow the instructions to set a new password.',
                    textAlign: TextAlign.center,
                    style: T.j(14.5, c: AuthColors.body, h: 1.45)),
                const SizedBox(height: 22),
                // Offline build: tapping "Check Your Inbox" opens the reset form (stands in for the emailed link).
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () =>
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => SetNewPasswordScreen(email: email))),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: _cardBlue, borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(color: Color(0xFFA8E6BE), shape: BoxShape.circle),
                        child: const Icon(Icons.mark_email_unread, size: 18, color: AuthColors.green),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Check Your Inbox', style: T.j(15, w: FontWeight.w600, c: AuthColors.title)),
                          const SizedBox(height: 4),
                          Text(
                              'Please check your inbox (and spam folder) for the reset link. It may take 1-2 minutes to arrive.',
                              style: T.j(11, c: AuthColors.body, h: 1.5)),
                        ]),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 8)],
                  ),
                  child: Row(children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(color: Color(0xFFE8EDFB), shape: BoxShape.circle),
                      child: const Icon(Icons.schedule, size: 17, color: AuthColors.title),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Link valid for 15 minutes', style: T.j(12.5, w: FontWeight.w700, c: AuthColors.title)),
                        Text('For your study journal security', style: T.j(12, c: AuthColors.body)),
                      ]),
                    ),
                    GestureDetector(
                      onTap: () => ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(content: Text('Reset link re-sent.'))),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration:
                            BoxDecoration(color: const Color(0xFFB9EDCA), borderRadius: BorderRadius.circular(20)),
                        child: Text('Resend', style: T.j(13, w: FontWeight.w500, c: AuthColors.green)),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 46),
                AuthButton('Back to Sign In', onTap: () => goRoot(context, const SignInScreen())),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class SetNewPasswordScreen extends StatefulWidget {
  final String email;
  const SetNewPasswordScreen({super.key, required this.email});
  @override
  State<SetNewPasswordScreen> createState() => _SetNewPasswordScreenState();
}

class _SetNewPasswordScreenState extends State<SetNewPasswordScreen> {
  final _p1 = TextEditingController();
  final _p2 = TextEditingController();
  bool _o1 = true, _o2 = true;
  String? _error;

  Future<void> _reset() async {
    if (!AppState.strongPassword(_p1.text)) {
      setState(() => _error = 'Password must be at least 8 characters and include a number or special character.');
      return;
    }
    if (_p1.text != _p2.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    await context.read<AppState>().resetPassword(widget.email, _p1.text);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const PasswordResetSuccessScreen()));
  }

  Widget _field(String label, String hint, TextEditingController c, IconData icon, bool ob, VoidCallback toggle) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: T.j(15, w: FontWeight.w500, c: AuthColors.title)),
      const SizedBox(height: 10),
      TextField(
        controller: c,
        obscureText: ob,
        onChanged: (_) => setState(() => _error = null),
        style: T.j(15, w: FontWeight.w700, c: Colors.black),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: T.j(15, c: const Color(0xFF94A3B8)),
          filled: true,
          fillColor: Colors.white,
          prefixIcon: Icon(icon, color: AuthColors.title, size: 20),
          suffixIcon: IconButton(
              onPressed: toggle,
              icon: Icon(ob ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AuthColors.title)),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AuthColors.green)),
        ),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final strength = AppState.passwordStrength(_p1.text);
    final ready = _p1.text.isNotEmpty && _p1.text == _p2.text && AppState.strongPassword(_p1.text);
    final label = strength >= .85 ? 'Blooming' : (strength >= .5 ? 'Tender' : 'Seed');
    return Scaffold(
      backgroundColor: AuthColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 56, 22, 24),
          child: Column(children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(color: Color(0xFFB9EDCA), shape: BoxShape.circle),
              child: const Icon(Icons.lock, size: 30, color: AuthColors.green),
            ),
            const SizedBox(height: 20),
            Text('Reset Your Password', style: T.j(26, w: FontWeight.w600, c: AuthColors.title)),
            const SizedBox(height: 6),
            Text('Enter your new password below.', style: T.j(14.5, c: AuthColors.body)),
            const SizedBox(height: 34),
            _field(
                'New Password', 'Enter new password', _p1, Icons.lock_outline, _o1, () => setState(() => _o1 = !_o1)),
            const SizedBox(height: 22),
            _field('Confirm Password', 'Confirm new password', _p2, Icons.lock_reset, _o2,
                () => setState(() => _o2 = !_o2)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              decoration: BoxDecoration(color: const Color(0xFFEFF2FF), borderRadius: BorderRadius.circular(8)),
              child: Column(children: [
                Row(children: [
                  const Icon(Icons.eco_outlined, size: 13, color: AuthColors.green),
                  const SizedBox(width: 4),
                  Text('Seedling Strength', style: T.j(12, w: FontWeight.w500, c: AuthColors.body)),
                  const Spacer(),
                  Text(label, style: T.j(12, w: FontWeight.w700, c: AuthColors.green)),
                ]),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: strength == 0 ? .01 : strength,
                    minHeight: 5,
                    backgroundColor: const Color(0xFFDCE3F8),
                    color: AuthColors.green,
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 22),
            AuthButton(ready ? 'Reset Password' : 'Reset Password',
                icon: ready ? Icons.check : null, color: AuthColors.create, onTap: _reset),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, textAlign: TextAlign.center, style: T.j(12.5, c: AuthColors.red)),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFEFF2FF), borderRadius: BorderRadius.circular(12)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.schedule, size: 20, color: AuthColors.green),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Password must be at least 8 characters and include a number or special character.',
                      style: T.j(13, c: AuthColors.body, h: 1.5)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class PasswordResetSuccessScreen extends StatelessWidget {
  const PasswordResetSuccessScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 56),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              SizedBox(
                width: 140,
                height: 130,
                child: Stack(alignment: Alignment.center, children: [
                  Container(
                    width: 128,
                    height: 128,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFDDF7E6), boxShadow: [
                      BoxShadow(color: const Color(0xFF86EFAC).withValues(alpha: .5), blurRadius: 24),
                    ]),
                  ),
                  Container(
                      width: 96,
                      height: 96,
                      decoration: const BoxDecoration(color: Color(0xFFB4EDC8), shape: BoxShape.circle)),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(color: Color(0xFF1F5A3D), shape: BoxShape.circle),
                    child: const Icon(Icons.check_rounded, size: 34, color: Colors.white),
                  ),
                  const Positioned(right: 10, top: 6, child: Icon(Icons.eco, color: Color(0xFF1F5A3D), size: 22)),
                  const Positioned(left: 14, bottom: 12, child: Icon(Icons.spa, color: Color(0xFF3E7B54), size: 18)),
                ]),
              ),
              const SizedBox(height: 14),
              Text('Password Reset\nSuccessful!',
                  textAlign: TextAlign.center, style: T.j(25, w: FontWeight.w600, c: AuthColors.title, h: 1.25)),
              const SizedBox(height: 10),
              Text('Your password has been updated successfully. You can now step back into your mindful sanctuary.',
                  textAlign: TextAlign.center, style: T.j(14.5, c: AuthColors.body, h: 1.55)),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: _cardBlue, borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(color: Color(0xFFB4EDC8), shape: BoxShape.circle),
                    child: const Icon(Icons.verified_user, size: 18, color: AuthColors.green),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('All sessions protected', style: T.j(15, w: FontWeight.w600, c: AuthColors.title)),
                      Text('Other active logins have been safely signed out. Your study garden remains secure.',
                          style: T.j(12.5, c: AuthColors.body, h: 1.4)),
                    ]),
                  ),
                ]),
              ),
              const Spacer(),
              AuthButton('Back to Sign In', onTap: () => goRoot(context, const SignInScreen())),
              const SizedBox(height: 14),
              Text("Need assistance or didn't request this?", style: T.j(12.5, c: AuthColors.title)),
            ]),
          ),
        ),
      ),
    );
  }
}
