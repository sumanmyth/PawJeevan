import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/pet/pet_model.dart';
import '../../providers/pet_provider.dart';
import '../../widgets/custom_app_bar.dart';

class AddPetScreen extends StatefulWidget {
  const AddPetScreen({super.key});

  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _weightController = TextEditingController();
  final _colorController = TextEditingController();
  final _notesController = TextEditingController();

  String _petType = 'dog';
  String _gender = 'male';
  DateTime? _dob; // NEW: Date of birth

  XFile? _pickedImage;
  bool _isSubmitting = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _weightController.dispose();
    _colorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) {
      setState(() => _pickedImage = image);
    }
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final first = DateTime(now.year - 30, now.month, now.day);
    final dt = await showDatePicker(
      context: context,
      initialDate: _dob ?? now,
      firstDate: first,
      lastDate: now,
    );
    if (dt != null) {
      setState(() => _dob = dt);
    }
  }

  String _ageText() {
    if (_dob == null) return '—';
    final today = DateTime.now();
    int years = today.year - _dob!.year;
    if (today.month < _dob!.month || (today.month == _dob!.month && today.day < _dob!.day)) {
      years -= 1;
    }
    return '$years years';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final pet = PetModel(
      name: _nameController.text.trim(),
      petType: _petType,
      breed: _breedController.text.trim(),
      gender: _gender,
      dateOfBirth: _dob, // send DOB to backend
      weight: double.tryParse(_weightController.text.trim()) ?? 0.0,
      color: _colorController.text.trim().isEmpty ? null : _colorController.text.trim(),
      medicalNotes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    try {
      final petProvider = Provider.of<PetProvider>(context, listen: false);
      bool ok;
      // Always use multipart form data
      if (_pickedImage != null) {
        if (kIsWeb) {
          final bytes = await _pickedImage!.readAsBytes();
          ok = await petProvider.addPetWithImage(
            pet,
            imageBytes: bytes,
            fileName: _pickedImage!.name,
          );
        } else {
          ok = await petProvider.addPetWithImage(
            pet,
            imagePath: _pickedImage!.path,
          );
        }
      } else {
        // Even without image, use multipart to match Django's expected format
        ok = await petProvider.addPetWithImage(pet);
      }

      if (!mounted) return;

      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pet added successfully!')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(petProvider.error ?? 'Failed to add pet')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? picked;
    if (_pickedImage != null) {
      picked = kIsWeb ? NetworkImage(_pickedImage!.path) : FileImage(File(_pickedImage!.path)) as ImageProvider;
    }

    return Scaffold(
      appBar: const CustomAppBar(title: 'Add Pet', showBackButton: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Image Picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.purple.shade100),
                    image: picked != null
                        ? DecorationImage(image: picked, fit: BoxFit.cover)
                        : null,
                  ),
                  child: picked == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo, color: Colors.purple),
                            SizedBox(height: 8),
                            Text('Tap to add photo'),
                          ],
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),

              // Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Pet Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.pets),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter pet name' : null,
              ),
              const SizedBox(height: 12),

              // Species & Gender
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _petType,
                      items: const [
                        DropdownMenuItem(value: 'dog', child: Text('Dog')),
                        DropdownMenuItem(value: 'cat', child: Text('Cat')),
                        DropdownMenuItem(value: 'bird', child: Text('Bird')),
                        DropdownMenuItem(value: 'fish', child: Text('Fish')),
                        DropdownMenuItem(value: 'rabbit', child: Text('Rabbit')),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (v) => setState(() => _petType = v ?? 'dog'),
                      decoration: const InputDecoration(
                        labelText: 'Species',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _gender,
                      items: const [
                        DropdownMenuItem(value: 'male', child: Text('Male')),
                        DropdownMenuItem(value: 'female', child: Text('Female')),
                      ],
                      onChanged: (v) => setState(() => _gender = v ?? 'male'),
                      decoration: const InputDecoration(
                        labelText: 'Gender',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.male),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Breed
              TextFormField(
                controller: _breedController,
                decoration: const InputDecoration(
                  labelText: 'Breed',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label),
                ),
              ),
              const SizedBox(height: 12),

              // DOB + Age display
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickDob,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date of Birth (recommended)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.event),
                        ),
                        child: Text(
                          _dob != null ? _fmtDate(_dob!) : 'Tap to select',
                          style: TextStyle(color: _dob == null ? Colors.grey[600] : Colors.black87),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Age (auto)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.cake),
                      ),
                      child: Text(_ageText()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Weight
              TextFormField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.monitor_weight),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  final val = double.tryParse(v);
                  if (val == null || val < 0) return 'Invalid weight';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Color
              TextFormField(
                controller: _colorController,
                decoration: const InputDecoration(
                  labelText: 'Color (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.color_lens),
                ),
              ),
              const SizedBox(height: 12),

              // Notes
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Medical Notes (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note_alt),
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isSubmitting ? 'Saving...' : 'Save Pet'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) => d.toIso8601String().split('T')[0];
}