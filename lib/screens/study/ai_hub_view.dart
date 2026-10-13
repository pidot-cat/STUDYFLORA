import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/formatters.dart';
import '../../models/quiz_models.dart';
import '../../models/study_module.dart';
import '../../providers/study_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/pill.dart';
import 'flashcard_sheet.dart';

class AiHubView extends StatelessWidget {
  const AiHubView({super.key});

  @override
  Widget build(BuildContext context) {
    final study = context.watch<StudyProvider>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        const _DailyHeader(),
        const SizedBox(height: 16),
        switch (study.phase) {
          QuizPhase.running => const _QuizCard(),
          QuizPhase.finished => _FinishedCard(result: study.lastResult!),
          QuizPhase.idle => const _IdleCard(),
        },
        const SizedBox(height: 22),
        _RecentScores(results: study.results),
        const SizedBox(height: 16),
        const _FlashReviewCard(),
      ],
    );
  }
}

class _DailyHeader extends StatelessWidget {
  const _DailyHeader();

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AppCard(
      color: dark ? p.surface : p.neutralChip.withAlpha(150),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: p.neutralChip,
              borderRadius: BorderRadius.circular(14),
              border: dark ? Border.all(color: p.border) : null,
            ),
            child: Icon(Icons.quiz_outlined, color: p.textMuted),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Daily AI Quiz',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('Earn 5-100 Coins based on score',
                    style: TextStyle(color: p.textMuted, fontSize: 13.5)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Pill(
            label: dark ? 'UP TO 100' : 'Up to 100',
            icon: Icons.monetization_on_outlined,
            background: p.warmSoft,
            foreground: p.warmText,
            fontSize: 11.5,
            borderColor: p.warmText.withAlpha(70),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Active question
// ---------------------------------------------------------------------------

class _QuizCard extends StatelessWidget {
  const _QuizCard();

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final s = context.watch<StudyProvider>();
    final q = s.question;
    if (q == null) return const SizedBox.shrink();

    final timedOut = s.answered && s.selected == -1;
    final wasCorrect = s.answered && s.selected == q.correctIndex;
    final mm = two(s.timeLeft ~/ 60);
    final ss = two(s.timeLeft % 60);
    final lowTime = s.timeLeft <= 10 && !s.answered;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.spa_outlined, size: 16, color: p.primary),
              const SizedBox(width: 5),
              Expanded(
                child: Text('Module: ${s.current?.displayName ?? ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: p.text, fontSize: 12.5, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 6),
              Pill(
                label: 'Score: ${s.correctCount}/${s.answeredCount}',
                icon: Icons.check_circle,
                background: p.primarySoft,
                foreground: p.onPrimarySoft,
                fontSize: 11,
                borderColor: dark ? p.onPrimarySoft.withAlpha(90) : null,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              ),
              const SizedBox(width: 6),
              Pill(
                label: '$mm:${ss}s',
                icon: Icons.timer_outlined,
                background: lowTime ? p.dangerBg : p.warmSoft,
                foreground: lowTime ? p.dangerText : p.warmText,
                fontSize: 11,
                borderColor: (lowTime ? p.dangerText : p.warmText).withAlpha(70),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: s.progress,
              minHeight: 6,
              backgroundColor: p.border,
              valueColor: AlwaysStoppedAnimation(p.primary),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('ACTIVE PROMPT',
                  style: TextStyle(
                      color: p.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8)),
              const Spacer(),
              Text('${s.index + 1} / ${s.questions.length}',
                  style: TextStyle(color: p.textMuted, fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            q.prompt,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: dark ? 22 : 24,
                  color: p.text,
                  height: 1.25,
                ),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < q.options.length; i++) ...[
            _OptionTile(
              letter: String.fromCharCode(65 + i),
              text: q.options[i],
              state: _optionState(s, q, i),
              onTap: () => context.read<StudyProvider>().answer(i),
            ),
            const SizedBox(height: 10),
          ],
          if (s.answered) ...[
            const SizedBox(height: 2),
            _InsightBox(
              correct: wasCorrect,
              timedOut: timedOut,
              text: q.insight,
              retention: s.runningPercent,
            ),
            const SizedBox(height: 14),
          ] else
            const SizedBox(height: 6),
          Row(
            children: [
              TextButton.icon(
                style: TextButton.styleFrom(
                  backgroundColor: s.flagged.contains(s.index)
                      ? p.warmSoft
                      : p.neutralChip.withAlpha(dark ? 160 : 190),
                  foregroundColor:
                      s.flagged.contains(s.index) ? p.warmText : p.textMuted,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                onPressed: () => context.read<StudyProvider>().toggleFlag(),
                icon: Icon(
                    s.flagged.contains(s.index) ? Icons.flag : Icons.outlined_flag,
                    size: 19),
                label: const Text('Flag', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: p.primary,
                    foregroundColor: p.onPrimary,
                    disabledBackgroundColor: p.primary.withAlpha(90),
                    disabledForegroundColor: p.onPrimary.withAlpha(170),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  onPressed: s.answered ? () => context.read<StudyProvider>().next() : null,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(s.isLast ? 'Finish Quiz' : 'Next Question',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 19),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  _OptionState _optionState(StudyProvider s, QuizQuestion q, int i) {
    if (!s.answered) return _OptionState.idle;
    if (i == q.correctIndex) return _OptionState.correct;
    if (i == s.selected) return _OptionState.wrong;
    return _OptionState.dimmed;
  }
}

enum _OptionState { idle, correct, wrong, dimmed }

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.letter,
    required this.text,
    required this.state,
    required this.onTap,
  });

  final String letter;
  final String text;
  final _OptionState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;

    Color bg = p.neutralChip.withAlpha(dark ? 120 : 190);
    Color border = dark ? p.border : Colors.transparent;
    Color letterBg = p.neutralChip;
    Color letterFg = p.textMuted;
    Color textColor = p.textMuted;
    FontWeight weight = FontWeight.w500;
    Widget? trailing;

    switch (state) {
      case _OptionState.idle:
        textColor = p.text;
        break;
      case _OptionState.correct:
        bg = dark ? p.primarySoft.withAlpha(150) : const Color(0xFFA6EBC3);
        border = dark ? p.onPrimarySoft : Colors.transparent;
        letterBg = dark ? p.onPrimarySoft : p.primary;
        letterFg = dark ? p.onPrimary : Colors.white;
        textColor = p.text;
        weight = FontWeight.w700;
        trailing = Icon(Icons.check_circle, color: dark ? p.onPrimarySoft : p.primary, size: 22);
        break;
      case _OptionState.wrong:
        bg = p.dangerBg;
        border = p.dangerText.withAlpha(140);
        letterBg = p.dangerText;
        letterFg = Colors.white;
        textColor = p.text;
        weight = FontWeight.w700;
        trailing = Icon(Icons.cancel, color: p.dangerText, size: 22);
        break;
      case _OptionState.dimmed:
        break;
    }

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: state == _OptionState.idle ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: letterBg, shape: BoxShape.circle),
                child: Text(letter,
                    style: TextStyle(
                        color: letterFg, fontSize: 12, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(text,
                    style: TextStyle(
                        color: textColor, fontSize: 15, height: 1.3, fontWeight: weight)),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing],
            ],
          ),
        ),
      ),
    );
  }
}

class _InsightBox extends StatelessWidget {
  const _InsightBox({
    required this.correct,
    required this.timedOut,
    required this.text,
    required this.retention,
  });

  final bool correct;
  final bool timedOut;
  final String text;
  final int retention;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final title = correct
        ? 'Correct Insight'
        : timedOut
            ? "Time's Up"
            : 'Review Insight';
    final accent = correct ? p.onPrimarySoft : p.dangerText;
    final lead = correct ? 'Correct! ' : (timedOut ? "Time's up. " : 'Not quite. ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.neutralChip.withAlpha(dark ? 110 : 190),
        borderRadius: BorderRadius.circular(16),
        border: dark ? Border.all(color: p.border) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(correct ? Icons.verified : Icons.info_outline, size: 18, color: accent),
              const SizedBox(width: 7),
              Expanded(
                child: Text(title,
                    style: TextStyle(
                        color: accent, fontSize: 14, fontWeight: FontWeight.w800)),
              ),
              Pill(
                label: retention >= 80 ? '$retention% High Retention' : '$retention% Retention',
                icon: Icons.psychology_outlined,
                background: p.primarySoft,
                foreground: p.onPrimarySoft,
                fontSize: 11,
                borderColor: dark ? p.onPrimarySoft.withAlpha(90) : null,
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('$lead$text', style: TextStyle(color: p.text, fontSize: 14.5, height: 1.45)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Idle + finished states
// ---------------------------------------------------------------------------

class _IdleCard extends StatelessWidget {
  const _IdleCard();

  void _pickModule(BuildContext context) {
    final p = AppPalette.of(context);
    final study = context.read<StudyProvider>();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: p.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(20),
          children: [
            Text('Choose a module', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            for (final StudyModule m in study.modules)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                    m.id == study.current?.id
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: p.primary),
                title: Text(m.displayName, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('${m.keyPoints.length} key takeaways'),
                onTap: () {
                  study.selectModule(m.id);
                  Navigator.pop(sheetCtx);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final study = context.watch<StudyProvider>();
    final module = study.current;

    if (module == null) {
      return AppCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.menu_book_outlined, size: 40, color: p.primary),
            const SizedBox(height: 10),
            const Text('Upload a reviewer first',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('The AI Hub builds quizzes from your own study files.',
                textAlign: TextAlign.center,
                style: TextStyle(color: p.textMuted, fontSize: 14.5)),
            const SizedBox(height: 14),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: p.primary,
                foregroundColor: p.onPrimary,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              ),
              onPressed: () => context.read<StudyProvider>().showReview(),
              child: const Text('Go to Study Review',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      );
    }

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('READY TO TEST YOURSELF?',
              style: TextStyle(
                  color: p.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8)),
          const SizedBox(height: 8),
          Text(module.displayName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(
              'Up to 10 questions • 30 seconds each • ${module.keyPoints.length} key topics'
              '${module.attempts > 0 ? ' • best ${module.bestPercent}%' : ''}',
              style: TextStyle(color: p.textMuted, fontSize: 14, height: 1.4)),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: p.primary,
              foregroundColor: p.onPrimary,
              minimumSize: const Size.fromHeight(52),
              shape: const StadiumBorder(),
            ),
            onPressed: () {
              final ok = context.read<StudyProvider>().startQuiz();
              if (!ok) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(const SnackBar(
                      content: Text('Not enough material to build a quiz from this file.')));
              }
            },
            icon: const Icon(Icons.play_arrow_outlined),
            label: const Text('Start Quiz',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
          ),
          if (study.modules.length > 1) ...[
            const SizedBox(height: 6),
            Center(
              child: TextButton(
                onPressed: () => _pickModule(context),
                child: Text('Change module',
                    style: TextStyle(color: p.primary, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FinishedCard extends StatelessWidget {
  const _FinishedCard({required this.result});

  final QuizResult result;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final pct = result.percent;
    final msg = pct >= 90
        ? 'Excellent recall!'
        : pct >= 70
            ? 'Solid work, keep going.'
            : pct >= 50
                ? 'Getting there. Try a flash review.'
                : 'Review the key points and try again.';
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text('QUIZ COMPLETE',
              style: TextStyle(
                  color: p.primary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1)),
          const SizedBox(height: 10),
          Text('$pct%',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontSize: 56, color: pct >= 90 ? p.primary : p.warmText)),
          Text('${result.correct} / ${result.total} correct',
              style: TextStyle(color: p.textMuted, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Pill(
            label: '+${result.coins} Coins earned',
            icon: Icons.monetization_on_outlined,
            background: p.warmSoft,
            foreground: p.warmText,
            fontSize: 14,
            borderColor: p.warmText.withAlpha(70),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          ),
          const SizedBox(height: 10),
          Text(msg, style: TextStyle(color: p.textMuted, fontSize: 14.5)),
          const SizedBox(height: 18),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: p.primary,
              foregroundColor: p.onPrimary,
              minimumSize: const Size.fromHeight(50),
              shape: const StadiumBorder(),
            ),
            onPressed: () => context.read<StudyProvider>().retry(),
            icon: const Icon(Icons.replay),
            label: const Text('Retry Quiz', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 8),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: p.neutralChip,
              foregroundColor: p.text,
              minimumSize: const Size.fromHeight(48),
              shape: const StadiumBorder(),
            ),
            onPressed: () {
              final s = context.read<StudyProvider>();
              s.backToIdle();
              s.showReview();
            },
            child: const Text('Back to Study Review',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recent scores + flash review
// ---------------------------------------------------------------------------

class _RecentScores extends StatelessWidget {
  const _RecentScores({required this.results});

  final List<QuizResult> results;

  void _viewAll(BuildContext context) {
    final p = AppPalette.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: p.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          children: [
            Text('Quiz History', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            for (final r in results) ...[
              _ResultTile(result: r),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.receipt_long_outlined, size: 17, color: p.primary),
            const SizedBox(width: 6),
            const Expanded(
              child: Text('Recent Quiz Scores & Rewards',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ),
            if (results.length > 3)
              GestureDetector(
                onTap: () => _viewAll(context),
                child: Text('View All',
                    style: TextStyle(
                        color: p.primary, fontSize: 13, fontWeight: FontWeight.w800)),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (results.isEmpty)
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Text('No quizzes yet. Finish one to see your scores and coin rewards here.',
                style: TextStyle(color: p.textMuted, fontSize: 14, height: 1.4)),
          )
        else
          for (final r in results.take(3)) ...[
            _ResultTile(result: r),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.result});

  final QuizResult result;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final great = result.percent >= 90;
    return AppCard(
      padding: const EdgeInsets.all(12),
      color: dark ? p.surface : p.neutralChip.withAlpha(150),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: great ? p.primarySoft : p.warmSoft,
              shape: BoxShape.circle,
              border: dark ? Border.all(color: p.border) : null,
            ),
            child: Icon(great ? Icons.biotech_outlined : Icons.science_outlined,
                color: great ? p.onPrimarySoft : p.warmText, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(children: [
                    TextSpan(text: 'Score: ', style: TextStyle(color: p.textMuted)),
                    TextSpan(
                        text: '${result.percent}%',
                        style: TextStyle(
                            color: great ? p.onPrimarySoft : p.warmText,
                            fontWeight: FontWeight.w800)),
                    TextSpan(
                        text: ' • ${result.correct}/${result.total} Correct',
                        style: TextStyle(color: p.textMuted)),
                  ]),
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Pill(
            label: '+${result.coins} Coins',
            icon: Icons.monetization_on_outlined,
            background: p.warmSoft,
            foreground: p.warmText,
            fontSize: 12,
            borderColor: p.warmText.withAlpha(70),
          ),
        ],
      ),
    );
  }
}

class _FlashReviewCard extends StatelessWidget {
  const _FlashReviewCard();

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AppCard(
      color: dark ? p.surface : p.neutralChip.withAlpha(150),
      padding: const EdgeInsets.all(14),
      onTap: () {
        final cards = context.read<StudyProvider>().flashcards();
        if (cards.isEmpty) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
                const SnackBar(content: Text('Upload a reviewer first to make flash cards.')));
          return;
        }
        showFlashcardSheet(context, cards);
      },
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: p.primarySoft,
              borderRadius: BorderRadius.circular(14),
              border: dark ? Border.all(color: p.border) : null,
            ),
            child: Icon(Icons.auto_awesome, color: p.onPrimarySoft),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Need Flash Review?',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('Generate 5 quick flash-cards from failed attempts',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13.5, color: p.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
