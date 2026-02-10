import 'package:dio/dio.dart';
import '../models/ai/breed_detection_model.dart';
import '../models/ai/diet_recommendation_model.dart';
import '../models/ai/chat_model.dart';
import '../models/ai/disease_detection_model.dart';
import '../utils/constants.dart';
import 'api_service.dart';
import '../utils/file_utils.dart';
import 'package:image_picker/image_picker.dart';

/// Service for AI-related API calls
class AIService {
  final ApiService _api = ApiService();

  // ===== Breed Detection =====

  /// Detect dog breed from an image file
  /// Returns BreedDetectionResult with detected breed and confidence
  Future<BreedDetectionResult> detectBreed({
    required XFile imageFile,
  }) async {
    try {
      final mp = await multipartFileFromXFile(imageFile);
      final formData = FormData.fromMap({
        'image': mp,
      });

      final response = await _api.post(
        ApiConstants.breedDetection,
        data: formData,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return BreedDetectionResult.fromJson(response.data);
      }
      throw Exception('Failed to detect breed: ${response.statusCode}');
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data['error'] != null) {
        throw Exception(e.response?.data['error']);
      }
      throw Exception('Network error during breed detection');
    }
  }

  /// Detect breed from image bytes (for web)
  Future<BreedDetectionResult> detectBreedFromBytes({
    required List<int> imageBytes,
    String fileName = 'pet_image.jpg',
  }) async {
    try {
      final mp = await multipartFileFromBytes(imageBytes, fileName);
      final formData = FormData.fromMap({
        'image': mp,
      });

      final response = await _api.post(
        ApiConstants.breedDetection,
        data: formData,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return BreedDetectionResult.fromJson(response.data);
      }
      throw Exception('Failed to detect breed: ${response.statusCode}');
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data['error'] != null) {
        throw Exception(e.response?.data['error']);
      }
      throw Exception('Network error during breed detection');
    }
  }

  /// Get all breed detection history for current user
  Future<List<BreedDetectionResult>> getBreedDetectionHistory() async {
    final response = await _api.get(ApiConstants.breedDetection);
    if (response.statusCode == 200) {
      final data = response.data;
      if (data is List) {
        return data.map((j) => BreedDetectionResult.fromJson(j)).toList();
      }
      if (data is Map && data['results'] is List) {
        return (data['results'] as List)
            .map((j) => BreedDetectionResult.fromJson(j))
            .toList();
      }
    }
    return [];
  }

  /// Get a specific breed detection result by ID
  Future<BreedDetectionResult> getBreedDetection(int id) async {
    final response = await _api.get('${ApiConstants.breedDetection}$id/');
    if (response.statusCode == 200) {
      return BreedDetectionResult.fromJson(response.data);
    }
    throw Exception('Failed to get breed detection result');
  }

  /// Delete a breed detection result
  Future<void> deleteBreedDetection(int id) async {
    await _api.delete('${ApiConstants.breedDetection}$id/');
  }

  // ===== Diet Recommendations =====

  /// Generate a diet recommendation for a pet
  Future<DietRecommendationResult> getDietRecommendation({
    required int petId,
    String allergies = '',
    String healthConditions = '',
    String specialConsiderations = '',
  }) async {
    try {
      final response = await _api.post(
        ApiConstants.dietRecommendations,
        data: {
          'pet_id': petId,
          'allergies': allergies,
          'health_conditions': healthConditions,
          'special_considerations': specialConsiderations,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return DietRecommendationResult.fromJson(response.data);
      }
      throw Exception('Failed to get diet recommendation: ${response.statusCode}');
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data['error'] != null) {
        throw Exception(e.response?.data['error']);
      }
      throw Exception('Network error during diet recommendation');
    }
  }

  /// Get diet recommendation history for current user
  Future<List<DietRecommendationResult>> getDietHistory() async {
    final response = await _api.get(ApiConstants.dietRecommendations);
    if (response.statusCode == 200) {
      final data = response.data;
      if (data is List) {
        return data.map((j) => DietRecommendationResult.fromJson(j)).toList();
      }
      if (data is Map && data['results'] is List) {
        return (data['results'] as List)
            .map((j) => DietRecommendationResult.fromJson(j))
            .toList();
      }
    }
    return [];
  }

  /// Delete a diet recommendation
  Future<void> deleteDietRecommendation(int id) async {
    await _api.delete('${ApiConstants.dietRecommendations}$id/');
  }

  // ===== AI Chat (Llama 3.2) =====

  /// Get all chat sessions for current user
  Future<List<ChatSession>> getChatSessions() async {
    final response = await _api.get(ApiConstants.chatSessions);
    if (response.statusCode == 200) {
      final data = response.data;
      if (data is List) {
        return data.map((j) => ChatSession.fromJson(j)).toList();
      }
      if (data is Map && data['results'] is List) {
        return (data['results'] as List)
            .map((j) => ChatSession.fromJson(j))
            .toList();
      }
    }
    return [];
  }

  /// Create a new chat session
  Future<ChatSession> createChatSession({String title = 'New Pet Care Chat'}) async {
    final response = await _api.post(
      ApiConstants.chatSessions,
      data: {'title': title},
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return ChatSession.fromJson(response.data);
    }
    throw Exception('Failed to create chat session');
  }

  /// Get a specific chat session with messages
  Future<ChatSession> getChatSession(int sessionId) async {
    final response = await _api.get('${ApiConstants.chatSessions}$sessionId/');
    if (response.statusCode == 200) {
      return ChatSession.fromJson(response.data);
    }
    throw Exception('Failed to get chat session');
  }

  /// Send a message to a chat session
  Future<Map<String, ChatMessage>> sendChatMessage({
    required int sessionId,
    required String message,
  }) async {
    final response = await _api.post(
      '${ApiConstants.chatSessions}$sessionId/send_message/',
      data: {'message': message},
    );
    if (response.statusCode == 200) {
      return {
        'user': ChatMessage.fromJson(response.data['user_message']),
        'assistant': ChatMessage.fromJson(response.data['ai_message']),
      };
    }
    throw Exception('Failed to send message');
  }

  /// Delete a chat session
  Future<void> deleteChatSession(int sessionId) async {
    await _api.delete('${ApiConstants.chatSessions}$sessionId/');
  }

  // ===== Disease Detection (Llama 3.2) =====

  /// Detect disease from an image file
  Future<DiseaseDetectionResult> detectDisease({
    required XFile imageFile,
    String diseaseType = 'general',
    int? petId,
    String symptoms = '',
  }) async {
    try {
      final mp = await multipartFileFromXFile(imageFile);
      final formData = FormData.fromMap({
        'image': mp,
        'disease_type': diseaseType,
        if (petId != null) 'pet_id': petId,
        if (symptoms.isNotEmpty) 'symptoms': symptoms,
      });

      final response = await _api.post(
        ApiConstants.diseaseDetection,
        data: formData,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return DiseaseDetectionResult.fromJson(response.data);
      }
      throw Exception('Failed to detect disease: ${response.statusCode}');
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data['error'] != null) {
        throw Exception(e.response?.data['error']);
      }
      throw Exception('Network error during disease detection');
    }
  }

  /// Detect disease from image bytes
  Future<DiseaseDetectionResult> detectDiseaseFromBytes({
    required List<int> imageBytes,
    String fileName = 'pet_image.jpg',
    String diseaseType = 'general',
    int? petId,
    String symptoms = '',
  }) async {
    try {
      final mp = await multipartFileFromBytes(imageBytes, fileName);
      final formData = FormData.fromMap({
        'image': mp,
        'disease_type': diseaseType,
        if (petId != null) 'pet_id': petId,
        if (symptoms.isNotEmpty) 'symptoms': symptoms,
      });

      final response = await _api.post(
        ApiConstants.diseaseDetection,
        data: formData,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return DiseaseDetectionResult.fromJson(response.data);
      }
      throw Exception('Failed to detect disease: ${response.statusCode}');
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data['error'] != null) {
        throw Exception(e.response?.data['error']);
      }
      throw Exception('Network error during disease detection');
    }
  }

  /// Get disease detection history
  Future<List<DiseaseDetectionResult>> getDiseaseHistory() async {
    final response = await _api.get(ApiConstants.diseaseDetection);
    if (response.statusCode == 200) {
      final data = response.data;
      if (data is List) {
        return data.map((j) => DiseaseDetectionResult.fromJson(j)).toList();
      }
      if (data is Map && data['results'] is List) {
        return (data['results'] as List)
            .map((j) => DiseaseDetectionResult.fromJson(j))
            .toList();
      }
    }
    return [];
  }

  /// Delete a disease detection result
  Future<void> deleteDiseaseDetection(int id) async {
    await _api.delete('${ApiConstants.diseaseDetection}$id/');
  }
}
