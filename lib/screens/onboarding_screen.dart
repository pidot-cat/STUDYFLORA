import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../core/theme.dart';
import '../providers/settings_provider.dart';
import '../widgets/common.dart';

class _Page {
  final String chip;
  final IconData chipIcon;
  final String title;
  final String body;
  final Widget Function(BuildContext) art;
  final List<(IconData, String)> features;
  const _Page(this.chip, this.chipIcon, this.title, this.body, this.art, this.features);
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pc = PageController();
  int _i = 0;

  late final _pages = <_Page>[
    _Page('MINDFUL FOCUS', Icons.spa_outlined, 'Welcome to StudyFlora',
        'Spend your earned coins on garden items, nurture your flowers as they grow, and harvest XP to level up.',
        (_) => const _ArtImage(tag: 'Flora Garden Tier 1', reward: '+150 XP'),
        [(Icons.payments_outlined, 'Earn Coins'), (Icons.water_drop_outlined, 'Grow Plants'), (Icons.emoji_events_outlined, 'Level Up XP')]),
    _Page('SMART REVIEWER', Icons.auto_stories_outlined, 'Upload. Review. Quiz.',
        'Upload your PDF, DOCX or TXT notes. StudyFlora pulls out key points, builds a practice quiz, and rewards verified modules.',
        (_) => const _ArtReviewer(),
        [(Icons.upload_file_rounded, 'Upload'), (Icons.lightbulb_outline_rounded, 'Key Points'), (Icons.quiz_outlined, '10-Q Quiz')]),
    _Page('MILESTONES', Icons.flag_outlined, 'Watch your garden bloom',
        'Every flower grows in three stages — seed, sprout and full bloom. Keep it watered, then tap to claim your XP and badges.',
        (_) => const _ArtStages(),
        [(Icons.grass_rounded, 'Seed'), (Icons.eco_outlined, 'Sprout'), (Icons.local_florist_outlined, 'Bloom')]),
  ];

  void _finish() {
    context.read<SettingsProvider>().finishOnboarding();
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const RootGate()));
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sf;
    final last = _i == _pages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 12, 0),
            child: Row(children: [
              IconTile(Icons.spa_rounded, size: 40, bg: c.brandSoft),
              const SizedBox(width: 10),
              Text('StudyFlora', style: TextStyle(fontFamily: 'DMSerif', fontSize: 24, color: context.isDark ? c.ink : c.brand)),
              const Spacer(),
              TextButton(onPressed: _finish, child: Text('Skip', style: TextStyle(color: c.muted, fontWeight: FontWeight.w600))),
            ]),
          ),
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var k = 0; k < _pages.length; k++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: k == _i ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(color: k == _i ? c.brand : c.line, borderRadius: BorderRadius.circular(9)),
              ),
          ]),
          Expanded(
            child: PageView.builder(
              controller: _pc,
              itemCount: _pages.length,
              onPageChanged: (v) => setState(() => _i = v),
              itemBuilder: (context, k) => _PageView(page: _pages[k]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
            child: PrimaryButton(
              label: last ? 'Get Started' : 'Continue',
              icon: last ? Icons.spa_rounded : null,
              onTap: () => last ? _finish() : _pc.nextPage(duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 14, top: 4),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.wb_sunny_outlined, size: 14, color: c.muted),
              const SizedBox(width: 6),
              Text('Deep focus made mindful and natural', style: context.tt.bodySmall),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _PageView extends StatelessWidget {
  const _PageView({required this.page});
  final _Page page;
  @override
  Widget build(BuildContext context) {
    final c = context.sf;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: SfCard(
        radius: 26,
        padding: const EdgeInsets.all(14),
        child: Column(children: [
          ClipRRect(borderRadius: BorderRadius.circular(18), child: SizedBox(height: 220, width: double.infinity, child: page.art(context))),
          const SizedBox(height: 18),
          StatusBadge(page.chip, icon: page.chipIcon),
          const SizedBox(height: 12),
          Text(page.title, style: context.tt.headlineMedium?.copyWith(fontSize: 24), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(page.body, style: context.tt.bodyMedium?.copyWith(color: c.muted), textAlign: TextAlign.center),
          const SizedBox(height: 18),
          Row(children: [
            for (final f in page.features)
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: c.surfaceAlt,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: c.brandSoft),
                  ),
                  child: Column(children: [
                    Icon(f.$1, color: c.brand, size: 22),
                    const SizedBox(height: 6),
                    Text(f.$2, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5), textAlign: TextAlign.center),
                  ]),
                ),
              ),
          ]),
          const SizedBox(height: 4),
        ]),
      ),
    );
  }
}

class _ArtImage extends StatelessWidget {
  const _ArtImage({required this.tag, required this.reward});
  final String tag;
  final String reward;
  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: [
      Image.asset('assets/images/garden_day.webp', fit: BoxFit.cover, alignment: const Alignment(0, -0.35)),
      Positioned(
        top: 10,
        right: 10,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: const Color(0xFFBDF0CF), borderRadius: BorderRadius.circular(99)),
          child: Text(reward, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF0F4A2E))),
        ),
      ),
      Positioned(
        left: 10,
        bottom: 10,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.92), borderRadius: BorderRadius.circular(99)),
          child: Row(children: [
            const Icon(Icons.eco_outlined, size: 15, color: Color(0xFF1E4D3A)),
            const SizedBox(width: 6),
            Text(tag, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF12261C))),
          ]),
        ),
      ),
    ]);
  }
}

class _ArtReviewer extends StatelessWidget {
  const _ArtReviewer();
  @override
  Widget build(BuildContext context) {
    final c = context.sf;
    Widget doc(String ext, Color col, double angle) => Transform.rotate(
          angle: angle,
          child: Container(
            width: 74,
            height: 94,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: c.shadow, blurRadius: 12)]),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.description_rounded, color: col, size: 34),
              const SizedBox(height: 4),
              Text(ext, style: TextStyle(color: col, fontWeight: FontWeight.w800, fontSize: 12)),
            ]),
          ),
        );
    return Container(
      decoration: BoxDecoration(gradient: LinearGradient(colors: [c.surfaceAlt, c.brandSoft], begin: Alignment.topLeft, end: Alignment.bottomRight)),
      child: Stack(alignment: Alignment.center, children: [
        Positioned(left: 36, top: 44, child: doc('PDF', const Color(0xFFE5484D), -0.18)),
        Positioned(child: doc('DOCX', const Color(0xFF2B7BD6), 0)),
        Positioned(right: 36, top: 44, child: doc('TXT', const Color(0xFF1F8F5F), 0.18)),
        Positioned(bottom: 16, child: Image.asset('assets/plants/tulip_sprout.webp', height: 70)),
      ]),
    );
  }
}

class _ArtStages extends StatelessWidget {
  const _ArtStages();
  @override
  Widget build(BuildContext context) {
    final c = context.sf;
    return Container(
      decoration: BoxDecoration(gradient: LinearGradient(colors: [c.goldSoft, c.surfaceAlt], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
      padding: const EdgeInsets.fromLTRB(10, 16, 10, 18),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        for (final (img, label) in [
          ('assets/plants/rose_seed.webp', 'Seed'),
          ('assets/plants/rose_sprout.webp', 'Sprout'),
          ('assets/plants/rose_bloom.webp', 'Bloom'),
        ])
          Expanded(
            child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
              Image.asset(img, height: 120, fit: BoxFit.fitHeight),
              const SizedBox(height: 8),
              StatusBadge(label, dense: true),
            ]),
          ),
      ]),
    );
  }
}
