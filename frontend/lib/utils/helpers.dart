import 'package:flutter/material.dart';

class Helpers {
  static void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    final messenger = ScaffoldMessenger.of(context);
    // Remove any current snackbar immediately so the new one doesn't queue.
    messenger.removeCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        // Short, noticeable duration. Adjust as needed.
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Show a custom SnackBar immediately by removing any current one first.
  static void showInstantSnackBar(BuildContext context, SnackBar snackBar) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.removeCurrentSnackBar();
    messenger.showSnackBar(snackBar);
  }

  static void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  static String timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  // Parse a stored location string of the form "City, Country".
  // Returns a map with keys 'city' and 'country' (may be null).
  static Map<String, String?> parseLocation(String? location) {
    if (location == null) return {'city': null, 'country': null};
    final parts = location.split(',');
    if (parts.isEmpty) return {'city': null, 'country': null};
    final city = parts[0].trim();
    final country = parts.length > 1 ? parts.sublist(1).join(',').trim() : null;
    return {'city': city.isEmpty ? null : city, 'country': country == null || country.isEmpty ? null : country};
  }
}