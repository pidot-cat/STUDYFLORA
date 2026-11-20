import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/feedback_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/common.dart';
import '../auth/auth_widgets.dart';

/// Settings → Report Feedback: users share comments, problems or ideas.
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});
  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  static const _categories = [
    (Icons.lightbulb_outline_rounded, 'Suggestion'),
    (Icons.bug_report_outlined, 'Problem / Bug'),
    (Icons.chat_bubble_outline_rounded, 'Comment'),
  ];
  final _form = GlobalKey<FormState>();
  final _msg = TextEditingController();
  String _category = 'Suggestion';
  int _rating = 0;
  bool _busy = false;
  bool _done = false;
  FeedbackResult _result = FeedbackResult.sent;

  @override
  void dispose() {
    _msg.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final email = context.read<AuthProvider>().user?.email;
    final store = await StorageService.create();
    final result = await FeedbackService(store).submit(category: _category, rating: _rating, message: _msg.text, email: email);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _done = true;
      _result = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sf;
    return Scaffold(
      appBar: AppBar(backgroundColor: c.bg, surfaceTintColor: Colors.transparent, title: Text('Report Feedback', style: context.tt.titleMedium)),
      body: _done ? _thanks(context) : _formView(context),
    );
  }

  Widget _thanks(BuildContext context) {
    final c = context.sf;
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 0, 32, 60),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(color: c.brandSoft, shape: BoxShape.circle),
            child: Icon(Icons.favorite_rounded, size: 42, color: c.brand),
          ),
          const SizedBox(height: 18),
          Text('Thank you!', style: context.tt.titleLarge),
          const SizedBox(height: 6),
          Text(
            switch (_result) {
              FeedbackResult.sent => 'Your feedback was sent to the Study Flora team. It helps us make the app better.',
              FeedbackResult.offline =>
                'You’re offline right now, so your feedback is saved on this phone. It will be sent automatically when you’re back online.',
              FeedbackResult.notSignedIn =>
                'Your feedback is saved on this phone. It will be sent automatically the next time you log in.',
              FeedbackResult.serverError =>
                'We couldn’t reach the feedback server right now, so your feedback is saved on this phone. The app will send it again automatically.',
            },
            style: context.tt.bodyMedium?.copyWith(color: c.muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          PrimaryButton(label: 'Back to Settings', icon: Icons.arrow_back_rounded, onTap: () => Navigator.of(context).pop()),
        ]),
      ),
    );
  }

  Widget _formView(BuildContext context) {
    final c = context.sf;
    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          Text('Tell us what you think about Study Flora — what you like, what is confusing, or what we should fix.',
              style: context.tt.bodyMedium?.copyWith(color: c.muted)),
          const SizedBox(height: 16),
          SfCard(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const FieldLabel('Type', icon: Icons.category_outlined),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final (icon, label) in _categories)
                  ChoiceChip(
                    avatar: Icon(icon, size: 18, color: _category == label ? c.brand : c.muted),
                    label: Text(label),
                    selected: _category == label,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _category = label),
                    selectedColor: c.brandSoft,
                    labelStyle: TextStyle(fontWeight: FontWeight.w600, color: _category == label ? c.brand : c.ink),
                    side: BorderSide(color: _category == label ? c.brand : c.line),
                  ),
              ]),
              const SizedBox(height: 16),
              const FieldLabel('How do you like the app?', icon: Icons.star_outline_rounded),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (var i = 1; i <= 5; i++)
                  IconButton(
                    onPressed: () => setState(() => _rating = _rating == i ? 0 : i),
                    icon: Icon(i <= _rating ? Icons.star_rounded : Icons.star_outline_rounded, size: 34, color: i <= _rating ? c.gold : c.muted),
                  ),
              ]),
              const SizedBox(height: 8),
              const FieldLabel('Your comments', icon: Icons.edit_note_rounded),
              TextFormField(
                controller: _msg,
                minLines: 5,
                maxLines: 10,
                maxLength: 1000,
                textCapitalization: TextCapitalization.sentences,
                validator: (v) => (v ?? '').trim().length < 5 ? 'Please write at least a few words.' : null,
                decoration: const InputDecoration(hintText: 'Write your feedback here…', alignLabelWithHint: true),
              ),
              const SizedBox(height: 12),
              PrimaryButton(label: 'Send Feedback', icon: Icons.send_rounded, busy: _busy, onTap: _submit),
            ]),
          ),
        ],
      ),
    );
  }
}
