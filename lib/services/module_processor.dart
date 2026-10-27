import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../data/seed_data.dart';
import '../models/models.dart';

/// Result of processing an uploaded study file entirely on-device.
class ProcessedFile {
  final StudyModule module;
  final String hash;
  ProcessedFile(this.module, this.hash);
}

/// Offline, rule-based processing: extracts text from PDF/DOCX/TXT, picks key
/// sentences by word frequency and builds multiple-choice + fill-in-the-blank
/// questions from them. No network or AI service is used.
class ModuleProcessor {
  static const maxBytes = 25 * 1024 * 1024;

  static Future<ProcessedFile> process(File file, String fileName) async {
    final bytes = await file.readAsBytes();
    if (bytes.length > maxBytes) throw Exception('File is larger than 25 MB.');
    final hash = sha256.convert(bytes).toString();
    final ext = fileName.split('.').last.toLowerCase();
    String text;
    switch (ext) {
      case 'pdf':
        final doc = PdfDocument(inputBytes: bytes);
        text = PdfTextExtractor(doc).extractText();
        doc.dispose();
        break;
      case 'docx':
        text = _docxText(bytes);
        break;
      default:
        text = utf8.decode(bytes, allowMalformed: true);
    }
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    final title = _titleFrom(fileName);
    final sentences = _sentences(text);
    final ranked = _rank(sentences);
    final kp = <KeyPoint>[];
    for (final s in ranked.take(4)) {
      kp.add(_toKeyPoint(s));
    }
    final questions = _buildQuestions(ranked, text);
    final module = StudyModule(
      id: 'm_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      fileName: fileName,
      ext: ext,
      sizeBytes: bytes.length,
      uploadedAt: DateTime.now(),
      category: 'General',
      iconKey: 'file',
      keyPoints: kp.isEmpty ? const [KeyPoint('Overview', 'No readable text was found in this file.')] : kp,
      overview: kp.map((k) => k.term).toList(),
      questions: questions.length >= 4 ? questions : SeedData.plantCellQuiz,
      fullText: text.length > 20000 ? text.substring(0, 20000) : text,
    );
    return ProcessedFile(module, hash);
  }

  static String _docxText(List<int> bytes) {
    final arc = ZipDecoder().decodeBytes(bytes);
    final f = arc.findFile('word/document.xml');
    if (f == null) return '';
    final xml = utf8.decode(f.content as List<int>, allowMalformed: true);
    return xml
        .replaceAll(RegExp(r'</w:p>'), '. ')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
  }

  static String _titleFrom(String name) {
    final base = name.contains('.') ? name.substring(0, name.lastIndexOf('.')) : name;
    return base.replaceAll(RegExp(r'[_\-]+'), ' ').trim();
  }

  static List<String> _sentences(String text) => text
      .split(RegExp(r'(?<=[.!?])\s+'))
      .map((s) => s.trim())
      .where((s) => s.split(' ').length >= 6 && s.length < 300)
      .toList();

  static const _stop = {
    'the',
    'and',
    'of',
    'to',
    'a',
    'in',
    'is',
    'are',
    'for',
    'on',
    'with',
    'as',
    'by',
    'that',
    'this',
    'it',
    'be',
    'or',
    'from',
    'an',
    'at',
    'which',
    'its',
    'into',
    'their',
    'can',
    'was',
    'were',
    'has',
    'have',
    'also',
    'these',
    'such',
    'than',
    'they',
    'not',
    'but',
    'other',
    'between',
    'during'
  };

  static List<String> _words(String s) =>
      RegExp(r"[A-Za-z][A-Za-z\-']{2,}").allMatches(s).map((m) => m.group(0)!).toList();

  static List<String> _rank(List<String> sentences) {
    final freq = <String, int>{};
    for (final s in sentences) {
      for (final w in _words(s)) {
        final k = w.toLowerCase();
        if (!_stop.contains(k)) freq[k] = (freq[k] ?? 0) + 1;
      }
    }
    double score(String s) {
      final ws = _words(s).where((w) => !_stop.contains(w.toLowerCase())).toList();
      if (ws.isEmpty) return 0;
      return ws.fold<int>(0, (a, w) => a + (freq[w.toLowerCase()] ?? 0)) / math.sqrt(ws.length);
    }

    final copy = [...sentences]..sort((a, b) => score(b).compareTo(score(a)));
    return copy.take(12).toList();
  }

  static KeyPoint _toKeyPoint(String s) {
    final colon = s.indexOf(':');
    if (colon > 2 && colon < 40) return KeyPoint(s.substring(0, colon).trim(), s.substring(colon + 1).trim());
    final ws = _words(s).where((w) => !_stop.contains(w.toLowerCase())).toList();
    final term = ws.isEmpty ? 'Key Idea' : ws.take(2).map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
    return KeyPoint(term, s);
  }

  static List<QuizQuestion> _buildQuestions(List<String> ranked, String text) {
    final rnd = math.Random(text.length);
    final pool = _words(text).where((w) => w.length > 5 && !_stop.contains(w.toLowerCase())).toSet().toList();
    final out = <QuizQuestion>[];
    for (final s in ranked) {
      if (out.length >= 10) break;
      final candidates = _words(s).where((w) => w.length > 5 && !_stop.contains(w.toLowerCase())).toList();
      if (candidates.isEmpty || pool.length < 4) continue;
      candidates.sort((a, b) => b.length.compareTo(a.length));
      final answer = candidates.first;
      final distractors =
          (pool.where((w) => w.toLowerCase() != answer.toLowerCase()).toList()..shuffle(rnd)).take(3).toList();
      if (distractors.length < 3) continue;
      final opts = [...distractors, answer]..shuffle(rnd);
      out.add(QuizQuestion(
        prompt: s.replaceFirst(answer, '______'),
        options: opts,
        answer: opts.indexOf(answer),
        insight: s,
        fillBlank: true,
      ));
    }
    return out;
  }
}
