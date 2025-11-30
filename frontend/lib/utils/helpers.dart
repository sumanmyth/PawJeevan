import 'dart:ui';

import 'package:flutter/material.dart';

/// Show a SnackBar immediately by hiding any current one first.
/// Use this across the app to avoid snackbars queuing.
void showAppSnackBar(BuildContext context, SnackBar snackBar) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar(reason: SnackBarClosedReason.dismiss);
  messenger.showSnackBar(snackBar);
}

/// Convenience helper to show a plain message.
void showAppMessage(BuildContext context, String message, {SnackBarBehavior behavior = SnackBarBehavior.floating, Duration? duration}) {
  showAppSnackBar(
    context,
    SnackBar(
      content: Text(message),
      behavior: behavior,
      duration: duration ?? const Duration(seconds: 3),
    ),
  );
}

class Helpers {
  static void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    showAppMessage(context, message, behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2));
  }

  // Show a custom SnackBar immediately by removing any current one first.
  static void showInstantSnackBar(BuildContext context, SnackBar snackBar) {
    showAppSnackBar(context, snackBar);
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

  // Show a dialog with a blurred backdrop. The `builder` should return
  // the dialog widget (typically an AlertDialog). Returns the same value
  // as `showGeneralDialog` (often a bool for confirmations).
  static Future<T?> showBlurredDialog<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    bool barrierDismissible = true,
    Color barrierColor = const Color(0x80000000),
    double blurSigma = 6.0,
    Duration transitionDuration = const Duration(milliseconds: 180),
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: barrierColor,
      transitionDuration: transitionDuration,
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: SafeArea(
            child: Builder(
              builder: (innerContext) {
                // Center to ensure dialogs are centered on screen like showDialog
                return Center(
                  child: Material(
                    type: MaterialType.transparency,
                    child: builder(dialogContext),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // Convenience confirmation dialog with blurred background.
  static Future<bool?> showBlurredConfirmationDialog(
    BuildContext context, {
    required String title,
    required String content,
    String cancelLabel = 'Cancel',
    String confirmLabel = 'Delete',
    bool confirmDestructive = true,
    bool barrierDismissible = true,
  }) {
    return showBlurredDialog<bool>(
      context,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(cancelLabel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: confirmDestructive ? Colors.red : null),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  // Show a date picker dialog with a blurred backdrop and custom primary color.
  static Future<DateTime?> showBlurredDatePicker({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    DatePickerEntryMode initialEntryMode = DatePickerEntryMode.calendar,
    DatePickerMode initialDatePickerMode = DatePickerMode.day,
    SelectableDayPredicate? selectableDayPredicate,
    double blurSigma = 6.0,
    Color primaryColor = const Color(0xFF7C3AED),
  }) {
    final theme = Theme.of(context);
    final overrideTheme = theme.copyWith(
      colorScheme: theme.colorScheme.copyWith(primary: primaryColor),
    );

    return showGeneralDialog<DateTime>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: SafeArea(
            child: Center(
              child: Material(
                type: MaterialType.transparency,
                child: Theme(
                  data: overrideTheme,
                  child: DatePickerDialog(
                    initialDate: initialDate,
                    firstDate: firstDate,
                    lastDate: lastDate,
                    initialEntryMode: initialEntryMode,
                    initialCalendarMode: initialDatePickerMode,
                    selectableDayPredicate: selectableDayPredicate,
                  ),
                ),
              ),
            ),
          ),
        );
      },
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