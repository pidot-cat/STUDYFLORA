import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/study.dart';
import '../../providers/study_provider.dart';
import '../../widgets/common.dart';
import 'module_screen.dart';
import 'study_screen.dart';
import 'upload_flow.dart';

/// One quiz attempt row (mockup: "Plant Cell Biology · 80% • Oct 4, 2026 · +50 coins").
class QuizHistoryRow extends StatelessWidget {
  const QuizHistoryRow({super.key, required this.attempt});
  final QuizAttempt attempt;
  @override
  Widget build(BuildContext context) {
    final c = context.sf;
    final a = attempt;
    final pass = a.percent >= 60;
    final s = context.read<StudyProvider>();
    return InkWell(
      onTap: s.byId(a.moduleId) == null
          ? null
          : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ModuleScreen(moduleId: a.moduleId))),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(children: [
          IconTile(Icons.assignment_outlined, size: 42, bg: pass ? c.brandSoft : c.surfaceAlt, color: pass ? c.brand : c.muted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a.moduleTitle, style: context.tt.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text('${a.correct}/${a.total} • ${a.percent}% • ${fmtShortDate(DateTime.fromMillisecondsSinceEpoch(a.takenAt))}',
                  style: context.tt.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
          const SizedBox(width: 8),
          Text(a.coins > 0 ? '+${a.coins} coins' : 'Retake', style: TextStyle(color: a.coins > 0 ? c.accent : c.muted, fontWeight: FontWeight.w700, fontSize: 12.5)),
        ]),
      ),
    );
  }
}

/// FR-3.7 — most recent quiz results.
class QuizHistoryScreen extends StatelessWidget {
  const QuizHistoryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<StudyProvider>();
    final c = context.sf;
    final list = s.recentAttempts.take(50).toList();
    return Scaffold(
      appBar: AppBar(backgroundColor: c.bg, surfaceTintColor: Colors.transparent, title: Text('Quiz History', style: context.tt.titleMedium)),
      body: list.isEmpty
          ? const _FullEmpty(
              icon: Icons.history_rounded,
              title: 'No quizzes yet',
              message: 'Open a module and take a practice quiz. Every attempt is listed here.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                SfCard(
                  padding: EdgeInsets.zero,
                  child: Column(children: [
                    for (var i = 0; i < list.length; i++) ...[
                      if (i > 0) Divider(height: 1, color: c.line),
                      QuizHistoryRow(attempt: list[i]),
                    ],
                  ]),
                ),
              ],
            ),
    );
  }
}

/// FR-2.6 — every previously uploaded module, ready to reopen.
class ArchivedModulesScreen extends StatefulWidget {
  const ArchivedModulesScreen({super.key});
  @override
  State<ArchivedModulesScreen> createState() => _ArchivedModulesScreenState();
}

class _ArchivedModulesScreenState extends State<ArchivedModulesScreen> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final s = context.watch<StudyProvider>();
    final c = context.sf;
    final all = s.allModules;
    final list = _q.isEmpty
        ? all
        : all.where((m) => m.title.toLowerCase().contains(_q) || m.fileName.toLowerCase().contains(_q)).toList();
    return Scaffold(
      appBar: AppBar(backgroundColor: c.bg, surfaceTintColor: Colors.transparent, title: Text('Archived Modules', style: context.tt.titleMedium)),
      body: all.isEmpty
          ? _FullEmpty(
              icon: Icons.inventory_2_outlined,
              title: 'No modules yet',
              message: 'Every file you upload is saved here as a module, so you can reopen its key points and quiz anytime.',
              action: 'Upload a file',
              onAction: () => runUploadFlow(context),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                if (all.length > 4)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextField(
                      onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
                      decoration: const InputDecoration(hintText: 'Search modules', prefixIcon: Icon(Icons.search_rounded)),
                    ),
                  ),
                Text('${all.length} module${all.length == 1 ? '' : 's'} • newest first', style: context.tt.bodySmall),
                const SizedBox(height: 10),
                for (final m in list) ModuleTile(module: m),
                if (list.isEmpty) Padding(padding: const EdgeInsets.all(20), child: Center(child: Text('No module matches “$_q”.', style: context.tt.bodySmall))),
              ],
            ),
    );
  }
}

/// Empty state that fills the whole screen (no floating card).
class _FullEmpty extends StatelessWidget {
  const _FullEmpty({required this.icon, required this.title, required this.message, this.action, this.onAction});
  final IconData icon;
  final String title;
  final String message;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) {
    final c = context.sf;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(32, 0, 32, 60),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(color: c.brandSoft, shape: BoxShape.circle),
            child: Icon(icon, size: 42, color: c.brand),
          ),
          const SizedBox(height: 18),
          Text(title, style: context.tt.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(message, style: context.tt.bodyMedium?.copyWith(color: c.muted), textAlign: TextAlign.center),
          if (action != null) ...[
            const SizedBox(height: 22),
            PrimaryButton(label: action!, icon: Icons.upload_file_rounded, onTap: onAction),
          ],
        ]),
      ),
    );
  }
}
