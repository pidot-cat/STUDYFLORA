import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../nav.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/visuals.dart';
import '../auth/create_account_screen.dart';
import '../auth/forgot_password_screen.dart';
import '../auth/sign_in_screen.dart';
import '../shell/main_shell.dart';

const _lvColors = [
  (Color(0xFFDDF5E6), Color(0xFF15803D)),
  (Color(0xFFFEF3C7), Color(0xFFB45309)),
  (Color(0xFFEDE9FE), Color(0xFF6D28D9)),
];

class SwitchAccountScreen extends StatelessWidget {
  const SwitchAccountScreen({super.key});

  Future<void> _manage(BuildContext context) async {
    final s = context.read<AppState>();
    await showModalBottomSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) {
        final others = s.signedInEmails.where((e) => e != s.currentEmail).toList();
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Accounts on This Device', style: T.p(16, w: FontWeight.w600)),
              const SizedBox(height: 10),
              if (others.isEmpty) Text('No other accounts saved on this device.', style: T.p(13)),
              for (final e in others)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(e, style: T.p(13.5)),
                  trailing: TextButton(
                    onPressed: () {
                      s.signedInEmails.remove(e);
                      setSt(() {});
                    },
                    child: const Text('Remove'),
                  ),
                ),
            ]),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = context.c;
    final emails = [
      if (s.currentEmail != null) s.currentEmail!,
      ...s.signedInEmails.where((e) => e != s.currentEmail),
    ];
    return Scaffold(
      backgroundColor: c.isDark ? c.bg : const Color(0xFFEFF7F1),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 14, 20, 28), children: [
          Row(children: [
            const CircleBackButton(),
            Expanded(
                child: Text('Switch Account',
                    textAlign: TextAlign.center, style: T.p(18, w: FontWeight.w600, c: c.heading))),
            const SizedBox(width: 40),
          ]),
          const SizedBox(height: 20),
          Row(children: [
            Icon(Icons.yard_outlined, size: 15, color: c.mintText),
            const SizedBox(width: 6),
            Text('PROFILES & GARDENS', style: T.p(12, w: FontWeight.w600, c: c.mintText, ls: .6)),
          ]),
          const SizedBox(height: 4),
          Text('Choose an account to continue studying and tending your flourishing digital greenhouse.',
              style: T.p(14, c: c.text, h: 1.5)),
          const SizedBox(height: 18),
          for (var i = 0; i < emails.length; i++) ...[
            _AccountCard(email: emails[i], active: emails[i] == s.currentEmail, colorIndex: i % 3),
            const SizedBox(height: 16),
          ],
          SFCard(
            radius: 18,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddAccountScreen())),
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              IconTile(Icons.person_add_alt,
                  size: 44, iconSize: 22, radius: 12, bg: c.isDark ? c.mint : const Color(0xFFCDF2DA)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Add Another Account', style: T.p(14.5, w: FontWeight.w600, c: c.heading)),
                  Text('Sign in with an existing StudyFlora profile', style: T.p(12, c: c.textMuted)),
                ]),
              ),
              Icon(Icons.chevron_right, color: c.textMuted),
            ]),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: c.isDark ? c.cardAlt : const Color(0xFFE2F7EA), borderRadius: BorderRadius.circular(16)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              IconTile(Icons.laptop_chromebook,
                  size: 28, iconSize: 16, radius: 6, bg: c.isDark ? c.mint : const Color(0xFFB9EDCA)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Seamless Progress Hand-off', style: T.p(12.5, w: FontWeight.w600, c: c.heading)),
                  const SizedBox(height: 4),
                  Text(
                      'Switching accounts preserves your local garden progress and offline study modules. Data syncs automatically once signed in.',
                      style: T.p(11.5, c: c.textMuted, h: 1.5)),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 28),
          Center(
            child: InkWell(
              onTap: () => _manage(context),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.manage_accounts_outlined, size: 16, color: c.heading),
                const SizedBox(width: 6),
                Text('Manage Accounts on This Device', style: T.p(12.5, w: FontWeight.w500, c: c.heading)),
              ]),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: InkWell(
              onTap: () async {
                await s.logoutAll();
                if (context.mounted) goRoot(context, const SignInScreen());
              },
              child: Text('Sign out of all accounts', style: T.p(12.5, c: const Color(0xFFE11D48))),
            ),
          ),
        ]),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final String email;
  final bool active;
  final int colorIndex;
  const _AccountCard({required this.email, required this.active, required this.colorIndex});
  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final c = context.c;
    final acc = s.accounts.firstWhere((a) => a.email == email, orElse: () => SavedAccount(email, 'StudyFlora', ''));
    final info = active ? {'xp': s.xp, 'pots': GardenRules.potCount, 'avatar': s.avatarId} : s.accountSummary(email);
    final xp = info['xp'] as int;
    final lv = Levels.level(xp);
    final avatar = AvatarOption.byId(info['avatar'] as String);
    final lvc = _lvColors[colorIndex];
    return Stack(clipBehavior: Clip.none, children: [
      SFCard(
        radius: 20,
        padding: const EdgeInsets.fromLTRB(14, 18, 14, 16),
        child: Row(children: [
          Stack(clipBehavior: Clip.none, children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                  shape: BoxShape.circle, color: lvc.$1, border: Border.all(color: lvc.$2.withValues(alpha: .3))),
              padding: const EdgeInsets.all(4),
              child: ClipOval(child: Image.asset(avatar.asset, fit: BoxFit.cover)),
            ),
            if (active)
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                      color: const Color(0xFF16A34A),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2)),
                  child: const Icon(Icons.eco, size: 9, color: Colors.white),
                ),
              ),
          ]),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(
                    child: Text(acc.name,
                        overflow: TextOverflow.ellipsis, style: T.p(16, w: FontWeight.w600, c: c.heading))),
                const SizedBox(width: 8),
                Pill('Lv. $lv',
                    fontSize: 11,
                    bg: lvc.$1,
                    fg: lvc.$2,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1)),
              ]),
              Text(email, overflow: TextOverflow.ellipsis, style: T.p(12, c: c.textMuted)),
              const SizedBox(height: 6),
              Row(children: [
                Pill('$xp${active ? ' / ${Levels.nextThreshold(xp)}' : ''} XP',
                    icon: Icons.bolt,
                    fontSize: 11,
                    weight: FontWeight.w500,
                    bg: c.isDark ? c.cardAlt : const Color(0xFFF2F4F3),
                    fg: c.text,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3)),
                const SizedBox(width: 8),
                Pill('${info['pots']} Pots',
                    icon: Icons.spa_outlined,
                    fontSize: 11,
                    weight: FontWeight.w500,
                    bg: c.isDark ? c.cardAlt : const Color(0xFFF2F4F3),
                    fg: c.text,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3)),
              ]),
            ]),
          ),
          if (active)
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(color: Color(0xFFCDF2DA), shape: BoxShape.circle),
              child: const Icon(Icons.check, size: 17, color: Color(0xFF15803D)),
            )
          else
            Material(
              color: c.isDark ? c.mint : const Color(0xFFE3F8EA),
              shape: const StadiumBorder(),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: () async {
                  await s.switchAccount(email);
                  MainShell.controller.value = ShellRequest(0, true);
                  if (context.mounted) goRoot(context, const MainShell());
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  child: Text('Switch', style: T.p(12.5, w: FontWeight.w600, c: c.heading)),
                ),
              ),
            ),
        ]),
      ),
      if (active)
        Positioned(
          right: 14,
          top: -10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(color: const Color(0xFF1B6B3F), borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              const Icon(Icons.check_circle, size: 13, color: Colors.white),
              const SizedBox(width: 4),
              Text('Current Active', style: T.p(11.5, w: FontWeight.w500, c: Colors.white)),
            ]),
          ),
        ),
    ]);
  }
}

class AddAccountScreen extends StatefulWidget {
  const AddAccountScreen({super.key});
  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _ob = true;
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    final s = context.read<AppState>();
    if (_email.text.trim().toLowerCase() == s.currentEmail) {
      setState(() => _error = 'This account is already signed in.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final r = await s.signIn(_email.text, _pass.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (r == AuthResult.ok) {
      MainShell.controller.value = ShellRequest(0, true);
      goRoot(context, const MainShell());
    } else {
      setState(() => _error =
          r == AuthResult.invalidEmail ? 'Please enter a valid email address.' : 'Incorrect email or password.');
    }
  }

  InputDecoration _deco(BuildContext context, String hint, IconData icon, {Widget? suffix}) {
    final c = context.c;
    return InputDecoration(
      hintText: hint,
      hintStyle: T.p(13, c: c.textFaint),
      filled: true,
      fillColor: c.isDark ? c.cardAlt : const Color(0xFFF2FAF5),
      prefixIcon: Icon(icon, size: 19, color: c.mintText),
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(vertical: 14),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.isDark ? c.border : const Color(0xFFD5EEDD))),
      focusedBorder:
          OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c.mintText)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.isDark ? c.bg : const Color(0xFFEFF7F1),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 14, 20, 28), children: [
          Row(children: [
            const CircleBackButton(),
            Expanded(
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.eco, size: 18, color: c.mintText),
                const SizedBox(width: 6),
                Text('Add Another Account', style: T.p(17, w: FontWeight.w600, c: c.heading)),
              ]),
            ),
            IconButton(
              onPressed: () => showSnack(context, 'Sign in with another StudyFlora account saved on this device.'),
              icon: Icon(Icons.help_outline, color: c.mintText),
            ),
          ]),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: c.isDark ? null : const LinearGradient(colors: [Color(0xFFE3F7EA), Color(0xFFF5FBF7)]),
              color: c.isDark ? c.card : null,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: c.isDark ? c.border : Colors.white),
            ),
            child: Row(children: [
              Stack(clipBehavior: Clip.none, children: [
                ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child:
                        Image.asset('assets/images/add_account_thumb.png', width: 64, height: 64, fit: BoxFit.cover)),
              ]),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Pill('Seamless Multi-Garden',
                      fontSize: 11.5,
                      weight: FontWeight.w500,
                      bg: c.isDark ? c.mint : const Color(0xFFCDF2DA),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2)),
                  const SizedBox(height: 4),
                  Text('Connect Another Account', style: T.p(18, w: FontWeight.w700, c: c.heading, h: 1.2)),
                  const SizedBox(height: 4),
                  Text('Sign in to sync your study decks, daily streaks, and floral terraces.',
                      style: T.p(12, c: c.textMuted, h: 1.4)),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 18),
          SFCard(
            radius: 24,
            padding: const EdgeInsets.all(22),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('Email Address', style: T.p(13, w: FontWeight.w600, c: c.heading)),
              const SizedBox(height: 8),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                style: T.p(13.5, c: c.text),
                decoration: _deco(context, 'e.g. name@email.com', Icons.mail_outline),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Text('Password', style: T.p(13, w: FontWeight.w600, c: c.heading)),
                const Spacer(),
                GestureDetector(
                  onTap: () =>
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                  child: Text('Forgot Password?', style: T.p(12, w: FontWeight.w500, c: c.mintText)),
                ),
              ]),
              const SizedBox(height: 8),
              TextField(
                controller: _pass,
                obscureText: _ob,
                style: T.p(13.5, c: c.text),
                decoration: _deco(context, 'Enter your account password', Icons.lock_outline,
                    suffix: IconButton(
                        onPressed: () => setState(() => _ob = !_ob),
                        icon: Icon(_ob ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 20, color: c.textFaint))),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: T.p(12, c: c.danger)),
              ],
              const SizedBox(height: 18),
              PrimaryButton('Sign In & Add Account',
                  trailingIcon: Icons.arrow_forward,
                  radius: 16,
                  fontSize: 14,
                  loading: _loading,
                  color: c.isDark ? c.primary : const Color(0xFF14533C),
                  onTap: _submit),
            ]),
          ),
          const SizedBox(height: 26),
          Row(children: [
            Expanded(child: Divider(color: c.border)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('OR CONNECT WITH', style: T.p(11.5, c: c.textFaint, ls: .6)),
            ),
            Expanded(child: Divider(color: c.border)),
          ]),
          const SizedBox(height: 16),
          OutlineButtonSF('Continue with Google',
              height: 46,
              radius: 16,
              fontSize: 13.5,
              fg: c.text,
              icon: Icons.g_mobiledata,
              onTap: () => showSnack(context, 'Google sign-in is not available in this offline build.')),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: c.isDark ? c.cardAlt : const Color(0xFFDDF5E6), borderRadius: BorderRadius.circular(16)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.verified_user_outlined, size: 18, color: c.mintText),
              const SizedBox(width: 10),
              Expanded(
                child: RichText(
                  text: TextSpan(style: T.p(12, c: c.text, h: 1.5), children: [
                    TextSpan(text: 'Multi-Account Isolation: ', style: T.p(12, w: FontWeight.w700, c: c.text)),
                    const TextSpan(
                        text:
                            'Adding this profile allows instant switching without clearing offline review flashcards or interrupting plant hydration cycles.'),
                  ]),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 22),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text("Don't have a second account?  ", style: T.p(12.5, c: c.textMuted)),
            GestureDetector(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateAccountScreen())),
              child: Text('Create a new student garden',
                  style: T.p(12.5, w: FontWeight.w600, c: c.mintText).copyWith(decoration: TextDecoration.underline)),
            ),
          ]),
        ]),
      ),
    );
  }
}

class LogoutScreen extends StatelessWidget {
  const LogoutScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = context.c;
    return Scaffold(
      backgroundColor: c.isDark ? c.bg : const Color(0xFFF1F7F3),
      body: SafeArea(
        bottom: false,
        child: Stack(children: [
          Positioned(
            right: -60,
            top: -40,
            child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(color: c.isDark ? c.card : const Color(0xFFDDF3E5), shape: BoxShape.circle)),
          ),
          ListView(padding: const EdgeInsets.fromLTRB(24, 14, 24, 28), children: [
            Row(children: [
              const CircleBackButton(size: 38),
              const SizedBox(width: 16),
              Text('Log Out', style: T.p(22, w: FontWeight.w600, c: c.heading)),
            ]),
            const SizedBox(height: 40),
            Center(child: AvatarRing(avatarAsset: s.avatar.asset, border: s.border.kind, size: 132)),
            const SizedBox(height: 4),
            Center(child: Text('Log Out', style: T.p(24, w: FontWeight.w700, c: c.heading))),
            const SizedBox(height: 10),
            Text("Are you sure you want to log out? You'll need to sign in again to access your account.",
                textAlign: TextAlign.center, style: T.p(13.5, c: c.textMuted, h: 1.6)),
            const SizedBox(height: 40),
            PrimaryButton('Log Out', color: c.isDark ? c.primary : const Color(0xFF1B3A2E), onTap: () async {
              await s.logout();
              if (context.mounted) goRoot(context, const SignInScreen());
            }),
            const SizedBox(height: 30),
            OutlineButtonSF('Cancel',
                borderColor: const Color(0xFF86C7A0),
                weight: FontWeight.w700,
                onTap: () => Navigator.of(context).pop()),
            const SizedBox(height: 90),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.link, size: 16, color: c.mintText),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                    'Your saved data remains on this device. Pending changes will sync when a connection is available.',
                    textAlign: TextAlign.center,
                    style: T.p(12, c: c.textMuted, h: 1.5)),
              ),
            ]),
          ]),
        ]),
      ),
    );
  }
}
