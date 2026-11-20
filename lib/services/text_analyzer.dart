import '../models/study.dart';

/// FR-2.3 — rule-based analysis (no ML). The text is first split into
/// headings and paragraphs, then key points are found in this order:
///  1. "Term: explanation" paragraphs
///  2. a short heading followed by the paragraph that explains it
///  3. definition sentences ("X is defined as…", "X refers to…", "X is a…")
/// Only clean concepts are kept (see [goodTitle] / [goodExplanation]) so the
/// quiz never shows broken words, links, references or code.
/// Produces up to eight key points, each with a title and a full-sentence
/// explanation.
class TextAnalyzer {
  static const maxPoints = 8;

  /// Longer files (e.g. a module that also covers an earlier module's topics)
  /// keep more key points: 8 for a normal lesson, up to 20 for big modules.
  static int maxPointsFor(int wordCount) => (wordCount / 180).round().clamp(maxPoints, 20);
  static const _maxExplanation = 320;

  static const stopwords = {
    'the', 'and', 'for', 'are', 'but', 'not', 'you', 'all', 'any', 'can', 'had', 'her', 'was', 'one', 'our', 'out',
    'has', 'have', 'his', 'how', 'its', 'may', 'new', 'now', 'old', 'see', 'two', 'way', 'who', 'did', 'yes', 'yet',
    'this', 'that', 'with', 'from', 'they', 'them', 'then', 'than', 'there', 'their', 'these', 'those', 'what', 'when',
    'where', 'which', 'while', 'will', 'would', 'should', 'could', 'into', 'onto', 'also', 'such', 'each', 'other',
    'some', 'more', 'most', 'many', 'much', 'very', 'been', 'being', 'were', 'does', 'done', 'about', 'after', 'before',
    'because', 'between', 'through', 'during', 'under', 'over', 'only', 'same', 'just', 'like', 'used', 'using', 'uses',
    'use', 'make', 'made', 'makes', 'well', 'example', 'examples', 'refers', 'defined', 'called', 'known', 'include',
    'includes', 'including', 'page', 'chapter', 'lesson', 'module', 'figure', 'table', 'unit', 'part', 'students',
    'student', 'within', 'without', 'upon', 'among', 'every', 'both', 'either', 'neither', 'here', 'your', 'yours',
    'ours', 'mine', 'itself', 'himself', 'herself', 'something', 'anything', 'everything', 'thing', 'things', 'often',
    'usually', 'always', 'never', 'again', 'still', 'even', 'must', 'shall', 'might', 'first', 'second', 'third',
    'another', 'whose', 'whom', 'why', 'per', 'via', 'etc', 'ang', 'mga', 'ng', 'sa', 'na', 'at', 'ay', 'expected',
    'able', 'given', 'following', 'based', 'end', 'help', 'helps',
  };

  static final _leadingArticle = RegExp(r'^(a|an|the)\s+', caseSensitive: false);

  /// Pronouns / vague words that are never a real concept name.
  static const _badTitles = {
    'this', 'it', 'that', 'there', 'these', 'those', 'they', 'he', 'she', 'we', 'you', 'i', 'here', 'which',
    'what', 'who', 'one', 'each', 'all', 'some', 'everything', 'something', 'example', 'note', 'answer',
    'in addition', 'however', 'therefore', 'for example', 'in short', 'in conclusion', 'also',
    // Labels, not concepts ("Tip: …", "Real-world analogy: …", "Output: …").
    'tip', 'tips', 'hint', 'hints', 'notes', 'reminder', 'remember', 'important', 'warning', 'caution', 'analogy',
    'real-world analogy', 'real world analogy', 'real-life example', 'real life example', 'examples', 'sample',
    'output', 'result', 'results', 'syntax', 'usage', 'code', 'source', 'sources', 'reference', 'references',
    'instruction', 'instructions', 'direction', 'directions', 'question', 'questions', 'answers', 'solution',
    'explanation', 'description', 'definition', 'purpose', 'summary', 'overview', 'objective', 'objectives',
    'trivia', 'fun fact', 'did you know', 'key takeaway', 'key takeaways', 'takeaway', 'conclusion', 'introduction',
    'step', 'steps', 'task', 'tasks', 'given', 'required', 'scenario', 'situation', 'method name', 'file name',
    'filename', 'title', 'name', 'date', 'score', 'time', 'prepared by', 'submitted by', 'submitted to',
  };

  /// Document headings like "Lesson 3", "Module 1", "Learning Objectives".
  static final _headingTitle = RegExp(
    r'^(lesson|module|chapter|unit|week|topic|part|section|activity|exercise|quiz|test|exam|page|figure|table|day|'
    r'session|learning objectives?|objectives?|learning outcomes?|references?|name|date|subject|course|instructor|'
    r'prepared by|introduction|overview|summary|conclusion|activities|assessment|review questions?)\b',
    caseSensitive: false,
  );

  /// Intro lines of a learning-objectives list ("At the end of this module…").
  static final _objectiveIntro = RegExp(
    r'^(at the end of|by the end of|after (this|the) (lesson|module|chapter)|upon completion|students? (are|will|should)|'
    r'you (are|will|should) be able|learners? (are|will|should)|in this (lesson|module|chapter))',
    caseSensitive: false,
  );

  static final _bullet = RegExp(r'^\s*(?:[-•*▪●◦–]|\d{1,2}[.)]|[a-zA-Z][.)])\s+');

  /// Words a real concept name never starts with ("After the designing",
  /// "Provides the f", "Can", "Below"…).
  static const _badStart = {
    'after', 'before', 'this', 'that', 'these', 'those', 'there', 'here', 'on', 'in', 'at', 'by', 'for', 'to', 'of',
    'with', 'from', 'as', 'can', 'could', 'will', 'would', 'should', 'may', 'might', 'must', 'be', 'is', 'are', 'was',
    'were', 'go', 'do', 'does', 'did', 'describe', 'apply', 'explain', 'identify', 'enumerate', 'discuss', 'define',
    'list', 'provides', 'provide', 'helps', 'help', 'clear', 'below', 'above', 'through', 'let', 'how', 'what', 'why',
    'when', 'where', 'who', 'which', 'if', 'while', 'since', 'because', 'also', 'however', 'then', 'once', 'during',
    'further', 'furthermore', 'moreover', 'and', 'or', 'but', 'so', 'look', 'ponder', 'note', 'read', 'see', 'try',
    'make', 'use', 'using', 'based', 'according', 'such', 'each', 'every', 'all', 'some', 'any', 'many', 'more',
    'most', 'it', 'its', 'you', 'your', 'we', 'our', 'they', 'their', 'he', 'she', 'his', 'her', 'i', 'my', 'one',
    'only', 'other', 'another', 'not', 'no', 'yes', 'just', 'very', 'even', 'like', 'unlike', 'into', 'onto', 'over',
    'under', 'about', 'around', 'among', 'between', 'without', 'within', 'than', 'thus', 'hence', 'therefore',
    'understand', 'analyze', 'distinguish', 'create', 'know', 'learn', 'determine', 'compare', 'evaluate',
    'answer', 'click', 'select', 'choose', 'write', 'submit', 'return', 'get', 'set', 'new', 'var', 'const', 'final',
    'public', 'private', 'static', 'void', 'function', 'def', 'class', 'import', 'export', 'echo', 'print',
  };

  /// Words a concept name never ends with ("…research according", "…for").
  static const _badEnd = {
    'the', 'a', 'an', 'of', 'for', 'to', 'in', 'on', 'at', 'by', 'with', 'from', 'and', 'or', 'but', 'as', 'is',
    'are', 'be', 'was', 'were', 'should', 'would', 'could', 'can', 'will', 'may', 'must', 'between', 'according',
    'about', 'into', 'than', 'that', 'which', 'who', 'whose', 'this', 'these', 'those', 'its', 'their', 'our', 'your',
    'very', 'such', 'also', 'not', 'there', 'here', 'we', 'you', 'they', 'it',
  };

  static final _url = RegExp(r'(https?://|www\.)\S+|\bbit\.ly/\S+', caseSensitive: false);
  static final _codey = RegExp(r'[{}\[\];=<>$|`\\]|//|=>|->|::|\(\)');
  static final _referencesHeading = RegExp(
    r'^(references?|bibliography|sources|works cited|readings|suggested readings|further readings?|links?)\s*:?$',
    caseSensitive: false,
  );

  /// A short noun-phrase-like name: 1–6 real words, no punctuation, digits,
  /// code or dangling function words.
  static bool goodTitle(String t) {
    if (t.length < 2 || t.length > 60) return false;
    if (RegExp(r'[,;:?!()"“”\[\]{}<>=/\\|$@#*_]').hasMatch(t)) return false;
    if (RegExp(r'\d').hasMatch(t)) return false;
    final ws = t.split(RegExp(r'\s+'));
    if (ws.length > 6) return false;
    final first = ws.first.toLowerCase(), last = ws.last.toLowerCase();
    if (_badStart.contains(first) || _badEnd.contains(last)) return false;
    // Every word must be a real word (no "desi", "f" fragments), acronyms OK.
    for (final w in ws) {
      final isAcronym = RegExp(r'^[A-Z]{2,6}s?$').hasMatch(w);
      if (!isAcronym && !RegExp(r"^[A-Za-z][A-Za-z\-']*[A-Za-z]$").hasMatch(w)) return false;
      if (!isAcronym && w.length < 3 && !{'of', 'in', 'on', 'to', 'by', 'as', 'at', 'or', 'an'}.contains(w.toLowerCase())) return false;
    }
    return true;
  }

  /// A readable full-sentence explanation (no links, code or list intros).
  static bool goodExplanation(String raw) {
    final e = raw.trim();
    if (e.isEmpty) return false;
    // Text that continues a broken word/sentence starts in lowercase.
    if (RegExp(r'^[a-z]').hasMatch(e)) return false;
    if (RegExp(r'[:,;\-–]\s*$').hasMatch(e) || e.endsWith('?')) return false;
    if (_url.hasMatch(e) || _codey.allMatches(e).length >= 2) return false;
    // List letters mixed in from another column ("…current c. environmental… d. e.").
    if (RegExp(r'(?:^|\s)[a-hA-H]\.(?=\s|$)').hasMatch(e)) return false;
    final lastWord = RegExp(r'([A-Za-z]+)\W*$').firstMatch(e)?.group(1)?.toLowerCase();
    if (lastWord != null && _badEnd.contains(lastWord)) return false;
    final ws = e.split(RegExp(r'\s+'));
    if (ws.length < 6) return false;
    final letters = RegExp(r'[A-Za-z]').allMatches(e).length;
    if (letters < e.replaceAll(' ', '').length * 0.75) return false;
    // Too many 1–2 letter fragments → broken extraction.
    if (ws.any((w) => RegExp(r'^[b-hj-z]$').hasMatch(w))) return false;
    final frags = ws.where((w) => RegExp(r'^[a-z]{1,2}$').hasMatch(w) && !_shortWords.contains(w)).length;
    return frags <= 1;
  }

  static const _shortWords = {'a', 'an', 'as', 'at', 'be', 'by', 'do', 'go', 'he', 'if', 'in', 'is', 'it', 'me', 'my', 'no', 'of', 'on', 'or', 'so', 'to', 'up', 'us', 'we', 'am'};

  static String clean(String raw) => raw
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .replaceAll(RegExp(r'[ \t ]+'), ' ')
      .replaceAll(RegExp(r'\n[ ]+'), '\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();

  static List<String> words(String text) =>
      RegExp(r"[A-Za-z][A-Za-z\-']+").allMatches(text).map((m) => m.group(0)!).toList();

  // ---------------------------------------------------------------------------
  // Structure: headings + paragraphs
  // ---------------------------------------------------------------------------

  static bool _endsSentence(String l) => RegExp(r'[.!?;:,…)"”]$').hasMatch(l);

  /// Short line without ending punctuation, e.g. "Conceptual Framework".
  static bool isHeading(String line) {
    final l = line.trim();
    if (l.isEmpty || _endsSentence(l) || _bullet.hasMatch(l)) return false;
    final ws = l.split(' ');
    // "Research is the process of gathering information for" is the first
    // line of a sentence, not a heading.
    if (_badEnd.contains(ws.last.toLowerCase()) || RegExp(r'\b(is|are|was|were|refers?|means|has|have)\b').hasMatch(l)) {
      return false;
    }
    return ws.length <= 8 && l.length <= 70 && RegExp(r'^[A-Z0-9]').hasMatch(l) && RegExp(r'[A-Za-z]{2}').hasMatch(l);
  }

  /// Splits the text into blocks. A block is either a heading (`heading`
  /// set, `text` empty) or a paragraph. Wrapped PDF lines are joined back
  /// together; bullets each start a new paragraph.
  static List<({String? heading, String text})> blocks(String raw) {
    final lines = clean(raw).split('\n');
    final out = <({String? heading, String text})>[];
    final buf = StringBuffer();
    void flush() {
      final t = buf.toString().trim();
      if (t.isNotEmpty) out.add((heading: null, text: t));
      buf.clear();
    }

    for (var i = 0; i < lines.length; i++) {
      final l = lines[i].trim();
      if (l.isEmpty) {
        flush();
        continue;
      }
      final next = i + 1 < lines.length ? lines[i + 1].trim() : '';
      // A heading line must be followed by more text and not be mid-sentence.
      if (buf.isEmpty && isHeading(l) && next.isNotEmpty && !RegExp(r'^[a-z]').hasMatch(next) && !_termLine.hasMatch(l)) {
        out.add((heading: l, text: ''));
        continue;
      }
      final continues = buf.isNotEmpty && !_endsSentence(buf.toString().trim()) && RegExp(r'^[a-z]').hasMatch(l);
      if (_bullet.hasMatch(l) || (_termLine.hasMatch(l) && !continues)) flush();
      // "sub-" + "problems" → "sub-problems" (word split across lines).
      final splitWord = buf.isNotEmpty && RegExp(r'[A-Za-z]-$').hasMatch(buf.toString()) && RegExp(r'^[a-z]').hasMatch(l);
      if (buf.isNotEmpty && !splitWord) buf.write(' ');
      buf.write(l);
      if (_endsSentence(l) && (next.isEmpty || _bullet.hasMatch(next) || isHeading(next) || _termLine.hasMatch(next))) {
        flush();
      }
    }
    flush();
    return out;
  }

  /// Sentences, never crossing a heading or paragraph boundary.
  static List<String> sentences(String text) => [
        for (final b in blocks(text))
          if (b.heading == null) ..._splitSentences(b.text),
      ].where((s) => s.split(' ').length >= 5).toList();

  static List<String> _splitSentences(String p) => p
      .split(RegExp(r'(?<=[.!?])\s+(?=[A-Z0-9"“(])'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  // ---------------------------------------------------------------------------
  // Analysis
  // ---------------------------------------------------------------------------

  static final _termLine = RegExp(r'^\s*(?:[-•*▪●\d.)]+\s*)?([A-Za-z][^:\n]{1,60}?)(?:\s*[:–—]|\s+-)\s+(.{15,})$');

  static final _defPatterns = [
    RegExp(r'^(?:(?:a|an|the)\s+)?([A-Za-z][\w\s\-()/]{1,50}?)\s+(?:is|are|was|were|can be|may be|has been|have been)\s+(?:defined|described|known)\s+as\s+(.+)$', caseSensitive: false),
    RegExp(r'^(?:(?:a|an|the)\s+)?([A-Za-z][\w\s\-()/]{1,50}?)\s+refers?\s+to\s+(.+)$', caseSensitive: false),
    RegExp(r'^(?:(?:a|an|the)\s+)?([A-Za-z][\w\s\-()/]{1,50}?)\s+means\s+(.+)$', caseSensitive: false),
    RegExp(r'^(?:(?:A|An|The)\s+)?([A-Z][\w\-()/]*(?:\s+[\w\-()/]+){0,4}?)\s+(?:is|are)\s+((?:a|an|the|one|any)\s+.+)$'),
  ];

  static final _citationCue = RegExp(
    r'(https?://|www\.|bit\.ly|isbn|doi|retrieved|et al\.?|edition|press|publish|journal|vol\.|pp\.|prepared by|faculty|university|college|library|\(\d{4}\)|\b(19|20)\d{2}\b)',
    caseSensitive: false,
  );

  /// A line from a reference list: a citation, a link, or the short
  /// author / "Prepared by" lines that follow it.
  static bool _isReferenceEntry(({String? heading, String text}) b) {
    final t = (b.heading ?? b.text).trim();
    if (t.isEmpty) return true;
    if (_citationCue.hasMatch(t)) return true;
    // "Bell, Judith." / "Kendall, Kenneth and Kendall, Julie"
    if (RegExp(r'^[A-Z][A-Za-z\-]+, [A-Z]').hasMatch(t)) return true;
    // Names and titles in capitals ("ARNEL B. OCAY, DIT").
    if (t.split(' ').length <= 8 && t == t.toUpperCase()) return true;
    return false;
  }

  static List<KeyPoint> analyze(String raw) {
    final bs = blocks(raw);
    final limit = maxPointsFor(words(raw).length);
    final points = <KeyPoint>[];
    final seen = <String>{};
    final seenExplanations = <String>{};

    bool add(String title, String explanation) {
      if (points.length >= limit) return false;
      title = _tidyTitle(title.replaceFirst(_leadingArticle, '').replaceAll(RegExp(r'\s*\([^)]*\)'), ''));
      final rawExplanation = explanation
          .replaceAll(RegExp(r'(?<=\s)[a-h]\.(?=\s|$)'), '') // stray list letters from another column
          .replaceAll(RegExp(r'(?<=\w)- (?=[a-z])'), '-') // "research- related" → "research-related"
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      if (!goodTitle(title) || !goodExplanation(rawExplanation)) return false;
      explanation = _tidyExplanation(rawExplanation);
      final key = title.toLowerCase();
      if (_badTitles.contains(key) || _headingTitle.hasMatch(title) || _objectiveIntro.hasMatch(title)) return false;
      final ekey = explanation.toLowerCase();
      if (seen.contains(key) || seenExplanations.contains(ekey)) return false;
      seen.add(key);
      seenExplanations.add(ekey);
      points.add(KeyPoint(title, explanation));
      return true;
    }

    // Skip learning-objective lists: an intro line ending with ":" and the
    // bullets that follow it are goals, not concepts.
    final skip = <int>{};
    // A "References" heading starts a bibliography. Skip it and the citation
    // entries under it, but start reading again at the next real section, so a
    // file that joins several lessons (each with its own references) is still
    // analyzed past the first reference list.
    for (var i = 0; i < bs.length; i++) {
      if (!_referencesHeading.hasMatch((bs[i].heading ?? bs[i].text).trim())) continue;
      skip.add(i);
      var j = i + 1;
      while (j < bs.length && _isReferenceEntry(bs[j])) {
        skip.add(j);
        j++;
      }
      i = j - 1;
    }
    for (var i = 0; i < bs.length; i++) {
      final t = bs[i].heading ?? bs[i].text;
      if (_objectiveIntro.hasMatch(t) || RegExp(r'objectives?:?$', caseSensitive: false).hasMatch(t)) {
        skip.add(i);
        for (var j = i + 1; j < bs.length && bs[j].heading == null && _bullet.hasMatch(bs[j].text); j++) {
          skip.add(j);
        }
      }
    }

    // 1) "Term: explanation"
    for (var i = 0; i < bs.length; i++) {
      if (skip.contains(i) || bs[i].heading != null) continue;
      final m = _termLine.firstMatch(bs[i].text.replaceFirst(_bullet, ''));
      if (m != null) add(m.group(1)!, _firstSentences(_capitalize(m.group(2)!.trim())));
    }

    // 1b) "What is a research question?" followed by bullet answers.
    for (var i = 0; i < bs.length - 1; i++) {
      if (skip.contains(i)) continue;
      final q = RegExp(r'^what (?:is|are) (?:a |an |the )?(.{2,50}?)\s*\?$', caseSensitive: false).firstMatch((bs[i].heading ?? bs[i].text).trim());
      if (q == null) continue;
      final parts = <String>[];
      for (var j = i + 1; j < bs.length && parts.length < 2 && bs[j].heading == null && _bullet.hasMatch(bs[j].text); j++) {
        var t = bs[j].text.replaceFirst(_bullet, '').trim();
        if (RegExp(r'^(is|are)\b', caseSensitive: false).hasMatch(t)) t = 'It $t';
        t = _capitalize(t);
        if (!RegExp(r'[.!?]$').hasMatch(t)) t = '$t.';
        parts.add(t);
      }
      if (parts.isNotEmpty) add(q.group(1)!, parts.join(' '));
    }

    // 2) heading + explaining paragraph
    for (var i = 0; i < bs.length - 1; i++) {
      final h = bs[i].heading;
      if (h == null || skip.contains(i) || skip.contains(i + 1)) continue;
      final body = bs[i + 1];
      if (body.heading != null || _termLine.hasMatch(body.text) || _bullet.hasMatch(body.text)) continue;
      add(h, _firstSentences(body.text));
    }

    // 3) definition sentences inside paragraphs
    for (var i = 0; i < bs.length; i++) {
      if (skip.contains(i) || bs[i].heading != null) continue;
      final ss = _splitSentences(bs[i].text.replaceFirst(_bullet, ''));
      for (var k = 0; k < ss.length; k++) {
        for (final p in _defPatterns) {
          final m = p.firstMatch(ss[k]);
          if (m == null) continue;
          // Keep the whole sentence (and a follow-up "It/This…" sentence) so
          // the explanation reads naturally.
          final follow = k + 1 < ss.length && RegExp(r'^(it|this|they|these|its)\b', caseSensitive: false).hasMatch(ss[k + 1]);
          add(m.group(1)!, follow ? '${ss[k]} ${ss[k + 1]}' : ss[k]);
          break;
        }
      }
    }

    return points;
  }

  static List<String> topTerms(String text, int n) {
    final freq = <String, int>{};
    for (final w in words(text)) {
      final l = w.toLowerCase();
      if (l.length < 4 || stopwords.contains(l)) continue;
      freq[l] = (freq[l] ?? 0) + 1;
    }
    final list = freq.entries.where((e) => e.value >= 3).toList()..sort((a, b) => b.value.compareTo(a.value));
    return list.take(n).map((e) => e.key).toList();
  }

  /// Best guess for a module title: the first heading-like line that is not
  /// an objectives intro; otherwise the file name.
  static String guessTitle(String raw, String fileName) {
    for (final line in clean(raw).split('\n').take(15)) {
      final l = line.trim();
      final wc = l.split(' ').length;
      if (l.length < 4 || wc > 10 || l.endsWith('.') || l.endsWith(':') || l.endsWith(',')) continue;
      if (_objectiveIntro.hasMatch(l) || _bullet.hasMatch(l) || !RegExp(r'[A-Za-z]{2}').hasMatch(l)) continue;
      if (_badStart.contains(l.split(' ').first.toLowerCase()) || _url.hasMatch(l) || _codey.hasMatch(l)) continue;
      if (_badEnd.contains(l.split(' ').last.toLowerCase())) continue;
      return _tidyTitle(l);
    }
    final base = fileName.contains('.') ? fileName.substring(0, fileName.lastIndexOf('.')) : fileName;
    return _capitalize(base.replaceAll(RegExp(r'[_\-]+'), ' ').trim());
  }

  /// Up to two sentences, never cut in the middle of a sentence when possible.
  static String _firstSentences(String p) {
    final ss = _splitSentences(p);
    if (ss.isEmpty) return p;
    var out = ss.first;
    if (ss.length > 1 && (out.length + ss[1].length) < _maxExplanation) out = '$out ${ss[1]}';
    return out;
  }

  static String _tidyTitle(String s) {
    s = s.replaceAll(RegExp(r'^[\s\-•*▪●\d.)]+'), '').replaceAll(RegExp(r'[\s:.\-–—,;]+$'), '').trim();
    if (s.length > 60) s = s.substring(0, 60).trim();
    return _capitalize(s);
  }

  static String _tidyExplanation(String s) {
    s = s.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (s.length > _maxExplanation) {
      // Prefer ending at a sentence boundary.
      final cut = s.substring(0, _maxExplanation);
      final dot = cut.lastIndexOf(RegExp(r'[.!?]\s'));
      if (dot > 80) {
        s = cut.substring(0, dot + 1);
      } else {
        final i = cut.lastIndexOf(' ');
        s = '${cut.substring(0, i > 0 ? i : _maxExplanation)}…';
      }
    }
    if (s.isNotEmpty) s = s[0].toUpperCase() + s.substring(1);
    if (!RegExp(r'[.!?…]$').hasMatch(s)) s = '$s.';
    return s;
  }

  static String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
