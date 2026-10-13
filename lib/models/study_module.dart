class KeyPoint {
  const KeyPoint({required this.title, required this.detail});

  final String title;
  final String detail;

  Map<String, dynamic> toJson() => {'t': title, 'd': detail};

  factory KeyPoint.fromJson(Map<String, dynamic> j) =>
      KeyPoint(title: j['t'] as String, detail: j['d'] as String);
}

/// One analysed upload (a "reviewer"): its key points plus the raw material
/// the quiz generator needs. Quiz progress fields are mutable and persisted.
class StudyModule {
  StudyModule({
    required this.id,
    required this.fileName,
    required this.extension,
    required this.sizeBytes,
    required this.keyPoints,
    required this.facts,
    required this.vocab,
    required this.createdAt,
    this.rewarded = true,
    this.bestPercent = 0,
    this.attempts = 0,
    List<String>? weakTitles,
  }) : weakTitles = weakTitles ?? [];

  final String id;
  final String fileName;
  final String extension;
  final int sizeBytes;
  final List<KeyPoint> keyPoints;
  final List<String> facts;
  final List<String> vocab;
  final DateTime createdAt;
  final bool rewarded;

  int bestPercent;
  int attempts;
  List<String> weakTitles;

  String get displayName {
    final dot = fileName.lastIndexOf('.');
    return dot > 0 ? fileName.substring(0, dot) : fileName;
  }

  bool get mastered => bestPercent >= 90;

  Map<String, dynamic> toJson() => {
        'id': id,
        'fn': fileName,
        'ext': extension,
        'size': sizeBytes,
        'kp': keyPoints.map((k) => k.toJson()).toList(),
        'facts': facts,
        'vocab': vocab,
        'at': createdAt.toIso8601String(),
        'rew': rewarded,
        'best': bestPercent,
        'att': attempts,
        'weak': weakTitles,
      };

  factory StudyModule.fromJson(Map<String, dynamic> j) => StudyModule(
        id: j['id'] as String,
        fileName: j['fn'] as String,
        extension: j['ext'] as String,
        sizeBytes: j['size'] as int,
        keyPoints: (j['kp'] as List)
            .map((e) => KeyPoint.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        facts: List<String>.from(j['facts'] as List),
        vocab: List<String>.from(j['vocab'] as List),
        createdAt: DateTime.parse(j['at'] as String),
        rewarded: j['rew'] as bool? ?? true,
        bestPercent: j['best'] as int? ?? 0,
        attempts: j['att'] as int? ?? 0,
        weakTitles: List<String>.from(j['weak'] as List? ?? const []),
      );
}
