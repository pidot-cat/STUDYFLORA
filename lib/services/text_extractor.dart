import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class UnsupportedFileException implements Exception {
  UnsupportedFileException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Turns PDF / DOCX / TXT bytes into plain text on-device.
class TextExtractor {
  const TextExtractor._();

  static Future<String> extract(String fileName, Uint8List bytes) async {
    final ext = fileName.split('.').last.toLowerCase();
    String text;
    switch (ext) {
      case 'txt':
        text = utf8.decode(bytes, allowMalformed: true);
        break;
      case 'docx':
        text = _docx(bytes);
        break;
      case 'pdf':
        text = await compute(_pdf, bytes);
        break;
      default:
        throw UnsupportedFileException('Only PDF, DOCX, or TXT files are supported.');
    }
    return _reflow(text);
  }

  static String _pdf(Uint8List bytes) {
    final doc = PdfDocument(inputBytes: bytes);
    try {
      return PdfTextExtractor(doc).extractText();
    } finally {
      doc.dispose();
    }
  }

  static String _docx(Uint8List bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);
    final entry = archive.files.firstWhere(
      (f) => f.name == 'word/document.xml',
      orElse: () => throw UnsupportedFileException('Could not read this DOCX file.'),
    );
    final xml = utf8.decode(entry.content as List<int>, allowMalformed: true);
    return xml
        .replaceAll(RegExp(r'</w:p>'), '\n')
        .replaceAll(RegExp(r'<w:tab/>'), ' ')
        .replaceAll(RegExp(r'<w:br[^>]*/>'), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'");
  }

  /// Re-joins lines that a PDF/Word layout broke in the middle of a sentence.
  static String _reflow(String text) {
    final out = <String>[];
    for (final raw in text.replaceAll('\r', '').split('\n')) {
      final line = raw.trim();
      if (line.isEmpty) {
        out.add('');
        continue;
      }
      if (out.isNotEmpty &&
          out.last.isNotEmpty &&
          !RegExp(r'[.!?:]$').hasMatch(out.last) &&
          RegExp(r'^[a-z(]').hasMatch(line)) {
        out[out.length - 1] = '${out.last} $line';
      } else {
        out.add(line);
      }
    }
    return out.join('\n');
  }
}
