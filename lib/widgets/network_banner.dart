import 'dart:async';

import 'package:flutter/material.dart';

import '../services/net.dart';

/// App-wide notice at the top of the screen: a red "No internet" message when
/// the connection drops and a green "Back online" one when it returns. Both
/// slide away after a few seconds so they never keep covering the screen
/// (screens that need internet show their own message when used offline).
class NetworkBanner extends StatefulWidget {
  const NetworkBanner({super.key, required this.child});
  final Widget child;
  @override
  State<NetworkBanner> createState() => _NetworkBannerState();
}

class _NetworkBannerState extends State<NetworkBanner> {
  StreamSubscription<bool>? _sub;
  Timer? _hide;
  bool _offline = false;
  bool _showBack = false;
  bool _showOffline = false;

  void _hideLater(int seconds) {
    _hide?.cancel();
    _hide = Timer(Duration(seconds: seconds), () {
      if (mounted) {
        setState(() {
          _showBack = false;
          _showOffline = false;
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    Net.online().then((ok) {
      if (mounted && !ok) {
        setState(() {
          _offline = true;
          _showOffline = true;
        });
        _hideLater(5);
      }
    });
    _sub = Net.changes().listen((online) {
      if (!mounted) return;
      _hide?.cancel();
      if (!online) {
        setState(() {
          _offline = true;
          _showOffline = true;
          _showBack = false;
        });
        _hideLater(5);
      } else if (_offline) {
        setState(() {
          _offline = false;
          _showOffline = false;
          _showBack = true;
        });
        _hideLater(3);
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _hide?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _showOffline || _showBack;
    final top = MediaQuery.paddingOf(context).top;
    return Stack(children: [
      widget.child,
      Positioned(
        left: 0,
        right: 0,
        top: 0,
        child: IgnorePointer(
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            offset: visible ? Offset.zero : const Offset(0, -1.2),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 280),
              opacity: visible ? 1 : 0,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, top + 6, 16, 0),
                child: Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(14),
                  color: _offline ? const Color(0xFFC8463D) : const Color(0xFF2E7D5B),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(children: [
                      Icon(_offline ? Icons.wifi_off_rounded : Icons.wifi_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _offline
                              ? 'No internet connection. Some features won’t work until you’re back online.'
                              : 'You’re back online.',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                            decoration: TextDecoration.none,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ]);
  }
}
