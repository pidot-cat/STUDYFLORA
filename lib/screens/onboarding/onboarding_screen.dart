import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../nav.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../shell/main_shell.dart';

/// Three-slide onboarding (designed in light mode).
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pc = PageController();
  int _page = 0;

  static const _heading = Color(0xFF16432F);

  void _finish() {
    context.read<AppState>().completeOnboarding();
    MainShell.controller.value = ShellRequest(0, true);
    goRoot(context, const MainShell());
  }

  void _next() {
    if (_page == 2) return _finish();
    _pc.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
  }

  void _prev() => _pc.previousPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOut);

  @override
  Widget build(BuildContext context) {
    final bg = _page == 2 ? const Color(0xFFF1F6F2) : (_page == 1 ? const Color(0xFFF1F3F1) : const Color(0xFFF3F6FC));
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(color: Color(0xFFCDEBD8), shape: BoxShape.circle),
                child: const Icon(Icons.eco_outlined, size: 18, color: _heading),
              ),
              const SizedBox(width: 10),
              Text('StudyFlora', style: T.serif(22, c: _heading)),
              const Spacer(),
              if (_page < 2)
                GestureDetector(
                  onTap: _finish,
                  child: Text('Skip', style: T.p(15, c: const Color(0xFF475569))),
                ),
            ]),
          ),
          SizedBox(height: _page == 2 ? 60 : 18),
          _Dots(page: _page),
          Expanded(
            child: PageView(
              controller: _pc,
              onPageChanged: (i) => setState(() => _page = i),
              children: const [_Slide1(), _Slide2(), _Slide3()],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
            child: _ContinueButton(
              label: _page == 2 ? 'Get Started' : 'Continue',
              arrow: _page == 2,
              onTap: _next,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 22,
            child: _page == 0
                ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.wb_sunny_outlined, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Text('Deep focus made mindful and natural', style: T.p(12.5, c: const Color(0xFF64748B))),
                  ])
                : GestureDetector(
                    onTap: _prev,
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.chevron_left, size: 16, color: Color(0xFF475569)),
                      const SizedBox(width: 4),
                      Text('Previous slide', style: T.p(12.5, c: const Color(0xFF475569))),
                    ]),
                  ),
          ),
          const SizedBox(height: 18),
        ]),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  final int page;
  const _Dots({required this.page});
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      for (var i = 0; i < 3; i++)
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: i == page ? 24 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: i == page ? const Color(0xFF1F5A3D) : const Color(0xFFD5E6DB),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
    ]);
  }
}

class _ContinueButton extends StatelessWidget {
  final String label;
  final bool arrow;
  final VoidCallback onTap;
  const _ContinueButton({required this.label, required this.arrow, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1F5A3D),
      borderRadius: BorderRadius.circular(40),
      elevation: 6,
      shadowColor: const Color(0xFF1F5A3D).withValues(alpha: .4),
      child: InkWell(
        borderRadius: BorderRadius.circular(40),
        onTap: onTap,
        child: SizedBox(
          height: 56,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(label, style: T.p(16, w: arrow ? FontWeight.w500 : FontWeight.w700, c: Colors.white)),
            if (arrow) ...[const SizedBox(width: 10), const Icon(Icons.arrow_forward, color: Colors.white, size: 20)],
          ]),
        ),
      ),
    );
  }
}

BoxDecoration _cardDeco() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 24, offset: Offset(0, 8))],
    );

class _Slide1 extends StatelessWidget {
  const _Slide1();
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Container(
        decoration: _cardDeco(),
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset('assets/images/onboarding_greenhouse.png', fit: BoxFit.cover, width: double.infinity),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(color: const Color(0xFFCFF3DD), borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.contrast, size: 13, color: Color(0xFF16432F)),
              const SizedBox(width: 6),
              Text('MINDFUL FOCUS', style: T.p(11, w: FontWeight.w700, c: const Color(0xFF16432F), ls: .5)),
            ]),
          ),
          const SizedBox(height: 12),
          Text('Welcome to StudyFlora',
              textAlign: TextAlign.center, style: T.p(23, w: FontWeight.w700, c: const Color(0xFF0F2B20))),
          const SizedBox(height: 10),
          Text(
              'Spend your earned coins on garden items, nurture your flowers as they grow, and harvest XP to level up.',
              textAlign: TextAlign.center,
              style: T.p(13.5, c: const Color(0xFF475569), h: 1.6)),
          const SizedBox(height: 18),
          Row(children: const [
            Expanded(child: _FeatureChip(Icons.payments_outlined, 'Earn Coins')),
            SizedBox(width: 10),
            Expanded(child: _FeatureChip(Icons.water_drop_outlined, 'Grow Plants')),
            SizedBox(width: 10),
            Expanded(child: _FeatureChip(Icons.emoji_events_outlined, 'Level Up XP')),
          ]),
        ]),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureChip(this.icon, this.label);
  @override
  Widget build(BuildContext context) => Container(
        height: 68,
        decoration: BoxDecoration(
          color: const Color(0xFFEDF8F1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFCDEBD8)),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 20, color: const Color(0xFF16432F)),
          const SizedBox(height: 6),
          Text(label, style: T.p(11.5, w: FontWeight.w600, c: const Color(0xFF16432F))),
        ]),
      );
}

class _Slide2 extends StatelessWidget {
  const _Slide2();
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 18, 32, 16),
      child: Container(
        decoration: _cardDeco(),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(color: const Color(0xFFD7F2DF), borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.spa_outlined, size: 14, color: Color(0xFF16432F)),
              const SizedBox(width: 6),
              Text('A little focus . A little growth.', style: T.p(12, c: const Color(0xFF16432F))),
            ]),
          ),
          const SizedBox(height: 22),
          Image.asset('assets/images/onboarding_flowers.png', fit: BoxFit.cover),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(color: const Color(0xFFE8EDFB), borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.speed, size: 14, color: Color(0xFF1E293B)),
              const SizedBox(width: 6),
              Text('Quiz Master', style: T.p(12, w: FontWeight.w600, c: const Color(0xFF1E293B))),
            ]),
          ),
          const SizedBox(height: 16),
          Text('Make Learning Rewarding',
              textAlign: TextAlign.center, style: T.p(27, w: FontWeight.w700, c: const Color(0xFF1C4D35), h: 1.2)),
          const SizedBox(height: 14),
          Text(
              'Turn your study sessions into progress. Complete quizzes, track your scores, and build your learning streak.',
              textAlign: TextAlign.center,
              style: T.p(13.5, c: const Color(0xFF475569), h: 1.6)),
        ]),
      ),
    );
  }
}

class _Slide3 extends StatelessWidget {
  const _Slide3();
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 56, 24, 16),
      child: Container(
        decoration: _cardDeco(),
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Image.asset('assets/images/onboarding_pots.png', fit: BoxFit.cover, width: double.infinity),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 22, 10, 18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Welcome to\nStudyFlora', style: T.serif(28, c: const Color(0xFF16432F), h: 1.2)),
              const SizedBox(height: 12),
              Text(
                  'Spend your earned coins on garden items, nurture your flowers as they grow, and harvest XP to level up.',
                  style: T.p(14, c: const Color(0xFF475569), h: 1.6)),
            ]),
          ),
        ]),
      ),
    );
  }
}
