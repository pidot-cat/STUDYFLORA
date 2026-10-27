import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';

/// Writes the module summary to a .txt file and shows the "Summary Exported!" screen.
class ExportSummaryScreen extends StatefulWidget {
  final String moduleId;
  const ExportSummaryScreen({super.key, required this.moduleId});
  @override
  State<ExportSummaryScreen> createState() => _ExportSummaryScreenState();
}

class _ExportSummaryScreenState extends State<ExportSummaryScreen> {
  File? _file;
  int _size = 0;
  DateTime _at = DateTime.now();
  String? _error;

  @override
  void initState() {
    super.initState();
    _export();
  }

  String _build(StudyModule m) {
    final b = StringBuffer()
      ..writeln('StudyFlora Summary — ${m.title}')
      ..writeln('Source: ${m.fileName}')
      ..writeln('Exported: ${fmtDateTime(DateTime.now())}')
      ..writeln()
      ..writeln('KEY POINTS');
    for (var i = 0; i < m.keyPoints.length; i++) {
      b.writeln('${i + 1}. ${m.keyPoints[i].term}: ${m.keyPoints[i].detail}');
    }
    b
      ..writeln()
      ..writeln('TOPIC OVERVIEW');
    for (final o in m.overview) {
      b.writeln('• $o');
    }
    if (m.fullText.isNotEmpty) {
      b
        ..writeln()
        ..writeln('EXTRACTED NOTES')
        ..writeln(m.fullText);
    }
    return b.toString();
  }

  Future<void> _export() async {
    final m = context.read<AppState>().moduleById(widget.moduleId);
    if (m == null) return;
    try {
      Directory dir = Directory('/storage/emulated/0/Download');
      if (!Platform.isAndroid || !await dir.exists()) dir = await getApplicationDocumentsDirectory();
      final name = 'StudyFlora_${m.title.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')}_Summary.txt';
      File f = File('${dir.path}/$name');
      try {
        await f.writeAsString(_build(m));
      } catch (_) {
        // Fallback when the public Downloads folder isn't writable.
        final d = await getApplicationDocumentsDirectory();
        f = File('${d.path}/$name');
        await f.writeAsString(_build(m));
      }
      final len = await f.length();
      if (!mounted) return;
      setState(() {
        _file = f;
        _size = len;
        _at = DateTime.now();
      });
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final name = _file?.path.split('/').last ?? 'StudyFlora_Summary.txt';
    final inDownloads = _file?.path.contains('/Download') ?? true;
    return Scaffold(
      backgroundColor: c.isDark ? c.bg : const Color(0xFFF6F8F7),
      body: SafeArea(
        bottom: false,
        child: ListView(padding: const EdgeInsets.fromLTRB(24, 30, 24, 28), children: [
          Center(child: Text('Export Summary', style: T.j(19, w: FontWeight.w700, c: c.heading))),
          const SizedBox(height: 30),
          Center(
            child: Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(color: c.isDark ? c.mint : const Color(0xFFDDF0E4), shape: BoxShape.circle),
              child: Stack(alignment: Alignment.center, children: [
                Icon(Icons.description_outlined, size: 52, color: c.heading),
                Positioned(
                  right: 26,
                  bottom: 26,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                        color: const Color(0xFF1F6B45),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2)),
                    child: const Icon(Icons.check, size: 13, color: Colors.white),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(_error == null ? (_file == null ? 'Exporting…' : 'Summary Exported!') : 'Export Failed',
                style: T.j(22, w: FontWeight.w700, c: c.heading)),
          ),
          const SizedBox(height: 10),
          Text(_error ?? 'Your study summary has been saved\nas a .txt file.',
              textAlign: TextAlign.center, style: T.j(14, c: c.textMuted, h: 1.5)),
          const SizedBox(height: 22),
          SFCard(
            radius: 16,
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              IconTile(Icons.description_outlined,
                  size: 48, iconSize: 22, radius: 12, bg: c.isDark ? c.mint : const Color(0xFFE6F4EA)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name,
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: T.j(15, w: FontWeight.w700, c: c.text)),
                  Text('${fmtSize(_size)} • ${fmtDateTime(_at)}', style: T.j(11.5, c: c.textMuted)),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 14),
          PrimaryButton('Open File',
              icon: Icons.open_in_new,
              radius: 14,
              jakarta: true,
              color: c.isDark ? c.primary : const Color(0xFF226B45),
              onTap: _file == null ? null : () => OpenFilex.open(_file!.path)),
          const SizedBox(height: 12),
          OutlineButtonSF('Done',
              radius: 14,
              jakarta: true,
              weight: FontWeight.w700,
              borderColor: const Color(0xFFA3C9B3),
              bg: Colors.transparent,
              onTap: () => Navigator.of(context).pop()),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: c.isDark ? c.cardAlt : const Color(0xFFEFF5F1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.border),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.info_outline, size: 18, color: c.heading),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                    inDownloads
                        ? "The file is saved in your device's Downloads folder."
                        : "The file is saved in StudyFlora's documents folder.",
                    style: T.j(12, c: c.textMuted, h: 1.5)),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
