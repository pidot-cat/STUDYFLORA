import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../nav.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../auth/sign_in_screen.dart';
import '../shell/main_shell.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))
    ..forward();

  @override
  void initState() {
    super.initState();
    _ac.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        final st = context.read<AppState>();
        if (st.currentEmail == null) {
          goRoot(context, const SignInScreen());
        } else if (!st.onboardingDone) {
          goRoot(context, const OnboardingScreen());
        } else {
          goRoot(context, const MainShell());
        }
      }
    });
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The splash is designed in light mode only.
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-.75, -.8),
            radius: 1.1,
            colors: [Color(0xFFE3F5E8), Color(0xFFF5F7FE)],
          ),
        ),
        child: SafeArea(
          child: Column(children: [
            const SizedBox(height: 50),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFDDF3E5),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: const Color(0xFFC6E9D3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(color: Color(0xFF155E43), shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text('MINDFUL SPACE', style: T.j(11.5, w: FontWeight.w700, c: const Color(0xFF155E43), ls: .6)),
              ]),
            ),
            const SizedBox(height: 26),
            Container(
              width: 196,
              height: 196,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF1F6F3),
                boxShadow: [BoxShadow(color: const Color(0xFF155E43).withValues(alpha: .06), blurRadius: 30)],
              ),
              alignment: Alignment.center,
              child: Container(
                width: 176,
                height: 176,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  SizedBox(
                    width: 34,
                    height: 30,
                    child: Stack(alignment: Alignment.bottomCenter, children: [
                      const Positioned(
                          top: 0, child: Icon(Icons.local_fire_department, size: 18, color: Color(0xFFE8826B))),
                      Icon(Icons.menu_book_rounded, size: 22, color: const Color(0xFF155E43).withValues(alpha: .95)),
                    ]),
                  ),
                  const SizedBox(height: 10),
                  Text('StudyFlora', style: T.j(13, w: FontWeight.w600, c: const Color(0xFF155E43))),
                ]),
              ),
            ),
            const SizedBox(height: 28),
            Text('StudyFlora', style: T.j(32, w: FontWeight.w800, c: const Color(0xFF111827))),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: Text('Mindful study sessions, nurtured focus.',
                  textAlign: TextAlign.center, style: T.j(15, c: const Color(0xFF475569), h: 1.45)),
            ),
            const SizedBox(height: 40),
            Container(
              width: 54,
              height: 54,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Color(0x10000000), blurRadius: 12, offset: Offset(0, 3))],
              ),
              child: const Icon(Icons.local_drink_outlined, size: 20, color: Color(0xFF155E43)),
            ),
            const SizedBox(height: 18),
            Text('breathe & focus', style: T.j(13.5, c: const Color(0xFF64748B))),
            const SizedBox(height: 14),
            SizedBox(
              width: 192,
              child: AnimatedBuilder(
                animation: _ac,
                builder: (_, __) => ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: Curves.easeInOut.transform(_ac.value),
                    minHeight: 6,
                    backgroundColor: const Color(0xFFE2E6FA),
                    color: const Color(0xFF155E43),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.eco_outlined, size: 14, color: Color(0xFF155E43)),
              const SizedBox(width: 6),
              Text('Version 1.0  •  Study thoughtfully', style: T.j(12.5, c: const Color(0xFF64748B))),
            ]),
          ]),
        ),
      ),
    );
  }
}
