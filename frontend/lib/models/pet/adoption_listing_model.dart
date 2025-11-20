class AdoptionListing {
  final int id;
  final String title;
  final String petName;
  final String petType;
  final String breed;
  final int age;
  final String gender;
  final String description;
  final String healthStatus;
  final String vaccinationStatus;
  final bool isNeutered;
  final String? photo;
  final int poster;
  final String posterUsername;
  final String contactPhone;
  final String contactEmail;
  final String location;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  AdoptionListing({
    required this.id,
    required this.title,
    required this.petName,
    required this.petType,
    required this.breed,
    required this.age,
    required this.gender,
    required this.description,
    required this.healthStatus,
    required this.vaccinationStatus,
    required this.isNeutered,
    this.photo,
    required this.poster,
    required this.posterUsername,
    required this.contactPhone,
    required this.contactEmail,
    required this.location,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdoptionListing.fromJson(Map<String, dynamic> json) {
    return AdoptionListing(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      petName: json['pet_name'] ?? '',
      petType: json['pet_type'] ?? '',
      breed: json['breed'] ?? '',
      age: json['age'] ?? 0,
      gender: json['gender'] ?? '',
      description: json['description'] ?? '',
      healthStatus: json['health_status'] ?? '',
      vaccinationStatus: json['vaccination_status'] ?? '',
      isNeutered: json['is_neutered'] ?? false,
      photo: json['photo'],
      poster: json['poster'] ?? 0,
      posterUsername: json['poster_username'] ?? '',
      contactPhone: json['contact_phone'] ?? '',
      contactEmail: json['contact_email'] ?? '',
      location: json['location'] ?? '',
      status: json['status'] ?? 'available',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'pet_name': petName,
      'pet_type': petType,
      'breed': breed,
      'age': age,
      'gender': gender,
      'description': description,
      'health_status': healthStatus,
      'vaccination_status': vaccinationStatus,
      'is_neutered': isNeutered,
      'photo': photo,
      'poster': poster,
      'contact_phone': contactPhone,
      'contact_email': contactEmail,
      'location': location,
      'status': status,
    };
  }

  String get ageDisplay {
    if (age < 12) {
      return '$age months';
    } else {
      final years = age ~/ 12;
      final months = age % 12;
      if (months == 0) {
        return '$years ${years == 1 ? 'year' : 'years'}';
      }
      return '$years ${years == 1 ? 'year' : 'years'} $months ${months == 1 ? 'month' : 'months'}';
    }
  }

  String get petTypeDisplay {
    return petType.substring(0, 1).toUpperCase() + petType.substring(1);
  }
}
