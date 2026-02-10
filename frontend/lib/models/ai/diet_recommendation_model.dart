/// Model for diet recommendation results from the AI backend.
class DietRecommendationResult {
  final int? id;
  final int? petId;
  final String recommendedDiet;
  final int dailyCalories;
  final String feedingFrequency;
  final List<String> foodTypes;
  final String specialConsiderations;
  final String allergies;
  final String healthConditions;
  final List<dynamic> recommendedProducts;
  final DateTime? createdAt;

  // Extra fields returned by the API (not stored in DB)
  final String? sizeCategory;
  final String? lifeStage;
  final String? weightStatus;
  final bool breedSpecificAvailable;
  final List<String> foodsToAvoid;
  final List<String> supplements;
  final List<String> recentDetections;
  final String? ageStageNotes;
  final String? weightNotes;

  DietRecommendationResult({
    this.id,
    this.petId,
    required this.recommendedDiet,
    required this.dailyCalories,
    required this.feedingFrequency,
    required this.foodTypes,
    this.specialConsiderations = '',
    this.allergies = '',
    this.healthConditions = '',
    this.recommendedProducts = const [],
    this.createdAt,
    this.sizeCategory,
    this.lifeStage,
    this.weightStatus,
    this.breedSpecificAvailable = false,
    this.foodsToAvoid = const [],
    this.supplements = const [],
    this.recentDetections = const [],
    this.ageStageNotes,
    this.weightNotes,
  });

  factory DietRecommendationResult.fromJson(Map<String, dynamic> json) {
    return DietRecommendationResult(
      id: json['id'],
      petId: json['pet'],
      recommendedDiet: json['recommended_diet'] ?? '',
      dailyCalories: json['daily_calories'] ?? 0,
      feedingFrequency: json['feeding_frequency'] ?? '',
      foodTypes: _toStringList(json['food_types']),
      specialConsiderations: json['special_considerations'] ?? '',
      allergies: json['allergies'] ?? '',
      healthConditions: json['health_conditions'] ?? '',
      recommendedProducts: json['recommended_products'] ?? [],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      // Extra API fields
      sizeCategory: json['size_category'],
      lifeStage: json['life_stage'],
      weightStatus: json['weight_status'],
      breedSpecificAvailable: json['breed_specific_available'] ?? false,
      foodsToAvoid: _toStringList(json['foods_to_avoid']),
      supplements: _toStringList(json['supplements']),
      recentDetections: _toStringList(json['recent_detections']),
      ageStageNotes: json['age_stage_notes'],
      weightNotes: json['weight_notes'],
    );
  }

  static List<String> _toStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }

  String get sizeCategoryLabel =>
      (sizeCategory ?? 'unknown').replaceAll('_', ' ');

  String get lifeStageLabel =>
      (lifeStage ?? 'adult').replaceAll('_', ' ');

  String get weightStatusLabel =>
      (weightStatus ?? 'ideal').replaceAll('_', ' ');
}
