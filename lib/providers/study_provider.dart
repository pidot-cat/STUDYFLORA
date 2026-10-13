import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/storage_keys.dart';
import '../core/utils/coin_rewards.dart';
import '../models/quiz_models.dart';
import '../models/study_module.dart';
import '../services/quiz_generator.dart';
import '../services/storage_service.dart';
import '../services/study_analyzer.dart';
import '../services/text_extractor.dart';
import 'user_provider.dart';

enum StudyView { review, aiHub }

enum QuizPhase { idle, running, finished }

enum UploadStatus { success, duplicate, cancelled, tooBig, unreadable, notEnoughContent }

class UploadOutcome {
  const UploadOutcome(this.status, [this.message = '']);
  final UploadStatus status;
  final String message;
}

/// Study Review (upload + key points) and AI Hub (quiz + rewards) state.
class StudyProvider extends ChangeNotifier {
  StudyProvider(this._s, this._user) {
    _load();
  }

  static const maxFileBytes = 25 * 1024 * 1024;
  static const secondsPerQuestion = 30;

  final StorageService _s;
  final UserProvider _user;

  // ---- library --------------------------------------------------------------
  final List<StudyModule> _modules = [];
  final List<QuizResult> _results = [];
  String? _currentId;
  bool processing = false;
  StudyView view = StudyView.review;

  List<StudyModule> get modules => List.unmodifiable(_modules);
  List<QuizResult> get results => List.unmodifiable(_results);

  StudyModule? get current {
    if (_modules.isEmpty) return null;
    return _modules.firstWhere((m) => m.id == _currentId, orElse: () => _modules.first);
  }

  List<StudyModule> get archived =>
      _modules.where((m) => m.id != current?.id).toList();

  // ---- quiz session -----------------------------------------------------------
  QuizPhase phase = QuizPhase.idle;
  List<QuizQuestion> questions = [];
  int index = 0;
  int correctCount = 0;
  int? selected;
  bool answered = false;
  int timeLeft = secondsPerQuestion;
  final Set<int> flagged = {};
  final Set<String> _missedTitles = {};
  QuizResult? lastResult;
  Timer? _timer;

  QuizQuestion? get question =>
      phase == QuizPhase.running && index < questions.length ? questions[index] : null;

  int get answeredCount => index + (answered ? 1 : 0);
  double get progress => questions.isEmpty ? 0 : answeredCount / questions.length;
  bool get isLast => index >= questions.length - 1;
  int get runningPercent =>
      answeredCount == 0 ? 0 : (correctCount * 100 / answeredCount).round();

  // ---- navigation -------------------------------------------------------------

  void showAiHub() {
    if (view == StudyView.aiHub) return;
    view = StudyView.aiHub;
    notifyListeners();
  }

  /// Ignored mid-quiz so progress is never lost by an accidental tap.
  void showReview() {
    if (phase == QuizPhase.running || view == StudyView.review) return;
    view = StudyView.review;
    notifyListeners();
  }

  void selectModule(String id) {
    if (phase == QuizPhase.running) return;
    _currentId = id;
    _s.setString(StorageKeys.studyCurrent, id);
    if (phase == QuizPhase.finished) phase = QuizPhase.idle;
    notifyListeners();
  }

  // ---- upload -------------------------------------------------------------------

  Future<UploadOutcome> pickAndAnalyze() async {
    if (processing) return const UploadOutcome(UploadStatus.cancelled);

    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'docx', 'txt'],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) {
      return const UploadOutcome(UploadStatus.cancelled);
    }

    final file = picked.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      return const UploadOutcome(UploadStatus.unreadable, 'Could not read that file.');
    }
    if (file.size > maxFileBytes) {
      return const UploadOutcome(UploadStatus.tooBig, 'Files must be 25 MB or smaller.');
    }

    final id = '${file.name}_${file.size}';
    final existing = _modules.where((m) => m.id == id);
    if (existing.isNotEmpty) {
      selectModule(id);
      return const UploadOutcome(
          UploadStatus.duplicate, 'You already uploaded this file. Opened it for you.');
    }

    processing = true;
    notifyListeners();
    try {
      final text = await TextExtractor.extract(file.name, bytes);
      final result = StudyAnalyzer.analyze(text);
      if (result.keyPoints.length < 2) {
        return const UploadOutcome(
          UploadStatus.notEnoughContent,
          'Not enough readable text found. Scanned PDFs (images) are not supported yet.',
        );
      }

      final module = StudyModule(
        id: id,
        fileName: file.name,
        extension: file.extension?.toLowerCase() ?? '',
        sizeBytes: file.size,
        keyPoints: result.keyPoints,
        facts: result.facts,
        vocab: result.vocab,
        createdAt: DateTime.now(),
      );
      _modules.insert(0, module);
      _currentId = id;
      _user.addCoins(uploadReward);
      await _persistModules();
      await _s.setString(StorageKeys.studyCurrent, id);
      return const UploadOutcome(UploadStatus.success);
    } on UnsupportedFileException catch (e) {
      return UploadOutcome(UploadStatus.unreadable, e.message);
    } catch (_) {
      return const UploadOutcome(
          UploadStatus.unreadable, 'Something went wrong reading that file.');
    } finally {
      processing = false;
      notifyListeners();
    }
  }

  /// Plain-text summary used by "Download Summary Sheet".
  String summarySheet(StudyModule m) {
    final b = StringBuffer()
      ..writeln('StudyFlora Summary Sheet')
      ..writeln(m.displayName)
      ..writeln('=' * 32)
      ..writeln();
    for (var i = 0; i < m.keyPoints.length; i++) {
      b.writeln('${i + 1}. ${m.keyPoints[i].title}');
      b.writeln('   ${m.keyPoints[i].detail}');
      b.writeln();
    }
    return b.toString();
  }

  // ---- quiz -----------------------------------------------------------------------

  /// Returns false if the module has too little material for a quiz.
  bool startQuiz() {
    final m = current;
    if (m == null) return false;
    final qs = QuizGenerator.generate(m);
    if (qs.length < 2) return false;

    questions = qs;
    index = 0;
    correctCount = 0;
    flagged.clear();
    _missedTitles.clear();
    lastResult = null;
    phase = QuizPhase.running;
    _resetQuestion();
    notifyListeners();
    return true;
  }

  void answer(int option) {
    if (phase != QuizPhase.running || answered) return;
    _lock(option);
  }

  void toggleFlag() {
    if (phase != QuizPhase.running) return;
    flagged.contains(index) ? flagged.remove(index) : flagged.add(index);
    notifyListeners();
  }

  void next() {
    if (phase != QuizPhase.running || !answered) return;
    if (isLast) {
      _finish();
    } else {
      index++;
      _resetQuestion();
      notifyListeners();
    }
  }

  void retry() {
    phase = QuizPhase.idle;
    startQuiz();
  }

  void backToIdle() {
    phase = QuizPhase.idle;
    notifyListeners();
  }

  List<FlashCard> flashcards() {
    final m = current;
    if (m == null) return const [];
    final priority = <String>{...m.weakTitles, ..._missedTitles};
    for (final i in flagged) {
      if (i < questions.length && questions[i].keyTitle.isNotEmpty) {
        priority.add(questions[i].keyTitle);
      }
    }
    return QuizGenerator.flashcards(m, priority);
  }

  // ---- internals --------------------------------------------------------------------

  void _resetQuestion() {
    _timer?.cancel();
    selected = null;
    answered = false;
    timeLeft = secondsPerQuestion;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (answered) {
        t.cancel();
        return;
      }
      timeLeft--;
      if (timeLeft <= 0) {
        timeLeft = 0;
        _lock(-1); // timed out counts as wrong
      } else {
        notifyListeners();
      }
    });
  }

  void _lock(int option) {
    _timer?.cancel();
    selected = option;
    answered = true;
    final q = questions[index];
    if (option == q.correctIndex) {
      correctCount++;
    } else if (q.keyTitle.isNotEmpty) {
      _missedTitles.add(q.keyTitle);
    }
    notifyListeners();
  }

  void _finish() {
    _timer?.cancel();
    final m = current!;
    final coins = coinsForScore(correctCount, questions.length);
    final result = QuizResult(
      moduleId: m.id,
      moduleName: m.displayName,
      attempt: m.attempts + 1,
      correct: correctCount,
      total: questions.length,
      coins: coins,
      at: DateTime.now(),
    );

    m.attempts++;
    if (result.percent > m.bestPercent) m.bestPercent = result.percent;
    m.weakTitles = _missedTitles.toList();

    _results.insert(0, result);
    if (_results.length > 30) _results.removeRange(30, _results.length);
    lastResult = result;
    phase = QuizPhase.finished;

    _user.addCoins(coins);
    _persistModules();
    _persistResults();
    notifyListeners();
  }

  void _load() {
    final rawModules = _s.getStringList(StorageKeys.studyModules) ?? const [];
    for (final r in rawModules) {
      try {
        _modules.add(StudyModule.fromJson(jsonDecode(r) as Map<String, dynamic>));
      } catch (_) {/* skip corrupt entry */}
    }
    final rawResults = _s.getStringList(StorageKeys.quizResults) ?? const [];
    for (final r in rawResults) {
      try {
        _results.add(QuizResult.fromJson(jsonDecode(r) as Map<String, dynamic>));
      } catch (_) {}
    }
    final saved = _s.getString(StorageKeys.studyCurrent, '');
    _currentId = saved.isEmpty ? null : saved;
  }

  Future<void> _persistModules() =>
      _s.setStringList(StorageKeys.studyModules, _modules.map((m) => jsonEncode(m.toJson())).toList());

  Future<void> _persistResults() =>
      _s.setStringList(StorageKeys.quizResults, _results.map((r) => jsonEncode(r.toJson())).toList());

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
