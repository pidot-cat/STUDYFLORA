class QuizQuestion {
  const QuizQuestion({
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.insight,
    this.keyTitle = '',
  });

  final String prompt;
  final List<String> options;
  final int correctIndex;
  final String insight;

  /// Title of the key point this question tests ('' for fill-in-the-blank).
  final String keyTitle;
}

class QuizResult {
  const QuizResult({
    required this.moduleId,
    required this.moduleName,
    required this.attempt,
    required this.correct,
    required this.total,
    required this.coins,
    required this.at,
  });

  final String moduleId;
  final String moduleName;
  final int attempt;
  final int correct;
  final int total;
  final int coins;
  final DateTime at;

  int get percent => total == 0 ? 0 : (correct * 100 / total).round();
  String get title => '$moduleName Practice $attempt';

  Map<String, dynamic> toJson() => {
        'mid': moduleId,
        'mn': moduleName,
        'a': attempt,
        'c': correct,
        't': total,
        'coins': coins,
        'at': at.toIso8601String(),
      };

  factory QuizResult.fromJson(Map<String, dynamic> j) => QuizResult(
        moduleId: j['mid'] as String,
        moduleName: j['mn'] as String,
        attempt: j['a'] as int,
        correct: j['c'] as int,
        total: j['t'] as int,
        coins: j['coins'] as int,
        at: DateTime.parse(j['at'] as String),
      );
}

class FlashCard {
  const FlashCard({required this.front, required this.back});

  final String front;
  final String back;
}
