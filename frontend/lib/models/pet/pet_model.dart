class PetModel {
  final int? id;
  final String name;
  final String petType;
  final String breed;
  final String gender;

  // Use date of birth (preferred by your backend)
  final DateTime? dateOfBirth;

  // Age as received from backend or computed locally
  final int? age;

  final double weight;
  final String? color;
  final String? photo;
  final String? medicalNotes;

  final List<VaccinationModel>? vaccinations;
  final List<MedicalRecordModel>? medicalRecords;

  PetModel({
    this.id,
    required this.name,
    required this.petType,
    required this.breed,
    required this.gender,
    this.dateOfBirth,
    this.age,
    required this.weight,
    this.color,
    this.photo,
    this.medicalNotes,
    this.vaccinations,
    this.medicalRecords,
  });

  factory PetModel.fromJson(Map<String, dynamic> json) {
    DateTime? dob;
    if (json['date_of_birth'] != null && (json['date_of_birth'] as String).isNotEmpty) {
      dob = DateTime.tryParse(json['date_of_birth']);
    }

    int? serverAge;
    if (json['age'] != null) {
      try {
        serverAge = int.tryParse(json['age'].toString());
      } catch (_) {
        serverAge = null;
      }
    }

    // Compute age locally if backend didn't provide it but DOB exists
    final computedAge = serverAge ?? _computeAge(dob);

    return PetModel(
      id: json['id'],
      name: json['name'] ?? '',
      petType: json['pet_type'] ?? '',
      breed: json['breed'] ?? '',
      gender: json['gender'] ?? '',
      dateOfBirth: dob,
      age: computedAge,
      weight: json['weight'] != null ? double.tryParse(json['weight'].toString()) ?? 0.0 : 0.0,
      color: json['color'],
      photo: json['photo'],
      medicalNotes: json['medical_notes'],
      vaccinations: json['vaccinations'] != null
          ? (json['vaccinations'] as List).map((v) => VaccinationModel.fromJson(v)).toList()
          : null,
      medicalRecords: json['medical_records'] != null
          ? (json['medical_records'] as List).map((m) => MedicalRecordModel.fromJson(m)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    // Prefer sending date_of_birth for your backend
    final map = <String, dynamic>{
      'name': name,
      'pet_type': petType,
      'breed': breed,
      'gender': gender,
      'weight': weight,
      'color': color,
      'medical_notes': medicalNotes,
    };

    if (dateOfBirth != null) {
      map['date_of_birth'] = _fmtDate(dateOfBirth!); // YYYY-MM-DD
    } else if (age != null) {
      // Fallback if backend expects age (not typical for your current backend)
      map['age'] = age;
    }

    return map;
  }

  static int? _computeAge(DateTime? dob) {
    if (dob == null) return null;
    final today = DateTime.now();
    int years = today.year - dob.year;
    if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
      years -= 1;
    }
    return years < 0 ? 0 : years;
  }

  static String _fmtDate(DateTime d) => d.toIso8601String().split('T')[0];
}

class VaccinationModel {
  final int? id;
  final String vaccineName;
  final DateTime vaccinationDate;
  final DateTime? nextDueDate;
  final String? veterinarian;
  final String? notes;

  VaccinationModel({
    this.id,
    required this.vaccineName,
    required this.vaccinationDate,
    this.nextDueDate,
    this.veterinarian,
    this.notes,
  });

  factory VaccinationModel.fromJson(Map<String, dynamic> json) {
    return VaccinationModel(
      id: json['id'],
      vaccineName: json['vaccine_name'] ?? '',
      vaccinationDate: DateTime.parse(json['vaccination_date']),
      nextDueDate: json['next_due_date'] != null && (json['next_due_date'] as String).isNotEmpty
          ? DateTime.tryParse(json['next_due_date'])
          : null,
      veterinarian: json['veterinarian'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vaccine_name': vaccineName,
      'vaccination_date': vaccinationDate.toIso8601String().split('T')[0],
      'next_due_date': nextDueDate?.toIso8601String().split('T')[0],
      'veterinarian': veterinarian,
      'notes': notes,
    };
  }
}

class MedicalRecordModel {
  final int? id;
  final String recordType;
  final String title;
  final String description;
  final DateTime date;
  final String? veterinarian;
  final double? cost;

  MedicalRecordModel({
    this.id,
    required this.recordType,
    required this.title,
    required this.description,
    required this.date,
    this.veterinarian,
    this.cost,
  });

  factory MedicalRecordModel.fromJson(Map<String, dynamic> json) {
    return MedicalRecordModel(
      id: json['id'],
      recordType: json['record_type'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      date: DateTime.parse(json['date']),
      veterinarian: json['veterinarian'],
      cost: json['cost'] != null ? double.tryParse(json['cost'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'record_type': recordType,
      'title': title,
      'description': description,
      'date': date.toIso8601String().split('T')[0],
      'veterinarian': veterinarian,
      'cost': cost,
    };
  }
}