import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/pet/pet_model.dart';
import '../utils/constants.dart';
import 'api_service.dart';

class PetService {
  final ApiService _api = ApiService();

  // ===== Pets =====

  Future<List<PetModel>> getPets() async {
    final response = await _api.get(ApiConstants.pets);
    if (response.statusCode == 200) {
      final data = response.data;
      if (data is List) {
        return data.map((j) => PetModel.fromJson(j)).toList();
      }
      if (data is Map && data['results'] is List) {
        return (data['results'] as List).map((j) => PetModel.fromJson(j)).toList();
      }
    }
    return [];
  }

  Future<PetModel> getPet(int petId) async {
    final response = await _api.get('${ApiConstants.pets}$petId/');
    if (response.statusCode == 200) {
      return PetModel.fromJson(response.data);
    }
    throw Exception('Failed to get pet details');
  }

  Future<PetModel> createPet(PetModel pet) async {
    final response = await _api.post(ApiConstants.pets, data: pet.toJson());
    if (response.statusCode == 201 || response.statusCode == 200) {
      return PetModel.fromJson(response.data);
    }
    throw Exception('Failed to create pet');
  }

  Future<PetModel> createPetMultipart(
    PetModel pet, {
    String? imagePath,
    List<int>? imageBytes,
    String? fileName,
  }) async {
    final form = FormData.fromMap({
      ...pet.toJson(),
      if (imageBytes != null)
        'photo': MultipartFile.fromBytes(imageBytes, filename: fileName ?? 'pet.jpg')
      else if (imagePath != null && imagePath.isNotEmpty && !kIsWeb)
        'photo': await MultipartFile.fromFile(imagePath, filename: imagePath.split('/').last),
    });
    final response = await _api.post(ApiConstants.pets, data: form);
    if (response.statusCode == 201 || response.statusCode == 200) {
      return PetModel.fromJson(response.data);
    }
    throw Exception('Failed to create pet (multipart)');
  }

  // SWITCHED TO PATCH for partial updates to avoid serializer "required field" errors
  Future<PetModel> updatePet(int id, PetModel pet) async {
    final response = await _api.patch('${ApiConstants.pets}$id/', data: pet.toJson());
    if (response.statusCode == 200) {
      return PetModel.fromJson(response.data);
    }
    throw Exception('Failed to update pet');
  }

  Future<PetModel> updatePetMultipart(
    int id,
    PetModel pet, {
    String? imagePath,
    List<int>? imageBytes,
    String? fileName,
  }) async {
    final form = FormData.fromMap({
      ...pet.toJson(),
      if (imageBytes != null)
        'photo': MultipartFile.fromBytes(imageBytes, filename: fileName ?? 'pet.jpg')
      else if (imagePath != null && imagePath.isNotEmpty && !kIsWeb)
        'photo': await MultipartFile.fromFile(imagePath, filename: imagePath.split('/').last),
    });
    final response = await _api.patch('${ApiConstants.pets}$id/', data: form);
    if (response.statusCode == 200) {
      return PetModel.fromJson(response.data);
    }
    throw Exception('Failed to update pet (multipart)');
  }

  Future<void> deletePet(int id) async {
    await _api.delete('${ApiConstants.pets}$id/');
  }

  // ===== Vaccinations =====

  Future<List<VaccinationModel>> getVaccinations(int petId) async {
    final response = await _api.get('${ApiConstants.vaccinations}?pet=$petId');
    if (response.statusCode == 200) {
      final data = response.data;
      if (data is List) {
        return data.map((j) => VaccinationModel.fromJson(j)).toList();
      }
      if (data is Map && data['results'] is List) {
        return (data['results'] as List).map((j) => VaccinationModel.fromJson(j)).toList();
      }
    }
    return [];
  }

  Future<VaccinationModel> addVaccination(int petId, VaccinationModel vaccination) async {
    final raw = vaccination.toJson();
    final data = _cleanPayload(
      raw,
      stringFields: {'veterinarian', 'notes'},
      dateFields: {'next_due_date'},
    );
    data['pet'] = petId;

    final response = await _api.post(ApiConstants.vaccinations, data: data);
    if (response.statusCode == 201 || response.statusCode == 200) {
      return VaccinationModel.fromJson(response.data);
    }
    throw Exception('Failed to add vaccination');
  }

  // PATCH instead of PUT (avoid serializer required fields such as pet)
  Future<VaccinationModel> updateVaccination(int id, VaccinationModel vaccination) async {
    final raw = vaccination.toJson();
    final data = _cleanPayload(
      raw,
      stringFields: {'veterinarian', 'notes'},
      dateFields: {'next_due_date'},
    );

    final response = await _api.patch('${ApiConstants.vaccinations}$id/', data: data);
    if (response.statusCode == 200) {
      return VaccinationModel.fromJson(response.data);
    }
    throw Exception('Failed to update vaccination');
  }

  Future<void> deleteVaccination(int id) async {
    await _api.delete('${ApiConstants.vaccinations}$id/');
  }

  // ===== Medical Records =====

  Future<List<MedicalRecordModel>> getMedicalRecords(int petId) async {
    final response = await _api.get('${ApiConstants.medicalRecords}?pet=$petId');
    if (response.statusCode == 200) {
      final data = response.data;
      if (data is List) {
        return data.map((j) => MedicalRecordModel.fromJson(j)).toList();
      }
      if (data is Map && data['results'] is List) {
        return (data['results'] as List).map((j) => MedicalRecordModel.fromJson(j)).toList();
      }
    }
    return [];
  }

  Future<MedicalRecordModel> addMedicalRecord(int petId, MedicalRecordModel record) async {
    final raw = record.toJson();
    final data = _cleanPayload(
      raw,
      stringFields: {'veterinarian'},
      dropIfNull: {'cost'},
    );
    data['pet'] = petId;

    final response = await _api.post(ApiConstants.medicalRecords, data: data);
    if (response.statusCode == 201 || response.statusCode == 200) {
      return MedicalRecordModel.fromJson(response.data);
    }
    throw Exception('Failed to add medical record');
  }

  // PATCH instead of PUT
  Future<MedicalRecordModel> updateMedicalRecord(int id, MedicalRecordModel record) async {
    final raw = record.toJson();
    final data = _cleanPayload(
      raw,
      stringFields: {'veterinarian'},
      dropIfNull: {'cost'},
    );

    final response = await _api.patch('${ApiConstants.medicalRecords}$id/', data: data);
    if (response.statusCode == 200) {
      return MedicalRecordModel.fromJson(response.data);
    }
    throw Exception('Failed to update medical record');
  }

  Future<void> deleteMedicalRecord(int id) async {
    await _api.delete('${ApiConstants.medicalRecords}$id/');
  }

  // ===== Helpers =====

  Map<String, dynamic> _cleanPayload(
    Map<String, dynamic> input, {
    Set<String> stringFields = const {},
    Set<String> dateFields = const {},
    Set<String> dropIfNull = const {},
  }) {
    final data = <String, dynamic>{};
    input.forEach((key, value) {
      if (value == null) {
        if (stringFields.contains(key)) {
          data[key] = '';
        }
        // else drop nulls
      } else if (value is String) {
        final trimmed = value.trim();
        if (trimmed.isEmpty && stringFields.contains(key)) {
          data[key] = '';
        } else if (trimmed.isEmpty && dateFields.contains(key)) {
          // drop empty date
        } else {
          data[key] = trimmed;
        }
      } else {
        data[key] = value;
      }
    });

    // Remove empty-string dates if any
    for (final f in dateFields) {
      if (data[f] is String && (data[f] as String).trim().isEmpty) {
        data.remove(f);
      }
    }

    // Drop optional numerics if null (safe guard)
    for (final f in dropIfNull) {
      if (!data.containsKey(f) || data[f] == null) {
        data.remove(f);
      }
    }
    return data;
  }
}