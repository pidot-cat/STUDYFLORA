import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/app_header.dart';
import '../../widgets/common.dart';
import '../home/home_screen.dart';

class _Structure {
  final IconData icon;
  final String name, body, tag;
  const _Structure(this.icon, this.name, this.body, this.tag);
}

class _Note {
  final String title, body;
  const _Note(this.title, this.body);
}

/// Content model for the full summary page.
class _Summary {
  final List<InlineSpan> Function(TextStyle base, TextStyle bold) overview;
  final List<(String, String)> facts;
  final List<KeyPoint> concepts;
  final List<_Structure> structures;
  final List<_Note> notes;
  final List<String> recall;
  final bool diagram;
  const _Summary(
      {required this.overview,
      required this.facts,
      required this.concepts,
      required this.structures,
      required this.notes,
      required this.recall,
      this.diagram = false});
}

_Summary _plantCell() => _Summary(
      overview: (b, s) => [
        TextSpan(
            text:
                'Plant cells are eukaryotic structural units defined by specialized adaptations absent in animal counterparts. Primary architectural pillars include the ',
            style: b),
        TextSpan(text: 'rigid cellulosic wall', style: s),
        TextSpan(text: ', regulated osmotic ', style: b),
        TextSpan(text: 'turgor pressure', style: s),
        TextSpan(
            text: ' via the primary central vacuole, and solar transduction machinery within dual-membrane ', style: b),
        TextSpan(text: 'chloroplasts', style: s),
        TextSpan(text: '.', style: b),
      ],
      facts: const [('WALL TYPE', 'Cellulose'), ('KEY ORGANELLE', 'Plastid'), ('TONOPLAST', 'Osmotic')],
      concepts: const [
        KeyPoint('Cell Wall Composition & Mechanics',
            'Composed of microfibrillar cellulose cross-linked in a hydrated matrix of hemicellulose, structural proteins, and pectins. Provides dynamic tensile support balancing internal hydrostatic stress.'),
        KeyPoint('Plastid Differentiation',
            'Specialized ancestral endosymbionts including chloroplasts (photosynthesis), amyloplasts (insoluble polysaccharide storage), and carotenoid-rich chromoplasts (pollinator attraction).'),
        KeyPoint('Central Vacuole & Turgor Dynamics',
            'Occupies up to 90% of cellular volume. Governed by the selective semi-permeable tonoplast membrane to drive passive water intake and preserve upright physical posture without a skeleton.'),
        KeyPoint('Symplastic vs. Apoplastic Transport',
            'Intercellular communication pathways: symplastic transfer traverses continuous cytosolic strands through plasmodesmata, while apoplastic diffusion travels across porous cellulose wall gaps.'),
      ],
      structures: const [
        _Structure(
            Icons.eco_outlined,
            'Chloroplast',
            'Site of photophosphorylation and carbon fixation. Possesses thylakoid stacks (grana) and soluble stroma.',
            'METABOLISM'),
        _Structure(
            Icons.water_drop_outlined,
            'Central Vacuole',
            'Bounded by tonoplast; houses hydrolytic enzymes, anthocyanins, secondary metabolites, and ionic reservoir.',
            'HYDROSTATICS'),
        _Structure(
            Icons.shield_outlined,
            'Cell Wall',
            'Porous primary layer bound by a calcium pectate middle lamella cementing neighboring plant cells together.',
            'INTEGRITY'),
        _Structure(
            Icons.call_split,
            'Plasmodesmata',
            'Microscopic cytoplasmic bridges containing central desmotubules connecting adjacent endoplasmic reticula.',
            'SIGNALING'),
      ],
      notes: const [
        _Note('Light Reactions & Z-Scheme Transfer',
            'Occurs within the thylakoid membranes. Photons excite photosystems II (P680) and I (P700), initiating photolysis of water (2H₂O → O₂ + 4H⁺ + 4e⁻). The generated proton gradient across the thylakoid lumen drives ATP synthase rotor complex, synthesizing ATP and reducing NADP+ to NADPH.'),
        _Note('Calvin-Benson Cycle Compartmentalization',
            'Enzyme-rich stroma hosts RuBisCO-driven fixation of atmospheric carbon dioxide onto ribulose 1,5-bisphosphate (RuBP). Generates 3-phosphoglycerate molecules, which undergo phosphorylation and reduction to yield glyceraldehyde 3-phosphate (G3P) for glucose assembly.'),
        _Note('Symplastic Gating & Viral Transport',
            'Plasmodesmatal size-exclusion limits (SEL) are dynamically throttled via callose turnover catalyzed by callose synthases and beta-1,3-glucanases. Plant viruses often synthesize movement proteins (MPs) to deliberately dilate these junctions.'),
      ],
      recall: const [
        'Cell wall prevents cytolysis under severe hypotonic influx.',
        'Thylakoids host photon capture; stroma executes carbon fixation.',
        'Tonoplast osmotic gradients govern macroscopic structural turgor.',
      ],
      diagram: true,
    );

_Summary _generic(StudyModule m) {
  final sentences = m.fullText.split(RegExp(r'(?<=[.!?])\s+')).where((s) => s.trim().length > 20).toList();
  final intro =
      sentences.isNotEmpty ? sentences.take(3).join(' ') : m.keyPoints.map((k) => '${k.term}: ${k.detail}').join(' ');
  return _Summary(
    overview: (b, s) => [TextSpan(text: intro, style: b)],
    facts: [
      ('FILE TYPE', m.ext.toUpperCase()),
      ('KEY POINTS', '${m.keyPoints.length}'),
      ('QUESTIONS', '${m.questions.length}'),
    ],
    concepts: m.keyPoints,
    structures: const [],
    notes: [
      for (final s in sentences.skip(3).take(3)) _Note(s.split(' ').take(4).join(' '), s),
    ],
    recall: m.overview,
  );
}

class ModuleSummaryScreen extends StatelessWidget {
  final String moduleId;
  const ModuleSummaryScreen({super.key, required this.moduleId});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = context.c;
    final m = s.moduleById(moduleId);
    if (m == null) return const Scaffold();
    final data = m.id == 'plant_cell' ? _plantCell() : _generic(m);
    final base = T.p(13, c: c.text, h: 1.55);
    final bold = T.p(13, w: FontWeight.w700, c: c.text, h: 1.55);
    final words = m.fullText.isEmpty ? 2000 : m.fullText.split(' ').length;
    return Scaffold(
      backgroundColor: c.isDark ? c.bg : const Color(0xFFF3F7F4),
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          const AppHeader(),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(20, 2, 20, 28), children: [
              Row(children: [
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  child: Row(children: [
                    Icon(Icons.archive_outlined, size: 14, color: c.textMuted),
                    const SizedBox(width: 4),
                    Text('Archived Modules', style: T.p(12.5, c: c.textMuted)),
                  ]),
                ),
                Text('  ›  ', style: T.p(12.5, c: c.textMuted)),
                Text('Summary', style: T.p(12.5, w: FontWeight.w700, c: c.text)),
                const Spacer(),
                Pill('Saved Module', dot: true, fontSize: 11.5, bg: c.isDark ? c.mint : const Color(0xFFDDF5E6)),
              ]),
              const SizedBox(height: 12),
              SFCard(
                radius: 18,
                padding: const EdgeInsets.all(16),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  IconTile(moduleGlyph(m.iconKey),
                      size: 56, iconSize: 24, radius: 12, bg: c.isDark ? c.mint : const Color(0xFFE3F2E8)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(m.title, style: T.p(18, w: FontWeight.w700, c: c.heading)),
                      Text('Full Study Summary & ${m.id == 'plant_cell' ? 'Organelle Guide' : 'Key Concepts'}',
                          style: T.p(12, w: FontWeight.w600, c: const Color(0xFF15924F))),
                      const SizedBox(height: 4),
                      Wrap(spacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                        Icon(Icons.copy_outlined, size: 12, color: c.textMuted),
                        Text(m.fileName, style: T.p(11, c: c.textMuted)),
                        Text('•  ${fmtSize(m.sizeBytes)}', style: T.p(11, c: c.textMuted)),
                        Text('•  ${(words / 200).ceil().clamp(1, 60)} Min Read', style: T.p(11, c: c.textMuted)),
                      ]),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: c.isDark ? c.amberTint : const Color(0xFFFFF8E6), borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(color: Color(0xFFFDEBC0), shape: BoxShape.circle),
                    child: const Icon(Icons.visibility_outlined, size: 15, color: Color(0xFFB45309)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Archived Study Summary', style: T.p(11.5, w: FontWeight.w700, c: const Color(0xFF92400E))),
                      Text('Read-only mode. Offline copy preserved from local storage.',
                          style: T.p(10.5, c: const Color(0xFFB45309))),
                    ]),
                  ),
                  Pill('0 Coins', fontSize: 10.5, bg: const Color(0xFFFDEBC0), fg: const Color(0xFF92400E)),
                ]),
              ),
              const SizedBox(height: 14),
              _Section(icon: Icons.menu_book_outlined, title: '1. CORE OVERVIEW', children: [
                RichText(text: TextSpan(children: data.overview(base, bold))),
                const SizedBox(height: 16),
                Row(children: [
                  for (var i = 0; i < data.facts.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 70,
                        decoration: BoxDecoration(
                            color: c.isDark ? c.cardAlt : const Color(0xFFF1F5F2),
                            borderRadius: BorderRadius.circular(12)),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text(data.facts[i].$1,
                              textAlign: TextAlign.center, style: T.p(9.5, w: FontWeight.w600, c: c.textMuted, ls: .4)),
                          Text(data.facts[i].$2,
                              style: T.p(12.5, w: FontWeight.w700, c: i == 2 ? const Color(0xFF15924F) : c.text)),
                        ]),
                      ),
                    ),
                  ],
                ]),
              ]),
              _Section(
                icon: Icons.psychology_outlined,
                title: '2. FUNDAMENTAL CONCEPTS',
                badge: '${data.concepts.length} Topics',
                children: [
                  for (final k in data.concepts)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: c.isDark ? c.cardAlt : const Color(0xFFF3F7F4),
                          borderRadius: BorderRadius.circular(12)),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(color: Color(0xFFD7F5E2), shape: BoxShape.circle),
                          child: const Icon(Icons.check, size: 12, color: Color(0xFF15924F)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(k.term, style: T.p(12.5, w: FontWeight.w700, c: c.text)),
                            Text(k.detail, style: T.p(12.5, c: c.text, h: 1.5)),
                          ]),
                        ),
                      ]),
                    ),
                ],
              ),
              if (data.structures.isNotEmpty)
                _Section(icon: Icons.hub_outlined, title: '3. IMPORTANT STRUCTURES & FUNCTIONS', children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: c.isDark ? c.cardAlt : const Color(0xFFF3F7F4), borderRadius: BorderRadius.circular(12)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        const Icon(Icons.account_tree_outlined, size: 14, color: Color(0xFF15924F)),
                        const SizedBox(width: 6),
                        Text('Micro-Structure Anatomy Card', style: T.p(12, w: FontWeight.w700, c: c.text)),
                        const Spacer(),
                        Text('Cellular Schematic', style: T.p(10.5, c: c.textMuted)),
                      ]),
                      const SizedBox(height: 10),
                      if (data.diagram)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset('assets/images/cell_ultrastructure.png',
                              width: double.infinity, fit: BoxFit.cover),
                        ),
                      const SizedBox(height: 8),
                      Text('Figure 1.1: High-resolution schematics extracted from "${m.fileName}" page 4.',
                          style: T.p(10.5, c: c.textMuted, style: FontStyle.italic)),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  GridView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, mainAxisExtent: 176),
                    children: [
                      for (final st in data.structures)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: c.isDark ? c.cardAlt : const Color(0xFFF3F7F4),
                              borderRadius: BorderRadius.circular(12)),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Icon(st.icon, size: 14, color: const Color(0xFF15924F)),
                              const SizedBox(width: 6),
                              Flexible(child: Text(st.name, style: T.p(12.5, w: FontWeight.w700, c: c.text))),
                            ]),
                            const SizedBox(height: 6),
                            Expanded(child: Text(st.body, style: T.p(11, c: c.text, h: 1.4))),
                            Text(st.tag, style: T.p(9.5, w: FontWeight.w700, c: const Color(0xFF15924F), ls: .4)),
                          ]),
                        ),
                    ],
                  ),
                ]),
              if (data.notes.isNotEmpty)
                _Section(icon: Icons.edit_note, title: '4. IN-DEPTH STUDY NOTES', children: [
                  for (final n in data.notes)
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: c.isDark ? c.cardAlt : const Color(0xFFF3F7F4),
                          borderRadius: BorderRadius.circular(12)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(color: Color(0xFF15924F), shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Expanded(child: Text(n.title, style: T.p(12.5, w: FontWeight.w700, c: c.heading))),
                        ]),
                        const SizedBox(height: 6),
                        Text(n.body, style: T.p(12, c: c.text, h: 1.55)),
                      ]),
                    ),
                ]),
              _Section(
                icon: Icons.fact_check_outlined,
                title: '${data.notes.isEmpty ? (data.structures.isEmpty ? 3 : 4) : 5}. SYNTHESIS & RECALL',
                badge: m.bestScore >= 0 ? 'Previous Quiz Score: ${m.bestScore}%' : null,
                children: [
                  for (final r in data.recall)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: c.isDark ? c.cardAlt : const Color(0xFFF3F7F4),
                          borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        const Icon(Icons.check_circle_outline, size: 17, color: Color(0xFF15924F)),
                        const SizedBox(width: 12),
                        Expanded(child: Text(r, style: T.p(12.5, c: c.text, h: 1.4))),
                      ]),
                    ),
                ],
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? badge;
  final List<Widget> children;
  const _Section({required this.icon, required this.title, required this.children, this.badge});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SFCard(
        radius: 18,
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            IconTile(icon, size: 26, iconSize: 15, radius: 7, bg: c.isDark ? c.mint : const Color(0xFFE3F2E8)),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: T.p(14.5, w: FontWeight.w700, c: c.heading, ls: .3))),
            if (badge != null)
              Pill(badge!,
                  fontSize: 10.5,
                  bg: c.isDark ? c.mint : const Color(0xFFDDF5E6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3)),
          ]),
          const SizedBox(height: 14),
          ...children,
        ]),
      ),
    );
  }
}
