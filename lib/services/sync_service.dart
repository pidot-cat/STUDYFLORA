import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants.dart';

class RemoteSnapshot {
  final Map<String, dynamic> game;
  final Map<String, dynamic> study;
  final int updatedAt;
  const RemoteSnapshot(this.game, this.study, this.updatedAt);
}

class SyncFailure implements Exception {
  final String message;
  SyncFailure(this.message);
  @override
  String toString() => message;
}

/// FR-6.2 … FR-6.8 — talks to Supabase. Merge rules live in SyncProvider.
///
/// Tables (see supabase/schema.sql):
///   sf_user_data(user_id, game jsonb, study jsonb, updated_at bigint)
///   sf_quiz_attempts(id, user_id, payload jsonb, taken_at bigint)
class SyncService {
  bool get available => Env.cloud;
  SupabaseClient get _sb => Supabase.instance.client;

  Future<RemoteSnapshot?> fetch(String uid) async {
    _guard();
    try {
      final row = await _sb.from('sf_user_data').select().eq('user_id', uid).maybeSingle();
      if (row == null) return null;
      return RemoteSnapshot(
        Map<String, dynamic>.from((row['game'] ?? const {}) as Map),
        Map<String, dynamic>.from((row['study'] ?? const {}) as Map),
        (row['updated_at'] as num?)?.toInt() ?? 0,
      );
    } on PostgrestException catch (e) {
      throw SyncFailure('Cloud error: ${e.message}');
    } catch (e) {
      throw SyncFailure('Could not reach the cloud. Check your connection.');
    }
  }

  Future<void> push(String uid, Map<String, dynamic> game, Map<String, dynamic> study, int updatedAt) async {
    _guard();
    try {
      await _sb.from('sf_user_data').upsert({
        'user_id': uid,
        'game': game,
        'study': study,
        'updated_at': updatedAt,
      });
    } on PostgrestException catch (e) {
      throw SyncFailure('Cloud error: ${e.message}');
    } catch (_) {
      throw SyncFailure('Upload failed. Your progress is kept on this phone and will retry.');
    }
  }

  /// Quiz attempts are independent records → merged, never overwritten.
  Future<List<Map<String, dynamic>>> syncAttempts(String uid, List<Map<String, dynamic>> local) async {
    _guard();
    try {
      if (local.isNotEmpty) {
        await _sb.from('sf_quiz_attempts').upsert(
              [
                for (final a in local) {'id': a['id'], 'user_id': uid, 'payload': a, 'taken_at': a['takenAt']}
              ],
              onConflict: 'id',
              ignoreDuplicates: true,
            );
      }
      final rows = await _sb.from('sf_quiz_attempts').select('payload').eq('user_id', uid);
      return [for (final r in rows) Map<String, dynamic>.from(r['payload'] as Map)];
    } on PostgrestException catch (e) {
      throw SyncFailure('Cloud error: ${e.message}');
    } catch (_) {
      throw SyncFailure('Could not sync quiz history.');
    }
  }

  void _guard() {
    if (!available) throw SyncFailure('Cloud sync is not configured (Supabase keys missing).');
  }
}
