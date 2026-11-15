import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Internet checks. Wi-Fi being "connected" is not enough (captive portals,
/// no data), so a real DNS lookup confirms the connection.
class Net {
  static const offlineMessage = 'No internet connection. Please connect to Wi-Fi or mobile data and try again.';

  static Future<bool> online() async {
    try {
      final r = await Connectivity().checkConnectivity();
      if (r.isEmpty || r.every((x) => x == ConnectivityResult.none)) return false;
    } catch (_) {}
    try {
      final res = await InternetAddress.lookup('google.com').timeout(const Duration(seconds: 5));
      return res.isNotEmpty && res.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// True for errors that mean "the request never reached the server".
  static bool isNetworkError(Object e) {
    final l = e.toString().toLowerCase();
    return l.contains('socketexception') ||
        l.contains('failed host lookup') ||
        l.contains('clientexception') ||
        l.contains('network is unreachable') ||
        l.contains('connection refused') ||
        l.contains('connection reset') ||
        l.contains('connection closed') ||
        l.contains('handshakeexception') ||
        l.contains('timeoutexception') ||
        l.contains('timed out');
  }

  /// Emits `true`/`false` whenever the connection really changes.
  static Stream<bool> changes() async* {
    bool? last;
    await for (final _ in Connectivity().onConnectivityChanged) {
      // Give the network a moment to settle before checking.
      await Future<void>.delayed(const Duration(milliseconds: 800));
      final now = await online();
      if (now != last) {
        last = now;
        yield now;
      }
    }
  }
}
