import 'package:dio/dio.dart';
import '../models/ai/breed_detection_model.dart';
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
}
