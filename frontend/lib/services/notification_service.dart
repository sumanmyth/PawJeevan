import '../models/notification_model.dart';
import '../utils/constants.dart';
import 'api_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final ApiService _api = ApiService();

  Future<List<NotificationModel>> getNotifications() async {
    final response = await _api.get(ApiConstants.notifications);
    if (response.statusCode == 200) {
      final data = response.data;
      if (data is List) {
        return data.map((j) => NotificationModel.fromJson(j)).toList();
      }
      if (data is Map && data['results'] is List) {
        return (data['results'] as List)
            .map((j) => NotificationModel.fromJson(j))
            .toList();
      }
    }
    return [];
  }

  Future<void> markAsRead(int notificationId) async {
    await _api.patch(
      '${ApiConstants.notifications}$notificationId/mark_read/',
      data: {'is_read': true},
    );
  }

  Future<void> deleteNotification(int notificationId) async {
    await _api.delete('${ApiConstants.notifications}$notificationId/');
  }

  // Note: Local push notifications have been removed. Only in-app notifications are supported.
}