import 'package:flutter/material.dart';
import '../services/feedback_service.dart';
import '../widgets/custom_app_bar.dart';

class SendFeedbackScreen extends StatefulWidget {
  const SendFeedbackScreen({super.key});

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

  Future<void> _sendFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);
    try {
      await FeedbackService.sendFeedback(
        subject: _subjectController.text.trim(),
        message: _messageController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Opening email client...')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Send Feedback', showBackButton: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
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
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
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