import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../core/constants.dart';
import '../core/format.dart';
import '../models/cosmetics.dart';
import '../models/flower.dart';
import '../models/study.dart';
import '../services/module_validator.dart';
import '../services/storage_service.dart';
import '../services/text_analyzer.dart';
import '../services/text_extractor.dart';
import 'game_provider.dart';

enum UploadKind { duplicate, rejected, accepted }

class UploadOutcome {
  final UploadKind kind;
  final StudyModule? module;
  final ValidationReport? report;
  final String message;
  const UploadOutcome(this.kind, {this.module, this.report, this.message = ''});
}

class FileTooLargeException implements Exception {
  final String message;
  const FileTooLargeException(this.message);
  @override
  String toString() => message;
}

class PickedStudyFile {
  final String name;
  final String extension;
  final int size;
  final Uint8List bytes;
  const PickedStudyFile(this.name, this.extension, this.size, this.bytes);
}

/// What a verified upload can give (the user picks one).
enum UploadReward { seed, fertilizer, shovel }

/// The item actually granted, for the reward sheet and the module screen.
class UploadRewardResult {
  final UploadReward kind;
  final String label; // "Tulip seed", "1 Fertilizer"
  final String asset; // art shown in the sheet
  const UploadRewardResult(this.kind, this.label, this.asset);
}

/// Modules, summaries, quiz history (FR-2.x, FR-3.x).
class StudyProvider extends ChangeNotifier {
  StudyProvider(this._store, this._game);
  final StorageService _store;
  final GameProvider _game;
  VoidCallback? onChanged;

  String? _uid;
  List<StudyModule> modules = [];
  List<QuizAttempt> attempts = [];
  int updatedAt = 0;

  /// FR-2.6 — every uploaded module is kept in "Archived Modules", newest first.
  List<StudyModule> get allModules => [...modules]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  int get masteredCount => modules.where((m) => m.mastered).length;
  List<QuizAttempt> get recentAttempts => [...attempts]..sort((a, b) => b.takenAt.compareTo(a.takenAt));
  StudyModule? byId(String id) {
    for (final m in modules) {
      if (m.id == id) return m;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  Future<void> load(String uid) async {
    _uid = uid;
    final j = _store.readJson(StorageService.studyKey(uid));
    if (j != null) {
      applyJson(j);
    } else {
      modules = [];
      attempts = [];
    }
    notifyListeners();
  }

  void unload() {
    _uid = null;
    modules = [];
    attempts = [];
    notifyListeners();
  }

  Map<String, dynamic> toJson() => {
        'modules': modules.map((m) => m.toJson()).toList(),
        'attempts': attempts.map((a) => a.toJson()).toList(),
        'updatedAt': updatedAt,
      };

  void applyJson(Map<String, dynamic> j) {
    modules = ((j['modules'] ?? const []) as List).map((e) => StudyModule.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    attempts = ((j['attempts'] ?? const []) as List).map((e) => QuizAttempt.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    updatedAt = (j['updatedAt'] ?? 0) as int;
  }

  Future<void> _save() async {
    final uid = _uid;
    if (uid == null) return;
    updatedAt = DateTime.now().millisecondsSinceEpoch;
    await _store.writeJson(StorageService.studyKey(uid), toJson());
    onChanged?.call();
  }

  /// FR-6.5 merge: modules by file hash (newer wins), attempts by id (union).
  void mergeRemote(Map<String, dynamic> remote, List<Map<String, dynamic>> remoteAttempts) {
    final r = StudyProvider(_store, _game)..applyJson(remote);
    final byHash = {for (final m in modules) m.hash: m};
    for (final m in r.modules) {
      final mine = byHash[m.hash];
      if (mine == null || m.updatedAt > mine.updatedAt) byHash[m.hash] = m;
    }
    modules = byHash.values.toList();
    final ids = {for (final a in attempts) a.id: a};
    for (final raw in remoteAttempts) {
      final a = QuizAttempt.fromJson(raw);
      ids.putIfAbsent(a.id, () => a);
    }
    for (final a in r.attempts) {
      ids.putIfAbsent(a.id, () => a);
    }
    attempts = ids.values.toList();
    notifyListeners();
    _persistOnly();
  }

  Future<void> _persistOnly() async {
    final uid = _uid;
    if (uid == null) return;
    await _store.writeJson(StorageService.studyKey(uid), toJson());
  }

  // ---------------------------------------------------------------------------
  // Upload pipeline
  // ---------------------------------------------------------------------------
  /// FR-2.1 — returns null if the user cancelled.
  Future<PickedStudyFile?> pickFile() async {
    // file_picker 13: static API, returns an empty list when cancelled.
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: TextExtractor.supported,
    );
    if (files.isEmpty) return null;
    final f = files.first;
    // Check the size before loading the file, so a huge file never fills memory.
    final length = await f.length() ?? 0;
    if (length > GameRules.maxFileBytes) {
      throw FileTooLargeException('This file is ${fmtBytes(length)}. The limit is 25 MB.');
    }
    final bytes = await f.readAsBytes();
    final name = f.name;
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    return PickedStudyFile(name, ext, bytes.length, bytes);
  }

  Future<UploadOutcome> process(PickedStudyFile file) async {
    if (!TextExtractor.supported.contains(file.extension)) {
      return const UploadOutcome(UploadKind.rejected, message: 'Unsupported file type. Please upload a PDF, DOCX or TXT file.');
    }
    if (file.size > GameRules.maxFileBytes) {
      return UploadOutcome(UploadKind.rejected, message: 'This file is ${fmtBytes(file.size)}. The limit is 25 MB.');
    }

    // FR-2.5 duplicate check — same bytes = same module, no second reward.
    final hash = sha256.convert(file.bytes).toString();
    for (final m in modules) {
      if (m.hash == hash) {
        if (m.archived) {
          m.archived = false;
          m.updatedAt = GameClock.nowMs();
          await _save();
          notifyListeners();
        }
        return UploadOutcome(UploadKind.duplicate, module: m,
            message: 'You already uploaded this file. Opening the existing module — rewards are given once per file.');
      }
    }

    final String text;
    try {
      text = await TextExtractor.extract(file.bytes, file.extension);
    } on ExtractionException catch (e) {
      return UploadOutcome(UploadKind.rejected, message: e.message);
    } catch (_) {
      return const UploadOutcome(UploadKind.rejected, message: 'This file could not be read.');
    }

    final keyPoints = await compute(TextAnalyzer.analyze, text);
    final report = ModuleValidator.validate(
      text: text,
      keyPoints: keyPoints,
      fileBytes: file.size,
      extension: file.extension,
    );
    if (!report.accepted) {
      return UploadOutcome(UploadKind.rejected, report: report, message: report.rejectReason ?? 'File rejected.');
    }

    final now = GameClock.nowMs();
    final module = StudyModule(
      id: newId(),
      hash: hash,
      title: TextAnalyzer.guessTitle(text, file.name),
      fileName: file.name,
      fileType: file.extension,
      fileBytes: file.size,
      wordCount: TextAnalyzer.words(text).length,
      keyPoints: keyPoints,
      createdAt: now,
      verified: report.verified,
    );
    modules.add(module);
    await _save();
    if (report.verified) _game.recordVerifiedUpload();
    notifyListeners();
    return UploadOutcome(UploadKind.accepted, module: module, report: report);
  }

  /// Verified upload reward: a random seed, a fertilizer or a shovel — once
  /// per unique file. Returns null if the module has no reward to claim
  /// (not verified, or already claimed — e.g. a double tap).
  UploadRewardResult? claimUploadReward(StudyModule m, UploadReward choice) {
    if (!m.verified || m.rewardClaimed) return null;
    // Mark first so a second tap can never grant twice.
    m.rewardClaimed = true;
    m.rewardChoice = choice.name;
    m.updatedAt = GameClock.nowMs();
    final UploadRewardResult result;
    switch (choice) {
      case UploadReward.seed:
        final id = _game.grantRandomSeed();
        m.rewardItem = id;
        final f = Flower.of(id);
        result = UploadRewardResult(choice, '${f.name} seed', f.seedAsset);
      case UploadReward.fertilizer:
        _game.grantTool(ToolKind.fertilizer, GameRules.uploadRewardFertilizers);
        result = UploadRewardResult(choice, '${GameRules.uploadRewardFertilizers} Fertilizer', ToolDef.of(ToolKind.fertilizer).asset);
      case UploadReward.shovel:
        _game.grantTool(ToolKind.shovel, GameRules.uploadRewardShovels);
        result = UploadRewardResult(choice, '${GameRules.uploadRewardShovels} Shovel', ToolDef.of(ToolKind.shovel).asset);
    }
    _save();
    notifyListeners();
    return result;
  }

  /// Text for an already-claimed reward ("Random seed: Tulip", "1 Fertilizer").
  static String rewardLabel(StudyModule m) => switch (m.rewardChoice) {
        'seed' => m.rewardItem == null ? 'Random seed' : 'Random seed: ${Flower.of(m.rewardItem!).name}',
        'fertilizer' => '${GameRules.uploadRewardFertilizers} Fertilizer',
        'shovel' => '${GameRules.uploadRewardShovels} Shovel',
        'coins' => 'Coins', // saves from before the reward change
        'xp' => 'XP',
        _ => 'Claimed',
      };

  // ---------------------------------------------------------------------------
  void rename(StudyModule m, String title) {
    m.title = title.trim().isEmpty ? m.title : title.trim();
    m.updatedAt = GameClock.nowMs();
    _save();
    notifyListeners();
  }

  void setArchived(StudyModule m, bool v) {
    m.archived = v;
    m.updatedAt = GameClock.nowMs();
    _save();
    notifyListeners();
  }

  /// FR-3.7 / FR-3.8 / FR-3.6
  QuizAttempt recordAttempt(StudyModule m, {required int correct, required int total, required int flagged}) {
    final percent = total == 0 ? 0 : (correct * 100 / total).round();
    // Coins are earned on the FIRST attempt of a module only. Retakes are
    // free practice (they still update the best score and "Mastered").
    final coins = m.attempts == 0 ? GameRules.quizCoins(percent) : 0;
    m.attempts++;
    if (percent > m.bestScore) m.bestScore = percent;
    m.updatedAt = GameClock.nowMs();
    final a = QuizAttempt(
      id: newId(),
      moduleId: m.id,
      moduleHash: m.hash,
      moduleTitle: m.title,
      attempt: m.attempts,
      correct: correct,
      total: total,
      coins: coins,
      takenAt: GameClock.nowMs(),
      flagged: flagged,
    );
    attempts.add(a);
    _save();
    _game.recordQuiz(percent: percent, coinsEarned: coins, masteredModules: masteredCount);
    notifyListeners();
    return a;
  }

  /// FR-2.7 — summary sheet as .txt
  String summaryText(StudyModule m) {
    final b = StringBuffer()
      ..writeln('STUDY FLORA — KEY POINTS SUMMARY')
      ..writeln('=' * 36)
      ..writeln('Module: ${m.title}')
      ..writeln('Source file: ${m.fileName}')
      ..writeln('Best score: ${m.bestScore < 0 ? 'Not taken yet' : '${m.bestScore}%'}')
      ..writeln('Exported: ${fmtDate(DateTime.now())}')
      ..writeln();
    for (var i = 0; i < m.keyPoints.length; i++) {
      b
        ..writeln('${i + 1}. ${m.keyPoints[i].title}')
        ..writeln('   ${m.keyPoints[i].explanation}')
        ..writeln();
    }
    b.writeln('Study responsibly, grow together 🌱');
    return b.toString();
  }

  Future<bool> exportSummary(StudyModule m) async {
    final safe = m.title.replaceAll(RegExp(r'[^A-Za-z0-9 _-]'), '').trim().replaceAll(' ', '_');
    final saved = await FilePicker.saveFile(
      dialogTitle: 'Save summary sheet',
      fileName: '${safe.isEmpty ? 'StudyFlora_Summary' : safe}_summary.txt',
      bytes: Uint8List.fromList(utf8.encode(summaryText(m))),
    );
    return saved != null;
  }
}
