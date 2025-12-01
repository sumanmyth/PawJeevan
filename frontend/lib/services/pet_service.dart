import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import '../models/pet/pet_model.dart';
import '../utils/constants.dart';
import 'api_service.dart';
import '../utils/file_utils.dart';
import 'package:image_picker/image_picker.dart';

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
    final data = {...pet.toJson()};
    if (imageBytes != null) {
      final mp = await multipartFileFromBytes(imageBytes, fileName ?? 'pet.jpg');
      data['photo'] = mp;
    } else if (imagePath != null && imagePath.isNotEmpty && !kIsWeb) {
      final mp = await multipartFileFromPath(imagePath);
      data['photo'] = mp;
    }
    final form = FormData.fromMap(data);
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
    final data = {...pet.toJson()};
    if (imageBytes != null) {
      final mp = await multipartFileFromBytes(imageBytes, fileName ?? 'pet.jpg');
      data['photo'] = mp;
    } else if (imagePath != null && imagePath.isNotEmpty && !kIsWeb) {
      final mp = await multipartFileFromPath(imagePath);
      data['photo'] = mp;
    }
    final form = FormData.fromMap(data);
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

  /// Multipart add: supports uploading a certificate file alongside the vaccination.
  Future<VaccinationModel> addVaccinationMultipart(
    int petId,
    VaccinationModel vaccination, {
    List<XFile>? certificates,
  }) async {
    final raw = vaccination.toJson();
    final data = _cleanPayload(
      raw,
      stringFields: {'veterinarian', 'notes'},
      dateFields: {'next_due_date'},
    );
    data['pet'] = petId;

    if (certificates != null && certificates.isNotEmpty) {
      // Backwards-compatible: if only one certificate provided, send as 'certificate'
      if (certificates.length == 1) {
        final mp = await multipartFileFromXFile(certificates.first);
        data['certificate'] = mp;
      } else {
        final List<MultipartFile> files = [];
        for (final f in certificates) {
          final mp = await multipartFileFromXFile(f);
          files.add(mp);
        }
        data['certificates'] = files;
      }
    }

    final form = FormData.fromMap(data);
    final response = await _api.post(ApiConstants.vaccinations, data: form);
    if (response.statusCode == 201 || response.statusCode == 200) {
      return VaccinationModel.fromJson(response.data);
    }
    throw Exception('Failed to add vaccination (multipart)');
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

  /// Multipart update: supports uploading a new certificate alongside the vaccination.
  Future<VaccinationModel> updateVaccinationMultipart(
    int id,
    VaccinationModel vaccination, {
    List<XFile>? certificates,
  }) async {
    final raw = vaccination.toJson();
    final data = _cleanPayload(
      raw,
      stringFields: {'veterinarian', 'notes'},
      dateFields: {'next_due_date'},
    );

    if (certificates != null && certificates.isNotEmpty) {
      // Backwards-compatible: if only one certificate provided, send as 'certificate'
      if (certificates.length == 1) {
        final mp = await multipartFileFromXFile(certificates.first);
        data['certificate'] = mp;
      } else {
        final List<MultipartFile> files = [];
        for (final f in certificates) {
          final mp = await multipartFileFromXFile(f);
          files.add(mp);
        }
        data['certificates'] = files;
      }
    }

    final form = FormData.fromMap(data);
    final response = await _api.patch('${ApiConstants.vaccinations}$id/', data: form);
    if (response.statusCode == 200) {
      return VaccinationModel.fromJson(response.data);
    }
    throw Exception('Failed to update vaccination (multipart)');
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

  /// Multipart add: supports uploading attachments (images/files) alongside the record.
  Future<MedicalRecordModel> addMedicalRecordMultipart(
    int petId,
    MedicalRecordModel record, {
    List<XFile>? attachments,
  }) async {
    final raw = record.toJson();
    final data = _cleanPayload(
      raw,
      stringFields: {'veterinarian'},
      dropIfNull: {'cost'},
    );
    data['pet'] = petId;

    // Prepare multipart attachments if provided
    if (attachments != null && attachments.isNotEmpty) {
      final List<MultipartFile> files = [];
      for (final f in attachments) {
        final mp = await multipartFileFromXFile(f);
        files.add(mp);
      }
      data['attachments'] = files;
    }

    final form = FormData.fromMap(data);
    if (kDebugMode) {
      try {
        print('-- addMedicalRecordMultipart FormData keys: ${form.fields.map((f) => f.key).toList()}');
        print('-- addMedicalRecordMultipart files: ${form.files.map((f) => '${f.key}:${f.value.filename ?? 'unknown'}').toList()}');
      } catch (e) {
        print('debug print error: $e');
      }
    }
    final response = await _api.post(ApiConstants.medicalRecords, data: form);
    if (response.statusCode == 201 || response.statusCode == 200) {
      return MedicalRecordModel.fromJson(response.data);
    }
    throw Exception('Failed to add medical record (multipart)');
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

  /// Multipart update: supports uploading new attachments alongside the record.
  Future<MedicalRecordModel> updateMedicalRecordMultipart(
    int id,
    MedicalRecordModel record, {
    List<XFile>? attachments,
  }) async {
    final raw = record.toJson();
    final data = _cleanPayload(
      raw,
      stringFields: {'veterinarian'},
      dropIfNull: {'cost'},
    );

    if (attachments != null && attachments.isNotEmpty) {
      final List<MultipartFile> files = [];
      for (final f in attachments) {
        final mp = await multipartFileFromXFile(f);
        files.add(mp);
      }
      data['attachments'] = files;
    }

    final form = FormData.fromMap(data);
    if (kDebugMode) {
      try {
        print('-- updateMedicalRecordMultipart FormData keys: ${form.fields.map((f) => f.key).toList()}');
        print('-- updateMedicalRecordMultipart files: ${form.files.map((f) => '${f.key}:${f.value.filename ?? 'unknown'}').toList()}');
      } catch (e) {
        print('debug print error: $e');
      }
    }
    final response = await _api.patch('${ApiConstants.medicalRecords}$id/', data: form);
    if (response.statusCode == 200) {
      return MedicalRecordModel.fromJson(response.data);
    }
    throw Exception('Failed to update medical record (multipart)');
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