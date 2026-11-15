import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_application_project/models/study.dart';
import 'package:mobile_application_project/services/module_validator.dart';
import 'package:mobile_application_project/services/quiz_generator.dart';
import 'package:mobile_application_project/services/text_analyzer.dart';
import 'package:mobile_application_project/services/text_extractor.dart';

/// QA helper: runs the real pipeline on the sample files in test_files/ and
/// prints what the app would show. Skips when the folder is missing.
void main() {
  final dir = Directory('test_files');
  test('sample study files produce clean key points', () async {
    if (!dir.existsSync()) return;
    for (final f in dir.listSync().whereType<File>()) {
      final ext = f.path.split('.').last.toLowerCase();
      if (!TextExtractor.supported.contains(ext)) continue;
      final bytes = Uint8List.fromList(f.readAsBytesSync());
      final text = await TextExtractor.extract(bytes, ext);
      final kps = TextAnalyzer.analyze(text);
      final report = ModuleValidator.validate(text: text, keyPoints: kps, fileBytes: bytes.length, extension: ext);
      // ignore: avoid_print
      print('\n=== ${f.path} | title: ${TextAnalyzer.guessTitle(text, f.uri.pathSegments.last)} | accepted=${report.accepted} verified=${report.verified}');
      for (final c in report.checks) {
        // ignore: avoid_print
        print('  [${c.passed ? 'x' : ' '}] ${c.label}: ${c.detail}');
      }
      for (final k in kps) {
        // ignore: avoid_print
        print('  * ${k.title} -> ${k.explanation}');
      }
      if (kps.length >= 2) {
        final m = StudyModule(id: 'x', hash: 'h', title: 't', fileName: 'f', fileType: ext, fileBytes: 1, wordCount: 1, keyPoints: kps, createdAt: 0);
        for (final q in QuizGenerator.generate(m, seed: 7).take(4)) {
          // ignore: avoid_print
          print('  Q(${q.typeLabel}) ${q.prompt.replaceAll('\n', ' ')}');
          for (var i = 0; i < q.options.length; i++) {
            // ignore: avoid_print
            print('     ${i == q.answer ? '>' : ' '} ${q.options[i]}');
          }
          // ignore: avoid_print
          print('     insight: ${q.insight}');
        }
      }
    }
  });
}
