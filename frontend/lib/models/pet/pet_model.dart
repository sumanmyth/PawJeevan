import 'dart:convert';

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
  final String? clinicName;
  final String? certificate; // URL to certificate file
  final DateTime? createdAt;
  final DateTime? updatedAt;

  VaccinationModel({
    this.id,
    required this.vaccineName,
    required this.vaccinationDate,
    this.nextDueDate,
    this.veterinarian,
    this.notes,
    this.clinicName,
    this.certificate,
    this.createdAt,
    this.updatedAt,
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
      clinicName: json['clinic_name'],
      certificate: json['certificate'],
      createdAt: json['created_at'] != null && (json['created_at'] as String).isNotEmpty
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null && (json['updated_at'] as String).isNotEmpty
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vaccine_name': vaccineName,
      'vaccination_date': vaccinationDate.toIso8601String().split('T')[0],
      'next_due_date': nextDueDate?.toIso8601String().split('T')[0],
      'veterinarian': veterinarian,
      'notes': notes,
      'clinic_name': clinicName,
      'certificate': certificate,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
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
  final String? clinicName;
  final String? prescription;
  final List<String>? attachments;
  final int? petId;

  MedicalRecordModel({
    this.id,
    required this.recordType,
    required this.title,
    required this.description,
    required this.date,
    this.veterinarian,
    this.cost,
    this.clinicName,
    this.prescription,
    this.attachments,
    this.petId,
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
      clinicName: json['clinic_name'],
      prescription: json['prescription'],
      attachments: (() {
        final a = json['attachments'];
        if (a == null) return null;
        // If backend returns a proper List, normalize elements to strings
        if (a is List) return a.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
        // If backend returns a JSON-encoded list string, try to decode
        if (a is String) {
          try {
            final decoded = jsonDecode(a);
            if (decoded is List) return decoded.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
          } catch (_) {
            // not a JSON list string, fall through
          }
          // Otherwise treat the string as a single attachment URL
          final s = a.toString();
          return s.isEmpty ? null : <String>[s];
        }
        // Unknown type - try to stringify
        try {
          return (a as Iterable).map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
        } catch (_) {
          return null;
        }
      })(),
      petId: (() {
        final p = json['pet'];
        if (p == null) return null;
        if (p is int) return p;
        if (p is String) return int.tryParse(p);
        try {
          if (p is Map && p['id'] != null) {
            final idv = p['id'];
            if (idv is int) return idv;
            return int.tryParse(idv.toString());
          }
        } catch (_) {}
        return null;
      })(),
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
      'clinic_name': clinicName,
      'prescription': prescription,
      'attachments': attachments,
      'pet': petId,
    };
  }
}