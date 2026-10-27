import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../nav.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../onboarding/onboarding_screen.dart';
import 'auth_widgets.dart';
import 'sign_in_screen.dart';

/// "Creating Your Account" – runs the sign up and routes to success / failure.
class AccountCreatingScreen extends StatefulWidget {
  final String name, email, password, confirm;
  const AccountCreatingScreen(
      {super.key, required this.name, required this.email, required this.password, required this.confirm});
  @override
  State<AccountCreatingScreen> createState() => _AccountCreatingScreenState();
}

class _AccountCreatingScreenState extends State<AccountCreatingScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
    ..repeat();

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    final st = context.read<AppState>();
    final online = await st.isOnline();
    AuthResult r = AuthResult.offline;
    if (online) r = await st.signUp(widget.name, widget.email, widget.password, widget.confirm);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => r == AuthResult.ok
          ? const AccountCreatedScreen()
          : AccountFailedScreen(
              retry: () => AccountCreatingScreen(
                  name: widget.name, email: widget.email, password: widget.password, confirm: widget.confirm)),
    ));
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthColors.bg,
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE8F4EC),
              boxShadow: [
                BoxShadow(color: const Color(0xFF86EFAC).withValues(alpha: .55), blurRadius: 50, spreadRadius: 8)
              ],
            ),
            alignment: Alignment.center,
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE3F2E8),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.spa, size: 30, color: Color(0xFF1F6B45)),
            ),
          ),
          const SizedBox(height: 22),
          Text('Creating Your Account', style: T.j(25, w: FontWeight.w700, c: const Color(0xFF111827))),
          const SizedBox(height: 12),
          Text('Please wait while we prepare your\nmindful study garden...',
              textAlign: TextAlign.center, style: T.j(14.5, c: const Color(0xFF64748B), h: 1.5)),
          const SizedBox(height: 46),
          SizedBox(
            width: 42,
            height: 42,
            child: Stack(alignment: Alignment.center, children: [
              RotationTransition(
                turns: _spin,
                child: const CircularProgressIndicator(
                  value: .3,
                  strokeWidth: 3,
                  color: Color(0xFF1F6B45),
                  backgroundColor: Color(0xFFDCEFE3),
                ),
              ),
              Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(color: Color(0xFFA7B8AE), shape: BoxShape.circle)),
            ]),
          ),
        ]),
      ),
    );
  }
}

class AccountCreatedScreen extends StatelessWidget {
  const AccountCreatedScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
          child: Column(children: [
            const SizedBox(height: 12),
            SizedBox(
              width: 88,
              height: 88,
              child: Stack(children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFF2F8F4),
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 14)],
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(color: Color(0xFFDFF1E6), shape: BoxShape.circle),
                    child: const Icon(Icons.local_florist_outlined, size: 22, color: Color(0xFF1F5A3D)),
                  ),
                ),
                Positioned(
                  right: 4,
                  top: 2,
                  child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(color: Color(0xFF34D399), shape: BoxShape.circle)),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            Text('Account Created!', style: T.j(28, w: FontWeight.w800, c: const Color(0xFF111827))),
            const SizedBox(height: 10),
            Text('Your StudyFlora account has been successfully created. Welcome to your mindful study journey.',
                textAlign: TextAlign.center, style: T.j(14.5, c: AuthColors.body, h: 1.55)),
            const Spacer(),
            Container(
              width: 176,
              height: 176,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF2FAF5),
                border: Border.all(color: const Color(0xFFCDEBD8)),
                boxShadow: [BoxShadow(color: const Color(0xFF86EFAC).withValues(alpha: .4), blurRadius: 40)],
              ),
              alignment: Alignment.center,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1C6B45), Color(0xFF2C8A5B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: const [BoxShadow(color: Color(0x30000000), blurRadius: 14, offset: Offset(0, 6))],
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 46),
              ),
            ),
            const Spacer(),
            Container(
              height: 54,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF1B4D35), Color(0xFF1F6440)]),
                borderRadius: BorderRadius.circular(40),
                boxShadow: const [BoxShadow(color: Color(0x401B4D35), blurRadius: 16, offset: Offset(0, 6))],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(40),
                  onTap: () => goRoot(context, const OnboardingScreen()),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('Continue to Onboarding', style: T.j(15.5, w: FontWeight.w600, c: Colors.white)),
                    const SizedBox(width: 10),
                    const Icon(Icons.arrow_forward, size: 17, color: Colors.white),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 60),
          ]),
        ),
      ),
    );
  }
}

class AccountFailedScreen extends StatelessWidget {
  final Widget Function() retry;
  const AccountFailedScreen({super.key, required this.retry});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(children: [
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(children: [
                  Container(
                    width: 112,
                    height: 112,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFEAF5EE),
                      border: Border.all(color: const Color(0xFFD7EEDF)),
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(color: Color(0xFFD3EEDD), shape: BoxShape.circle),
                      child: const Icon(Icons.spa, size: 30, color: Color(0xFF1F6B45)),
                    ),
                  ),
                  Positioned(
                    right: 2,
                    bottom: 6,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFFCA5B4), width: 1.5),
                      ),
                      child: const Icon(Icons.priority_high_rounded, color: AuthColors.red, size: 20),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 20),
              Text('Account Creation Failed', style: T.j(25, w: FontWeight.w700, c: const Color(0xFF111827))),
              const SizedBox(height: 12),
              Text('Something went wrong while setting up your garden sanctuary. Please try again in a moment.',
                  textAlign: TextAlign.center, style: T.j(14.5, c: AuthColors.body, h: 1.55)),
              const SizedBox(height: 26),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFBCFD7)),
                ),
                child: Row(children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(color: Color(0xFFFFDDE3), shape: BoxShape.circle),
                    child: const Icon(Icons.priority_high_rounded, color: AuthColors.red, size: 16),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text('Unable to create account. Please check your connection and try again.',
                        style: T.j(13.5, c: const Color(0xFF9F1239), h: 1.4)),
                  ),
                ]),
              ),
              const SizedBox(height: 32),
              AuthButton('Try Again',
                  trailingIcon: Icons.refresh,
                  color: AuthColors.create,
                  weight: FontWeight.w600,
                  onTap: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => retry()))),
              const SizedBox(height: 14),
              SizedBox(
                height: 52,
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFB6DDD0)),
                    shape: const StadiumBorder(),
                  ),
                  onPressed: () => goRoot(context, const SignInScreen()),
                  child: Text('Back to Sign In', style: T.j(15, w: FontWeight.w600, c: const Color(0xFF1F5A3D))),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
