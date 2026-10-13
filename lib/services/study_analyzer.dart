import '../models/study_module.dart';

class AnalysisResult {
  const AnalysisResult({
    required this.keyPoints,
    required this.facts,
    required this.vocab,
  });

  final List<KeyPoint> keyPoints;
  final List<String> facts;
  final List<String> vocab;
}

/// Offline "AI" reviewer: pulls key points out of raw text with pattern rules
/// (definitions, "Term: explanation" lines) and falls back to frequency-ranked
/// sentences. No network needed, so it works for any Pangasinan classroom
/// connection (or none at all).
class StudyAnalyzer {
  const StudyAnalyzer._();

  static const maxKeyPoints = 8;

  static const _stop = <String>{
    'a', 'an', 'the', 'and', 'or', 'but', 'if', 'then', 'than', 'that', 'this',
    'these', 'those', 'it', 'its', 'is', 'are', 'was', 'were', 'be', 'been',
    'of', 'in', 'on', 'at', 'to', 'for', 'from', 'by', 'with', 'as', 'into',
    'over', 'under', 'about', 'between', 'through', 'during', 'not', 'no',
    'so', 'such', 'can', 'could', 'may', 'might', 'will', 'would', 'should',
    'do', 'does', 'did', 'have', 'has', 'had', 'which', 'who', 'whom', 'what',
    'when', 'where', 'why', 'how', 'also', 'only', 'very', 'more', 'most',
    'other', 'some', 'any', 'each', 'both', 'per', 'via', 'within', 'without',
    'across', 'their', 'there', 'they', 'them', 'we', 'you', 'he', 'she',
    'his', 'her', 'our', 'your', 'one', 'two', 'three', 'first', 'second',
    'however', 'thus', 'therefore', 'while', 'whereas', 'because', 'using',
    'used', 'use', 'called', 'form', 'forms', 'many', 'much', 'often', 'make',
    'makes', 'made', 'like', 'known', 'these', 'those', 'being', 'after',
    'before', 'while', 'where', 'which', 'among', 'could', 'other',
  };

  static const _pronouns = <String>{
    'this', 'it', 'they', 'these', 'those', 'there', 'we', 'he', 'she',
    'which', 'that', 'here', 'you', 'i', 'our', 'their', 'its',
  };

  static const _simpleVerbs = <String>{
    'is', 'are', 'is defined as', 'are defined as', 'is known as',
    'are known as', 'refers to', 'means',
  };

  static const _verbs =
      'is defined as|are defined as|is known as|are known as|is the process of|'
      'refers to|consists of|occurs when|occurs in|breaks down|is|are|means|'
      'involves|produces|yields|converts|generates|transports|stores|contains|'
      'provides';

  static final RegExp _def = RegExp(
    r"^(?:the |a |an )?([A-Za-z][A-Za-z0-9\-\s()/']{2,50}?)\s+(" +
        _verbs +
        r')\s+(.{20,})$',
    caseSensitive: false,
  );

  static final RegExp _kv = RegExp(
    r'^\s*(?:[-•*]|\d+[.)])?\s*([A-Z][^:\n]{1,45}?)\s*(?::|\s[-–—]\s)\s*(\S.{24,})$',
  );

  static final RegExp _sentenceSplit = RegExp(r'(?<=[.!?])\s+(?=[A-Z0-9])');
  static final RegExp _wordRe = RegExp(r"[A-Za-z][A-Za-z\-']{3,}");

  static AnalysisResult analyze(String raw) {
    final text = raw.replaceAll('\r', '');
    final lines = text
        .split('\n')
        .map((l) => l.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final sentences = <String>[];
    for (final line in lines) {
      for (final part in line.split(_sentenceSplit)) {
        final s = part.trim();
        if (s.length >= 25) sentences.add(s);
      }
    }

    final seen = <String>{};
    final points = <KeyPoint>[];
    final used = <String>{};

    void add(String title, String detail) {
      final key = title.toLowerCase().trim();
      if (key.length < 3 || seen.contains(key)) return;
      seen.add(key);
      points.add(KeyPoint(title: _titleCase(title.trim()), detail: _clip(detail)));
    }

    // 1) "Term: explanation" or "Term - explanation" lines.
    for (final line in lines) {
      final m = _kv.firstMatch(line);
      if (m != null && m.group(1)!.trim().split(' ').length <= 6) {
        add(m.group(1)!, _upperFirst(m.group(2)!.trim()));
        used.add(line);
      }
    }

    // 2) Definition-style sentences: "X is/refers to/produces ...".
    for (final s in sentences) {
      if (_kv.hasMatch(s)) continue;
      final m = _def.firstMatch(s);
      if (m == null) continue;
      final term = m.group(1)!.trim();
      final words = term.split(RegExp(r'\s+'));
      if (words.length > 6 || _pronouns.contains(words.first.toLowerCase())) {
        continue;
      }
      final verb = m.group(2)!.toLowerCase();
      final rest = m.group(3)!.trim();
      final String detail;
      if (verb == 'is the process of') {
        detail = 'The process of $rest';
      } else if (_simpleVerbs.contains(verb)) {
        detail = rest;
      } else {
        detail = '${_upperFirst(verb)} $rest';
      }
      add(term, _upperFirst(detail));
      used.add(s);
    }

    // 3) Fallback: highest-scoring sentences when the text has no definitions.
    final freq = _frequencies(text);
    if (points.length < 3) {
      final scored = <MapEntry<String, double>>[];
      for (final s in sentences) {
        if (used.contains(s) || s.length < 40 || s.length > 260) continue;
        final words = _significantWords(s);
        if (words.isEmpty) continue;
        var score = 0.0;
        for (final w in words) {
          score += freq[w] ?? 0;
        }
        scored.add(MapEntry(s, score / (words.length + 2)));
      }
      scored.sort((a, b) => b.value.compareTo(a.value));
      for (final e in scored) {
        if (points.length >= maxKeyPoints) break;
        final words = _significantWords(e.key);
        words.sort((a, b) => (freq[b] ?? 0).compareTo(freq[a] ?? 0));
        add(words.first, e.key);
      }
    }

    final keyPoints = points.take(maxKeyPoints).toList();

    final facts = <String>[];
    for (final s in sentences) {
      if (s.length >= 40 && s.length <= 260 && !_kv.hasMatch(s)) facts.add(s);
      if (facts.length >= 60) break;
    }

    final vocab = freq.entries.where((e) => e.key.length >= 5).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final vocabWords = vocab.take(40).map((e) => e.key).toList();

    return AnalysisResult(keyPoints: keyPoints, facts: facts, vocab: vocabWords);
  }

  static Map<String, int> _frequencies(String text) {
    final map = <String, int>{};
    for (final m in _wordRe.allMatches(text)) {
      final w = m.group(0)!.toLowerCase();
      if (_stop.contains(w)) continue;
      map[w] = (map[w] ?? 0) + 1;
    }
    return map;
  }

  static List<String> _significantWords(String s) => _wordRe
      .allMatches(s)
      .map((m) => m.group(0)!.toLowerCase())
      .where((w) => !_stop.contains(w))
      .toList();

  static String _upperFirst(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  static const _smallWords = {'of', 'and', 'the', 'in', 'to', 'for', 'a', 'on'};

  static String _titleCase(String t) {
    final words = t.split(RegExp(r'\s+'));
    final out = <String>[];
    for (var i = 0; i < words.length; i++) {
      final w = words[i];
      final hasInnerCaps = w.length > 1 && w.substring(1) != w.substring(1).toLowerCase();
      final hasDigit = RegExp(r'\d').hasMatch(w);
      if (hasInnerCaps || hasDigit) {
        out.add(w);
      } else if (i > 0 && _smallWords.contains(w.toLowerCase())) {
        out.add(w.toLowerCase());
      } else {
        out.add(_upperFirst(w.toLowerCase()));
      }
    }
    return out.join(' ');
  }

  static String _clip(String s, [int max = 200]) {
    var t = s.trim();
    if (t.length > max) {
      final cut = t.lastIndexOf(' ', max);
      t = '${t.substring(0, cut > 40 ? cut : max).trimRight()}…';
      return t;
    }
    if (!RegExp(r'[.!?…]$').hasMatch(t)) t = '$t.';
    return t;
  }
}
