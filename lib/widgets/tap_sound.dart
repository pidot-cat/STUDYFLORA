import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../providers/feedback_bus.dart';
import '../services/sound_service.dart';

/// Plays the tap sound for EVERY tappable control in the app — buttons, list
/// rows, switches, chips, tabs, dialog actions, back arrows — not only the
/// ones built with [Pressable]. It watches finished taps (not drags or
/// scrolls) and checks whether something tappable was under the finger.
class TapSound extends StatefulWidget {
  const TapSound({super.key, required this.child});
  final Widget child;
  @override
  State<TapSound> createState() => _TapSoundState();
}

class _TapSoundState extends State<TapSound> {
  int? _pointer;
  Offset _downAt = Offset.zero;
  Duration _downTime = Duration.zero;

  void _down(PointerDownEvent e) {
    _pointer = e.pointer;
    _downAt = e.position;
    _downTime = e.timeStamp;
  }

  void _up(PointerUpEvent e) {
    if (e.pointer != _pointer) return;
    _pointer = null;
    if (!FeedbackPrefs.sound) return;
    // A tap, not a scroll or a long press.
    if ((e.position - _downAt).distance > kTouchSlop) return;
    if (e.timeStamp - _downTime > const Duration(milliseconds: 450)) return;
    if (_hitsTappable(e)) SoundService.instance.play(Sfx.tap);
  }

  bool _hitsTappable(PointerUpEvent e) {
    final result = HitTestResult();
    WidgetsBinding.instance.hitTestInView(result, e.position, e.viewId);
    for (final entry in result.path) {
      final t = entry.target;
      // Typing in a text field is not a button press.
      if (t is RenderEditable) return false;
      if (t is RenderSemanticsGestureHandler && t.onTap != null) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _down,
      onPointerUp: _up,
      onPointerCancel: (_) => _pointer = null,
      child: widget.child,
    );
  }
}
