import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1900))..forward();

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final auth = context.read<AuthProvider>();
    final settings = context.read<SettingsProvider>();
    await Future.wait([
      auth.restore().catchError((_) {}),
      Future<void>.delayed(const Duration(milliseconds: 2000)),
    ]);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (_, __, ___) => settings.onboardingSeen ? const RootGate() : const OnboardingScreen(),
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
    ));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F9EC),
      body: LayoutBuilder(builder: (context, box) {
        // The splash art is 600×1297 and drawn with BoxFit.cover; map the
        // original progress-bar spot (x 150–438, y 1003) onto the screen.
        final scale = box.maxWidth / 600 > box.maxHeight / 1297 ? box.maxWidth / 600 : box.maxHeight / 1297;
        final dx = (box.maxWidth - 600 * scale) / 2;
        final dy = (box.maxHeight - 1297 * scale) / 2;
        return Stack(fit: StackFit.expand, children: [
        Image.asset('assets/images/splash.webp', fit: BoxFit.cover),
        Positioned(
          left: dx + 150 * scale,
          top: dy + 1003 * scale,
          child: SizedBox(
              width: 288 * scale,
              child: AnimatedBuilder(
                animation: _c,
                builder: (_, __) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: Curves.easeInOut.transform(_c.value),
                    minHeight: 12 * scale,
                    backgroundColor: const Color(0xFFDDEFD9),
                    color: const Color(0xFF2E9A62),
                  ),
                ),
              ),
            ),
          ),
      ]);
      }),
    );
  }
}
