import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../services/storage_service.dart';
import '../services/sync_service.dart';
import 'game_provider.dart';
import 'study_provider.dart';

enum SyncStatus { localOnly, idle, syncing, synced, failed, offline }

/// Offline-first sync queue (FR-6.2 … FR-6.8, NFR 4.6).
///
/// * Every local change increments [pending] and is kept on the phone.
/// * When online, the snapshot is reconciled with the cloud:
///    - cloud unchanged since our last sync  → push local
///    - cloud changed, nothing pending here  → adopt cloud (restore)
///    - both changed                         → newer game snapshot wins,
///      modules merged by file hash (newer wins), quiz attempts unioned.
/// * Failures are shown and can be retried.
class SyncProvider extends ChangeNotifier {
  SyncProvider(this._store, this._game, this._study, this._service) {
    _game.onChanged = markDirty;
    _study.onChanged = markDirty;
    _conn = Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      final wasOffline = !_online;
      _online = online;
      if (online && wasOffline && pending > 0) syncNow();
      if (!online && _cloud) {
        status = SyncStatus.offline;
        notifyListeners();
      }
    });
  }

  final StorageService _store;
  final GameProvider _game;
  final StudyProvider _study;
  final SyncService _service;
  StreamSubscription<List<ConnectivityResult>>? _conn;
  Timer? _debounce;

  String? _uid;
  bool _cloud = false;
  bool _online = true;
  int pending = 0;
  int lastSyncedAt = 0;
  int lastRemoteSeen = 0;
  SyncStatus status = SyncStatus.idle;
  String? error;

  bool get cloudEnabled => _cloud && _service.available;
  bool get online => _online;

  Future<void> load(String uid, {required bool cloud}) async {
    _uid = uid;
    _cloud = cloud;
    final j = _store.readJson(StorageService.syncKey(uid)) ?? const {};
    pending = (j['pending'] ?? 0) as int;
    lastSyncedAt = (j['lastSyncedAt'] ?? 0) as int;
    lastRemoteSeen = (j['lastRemoteSeen'] ?? 0) as int;
    status = cloudEnabled ? (pending == 0 && lastSyncedAt > 0 ? SyncStatus.synced : SyncStatus.idle) : SyncStatus.localOnly;
    error = null;
    final res = await Connectivity().checkConnectivity();
    _online = res.any((r) => r != ConnectivityResult.none);
    if (!_online && cloudEnabled) status = SyncStatus.offline;
    notifyListeners();
  }

  void unload() {
    _uid = null;
    _cloud = false;
    pending = 0;
    status = SyncStatus.idle;
    notifyListeners();
  }

  Future<void> _persist() async {
    final uid = _uid;
    if (uid == null) return;
    await _store.writeJson(StorageService.syncKey(uid), {
      'pending': pending,
      'lastSyncedAt': lastSyncedAt,
      'lastRemoteSeen': lastRemoteSeen,
    });
  }

  /// FR-6.4 — queue the change; push a few seconds later when online.
  void markDirty() {
    pending++;
    _persist();
    if (!cloudEnabled) return;
    if (status == SyncStatus.synced) status = SyncStatus.idle;
    notifyListeners();
    _debounce?.cancel();
    if (_online) _debounce = Timer(const Duration(seconds: 4), syncNow);
  }

  bool _running = false;

  /// FR-6.7 retry also calls this.
  Future<void> syncNow() async {
    final uid = _uid;
    if (uid == null || !cloudEnabled || _running) return;
    if (!_online) {
      status = SyncStatus.offline;
      notifyListeners();
      return;
    }
    _running = true;
    status = SyncStatus.syncing;
    error = null;
    notifyListeners();
    final pendingAtStart = pending;
    try {
      final remote = await _service.fetch(uid);
      if (remote != null && remote.updatedAt > lastRemoteSeen) {
        // Restore when nothing changed here, OR when this device has never
        // synced before (fresh install / new phone) — otherwise default
        // starter data could overwrite the user's real cloud progress.
        if (pendingAtStart == 0 || lastSyncedAt == 0) {
          // Restore from cloud (new device or another device made changes).
          _game.applyJson(remote.game);
          if (pendingAtStart == 0) {
            _study.applyJson(remote.study);
          } else {
            _study.mergeRemote(remote.study, const []); // keep modules made here
          }
        } else {
          // Both sides changed — keep the newer game state, merge study data.
          final remoteGameAt = (remote.game['updatedAt'] ?? 0) as int;
          if (remoteGameAt > _game.updatedAt) _game.applyJson(remote.game);
          _study.mergeRemote(remote.study, const []);
        }
      }
      final mergedAttempts = await _service.syncAttempts(uid, _study.attempts.map((a) => a.toJson()).toList());
      _study.mergeRemote(const {}, mergedAttempts);

      final stamp = DateTime.now().millisecondsSinceEpoch;
      await _service.push(uid, _game.toJson(), _study.toJson(), stamp);
      // Save locally without re-marking dirty.
      await _store.writeJson(StorageService.gameKey(uid), _game.toJson());
      await _store.writeJson(StorageService.studyKey(uid), _study.toJson());

      lastRemoteSeen = stamp;
      lastSyncedAt = stamp;
      pending = pending - pendingAtStart < 0 ? 0 : pending - pendingAtStart;
      status = pending == 0 ? SyncStatus.synced : SyncStatus.idle;
      _game.refresh();
    } on SyncFailure catch (e) {
      status = SyncStatus.failed;
      error = e.message;
    } catch (e) {
      status = SyncStatus.failed;
      error = 'Sync failed. Tap retry.';
    } finally {
      _running = false;
      await _persist();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _conn?.cancel();
    _debounce?.cancel();
    super.dispose();
  }
}
