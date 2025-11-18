import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  static String get baseUrl {
    if (kIsWeb) {
      // For web browsers
      return 'http://localhost:8000';
    } else if (Platform.isAndroid) {
      // For physical Android device on local network
      return 'http://192.168.1.72:8000';
    } else if (Platform.isIOS) {
      // For iOS simulator, use localhost
      return 'http://localhost:8000';
    } else {
      // Default fallback
      return 'http://localhost:8000';
    }
  }
  
  // Auth endpoints
  static const String login = '/api/users/login/';
  static const String register = '/api/users/register/';
  static const String profile = '/api/users/profiles/me/';
  static const String changePassword = '/api/users/profiles/change-password/';
  
  // Pet endpoints
  static const String pets = '/api/users/pets/';
  static const String vaccinations = '/api/users/vaccinations/';
  static const String medicalRecords = '/api/users/medical-records/';
  
  // Store endpoints
  static const String products = '/api/store/products/';
  static const String categories = '/api/store/categories/';
  static const String cart = '/api/store/cart/';
  
  // Community endpoints
  static const String users = '/api/users/profiles/';
  static const String posts = '/api/community/posts/';
  static const String comments = '/api/community/comments/';
  static const String groups = '/api/community/groups/';
  static const String events = '/api/community/events/';
  static const String lostFound = '/api/community/lost-found/';
  
  // AI endpoints
  static const String breedDetection = '/api/ai/breed-detection/';
  static const String chatbot = '/api/ai/chat-sessions/';
  
  // Notifications endpoint
  static const String notifications = '/api/users/notifications/';
}
