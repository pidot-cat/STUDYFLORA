import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header.dart';
import '../../widgets/common.dart';
import 'settings_screen.dart';

const supportEmail = 'studyflora.support@gmail.com';

Future<void> _mail(BuildContext context) async {
  final ok = await launchUrl(Uri.parse('mailto:$supportEmail'));
  if (!ok && context.mounted) showSnack(context, 'No email app found. Write to $supportEmail');
}

class _Sec {
  final String title, body;
  final List<String> bullets;
  final Widget Function(BuildContext)? extra;
  final bool highlight;
  const _Sec(this.title, this.body, {this.bullets = const [], this.extra, this.highlight = false});
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final secs = <_Sec>[
      const _Sec('Introduction',
          'StudyFlora respects your privacy. This Privacy Policy explains how your information is stored, used, and protected when you use the app.'),
      const _Sec('Information We Store',
          'StudyFlora stores information needed to maintain your account and learning progress, including:',
          bullets: [
            'Account profile information and identifiers',
            'Study module records and summaries',
            'Quiz history and scores',
            'Coins, XP, and inventory',
            'Garden state and plant progress',
            'Avatar border selections and app preferences',
          ]),
      const _Sec('Local Storage',
          'StudyFlora saves supported app data on your device so your progress remains available after closing or restarting the app. Original uploaded study files and their full extracted text are processed and stored on your device by default.',
          highlight: true),
      _Sec('Cloud Synchronization',
          'When an internet connection is available, supported records are synchronized with your authenticated StudyFlora account. Changes made offline are queued and synchronized when the connection returns. The app displays pending, successful, or failed synchronization states and provides a retry option for failed synchronization.',
          extra: (ctx) => Wrap(spacing: 8, children: [
                Pill('Pending',
                    dot: true,
                    fontSize: 11.5,
                    weight: FontWeight.w500,
                    bg: const Color(0xFFFFF6DD),
                    fg: const Color(0xFFB45309),
                    borderColor: const Color(0xFFF7DB8A)),
                Pill('Successful',
                    dot: true,
                    fontSize: 11.5,
                    weight: FontWeight.w500,
                    bg: const Color(0xFFE3F8EA),
                    fg: const Color(0xFF15803D),
                    borderColor: const Color(0xFFA7E3BD)),
                Pill('Failed',
                    dot: true,
                    fontSize: 11.5,
                    weight: FontWeight.w500,
                    bg: const Color(0xFFFFEEF0),
                    fg: const Color(0xFFE11D48),
                    borderColor: const Color(0xFFFBC4CC)),
              ])),
      const _Sec('Data Security',
          "StudyFlora uses account-based access controls to help prevent unauthorized access to other users' cloud records. Network communication uses encrypted transport to help protect information while it is being transmitted."),
      const _Sec('Data Retention and Deletion',
          'Data may remain stored locally or in your cloud account. Unsynchronized or local-only data may be lost if app data is cleared or your device is lost before synchronization succeeds. Before account deletion is implemented, StudyFlora will explain how deletion affects local data, cloud records, and pending changes.'),
      const _Sec('Your Choices',
          'You can manage available app preferences through Settings. Check your synchronization status before signing out if you have changes that have not yet synced.'),
      _Sec('Contact Us', 'For privacy questions or concerns, contact StudyFlora Support.',
          extra: (ctx) => Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                decoration: BoxDecoration(
                    color: const Color(0xFFEAF8EF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFC9EED6))),
                child: Row(children: [
                  const IconTile(Icons.mail_outline, size: 32, iconSize: 16, radius: 8, bg: Color(0xFFCDEFD9)),
                  const SizedBox(width: 10),
                  Expanded(
                      child:
                          Text('studyflora.support', style: T.p(12.5, w: FontWeight.w600, c: const Color(0xFF16302A)))),
                  Material(
                    color: const Color(0xFF14533C),
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _mail(ctx),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        child: Row(children: [
                          Text('Email', style: T.p(12.5, w: FontWeight.w500, c: Colors.white)),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right, size: 16, color: Colors.white),
                        ]),
                      ),
                    ),
                  ),
                ]),
              )),
    ];
    return Scaffold(
      backgroundColor: c.isDark ? c.bg : const Color(0xFFF1F7F3),
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          const TitleBar('Privacy Policy', divider: true),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 28), children: [
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c.isDark ? c.mint : const Color(0xFFE3F8EA),
                      border: Border.all(color: const Color(0xFF6EE7B7), width: 2)),
                  child: Icon(Icons.shield_outlined, size: 28, color: c.heading),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Pill('Last Updated: October 27, 2026',
                    dot: true,
                    fontSize: 12,
                    bg: c.isDark ? c.mint : const Color(0xFFE3F8EA),
                    fg: c.heading,
                    borderColor: const Color(0xFFA7E3BD),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5)),
              ),
              const SizedBox(height: 22),
              for (var i = 0; i < secs.length; i++) ...[
                _SectionCard(number: '${i + 1}', sec: secs[i], indent: true),
                const SizedBox(height: 18),
              ],
              const SizedBox(height: 20),
              const StudyResponsiblyFooter(),
            ]),
          ),
        ]),
      ),
    );
  }
}

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final secs = <_Sec>[
      const _Sec('Acceptance of Terms',
          'By using StudyFlora, you agree to these Terms of Service. If you do not agree, please discontinue using the app.'),
      const _Sec('Use of StudyFlora',
          'StudyFlora is an educational application designed to support studying through learning modules, quizzes, progress tracking, and virtual gardening features. You agree to use the app for its intended educational purposes.'),
      const _Sec('Account Responsibilities',
          'You are responsible for maintaining the security of your account and using your own account when accessing synchronized data. You should ensure your account information is accurate and protect your login credentials.'),
      _Sec('Study Materials and Uploaded Files',
          'You may upload supported study files to create or manage learning materials. Original uploaded files and their full extracted text are stored on your device by default. You are responsible for ensuring that you have permission to use any materials you upload.',
          extra: (ctx) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                    color: const Color(0xFFEAF8EF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFC9EED6))),
                child: Row(children: [
                  const Icon(Icons.phone_android, size: 15, color: Color(0xFF14533C)),
                  const SizedBox(width: 8),
                  Text('Stored securely on device by default',
                      style: T.serif(12, w: FontWeight.w400, c: const Color(0xFF16302A))),
                ]),
              )),
      const _Sec('Quiz Results and Learning Progress',
          'StudyFlora may store quiz history, scores, module records, and related learning progress. Results and progress are intended to help you track your learning and may depend on successful saving or synchronization.'),
      const _Sec('Coins, XP, Inventory, and Garden',
          "Coins, XP, inventory items, avatar borders, and garden progress are in-app features. Their balances and states are managed according to the app's implemented rules and may be stored locally and synchronized to your account when available."),
      const _Sec('Data Storage and Synchronization',
          'StudyFlora stores supported information locally and synchronizes eligible records with your authenticated account when an internet connection is available. Changes made offline may remain pending until synchronization resumes. Check the displayed sync status before signing out or changing accounts.'),
      const _Sec('Availability and Technical Issues',
          'Some features may be temporarily unavailable because of connectivity problems, synchronization failures, or technical issues. StudyFlora may provide status messages and retry options where supported. You should not assume that unsynchronized changes have been saved to the cloud.'),
      const _Sec('Acceptable Use',
          "You agree not to misuse the app, attempt to access another user's account or data, interfere with app functionality, or use StudyFlora in an unlawful manner."),
      const _Sec('Privacy',
          'Your use of StudyFlora is also subject to its Privacy Policy, which explains what information is stored, how synchronization works, and how information is handled.'),
      const _Sec('Changes to the App or Terms',
          "StudyFlora's features and these Terms may be updated as the application develops. Any applicable changes should be reflected in the version of the Terms presented to users."),
      _Sec('Contact Us', 'For questions about these Terms of Service, contact:',
          extra: (ctx) => Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: const Color(0xFFF6F8F7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE3EBE6))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const IconTile(Icons.person_outline, size: 24, iconSize: 14, circle: true, bg: Color(0xFFE3F2E8)),
                    const SizedBox(width: 8),
                    Text('StudyFlora Support', style: T.serif(13, c: const Color(0xFF16302A))),
                  ]),
                  const SizedBox(height: 10),
                  Material(
                    color: const Color(0xFF14432E),
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _mail(ctx),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        child: Row(children: [
                          const Icon(Icons.mail_outline, size: 16, color: Colors.white),
                          const SizedBox(width: 10),
                          Expanded(child: Text(supportEmail, style: T.p(12.5, c: Colors.white))),
                          const Icon(Icons.chevron_right, size: 16, color: Colors.white70),
                        ]),
                      ),
                    ),
                  ),
                ]),
              )),
    ];
    return Scaffold(
      backgroundColor: c.isDark ? c.bg : const Color(0xFFF1F7F3),
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          const TitleBar('Terms of Service'),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(20, 10, 20, 28), children: [
              Center(child: Image.asset('assets/images/tos_illustration.png', width: 92, height: 94)),
              const SizedBox(height: 12),
              Center(child: Text('Terms of Service', style: T.serif(22, c: c.heading))),
              const SizedBox(height: 8),
              Center(
                child: Pill('Last Updated: October 27, 2026',
                    dot: true,
                    fontSize: 12,
                    bg: c.isDark ? c.mint : const Color(0xFFE3F2E8),
                    fg: c.heading,
                    borderColor: const Color(0xFFC9E3D2),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5)),
              ),
              const SizedBox(height: 12),
              Text('Please read these terms carefully before exploring\nyour study garden.',
                  textAlign: TextAlign.center, style: T.serif(12.5, w: FontWeight.w400, c: c.textMuted)),
              const SizedBox(height: 22),
              for (var i = 0; i < secs.length; i++) ...[
                _SectionCard(number: (i + 1).toString().padLeft(2, '0'), sec: secs[i], serif: true),
                const SizedBox(height: 16),
              ],
              const SizedBox(height: 16),
              const StudyResponsiblyFooter(),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String number;
  final _Sec sec;
  final bool indent;
  final bool serif;
  const _SectionCard({required this.number, required this.sec, this.indent = false, this.serif = false});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final titleStyle = serif ? T.serif(15, c: c.heading) : T.j(16, w: FontWeight.w600, c: c.heading);
    final bodyStyle =
        serif ? T.serif(12.5, w: FontWeight.w400, c: c.textMuted, h: 1.6) : T.j(14, c: c.textMuted, h: 1.6);
    return SFCard(
      radius: 24,
      color: sec.highlight ? (c.isDark ? c.mint : const Color(0xFFEAF9F0)) : null,
      borderColor: sec.highlight ? const Color(0xFFA7E9C3) : null,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: c.isDark ? c.cardAlt : const Color(0xFFE3F2E8),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFC9E3D2))),
          child: Text(number, style: T.p(11.5, w: FontWeight.w600, c: c.heading)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(sec.title, style: titleStyle),
            const SizedBox(height: 8),
            Text(sec.body, style: bodyStyle),
            for (final b in sec.bullets) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                decoration: BoxDecoration(
                    color: c.isDark ? c.cardAlt : const Color(0xFFF2F7F3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: c.border)),
                child: Row(children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(color: Color(0xFFD7F5E2), shape: BoxShape.circle),
                    child: const Icon(Icons.check, size: 12, color: Color(0xFF15924F)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(b, style: T.j(13.5, c: c.text))),
                ]),
              ),
            ],
            if (sec.extra != null) ...[const SizedBox(height: 14), sec.extra!(context)],
          ]),
        ),
      ]),
    );
  }
}
