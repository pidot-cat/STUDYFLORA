class KeyPoint {
  final String title;
  final String explanation;
  const KeyPoint(this.title, this.explanation);

  Map<String, dynamic> toJson() => {'t': title, 'e': explanation};
  factory KeyPoint.fromJson(Map<String, dynamic> j) => KeyPoint(j['t'] as String, j['e'] as String);
}

/// A verified/uploaded study file (SRS "Reviewer / Module").
class StudyModule {
  final String id;
  final String hash; // sha256 of file bytes – duplicate check (FR-2.5)
  String title;
  final String fileName;
  final String fileType; // pdf/docx/txt
  final int fileBytes;
  final int wordCount;
  final List<KeyPoint> keyPoints;
  final int createdAt;
  bool archived;
  bool verified; // passed the module requirements → reward eligible
  bool rewardClaimed;
  String? rewardChoice; // seed / fertilizer / shovel (old saves: coins / xp)
  String? rewardItem; // e.g. the flower id of the random seed
  int bestScore; // percent, -1 = never taken
  int attempts;
  int updatedAt;

  StudyModule({
    required this.id,
    required this.hash,
    required this.title,
    required this.fileName,
    required this.fileType,
    required this.fileBytes,
    required this.wordCount,
    required this.keyPoints,
    required this.createdAt,
    this.archived = false,
    this.verified = false,
    this.rewardClaimed = false,
    this.rewardChoice,
    this.rewardItem,
    this.bestScore = -1,
    this.attempts = 0,
    int? updatedAt,
  }) : updatedAt = updatedAt ?? createdAt;

  bool get mastered => bestScore >= 60;

  Map<String, dynamic> toJson() => {
        'id': id,
        'hash': hash,
        'title': title,
        'fileName': fileName,
        'fileType': fileType,
        'fileBytes': fileBytes,
        'wordCount': wordCount,
        'keyPoints': keyPoints.map((k) => k.toJson()).toList(),
        'createdAt': createdAt,
        'archived': archived,
        'verified': verified,
        'rewardClaimed': rewardClaimed,
        'rewardChoice': rewardChoice,
        'rewardItem': rewardItem,
        'bestScore': bestScore,
        'attempts': attempts,
        'updatedAt': updatedAt,
      };

  factory StudyModule.fromJson(Map<String, dynamic> j) => StudyModule(
        id: j['id'] as String,
        hash: j['hash'] as String,
        title: j['title'] as String,
        fileName: j['fileName'] as String,
        fileType: j['fileType'] as String,
        fileBytes: (j['fileBytes'] ?? 0) as int,
        wordCount: (j['wordCount'] ?? 0) as int,
        keyPoints: ((j['keyPoints'] ?? []) as List).map((e) => KeyPoint.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
        createdAt: j['createdAt'] as int,
        archived: (j['archived'] ?? false) as bool,
        verified: (j['verified'] ?? false) as bool,
        rewardClaimed: (j['rewardClaimed'] ?? false) as bool,
        rewardChoice: j['rewardChoice'] as String?,
        rewardItem: j['rewardItem'] as String?,
        bestScore: (j['bestScore'] ?? -1) as int,
        attempts: (j['attempts'] ?? 0) as int,
        updatedAt: j['updatedAt'] as int?,
      );
}

enum QuestionType { describeConcept, nameConcept, fillBlank, trueFalse }

class QuizQuestion {
  final QuestionType type;
  final String prompt;
  final List<String> options;
  final int answer;
  final String insight;
  const QuizQuestion({required this.type, required this.prompt, required this.options, required this.answer, required this.insight});

  String get typeLabel => switch (type) {
        QuestionType.describeConcept => 'Choose the description',
        QuestionType.nameConcept => 'Identify the concept',
        QuestionType.fillBlank => 'Fill in the blank',
        QuestionType.trueFalse => 'True or false',
      };
}

/// FR-3.7 — one quiz attempt. Stored independently so cloud sync can merge
/// attempts instead of overwriting the whole history.
class QuizAttempt {
  final String id;
  final String moduleId;
  final String moduleHash;
  final String moduleTitle;
  final int attempt;
  final int correct;
  final int total;
  final int coins;
  final int takenAt;
  final int flagged;

  const QuizAttempt({
    required this.id,
    required this.moduleId,
    required this.moduleHash,
    required this.moduleTitle,
    required this.attempt,
    required this.correct,
    required this.total,
    required this.coins,
    required this.takenAt,
    this.flagged = 0,
  });

  int get percent => total == 0 ? 0 : (correct * 100 / total).round();

  Map<String, dynamic> toJson() => {
        'id': id,
        'moduleId': moduleId,
        'moduleHash': moduleHash,
        'moduleTitle': moduleTitle,
        'attempt': attempt,
        'correct': correct,
        'total': total,
        'coins': coins,
        'takenAt': takenAt,
        'flagged': flagged,
      };

  factory QuizAttempt.fromJson(Map<String, dynamic> j) => QuizAttempt(
        id: j['id'] as String,
        moduleId: j['moduleId'] as String,
        moduleHash: (j['moduleHash'] ?? '') as String,
        moduleTitle: j['moduleTitle'] as String,
        attempt: j['attempt'] as int,
        correct: j['correct'] as int,
        total: j['total'] as int,
        coins: j['coins'] as int,
        takenAt: j['takenAt'] as int,
        flagged: (j['flagged'] ?? 0) as int,
      );
}
