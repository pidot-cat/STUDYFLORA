import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/study_provider.dart';
import 'ai_hub_view.dart';
import 'review_view.dart';

/// Study tab. Shows Study Review (upload + key points) or the AI Hub (quiz),
/// depending on [StudyProvider.view]. Tap the active Study tab to go back to
/// Study Review.
class StudyScreen extends StatelessWidget {
  const StudyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final view = context.select<StudyProvider, StudyView>((s) => s.view);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: view == StudyView.review
          ? const ReviewView(key: ValueKey('review'))
          : const AiHubView(key: ValueKey('hub')),
    );
  }
}
