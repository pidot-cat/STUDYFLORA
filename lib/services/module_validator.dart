import '../core/constants.dart';
import '../models/study.dart';
import 'text_analyzer.dart';

class CheckItem {
  final String label;
  final String detail;
  final bool passed;
  const CheckItem(this.label, this.detail, this.passed);
}

/// Decides whether an uploaded file is a real study module.
///
/// * [accepted]  – SRS FR-2.4: at least 2 key points → module is saved.
/// * [verified]  – stricter "proof it's a module" checks → the user may pick a
///                 reward (random seed / coins / XP), once per unique file.
class ValidationReport {
  final List<CheckItem> checks;
  final bool accepted;
  final bool verified;
  final String? rejectReason;
  const ValidationReport(this.checks, this.accepted, this.verified, this.rejectReason);
}

class ModuleValidator {
  /// "Original content" check that works for any file length.
  ///
  /// The old check (unique words ÷ all words) drops as a file gets longer, so
  /// a bigger module — e.g. Module 2 that repeats Module 1's topics and adds
  /// more — was wrongly marked "Too repetitive". This uses:
  ///  * vocabulary variety inside 100-word windows (same for short and long
  ///    files; real notes score ≈0.65–0.75, copy-pasted filler < 0.3), and
  ///  * how many sentences are exact repeats of earlier ones (the same text
  ///    pasted twice in one file).
  static bool _isOriginal(String text, List<String> words) {
    final w = [for (final x in words) x.toLowerCase()];
    if (w.isEmpty) return false;
    const window = 100;
    double variety;
    if (w.length <= window) {
      variety = w.toSet().length / w.length;
    } else {
      var sum = 0.0, n = 0;
      for (var i = 0; i + window <= w.length; i += 10) {
        sum += w.sublist(i, i + window).toSet().length / window;
        n++;
      }
      variety = sum / n;
    }
    final sentences = [
      for (final s in TextAnalyzer.sentences(text))
        if (s.split(' ').length >= 4) s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim(),
    ];
    final seen = <String>{};
    var repeats = 0;
    for (final s in sentences) {
      if (!seen.add(s)) repeats++;
    }
    final repeatRatio = sentences.isEmpty ? 0.0 : repeats / sentences.length;
    return variety >= 0.40 && repeatRatio < 0.5;
  }

  static const minWords = 100;
  static const minKeyPointsForReward = 3;
  static const minSentences = 6;

  static const _academicCues = [
    'lesson', 'module', 'chapter', 'unit', 'topic', 'objective', 'objectives', 'introduction', 'overview',
    'summary', 'definition', 'concept', 'theory', 'principle', 'process', 'function', 'types of', 'example',
    'importance', 'characteristics', 'advantages', 'disadvantages', 'learning', 'discussion', 'review',
    'assessment', 'activity', 'reference', 'refers to', 'defined as', 'is called', 'consists of',
  ];

  static ValidationReport validate({
    required String text,
    required List<KeyPoint> keyPoints,
    required int fileBytes,
    required String extension,
  }) {
    final words = TextAnalyzer.words(text);
    final wc = words.length;
    final sentences = TextAnalyzer.sentences(text).length;
    final lower = text.toLowerCase();
    final cues = _academicCues.where(lower.contains).length;
    final original = _isOriginal(text, words);

    final typeOk = ['pdf', 'docx', 'txt'].contains(extension.toLowerCase());
    final sizeOk = fileBytes <= GameRules.maxFileBytes;
    // Lesson cues ("lesson", "defined as"…) or several real definitions.
    final structured = cues >= 2 || keyPoints.length >= 4;

    final checks = <CheckItem>[
      CheckItem('Supported file', typeOk ? extension.toUpperCase() : 'PDF, DOCX, TXT only', typeOk),
      CheckItem('Within 25 MB', sizeOk ? 'OK' : 'Too large', sizeOk),
      CheckItem('Readable text', wc == 0 ? 'No text found' : '$wc words', wc >= minWords),
      CheckItem('Complete sentences', '$sentences found', sentences >= minSentences),
      CheckItem('Key points', '${keyPoints.length} found', keyPoints.length >= minKeyPointsForReward),
      CheckItem('Lesson structure', structured ? 'Looks like notes' : 'Not lesson-like', structured),
      CheckItem('Original content', original ? 'Not repetitive' : 'Too repetitive', original),
    ];

    String? reason;
    if (!typeOk) {
      reason = 'Unsupported file type. Please upload a PDF, DOCX or TXT file.';
    } else if (!sizeOk) {
      reason = 'The file is larger than 25 MB.';
    } else if (wc == 0) {
      reason = 'No readable text was found. Scanned PDFs that contain only images cannot be read (no OCR).';
    } else if (wc < 30) {
      reason = 'This file is too short ($wc words). Upload your lesson notes or a module with at least a few paragraphs.';
    } else if (keyPoints.length < 2) {
      reason = 'Fewer than two key points could be extracted. Try organized notes with definitions or "Term: explanation" lines.';
    }
    final accepted = reason == null;
    final verified = accepted && checks.every((c) => c.passed);
    return ValidationReport(checks, accepted, verified, reason);
  }
}
