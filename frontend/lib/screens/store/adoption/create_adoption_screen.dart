import 'package:flutter/material.dart';
import '../../../utils/helpers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../providers/store_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/pet/adoption_listing_model.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/app_dropdown_field.dart';
import '../../../widgets/app_form_card.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

class CreateAdoptionScreen extends StatefulWidget {
  final AdoptionListing? adoption;
  
  const CreateAdoptionScreen({super.key, this.adoption});

  @override
  State<CreateAdoptionScreen> createState() => _CreateAdoptionScreenState();
}

class _CreateAdoptionScreenState extends State<CreateAdoptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _petNameController = TextEditingController();
  final _breedController = TextEditingController();
  final _ageController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _healthStatusController = TextEditingController();
  final _vaccinationStatusController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _locationController = TextEditingController();

  String _selectedPetType = 'dog';
  String _selectedGender = 'male';
  bool _isNeutered = false;
  XFile? _selectedImage;
  bool _isSubmitting = false;

  final List<Map<String, String>> _petTypes = [
    {'value': 'dog', 'label': 'Dog'},
    {'value': 'cat', 'label': 'Cat'},
    {'value': 'bird', 'label': 'Bird'},
    {'value': 'fish', 'label': 'Fish'},
    {'value': 'rabbit', 'label': 'Rabbit'},
    {'value': 'other', 'label': 'Other'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.adoption != null) {
      _loadAdoptionData();
    }
  }

  void _loadAdoptionData() {
    final adoption = widget.adoption!;
    _titleController.text = adoption.title;
    _petNameController.text = adoption.petName;
    _breedController.text = adoption.breed;
    _ageController.text = adoption.age.toString();
    _descriptionController.text = adoption.description;
    _healthStatusController.text = adoption.healthStatus;
    _vaccinationStatusController.text = adoption.vaccinationStatus;
    _contactPhoneController.text = adoption.contactPhone;
    _contactEmailController.text = adoption.contactEmail;
    _locationController.text = adoption.location;
    _selectedPetType = adoption.petType;
    _selectedGender = adoption.gender;
    _isNeutered = adoption.isNeutered;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _petNameController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    _descriptionController.dispose();
    _healthStatusController.dispose();
    _vaccinationStatusController.dispose();
    _contactPhoneController.dispose();
    _contactEmailController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Only require image for new adoption (not when editing)
    if (_selectedImage == null && widget.adoption == null) {
      Helpers.showInstantSnackBar(
        context,
        const SnackBar(
          content: Text('Please select a photo of the pet'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final storeProvider = context.read<StoreProvider>();

      final isEditing = widget.adoption != null;

      // Create a temporary adoption listing object
      final adoption = AdoptionListing(
        id: isEditing ? widget.adoption!.id : 0,
        title: _titleController.text,
        petName: _petNameController.text,
        petType: _selectedPetType,
        breed: _breedController.text,
        age: int.parse(_ageController.text),
        gender: _selectedGender,
        description: _descriptionController.text,
        healthStatus: _healthStatusController.text,
        vaccinationStatus: _vaccinationStatusController.text,
        isNeutered: _isNeutered,
        contactPhone: _contactPhoneController.text,
        contactEmail: _contactEmailController.text,
        location: _locationController.text,
        poster: authProvider.user?.id ?? 0,
        posterUsername: authProvider.user?.username ?? '',
        status: isEditing ? widget.adoption!.status : 'available',
        createdAt: isEditing ? widget.adoption!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
      );

      bool success;
      if (isEditing) {
        success = await storeProvider.updateAdoption(adoption, _selectedImage);
      } else {
        success = await storeProvider.createAdoption(adoption, _selectedImage);
      }

      if (!mounted) return;

      if (success) {
        Helpers.showInstantSnackBar(
          context,
          SnackBar(
            content: Text(isEditing ? 'Pet updated successfully!' : 'Pet added for adoption successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        Helpers.showInstantSnackBar(
          context,
          SnackBar(
            content: Text('Failed to ${isEditing ? "update" : "add"} pet: ${storeProvider.error ?? "Unknown error"}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Helpers.showInstantSnackBar(
        context,
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.adoption != null;
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title: isEditing ? 'Edit Pet Listing' : 'Add Pet for Adoption',
        showBackButton: true,
      ),
      body: AppFormCard(
        padding: EdgeInsets.only(top: topPadding + 16, left: 16, right: 16, bottom: 16),
        maxWidth: 900,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Picker
              _buildImagePicker(),
              const SizedBox(height: 24),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Listing Title *',
                  hintText: 'e.g., "Friendly Golden Retriever Looking for Home"',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Pet Name
              TextFormField(
                controller: _petNameController,
                decoration: const InputDecoration(
                  labelText: 'Pet Name *',
                  hintText: 'e.g., "Max"',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter pet name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Pet Type
              AppDropdownFormField<String>(
                initialValue: _selectedPetType,
                decoration: const InputDecoration(
                  labelText: 'Pet Type *',
                  border: OutlineInputBorder(),
                ),
                items: _petTypes.map((type) {
                  return DropdownMenuItem(
                    value: type['value'],
                    child: Text(type['label']!),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPetType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Breed
              TextFormField(
                controller: _breedController,
                decoration: const InputDecoration(
                  labelText: 'Breed',
                  hintText: 'e.g., "Golden Retriever"',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Age and Gender
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ageController,
                      decoration: const InputDecoration(
                        labelText: 'Age (months) *',
                        hintText: 'e.g., "12"',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppDropdownFormField<String>(
                      initialValue: _selectedGender,
                      decoration: const InputDecoration(
                        labelText: 'Gender *',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'male', child: Text('Male')),
                        DropdownMenuItem(value: 'female', child: Text('Female')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  hintText: 'Describe the pet\'s personality and behavior',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Health Status
              TextFormField(
                controller: _healthStatusController,
                decoration: const InputDecoration(
                  labelText: 'Health Status *',
                  hintText: 'Current health condition',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter health status';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Vaccination Status
              TextFormField(
                controller: _vaccinationStatusController,
                decoration: const InputDecoration(
                  labelText: 'Vaccination Status *',
                  hintText: 'List of vaccinations received',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter vaccination status';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Neutered/Spayed
              SwitchListTile(
                title: const Text('Neutered/Spayed'),
                value: _isNeutered,
                onChanged: (value) {
                  setState(() {
                    _isNeutered = value;
                  });
                },
                activeThumbColor: const Color(0xFF7C3AED),
              ),
              const SizedBox(height: 16),

              // Contact Information Section
              Text(
                'Contact Information',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Contact Phone
              TextFormField(
                controller: _contactPhoneController,
                decoration: const InputDecoration(
                  labelText: 'Contact Phone *',
                  hintText: 'e.g., "+1234567890"',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter contact phone';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Contact Email
              TextFormField(
                controller: _contactEmailController,
                decoration: const InputDecoration(
                  labelText: 'Contact Email *',
                  hintText: 'e.g., "yourname@example.com"',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter contact email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Location
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location *',
                  hintText: 'e.g., "New York, NY"',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Add Pet for Adoption',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pet Photo *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickImage,
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? Colors.grey.shade800
                  : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.brightness == Brightness.dark
                    ? Colors.grey.shade700
                    : Colors.grey.shade400,
              ),
            ),
            child: _selectedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: kIsWeb
                        ? Image.network(
                            _selectedImage!.path,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      size: 48,
                                      color: theme.brightness == Brightness.dark
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade600,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Image preview unavailable',
                                      style: TextStyle(
                                        color: theme.brightness == Brightness.dark
                                            ? Colors.grey.shade400
                                            : Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          )
                        : FutureBuilder<Uint8List>(
                            future: _selectedImage!.readAsBytes(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return Image.memory(
                                  snapshot.data!,
                                  fit: BoxFit.cover,
                                );
                              }
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                          ),
                  )
                : widget.adoption?.photo != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          widget.adoption!.photo!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholder(theme);
                          },
                        ),
                      )
                    : _buildPlaceholder(theme),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate,
            size: 64,
            color: Color(0xFF7C3AED),
          ),
          SizedBox(height: 8),
          Text(
            'Tap to select a photo',
            style: TextStyle(
              color: Color(0xFF7C3AED),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
