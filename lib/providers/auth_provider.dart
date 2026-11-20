import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';
import 'game_provider.dart';
import 'study_provider.dart';
import 'sync_provider.dart';

/// Session state + wiring of the per-user providers.
class AuthProvider extends ChangeNotifier {
  AuthProvider(this.service, this._game, this._study, this._sync);
  final AuthService service;
  final GameProvider _game;
  final StudyProvider _study;
  final SyncProvider _sync;

  AppUser? user;
  bool busy = false;
  bool get signedIn => user != null;
  bool get demoMode => !service.usesSupabase;

  /// Called by the splash screen.
  Future<void> restore() async {
    final u = service.currentUser();
    if (u != null) await _bind(u, initialSync: true);
  }

  Future<void> signIn(String email, String password) => _run(() => service.signIn(email: email, password: password));

  /// Registers only; the user logs in afterwards (sign-up → Login screen).
  Future<({String message, bool needsCode})> signUp(String name, String email, String password) async {
    busy = true;
    notifyListeners();
    try {
      return await service.signUp(name: name, email: email, password: password);
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> _run(Future<AppUser> Function() action) async {
    busy = true;
    notifyListeners();
    try {
      final u = await action();
      await _bind(u, initialSync: true);
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> _bind(AppUser u, {bool initialSync = false}) async {
    user = u;
    await _game.load(u.id);
    await _study.load(u.id);
    await _sync.load(u.id, cloud: !u.isLocal);
    notifyListeners();
    // FR-6.8 — restore / reconcile cloud data after login (non-blocking).
    if (initialSync && !u.isLocal) _sync.syncNow();
  }

  Future<void> sendReset(String email) => service.sendPasswordReset(email);
  Future<void> verifySignupCode(String email, String code) => service.verifySignupCode(email, code);
  Future<void> resendSignupCode(String email) => service.resendSignupCode(email);
  Future<void> verifyResetCode(String email, String code) => service.verifyRecoveryCode(email, code);
  Future<void> setNewPassword(String newPassword) => service.setNewPassword(newPassword);
  Future<void> resetPassword(String email, String code, String newPassword) =>
      service.resetPasswordWithCode(email: email, code: code, newPassword: newPassword);

  Future<void> updateName(String name) async {
    final u = user;
    if (u == null) return;
    user = await service.updateDisplayName(u, name);
    notifyListeners();
  }

  /// FR-1.3 (confirmation happens in the UI).
  /// Permanently deletes the signed-in account (cloud and this phone).
  Future<void> deleteAccount(String password) async {
    final u = user;
    if (u == null) return;
    await service.deleteAccount(u, password);
    // Nothing is synced back up: the account is gone.
    user = null;
    _game.unload();
    _study.unload();
    _sync.unload();
    await service.clearLocalData(u);
    notifyListeners();
  }

  Future<void> signOut() async {
    if (user != null && !user!.isLocal) {
      try {
        await _sync.syncNow();
      } catch (_) {}
    }
    await service.signOut();
    user = null;
    _game.unload();
    _study.unload();
    _sync.unload();
    notifyListeners();
  }
}
