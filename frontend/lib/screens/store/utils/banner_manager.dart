import 'package:shared_preferences/shared_preferences.dart';

class BannerManager {
  static Future<bool> shouldShowBanner() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDismissed = prefs.getString('banner_dismissed_date_time');
    
    if (lastDismissed == null) {
      return true;
    }
    
    final lastDismissedTime = DateTime.parse(lastDismissed);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dismissedDate = DateTime(
      lastDismissedTime.year,
      lastDismissedTime.month,
      lastDismissedTime.day,
    );
    
    return today.isAfter(dismissedDate) || 
           now.difference(lastDismissedTime).inHours >= 4;
  }

  static Future<void> dismissBanner() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'banner_dismissed_date_time',
      DateTime.now().toIso8601String(),
    );
  }
}
