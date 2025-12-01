import 'package:flutter/material.dart';
import '../../utils/helpers.dart';
import '../../services/feedback_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/app_form_card.dart';

class SendFeedbackScreen extends StatefulWidget {
  final String? initialSubject;
  final String? initialMessage;

  const SendFeedbackScreen({super.key, this.initialSubject, this.initialMessage});

  @override
  State<SendFeedbackScreen> createState() => _SendFeedbackScreenState();
}

class _SendFeedbackScreenState extends State<SendFeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Prefill if provided
    if (widget.initialSubject != null && widget.initialSubject!.isNotEmpty) {
      _subjectController.text = widget.initialSubject!;
    }
    if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
      _messageController.text = widget.initialMessage!;
    }
  }

  Future<void> _sendFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);
    try {
      await FeedbackService.sendFeedback(
        subject: _subjectController.text.trim(),
        message: _messageController.text.trim(),
      );
      if (mounted) {
        Helpers.showInstantSnackBar(
          context,
          const SnackBar(content: Text('Opening email client...')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Helpers.showInstantSnackBar(
          context,
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const CustomAppBar(title: 'Send Feedback', showBackButton: true),
      body: AppFormCard(
        padding: EdgeInsets.only(top: topPadding + 16, left: 16, right: 16, bottom: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Help us improve PawJeevan by sending your feedback. We appreciate your input!',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  hintText: 'E.g., Suggestion, Bug Report, Feature Request',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.subject),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Subject is required';
                  return null;
                },
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _messageController,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  hintText: 'Please provide detailed feedback...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.message),
                  alignLabelWithHint: true,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Message is required';
                  return null;
                },
                maxLines: 8,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isSending ? null : _sendFeedback,
                  icon: _isSending 
                      ? const SizedBox(
                          width: 18, 
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: Text(_isSending ? 'Sending...' : 'Send Feedback'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}