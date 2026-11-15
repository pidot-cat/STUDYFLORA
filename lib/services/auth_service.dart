import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants.dart';
import 'net.dart';
import 'storage_service.dart';

class AppUser {
  final String id;
  final String email;
  final String displayName;
  final bool isLocal; // true when running without Supabase keys (demo mode)
  const AppUser({required this.id, required this.email, required this.displayName, this.isLocal = false});
}

class AuthFailure implements Exception {
  final String message;
  AuthFailure(this.message);
  @override
  String toString() => message;
}

/// FR-1.x — Supabase Authentication. When no Supabase keys are configured the
/// service falls back to on-device demo accounts so the app can still be run
/// and graded; a banner on the sign-in screen makes that obvious.
class AuthService {
  AuthService(this._store);
  final StorageService _store;

  static const _localAccountsKey = 'sf.localAccounts';
  static const _localSessionKey = 'sf.localSession';

  bool get usesSupabase => Env.cloud;
  SupabaseClient get _sb => Supabase.instance.client;

  static Future<void> init() async {
    if (!Env.hasSupabase) return;
    try {
      await Supabase.initialize(url: Env.supabaseUrl, publishableKey: Env.supabaseAnonKey);
      Env.supabaseReady = true;
    } catch (e) {
      // Bad URL/key: keep the app usable in demo mode rather than crash.
      debugPrint('Supabase init failed, running in demo mode: $e');
      Env.supabaseReady = false;
    }
  }

  /// FR-1.5 — restore the persisted session (works offline).
  AppUser? currentUser() {
    if (usesSupabase) {
      final u = _sb.auth.currentUser;
      if (u == null) return null;
      return _fromSupabase(u);
    }
    final id = _store.getString(_localSessionKey);
    if (id == null) return null;
    final acc = _localAccounts().values.cast<Map>().where((a) => a['id'] == id).toList();
    if (acc.isEmpty) return null;
    final a = acc.first;
    return AppUser(id: id, email: a['email'] as String, displayName: a['name'] as String, isLocal: true);
  }

  /// Creates the account but does NOT sign in. When [needsCode] is true the
  /// user must enter the 6-digit code emailed to them (no links/redirects).
  Future<({String message, bool needsCode})> signUp({required String name, required String email, required String password}) async {
    _validateEmail(email);
    if (password.length < 8) throw AuthFailure('Password must be at least 8 characters.');
    await requireOnline();
    if (usesSupabase) {
      try {
        final res = await _sb.auth.signUp(email: email.trim(), password: password, data: {'display_name': name.trim()});
        final u = res.user;
        if (u == null) throw AuthFailure('Account could not be created. Please try again.');
        // Supabase hides "email already used" by returning a user with no identities.
        if (u.identities != null && u.identities!.isEmpty) {
          throw AuthFailure('An account with this email already exists. Please log in instead.');
        }
        if (res.session != null) {
          await _sb.auth.signOut();
          return (message: 'Account created! You can now log in.', needsCode: false);
        }
        return (message: 'We sent a verification code to ${email.trim()}.', needsCode: true);
      } on AuthException catch (e) {
        throw AuthFailure(_friendly(e.message));
      } on AuthFailure {
        rethrow;
      } catch (_) {
        throw AuthFailure(Net.offlineMessage);
      }
    }
    final accounts = _localAccounts();
    final key = email.trim().toLowerCase();
    if (accounts.containsKey(key)) throw AuthFailure('An account with this email already exists. Please log in instead.');
    final id = 'local-${sha256.convert(utf8.encode(key)).toString().substring(0, 16)}';
    accounts[key] = {'id': id, 'email': email.trim(), 'name': name.trim(), 'pw': _hash(password)};
    await _store.writeJson(_localAccountsKey, accounts);
    return (message: 'Account created! You can now log in.', needsCode: false);
  }

  /// Confirms a new account with the code from the "Confirm signup" email.
  /// The session it creates is closed right away; the user then logs in.
  Future<void> verifySignupCode(String email, String code) async {
    await _verify(email, code, OtpType.signup);
    await _quietSignOut();
  }

  Future<void> resendSignupCode(String email) => _guard(() => _sb.auth.resend(type: OtpType.signup, email: email.trim()));

  /// FR-1.4 — verify the recovery code, then save the new password.
  Future<void> resetPasswordWithCode({required String email, required String code, required String newPassword}) async {
    if (newPassword.length < 8) throw AuthFailure('Password must be at least 8 characters.');
    await _verify(email, code, OtpType.recovery);
    await _guard(() => _sb.auth.updateUser(UserAttributes(password: newPassword)));
    await _quietSignOut();
  }

  /// Forgot password, step 2: check the emailed code. On success the user is
  /// allowed to set a new password with [setNewPassword].
  Future<void> verifyRecoveryCode(String email, String code) => _verify(email, code, OtpType.recovery);

  /// Forgot password, step 3: save the new password (after the code was
  /// verified). Can be retried without asking for the code again.
  Future<void> setNewPassword(String newPassword) async {
    if (newPassword.length < 8) throw AuthFailure('Password must be at least 8 characters.');
    if (_sb.auth.currentSession == null) {
      throw AuthFailure('Your code has expired. Please go back and request a new code.');
    }
    await _guard(() => _sb.auth.updateUser(UserAttributes(password: newPassword)));
    await _quietSignOut();
  }

  /// Leaves the half-finished recovery session (user closed the screen).
  Future<void> cancelRecovery() async {
    if (usesSupabase) await _quietSignOut();
  }

  Future<void> _verify(String email, String code, OtpType type) async {
    final token = code.replaceAll(RegExp(r'\s'), '');
    if (!RegExp(r'^\d{6,8}$').hasMatch(token)) throw AuthFailure('Enter the code from your email.');
    await _guard(() => _sb.auth.verifyOTP(type: type, email: email.trim(), token: token));
  }

  /// Login, sign up and password recovery only work with internet.
  Future<void> requireOnline() async {
    if (!await Net.online()) throw AuthFailure(Net.offlineMessage);
  }

  Future<T> _guard<T>(Future<T> Function() f) async {
    await requireOnline();
    try {
      return await f();
    } on AuthException catch (e) {
      throw AuthFailure(_friendly(e.message));
    } on AuthFailure {
      rethrow;
    } catch (_) {
      throw AuthFailure(Net.offlineMessage);
    }
  }

  Future<void> _quietSignOut() async {
    try {
      await _sb.auth.signOut(scope: SignOutScope.local);
    } catch (_) {}
  }

  Future<AppUser> signIn({required String email, required String password}) async {
    _validateEmail(email);
    if (password.isEmpty) throw AuthFailure('Please enter your password.');
    await requireOnline();
    if (usesSupabase) {
      try {
        final res = await _sb.auth.signInWithPassword(email: email.trim(), password: password);
        final u = res.user;
        if (u == null) throw AuthFailure('Incorrect email or password.');
        return _fromSupabase(u);
      } on AuthException catch (e) {
        throw AuthFailure(_friendly(e.message));
      } on AuthFailure {
        rethrow;
      } catch (_) {
        throw AuthFailure(Net.offlineMessage);
      }
    }
    final a = _localAccounts()[email.trim().toLowerCase()];
    if (a == null || a['pw'] != _hash(password)) throw AuthFailure('Incorrect email or password.');
    await _store.setString(_localSessionKey, a['id'] as String);
    return AppUser(id: a['id'] as String, email: a['email'] as String, displayName: a['name'] as String, isLocal: true);
  }

  /// FR-1.4
  Future<void> sendPasswordReset(String email) async {
    _validateEmail(email);
    await requireOnline();
    if (usesSupabase) {
      try {
        await _sb.auth.resetPasswordForEmail(email.trim());
        return;
      } on AuthException catch (e) {
        throw AuthFailure(_friendly(e.message));
      } catch (_) {
        throw AuthFailure(Net.offlineMessage);
      }
    }
    if (!_localAccounts().containsKey(email.trim().toLowerCase())) {
      throw AuthFailure('No account was found for this email.');
    }
  }

  /// Demo-mode only: local accounts can set a new password directly.
  Future<void> setLocalPassword(String email, String password) async {
    final accounts = _localAccounts();
    final key = email.trim().toLowerCase();
    final a = accounts[key];
    if (a == null) throw AuthFailure('No account was found for this email.');
    if (password.length < 8) throw AuthFailure('Password must be at least 8 characters.');
    accounts[key] = {...Map<String, dynamic>.from(a as Map), 'pw': _hash(password)};
    await _store.writeJson(_localAccountsKey, accounts);
  }

  Future<AppUser> updateDisplayName(AppUser user, String name) async {
    if (usesSupabase) {
      try {
        final res = await _sb.auth.updateUser(UserAttributes(data: {'display_name': name.trim()}));
        if (res.user != null) return _fromSupabase(res.user!);
      } catch (_) {
        throw AuthFailure('Could not update your name while offline.');
      }
    } else {
      final accounts = _localAccounts();
      final key = user.email.toLowerCase();
      final a = accounts[key];
      if (a != null) {
        accounts[key] = {...Map<String, dynamic>.from(a as Map), 'name': name.trim()};
        await _store.writeJson(_localAccountsKey, accounts);
      }
    }
    return AppUser(id: user.id, email: user.email, displayName: name.trim(), isLocal: user.isLocal);
  }

  Future<void> signOut() async {
    if (usesSupabase) {
      try {
        await _sb.auth.signOut();
      } catch (_) {
        // Offline sign-out still clears the local session.
        await _sb.auth.signOut(scope: SignOutScope.local);
      }
    } else {
      await _store.remove(_localSessionKey);
    }
  }

  // ---------------------------------------------------------------------------
  AppUser _fromSupabase(User u) {
    final meta = u.userMetadata ?? const {};
    final email = u.email ?? '';
    final name = (meta['display_name'] as String?) ?? (email.contains('@') ? email.split('@').first : 'Gardener');
    return AppUser(id: u.id, email: email, displayName: name);
  }

  Map<String, dynamic> _localAccounts() => _store.readJson(_localAccountsKey) ?? <String, dynamic>{};

  String _hash(String pw) => sha256.convert(utf8.encode('studyflora::$pw')).toString();

  void _validateEmail(String email) {
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim());
    if (!ok) throw AuthFailure('Please enter a valid email address.');
  }

  String _friendly(String m) {
    final l = m.toLowerCase();
    if (Net.isNetworkError(m)) return Net.offlineMessage;
    if (l.contains('invalid login')) return 'Incorrect email or password.';
    if (l.contains('already registered') || l.contains('already exists')) return 'An account with this email already exists.';
    if (l.contains('email not confirmed')) return 'Please confirm your email first using the code we sent you.';
    if (l.contains('expired') || (l.contains('invalid') && l.contains('token')) || l.contains('otp')) {
      return 'That code is wrong or has expired. Check your email or resend a new code.';
    }
    if (l.contains('same') && l.contains('password')) return 'Choose a password different from your old one.';
    if (l.contains('weak') || (l.contains('password') && l.contains('should'))) return 'That password is too weak. Use at least 8 characters with letters and numbers.';
    if (l.contains('user not found') || l.contains('signups not allowed')) return 'No account was found for this email.';
    if (l.contains('rate limit') || l.contains('security purposes')) return 'Too many attempts. Please wait a moment and try again.';
    return m;
  }
}
