import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class ExtractionException implements Exception {
  final String message;
  ExtractionException(this.message);
  @override
  String toString() => message;
}

/// FR-2.2 — on-device text extraction for PDF, DOCX and TXT.
/// PDF/DOCX work runs in a background isolate (NFR 4.2).
class TextExtractor {
  static const supported = ['pdf', 'docx', 'txt'];

  static Future<String> extract(Uint8List bytes, String extension) async {
    final ext = extension.toLowerCase();
    switch (ext) {
      case 'txt':
        return _decodeTxt(bytes);
      case 'docx':
        return compute(_extractDocx, bytes);
      case 'pdf':
        return compute(_extractPdf, bytes);
      default:
        throw ExtractionException('Unsupported file type. Please upload a PDF, DOCX or TXT file.');
    }
  }

  static String _decodeTxt(Uint8List bytes) {
    try {
      return utf8.decode(bytes);
    } catch (_) {
      return latin1.decode(bytes);
    }
  }
}

String _extractPdf(Uint8List bytes) {
  PdfDocument? doc;
  try {
    doc = PdfDocument(inputBytes: bytes);
    final extractor = PdfTextExtractor(doc);
    final pages = <String>[];
    for (var p = 0; p < doc.pages.count; p++) {
      String page;
      try {
        page = _layoutPage(extractor.extractTextLines(startPageIndex: p, endPageIndex: p));
      } catch (_) {
        page = extractor.extractText(startPageIndex: p, endPageIndex: p);
      }
      if (page.trim().isNotEmpty) pages.add(page.trim());
    }
    return pages.join('\n\n');
  } catch (e) {
    throw ExtractionException('This PDF could not be read. It may be password-protected or damaged.');
  } finally {
    doc?.dispose();
  }
}

typedef _W = ({String t, double l, double r, double top, double bottom});

double _h(_W w) => (w.bottom - w.top).abs().clamp(4.0, 80.0).toDouble();

/// Rebuilds the visual lines of a PDF page from word positions. The plain
/// extractor often returns every text run on its own line ("desi" / "gn",
/// lone ":" or "-"), which breaks sentences and words apart. Two-column
/// parts of a page are read column by column.
String _layoutPage(List<TextLine> lines) {
  final words = <_W>[];
  for (final line in lines) {
    final ws = line.wordCollection;
    if (ws.isEmpty) {
      final t = line.text.trim();
      if (t.isNotEmpty) words.add((t: t, l: line.bounds.left, r: line.bounds.right, top: line.bounds.top, bottom: line.bounds.bottom));
      continue;
    }
    for (final w in ws) {
      final t = w.text.trim();
      if (t.isEmpty) continue;
      words.add((t: t, l: w.bounds.left, r: w.bounds.right, top: w.bounds.top, bottom: w.bounds.bottom));
    }
  }
  if (words.isEmpty) return '';

  final rows = _groupRows(words);
  final split = _columnSplit(rows);
  if (split == null) return _emit(rows);

  // Walk down the page: rows that cross the gutter are full-width; runs of
  // rows that don't are a two-column band (left column first).
  final out = <String>[];
  var band = <List<_W>>[];
  void flushBand() {
    if (band.isEmpty) return;
    final left = [for (final r in band) [for (final w in r) if (w.l < split) w]]..removeWhere((r) => r.isEmpty);
    final right = [for (final r in band) [for (final w in r) if (w.l >= split) w]]..removeWhere((r) => r.isEmpty);
    out.add(_emit(left));
    if (right.isNotEmpty) out.add(_emit(right));
    band = [];
  }

  var full = <List<_W>>[];
  for (final r in rows) {
    final crosses = r.any((w) => w.l < split && w.r > split);
    if (crosses) {
      flushBand();
      full.add(r);
    } else {
      if (full.isNotEmpty) {
        out.add(_emit(full));
        full = [];
      }
      band.add(r);
    }
  }
  flushBand();
  if (full.isNotEmpty) out.add(_emit(full));
  return out.where((x) => x.trim().isNotEmpty).join('\n\n');
}

List<List<_W>> _groupRows(List<_W> words) {
  final sorted = [...words]..sort((a, b) => ((a.top + a.bottom) / 2).compareTo((b.top + b.bottom) / 2));
  final rows = <List<_W>>[];
  for (final w in sorted) {
    final cy = (w.top + w.bottom) / 2;
    if (rows.isNotEmpty) {
      final last = rows.last;
      final ly = last.map((x) => (x.top + x.bottom) / 2).reduce((a, b) => a + b) / last.length;
      if ((cy - ly).abs() < _h(w) * 0.55) {
        last.add(w);
        continue;
      }
    }
    rows.add([w]);
  }
  for (final r in rows) {
    r.sort((a, b) => a.l.compareTo(b.l));
  }
  return rows;
}

/// An x position inside the gutter between two columns on many rows, or
/// null for single-column pages.
double? _columnSplit(List<List<_W>> rows) {
  if (rows.length < 8) return null;
  final all = rows.expand((r) => r);
  final width = all.map((w) => w.r).reduce((a, b) => a > b ? a : b);
  final minX = all.map((w) => w.l).reduce((a, b) => a < b ? a : b);
  final span = width - minX;
  double? best;
  var bestScore = 0;
  for (var x = minX + span * 0.3; x <= minX + span * 0.7; x += 2) {
    var score = 0;
    for (final r in rows) {
      if (r.any((w) => w.l < x && w.r > x)) continue;
      // A real gutter: words on both sides with a wide gap between them.
      final leftEdge = r.where((w) => w.r <= x).map((w) => w.r);
      final rightEdge = r.where((w) => w.l >= x).map((w) => w.l);
      if (leftEdge.isEmpty || rightEdge.isEmpty) continue;
      final gap = rightEdge.reduce((a, b) => a < b ? a : b) - leftEdge.reduce((a, b) => a > b ? a : b);
      if (gap > _h(r.first) * 0.9) score++;
    }
    if (score > bestScore) {
      bestScore = score;
      best = x;
    }
  }
  return bestScore >= 4 && bestScore >= rows.length * 0.15 ? best : null;
}

String _emit(List<List<_W>> rows) {
  final out = StringBuffer();
  double? prevBottom;
  double? prevHeight;
  for (final row in rows) {
    final h = row.map(_h).reduce((a, b) => a > b ? a : b);
    final top = row.map((x) => x.top).reduce((a, b) => a < b ? a : b);
    final buf = StringBuffer();
    double? prevRight;
    for (final w in row) {
      if (prevRight != null) {
        final gap = w.l - prevRight;
        // Runs that touch belong to the same word ("desi"+"gn").
        final glue = gap < h * 0.12 || RegExp(r'^[,.;:!?)\]%]').hasMatch(w.t) || buf.toString().endsWith('(');
        if (!glue) buf.write(' ');
      }
      buf.write(w.t);
      prevRight = w.r;
    }
    final text = buf.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.isEmpty) continue;
    if (prevBottom != null) {
      // A clearly larger vertical gap means a new paragraph.
      out.write(top - prevBottom > (prevHeight ?? h) * 0.9 ? '\n\n' : '\n');
    }
    out.write(text);
    prevBottom = row.map((x) => x.bottom).reduce((a, b) => a > b ? a : b);
    prevHeight = h;
  }
  return out.toString();
}

String _extractDocx(Uint8List bytes) {
  try {
    final archive = ZipDecoder().decodeBytes(bytes);
    final entry = archive.findFile('word/document.xml');
    if (entry == null) throw ExtractionException('This DOCX file has no readable document body.');
    final xml = utf8.decode(entry.content as List<int>, allowMalformed: true);
    // Paragraph ends → newlines, tabs/breaks → spaces, then strip tags.
    final withBreaks = xml
        .replaceAll(RegExp(r'</w:p>'), '\n')
        .replaceAll(RegExp(r'<w:tab/>'), ' ')
        .replaceAll(RegExp(r'<w:br[^>]*/>'), '\n');
    final stripped = withBreaks.replaceAll(RegExp(r'<[^>]+>'), '');
    return stripped
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'");
  } on ExtractionException {
    rethrow;
  } catch (_) {
    throw ExtractionException('This DOCX file could not be opened.');
  }
}
