/// Model for breed detection results from the AI API

class BreedDetectionResult {
  final int? id;
  final String? imageUrl;
  final String detectedBreed;
  final double confidence;
  final List<AlternativeBreed> alternativeBreeds;
  final String modelVersion;
  final double? processingTime;
  final bool? isDog;
  final bool? isHuman;
  final String? error;
  final DateTime? createdAt;

  BreedDetectionResult({
    this.id,
    this.imageUrl,
    required this.detectedBreed,
    required this.confidence,
    this.alternativeBreeds = const [],
    this.modelVersion = 'unknown',
    this.processingTime,
    this.isDog,
    this.isHuman,
    this.error,
    this.createdAt,
  });

  factory BreedDetectionResult.fromJson(Map<String, dynamic> json) {
    List<AlternativeBreed> alternatives = [];
    if (json['alternative_breeds'] != null) {
      alternatives = (json['alternative_breeds'] as List)
          .map((a) => AlternativeBreed.fromJson(a))
          .toList();
    }

    return BreedDetectionResult(
      id: json['id'],
      imageUrl: json['image'],
      detectedBreed: json['detected_breed'] ?? 'Unknown',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      alternativeBreeds: alternatives,
      modelVersion: json['model_version'] ?? 'unknown',
      processingTime: json['processing_time']?.toDouble(),
      isDog: json['is_dog'],
      isHuman: json['is_human'],
      error: json['error'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image': imageUrl,
      'detected_breed': detectedBreed,
      'confidence': confidence,
      'alternative_breeds': alternativeBreeds.map((a) => a.toJson()).toList(),
      'model_version': modelVersion,
      'processing_time': processingTime,
      'is_dog': isDog,
      'is_human': isHuman,
      'error': error,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  /// Get confidence as percentage string
  String get confidencePercent => '${(confidence * 100).toStringAsFixed(1)}%';

  /// Check if detection was successful
  bool get isSuccessful => error == null && detectedBreed != 'Unknown' && detectedBreed != 'Error';

  /// Get formatted breed name (title case)
  String get formattedBreed {
    return detectedBreed
        .split('_')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
            : '')
        .join(' ');
  }
}

class AlternativeBreed {
  final String breed;
  final double confidence;

  AlternativeBreed({
    required this.breed,
    required this.confidence,
  });

  factory AlternativeBreed.fromJson(Map<String, dynamic> json) {
    return AlternativeBreed(
      breed: json['breed'] ?? 'Unknown',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'breed': breed,
      'confidence': confidence,
    };
  }

  /// Get confidence as percentage string
  String get confidencePercent => '${(confidence * 100).toStringAsFixed(1)}%';

  /// Get formatted breed name
  String get formattedBreed {
    return breed
        .split('_')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
            : '')
        .join(' ');
  }
}
