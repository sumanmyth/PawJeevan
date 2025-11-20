import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../models/pet/adoption_listing_model.dart';
import '../utils/constants.dart';
import 'api_service.dart';

class StoreService {
  final ApiService _api = ApiService();

  /// Fetch all adoption listings
  Future<List<AdoptionListing>> fetchAdoptions({
    String? petType,
    String? status,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (petType != null && petType != 'all') queryParams['pet_type'] = petType;
      if (status != null) queryParams['status'] = status;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      print('Fetching adoptions with params: $queryParams');
      
      final response = await _api.get(
        ApiConstants.adoptions,
        params: queryParams,
      );

      print('Adoption response status: ${response.statusCode}');
      print('Adoption response data: ${response.data}');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List 
            ? response.data 
            : (response.data['results'] ?? []);
        print('Found ${data.length} adoptions');
        return data.map((json) => AdoptionListing.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching adoptions: $e');
      rethrow;
    }
  }

  /// Fetch single adoption listing by ID
  Future<AdoptionListing?> fetchAdoptionById(int id) async {
    try {
      final response = await _api.get('${ApiConstants.adoptions}$id/');
      if (response.statusCode == 200) {
        return AdoptionListing.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print('Error fetching adoption: $e');
      return null;
    }
  }

  /// Create a new adoption listing
  Future<AdoptionListing?> createAdoption({
    required String title,
    required String petName,
    required String petType,
    required String breed,
    required int age,
    required String gender,
    required String description,
    required String healthStatus,
    required String vaccinationStatus,
    required bool isNeutered,
    required String contactPhone,
    required String contactEmail,
    required String location,
    XFile? photo,
  }) async {
    try {
      final formData = FormData();
      formData.fields.addAll([
        MapEntry('title', title),
        MapEntry('pet_name', petName),
        MapEntry('pet_type', petType),
        MapEntry('breed', breed),
        MapEntry('age', age.toString()),
        MapEntry('gender', gender),
        MapEntry('description', description),
        MapEntry('health_status', healthStatus),
        MapEntry('vaccination_status', vaccinationStatus),
        MapEntry('is_neutered', isNeutered.toString()),
        MapEntry('contact_phone', contactPhone),
        MapEntry('contact_email', contactEmail),
        MapEntry('location', location),
      ]);

      if (photo != null) {
        final bytes = await photo.readAsBytes();
        formData.files.add(MapEntry(
          'photo',
          MultipartFile.fromBytes(
            bytes,
            filename: photo.name,
          ),
        ));
      }

      final response = await _api.post(
        ApiConstants.adoptions,
        data: formData,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return AdoptionListing.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print('Error creating adoption: $e');
      rethrow;
    }
  }

  /// Update an existing adoption listing
  Future<AdoptionListing?> updateAdoption({
    required int id,
    String? title,
    String? petName,
    String? petType,
    String? breed,
    int? age,
    String? gender,
    String? description,
    String? healthStatus,
    String? vaccinationStatus,
    bool? isNeutered,
    String? contactPhone,
    String? contactEmail,
    String? location,
    String? status,
    XFile? photo,
  }) async {
    try {
      final formData = FormData();
      
      if (title != null) formData.fields.add(MapEntry('title', title));
      if (petName != null) formData.fields.add(MapEntry('pet_name', petName));
      if (petType != null) formData.fields.add(MapEntry('pet_type', petType));
      if (breed != null) formData.fields.add(MapEntry('breed', breed));
      if (age != null) formData.fields.add(MapEntry('age', age.toString()));
      if (gender != null) formData.fields.add(MapEntry('gender', gender));
      if (description != null) formData.fields.add(MapEntry('description', description));
      if (healthStatus != null) formData.fields.add(MapEntry('health_status', healthStatus));
      if (vaccinationStatus != null) formData.fields.add(MapEntry('vaccination_status', vaccinationStatus));
      if (isNeutered != null) formData.fields.add(MapEntry('is_neutered', isNeutered.toString()));
      if (contactPhone != null) formData.fields.add(MapEntry('contact_phone', contactPhone));
      if (contactEmail != null) formData.fields.add(MapEntry('contact_email', contactEmail));
      if (location != null) formData.fields.add(MapEntry('location', location));
      if (status != null) formData.fields.add(MapEntry('status', status));

      if (photo != null) {
        final bytes = await photo.readAsBytes();
        formData.files.add(MapEntry(
          'photo',
          MultipartFile.fromBytes(
            bytes,
            filename: photo.name,
          ),
        ));
      }

      final response = await _api.patch(
        '${ApiConstants.adoptions}$id/',
        data: formData,
      );

      if (response.statusCode == 200) {
        return AdoptionListing.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print('Error updating adoption: $e');
      rethrow;
    }
  }

  /// Delete an adoption listing
  Future<bool> deleteAdoption(int id) async {
    try {
      final response = await _api.delete('${ApiConstants.adoptions}$id/');
      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      print('Error deleting adoption: $e');
      return false;
    }
  }
}
