import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/app_theme.dart';

/// Shown when an action needs a connection. Pops with `true` when the
/// connection is back so the caller can retry.
class NoInternetScreen extends StatefulWidget {
  const NoInternetScreen({super.key});
  @override
  State<NoInternetScreen> createState() => _NoInternetScreenState();
}

class _NoInternetScreenState extends State<NoInternetScreen> {
  bool _checking = false;

  Future<void> _retry() async {
    setState(() => _checking = true);
    final ok = await context.read<AppState>().isOnline();
    if (!mounted) return;
    setState(() => _checking = false);
    if (ok) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            width: 110,
            height: 110,
            child: Stack(children: [
              Container(
                width: 106,
                height: 106,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFD5F2E1),
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 6)],
                ),
                child: const Icon(Icons.wifi_rounded, size: 52, color: Color(0xFF1F5A3D)),
              ),
              Positioned(
                right: 6,
                bottom: 6,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                      color: const Color(0xFF2F5D45),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2)),
                  child: const Icon(Icons.close, size: 12, color: Colors.white),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 26),
          Text('No Internet Connection', style: T.p(20, w: FontWeight.w700, c: const Color(0xFF16302A))),
          const SizedBox(height: 12),
          Text('Please check your connection\nand try again.',
              textAlign: TextAlign.center, style: T.p(14, c: const Color(0xFF64748B), h: 1.5)),
          const SizedBox(height: 46),
          SizedBox(
            width: 270,
            height: 50,
            child: Material(
              color: const Color(0xFFDDF0E4),
              shape: const StadiumBorder(),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: _checking ? null : _retry,
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _checking
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1F5A3D)))
                      : const Icon(Icons.sync, size: 18, color: Color(0xFF1F5A3D)),
                  const SizedBox(width: 8),
                  Text('Retry', style: T.p(15, w: FontWeight.w700, c: const Color(0xFF1F5A3D))),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
