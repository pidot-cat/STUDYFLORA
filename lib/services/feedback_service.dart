import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants.dart';
import 'net.dart';
import 'storage_service.dart';

/// What happened when feedback was sent.
enum FeedbackResult { sent, offline, notSignedIn, serverError }

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

  /// Saves the feedback, then tries to deliver everything that is waiting.
  Future<FeedbackResult> submit({
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
    return send();
  }

  /// Retry used on app start. Returns true when nothing is left waiting.
  Future<bool> flush() async => (await send()) == FeedbackResult.sent;

  Future<FeedbackResult> send() async {
    final q = _queue;
    if (q.isEmpty) return FeedbackResult.sent;
    if (!Env.cloud) return FeedbackResult.serverError;
    if (!await Net.online()) return FeedbackResult.offline;
    try {
      final sb = Supabase.instance.client;
      final uid = sb.auth.currentUser?.id;
      if (uid == null) return FeedbackResult.notSignedIn; // only signed-in users may add feedback
      await sb.from('sf_feedback').insert([
        for (final f in q) {...f, 'user_id': uid},
      ]).timeout(const Duration(seconds: 15));
      await _saveQueue(const []);
      return FeedbackResult.sent;
    } catch (e) {
      return Net.isNetworkError(e) ? FeedbackResult.offline : FeedbackResult.serverError;
    }
  }
}
