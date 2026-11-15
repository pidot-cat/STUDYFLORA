import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants.dart';
import 'storage_service.dart';

/// "Report Feedback": comments and opinions about the app. Saved on the phone
/// first, then sent to the Supabase table `sf_feedback` (see
/// supabase/schema.sql). Anything that could not be sent is retried the next
/// time feedback is submitted.
class FeedbackService {
  FeedbackService(this._store);
  final StorageService _store;
  static const _key = 'sf.feedback.queue';

  List<Map<String, dynamic>> get _queue =>
      [for (final e in (_store.readJson(_key)?['items'] as List? ?? const [])) Map<String, dynamic>.from(e as Map)];

  Future<void> _saveQueue(List<Map<String, dynamic>> q) => _store.writeJson(_key, {'items': q});

  /// Returns true when everything was delivered to the cloud.
  Future<bool> submit({
    required String category,
    required int rating,
    required String message,
    String? email,
  }) async {
    final q = _queue
      ..add({
        'category': category,
        'rating': rating,
        'message': message.trim(),
        'email': email,
        'app_version': '1.0',
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    await _saveQueue(q);
    return flush();
  }

  Future<bool> flush() async {
    final q = _queue;
    if (q.isEmpty) return true;
    if (!Env.cloud) return false;
    try {
      final sb = Supabase.instance.client;
      final uid = sb.auth.currentUser?.id;
      if (uid == null) return false; // only signed-in users may add feedback
      await sb.from('sf_feedback').insert([
        for (final f in q) {...f, 'user_id': uid},
      ]).timeout(const Duration(seconds: 15));
      await _saveQueue(const []);
      return true;
    } catch (_) {
      return false;
    }
  }
}
