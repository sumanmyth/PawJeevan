import 'package:flutter/material.dart';
import '../models/pet_model.dart';
import '../services/pet_service.dart';

class PetProvider extends ChangeNotifier {
  final PetService _petService = PetService();

  List<PetModel> _pets = [];
  bool _isLoading = false;
  String? _error;

  List<PetModel> get pets => _pets;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadPets() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _pets = await _petService.getPets();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addPet(PetModel pet) async {
    try {
      final newPet = await _petService.createPet(pet);
      _pets.add(newPet);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> addPetWithImage(
    PetModel pet, {
    String? imagePath,
    List<int>? imageBytes,
    String? fileName,
  }) async {
    try {
      final newPet = await _petService.createPetMultipart(
        pet,
        imagePath: imagePath,
        imageBytes: imageBytes,
        fileName: fileName,
      );
      _pets.add(newPet);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePet(int id, PetModel pet) async {
    try {
      final updatedPet = await _petService.updatePet(id, pet);
      final index = _pets.indexWhere((p) => p.id == id);
      if (index != -1) _pets[index] = updatedPet;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePetWithImage(
    int id,
    PetModel pet, {
    String? imagePath,
    List<int>? imageBytes,
    String? fileName,
  }) async {
    try {
      final updatedPet = await _petService.updatePetMultipart(
        id,
        pet,
        imagePath: imagePath,
        imageBytes: imageBytes,
        fileName: fileName,
      );
      final index = _pets.indexWhere((p) => p.id == id);
      if (index != -1) _pets[index] = updatedPet;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePet(int id) async {
    try {
      await _petService.deletePet(id);
      _pets.removeWhere((p) => p.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}