import 'package:url_launcher/url_launcher.dart';

class FeedbackService {
  static Future<void> sendFeedback({
    required String subject,
    required String message,
  }) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'pawjeevan0@gmail.com',
      query: _encodeQueryParameters({
        'subject': 'PawJeevan Feedback: $subject',
        'body': message,
      }),
    );

    if (!await launchUrl(emailLaunchUri)) {
      throw 'Could not launch email client';
    }
  }

  static String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }
}