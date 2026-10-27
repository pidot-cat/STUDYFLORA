import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../nav.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/app_header.dart';
import '../../widgets/common.dart';
import 'module_view_screen.dart';
import 'study_widgets.dart';

class ArchivedModulesScreen extends StatefulWidget {
  const ArchivedModulesScreen({super.key});
  @override
  State<ArchivedModulesScreen> createState() => _ArchivedModulesScreenState();
}

class _ArchivedModulesScreenState extends State<ArchivedModulesScreen> {
  String _cat = 'All';
  String _q = '';
  bool _newest = true;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = context.c;
    final cats = <String>{for (final m in s.modules) m.category}.toList();
    var list = s.modules
        .where((m) => _cat == 'All' || m.category == _cat)
        .where((m) =>
            _q.isEmpty || '${m.fileName} ${m.title} ${m.overview.join(' ')}'.toLowerCase().contains(_q.toLowerCase()))
        .toList()
      ..sort((a, b) => _newest ? b.uploadedAt.compareTo(a.uploadedAt) : a.uploadedAt.compareTo(b.uploadedAt));
    return Scaffold(
      backgroundColor: c.isDark ? c.bg : const Color(0xFFF3F7F4),
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          const AppHeader(back: true),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 28), children: [
              const SyncStatusRow(compact: true),
              const SizedBox(height: 14),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Archived Modules', style: T.p(23, w: FontWeight.w700, c: c.text)),
                    Text('Explore previously processed notes and generated quizzes', style: T.p(12.5, c: c.textMuted)),
                  ]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: c.isDark ? c.mint : const Color(0xFFD7F5E2), borderRadius: BorderRadius.circular(18)),
                  child: Text('${s.modules.length}\nfiles', style: T.p(12, w: FontWeight.w600, c: c.mintText, h: 1.2)),
                ),
              ]),
              const SizedBox(height: 12),
              Container(
                height: 42,
                decoration: BoxDecoration(
                    color: c.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: c.border)),
                child: TextField(
                  onChanged: (v) => setState(() => _q = v),
                  style: T.p(13, c: c.text),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.search, size: 20, color: c.textMuted),
                    hintText: 'Search archived files, topics...',
                    hintStyle: T.p(12.5, c: c.textFaint),
                    contentPadding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 34,
                child: ListView(scrollDirection: Axis.horizontal, children: [
                  _chip('All', 'All (${s.modules.length})'),
                  for (final cat in cats) _chip(cat, cat),
                ]),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Text('DOCUMENT HISTORY', style: T.p(11.5, w: FontWeight.w600, c: c.textFaint, ls: .5)),
                const Spacer(),
                InkWell(
                  onTap: () => setState(() => _newest = !_newest),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        color: c.card, borderRadius: BorderRadius.circular(8), border: Border.all(color: c.border)),
                    child: Row(children: [
                      Text(_newest ? 'Recently Uploaded' : 'Oldest First',
                          style: T.p(12.5, w: FontWeight.w500, c: c.text)),
                      Icon(Icons.keyboard_arrow_down, size: 16, color: c.text),
                    ]),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              for (final m in list) ...[
                _ModuleCard(module: m),
                const SizedBox(height: 14),
              ],
              const SizedBox(height: 4),
              const InfoBanner(
                  'Upload PDF, DOCX, or TXT (max 25 MB). Offline parsing uses on-device rules. Re-upload opens the saved module without another reward. Reopen archived modules to review summaries and retake quizzes.',
                  fontSize: 11.5),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _chip(String key, String label) {
    final c = context.c;
    final active = _cat == key;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: active ? (c.isDark ? c.mintStrong : const Color(0xFF1B3A2E)) : c.card,
        shape: StadiumBorder(side: BorderSide(color: active ? Colors.transparent : c.border)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => setState(() => _cat = key),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            child: Text(label, style: T.p(12.5, w: FontWeight.w500, c: active ? Colors.white : c.text)),
          ),
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final StudyModule module;
  const _ModuleCard({required this.module});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final m = module;
    final taken = m.bestScore >= 0;
    return SFCard(
      onTap: () => pushTab(context, ModuleViewScreen(moduleId: m.id)),
      radius: 16,
      padding: const EdgeInsets.fromLTRB(14, 16, 12, 14),
      child: Row(children: [
        Align(
          alignment: Alignment.topCenter,
          child: IconTile(Icons.note_alt_outlined,
              size: 40,
              iconSize: 18,
              radius: 10,
              bg: c.isDark ? c.mint : const Color(0xFFE3F5EA),
              borderColor: const Color(0xFFC9EED6)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.fileName,
                maxLines: 1, overflow: TextOverflow.ellipsis, style: T.p(13.5, w: FontWeight.w600, c: c.text)),
            Text('Previously Uploaded • ${m.ext} • ${fmtSize(m.sizeBytes)} • ${fmtAgoShort(m.uploadedAt)}',
                style: T.p(11, c: c.textMuted, h: 1.4)),
            const SizedBox(height: 6),
            if (taken)
              Pill(m.mastered ? 'Mastered ${m.bestScore}%' : 'Not Yet Mastered · ${m.bestScore}%',
                  fontSize: 11,
                  weight: FontWeight.w500,
                  bg: m.mastered ? const Color(0xFFE3F8EA) : const Color(0xFFF1F2F5),
                  fg: m.mastered ? const Color(0xFF15803D) : const Color(0xFF3F3F46),
                  borderColor: m.mastered ? const Color(0xFFBFE9CC) : const Color(0xFFE2E4EA),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3))
            else
              Pill('Quiz not taken yet',
                  fontSize: 11,
                  weight: FontWeight.w500,
                  bg: const Color(0xFFF1F2F5),
                  fg: const Color(0xFF3F3F46),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3)),
          ]),
        ),
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(color: c.isDark ? c.cardAlt : const Color(0xFFF2F4F7), shape: BoxShape.circle),
          child: Icon(Icons.chevron_right, size: 18, color: c.textFaint),
        ),
      ]),
    );
  }
}
