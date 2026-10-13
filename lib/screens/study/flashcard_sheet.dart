import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../models/quiz_models.dart';

Future<void> showFlashcardSheet(BuildContext context, List<FlashCard> cards) {
  final p = AppPalette.of(context);
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: p.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => _FlashcardSheet(cards: cards),
  );
}

class _FlashcardSheet extends StatefulWidget {
  const _FlashcardSheet({required this.cards});

  final List<FlashCard> cards;

  @override
  State<_FlashcardSheet> createState() => _FlashcardSheetState();
}

class _FlashcardSheetState extends State<_FlashcardSheet> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Flash Review',
                      style: Theme.of(context).textTheme.headlineSmall),
                ),
                Text('${_page + 1} / ${widget.cards.length}',
                    style: TextStyle(color: p.textMuted, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Tap a card to flip it.',
                  style: TextStyle(color: p.textMuted, fontSize: 13.5)),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 260,
              child: PageView.builder(
                controller: _controller,
                itemCount: widget.cards.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => _FlipCard(card: widget.cards[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlipCard extends StatefulWidget {
  const _FlipCard({required this.card});

  final FlashCard card;

  @override
  State<_FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<_FlipCard> {
  bool _showBack = false;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return GestureDetector(
      onTap: () => setState(() => _showBack = !_showBack),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: ScaleTransition(scale: Tween(begin: 0.96, end: 1.0).animate(anim), child: child),
        ),
        child: Container(
          key: ValueKey(_showBack),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.all(22),
          width: double.infinity,
          decoration: BoxDecoration(
            color: _showBack ? p.primarySoft : p.neutralChip,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: p.border),
          ),
          alignment: Alignment.center,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_showBack ? 'ANSWER' : 'CONCEPT',
                    style: TextStyle(
                        color: p.textMuted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1)),
                const SizedBox(height: 12),
                Text(
                  _showBack ? widget.card.back : widget.card.front,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: _showBack ? 17 : 24,
                    fontWeight: _showBack ? FontWeight.w500 : FontWeight.w800,
                    height: 1.4,
                    color: _showBack ? p.onPrimarySoft : p.text,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
