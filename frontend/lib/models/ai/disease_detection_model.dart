/// Model for disease detection results

class DiseaseDetectionResult {
  final int? id;
  final String? imageUrl;
  final String diseaseType;
  final String detectedDisease;
  final double confidence;
  final String severity;
  final String recommendations;
  final bool shouldSeeVet;
  final double? processingTime;
  final DateTime? createdAt;
  final bool aiPowered;

  DiseaseDetectionResult({
    this.id,
    this.imageUrl,
    required this.diseaseType,
    required this.detectedDisease,
    required this.confidence,
    required this.severity,
    required this.recommendations,
    required this.shouldSeeVet,
    this.processingTime,
    this.createdAt,
    this.aiPowered = false,
  });

  factory DiseaseDetectionResult.fromJson(Map<String, dynamic> json) {
    return DiseaseDetectionResult(
      id: json['id'],
      imageUrl: json['image'],
      diseaseType: json['disease_type'] ?? 'general',
      detectedDisease: json['detected_disease'] ?? 'Unknown',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      severity: json['severity'] ?? 'low',
      recommendations: json['recommendations'] ?? '',
      shouldSeeVet: json['should_see_vet'] ?? true,
      processingTime: json['processing_time']?.toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      aiPowered: json['ai_powered'] ?? false,
    );
  }

  String get confidencePercent => '${(confidence * 100).toStringAsFixed(0)}%';

  String get severityLabel {
    switch (severity.toLowerCase()) {
      case 'low':
        return 'Low';
      case 'medium':
        return 'Medium';
      case 'high':
        return 'High';
      case 'critical':
        return 'Critical';
      default:
        return severity;
    }
  }

  String get diseaseTypeLabel {
    switch (diseaseType.toLowerCase()) {
      case 'skin':
        return 'Skin Condition';
      case 'eye':
        return 'Eye Issue';
      case 'ear':
        return 'Ear Problem';
      case 'dental':
        return 'Dental Issue';
      default:
        return 'General Health';
    }
  }
}
