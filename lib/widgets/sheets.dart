import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'common.dart';

/// Rounded bottom sheet with a drag handle (mockup "Buy Fertilizer" style).
Future<T?> showSfSheet<T>({required BuildContext context, required WidgetBuilder builder}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (ctx) {
      final c = ctx.sf;
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.92),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(height: 10),
            Container(width: 44, height: 5, decoration: BoxDecoration(color: c.line, borderRadius: BorderRadius.circular(9))),
            Flexible(child: builder(ctx)),
          ]),
        ),
      );
    },
  );
}

class SheetHeader extends StatelessWidget {
  const SheetHeader({super.key, required this.title, this.icon, this.trailing});
  final String title;
  final IconData? icon;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    final c = context.sf;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 14, 8),
      child: Row(children: [
        if (icon != null) ...[Icon(icon, color: c.brand, size: 22), const SizedBox(width: 10)],
        Expanded(child: Text(title, style: context.tt.titleLarge)),
        if (trailing != null) trailing!,
        Pressable(
          onTap: () => Navigator.of(context).maybePop(),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: c.line.withValues(alpha: 0.7), shape: BoxShape.circle),
            child: Icon(Icons.close_rounded, size: 20, color: c.muted),
          ),
        ),
      ]),
    );
  }
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirm = 'Confirm',
  bool danger = false,
  IconData icon = Icons.help_outline_rounded,
  String? image,
}) async {
  final res = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final c = ctx.sf;
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            image != null
                ? Container(
                    width: 72,
                    height: 72,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: danger ? c.dangerSoft : c.surfaceAlt, borderRadius: BorderRadius.circular(22)),
                    child: ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.asset(image, fit: BoxFit.contain)),
                  )
                : IconTile(icon, size: 58, color: danger ? c.danger : c.brand, bg: danger ? c.dangerSoft : c.surfaceAlt),
            const SizedBox(height: 14),
            Text(title, style: ctx.tt.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(message, style: ctx.tt.bodyMedium?.copyWith(color: c.muted), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: SecondaryButton(label: 'Cancel', height: 48, onTap: () => Navigator.pop(ctx, false))),
              const SizedBox(width: 10),
              Expanded(
                child: PrimaryButton(label: confirm, height: 48, color: danger ? c.danger : null, onTap: () => Navigator.pop(ctx, true)),
              ),
            ]),
          ]),
        ),
      );
    },
  );
  return res ?? false;
}

/// One-field text prompt (rename module, edit name). Owns and disposes its
/// controller, so nothing leaks after the sheet closes.
Future<String?> showTextPromptSheet(
  BuildContext context, {
  required String title,
  required IconData icon,
  required String initial,
  String hint = '',
  TextCapitalization capitalization = TextCapitalization.sentences,
}) {
  return showSfSheet<String>(
    context: context,
    builder: (_) => _TextPrompt(title: title, icon: icon, initial: initial, hint: hint, capitalization: capitalization),
  );
}

class _TextPrompt extends StatefulWidget {
  const _TextPrompt({required this.title, required this.icon, required this.initial, required this.hint, required this.capitalization});
  final String title;
  final IconData icon;
  final String initial;
  final String hint;
  final TextCapitalization capitalization;
  @override
  State<_TextPrompt> createState() => _TextPromptState();
}

class _TextPromptState extends State<_TextPrompt> {
  late final TextEditingController _ctrl = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _save() => Navigator.pop(context, _ctrl.text.trim());

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SheetHeader(title: widget.title, icon: widget.icon),
        TextField(
          controller: _ctrl,
          autofocus: true,
          textCapitalization: widget.capitalization,
          onSubmitted: (_) => _save(),
          decoration: InputDecoration(hintText: widget.hint),
        ),
        const SizedBox(height: 14),
        PrimaryButton(label: 'Save', onTap: _save),
      ]),
    );
  }
}
