import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/loading_overlay.dart';
import '../../../utils/constants.dart';
import '../../../models/pet/lost_found_model.dart';

class EditLostFoundScreen extends StatefulWidget {
  final LostFoundReport report;

  const EditLostFoundScreen({super.key, required this.report});

  @override
  State<EditLostFoundScreen> createState() => _EditLostFoundScreenState();
}

class _EditLostFoundScreenState extends State<EditLostFoundScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _petNameController;
  late final TextEditingController _petTypeController;
  late final TextEditingController _breedController;
  late final TextEditingController _colorController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late final TextEditingController _addressController;
  late final TextEditingController _contactPhoneController;
  
  late String _reportType;
  late DateTime _dateLostFound;
  XFile? _photo;
  Uint8List? _imageBytes;
  bool _isLoading = false;

  final List<String> _petTypes = [
    'Dog',
    'Cat',
    'Bird',
    'Rabbit',
    'Hamster',
    'Guinea Pig',
    'Fish',
    'Reptile',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    // Initialize with existing report data
    _petNameController = TextEditingController(text: widget.report.petName ?? '');
    _petTypeController = TextEditingController(text: widget.report.petType);
    _breedController = TextEditingController(text: widget.report.breed ?? '');
    _colorController = TextEditingController(text: widget.report.color);
    _descriptionController = TextEditingController(text: widget.report.description);
    _locationController = TextEditingController(text: widget.report.location);
    _addressController = TextEditingController(text: widget.report.address);
    _contactPhoneController = TextEditingController(text: widget.report.contactPhone);
    _reportType = widget.report.reportType;
    _dateLostFound = widget.report.dateLostFound;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _photo = pickedFile;
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateLostFound,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        _dateLostFound = date;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _updateReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final dio = Dio();

      FormData formData = FormData.fromMap({
        'report_type': _reportType,
        'pet_type': _petTypeController.text.trim(),
        'color': _colorController.text.trim(),
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'address': _addressController.text.trim(),
        'date_lost_found': _dateLostFound.toIso8601String().split('T')[0],
        'contact_phone': _contactPhoneController.text.trim(),
      });

      // Add optional fields
      if (_petNameController.text.trim().isNotEmpty) {
        formData.fields.add(MapEntry('pet_name', _petNameController.text.trim()));
      }
      if (_breedController.text.trim().isNotEmpty) {
        formData.fields.add(MapEntry('breed', _breedController.text.trim()));
      }

      // Add photo if a new one was selected
      if (_photo != null) {
        final bytes = await _photo!.readAsBytes();
        formData.files.add(MapEntry(
          'photo',
          MultipartFile.fromBytes(
            bytes,
            filename: _photo!.name,
          ),
        ));
      }

      await dio.patch(
        '${ApiConstants.baseUrl}${ApiConstants.lostFound}${widget.report.id}/',
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report updated successfully!')),
        );
        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Error updating report';
        if (e is DioException && e.response != null) {
          final data = e.response!.data;
          if (data is Map) {
            errorMessage = data.values.first.toString();
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _petNameController.dispose();
    _petTypeController.dispose();
    _breedController.dispose();
    _colorController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const CustomAppBar(
        title: 'Edit Report',
        showBackButton: true,
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(parent: const AlwaysScrollableScrollPhysics()),
          padding: EdgeInsets.only(top: topPadding + 16, left: 16, right: 16, bottom: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Report Type Display (non-editable)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _reportType == 'lost' 
                        ? Colors.red.withOpacity(0.1) 
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _reportType == 'lost' ? Colors.red : Colors.green,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _reportType == 'lost' ? Icons.search : Icons.favorite,
                        color: _reportType == 'lost' ? Colors.red : Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _reportType == 'lost' ? 'Lost Pet Report' : 'Found Pet Report',
                        style: TextStyle(
                          color: _reportType == 'lost' ? Colors.red : Colors.green,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Photo Picker
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      image: _imageBytes != null
                          ? DecorationImage(
                              image: MemoryImage(_imageBytes!),
                              fit: BoxFit.cover,
                            )
                          : (widget.report.photo != null && widget.report.photo!.isNotEmpty)
                              ? DecorationImage(
                                  image: NetworkImage(widget.report.photo!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                    ),
                    child: _imageBytes == null && (widget.report.photo == null || widget.report.photo!.isEmpty)
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate, 
                                size: 50, 
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add Photo',
                                style: TextStyle(
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                            ],
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 24),

                // Pet Name (Optional)
                TextFormField(
                  controller: _petNameController,
                  decoration: const InputDecoration(
                    labelText: 'Pet Name (if known)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge),
                  ),
                ),
                const SizedBox(height: 16),

                // Pet Type
                DropdownButtonFormField<String>(
                  initialValue: _petTypeController.text.isEmpty ? null : _petTypeController.text,
                  decoration: const InputDecoration(
                    labelText: 'Pet Type *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.pets),
                  ),
                  items: _petTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      _petTypeController.text = value;
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select pet type';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Breed (Optional)
                TextFormField(
                  controller: _breedController,
                  decoration: const InputDecoration(
                    labelText: 'Breed (if known)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                ),
                const SizedBox(height: 16),

                // Color
                TextFormField(
                  controller: _colorController,
                  decoration: const InputDecoration(
                    labelText: 'Color *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.palette),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter color';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Date Lost/Found
                InkWell(
                  onTap: _selectDate,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Date ${_reportType == 'lost' ? 'Lost' : 'Found'} *',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.calendar_today),
                    ),
                    child: Text(_formatDate(_dateLostFound)),
                  ),
                ),
                const SizedBox(height: 16),

                // Location
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                    hintText: 'e.g., Central Park',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter location';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Address
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Detailed Address *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.home),
                    hintText: 'e.g., Near entrance, by the fountain',
                  ),
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter detailed address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                    hintText: 'Describe the pet, any distinguishing features, etc.',
                  ),
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Contact Phone
                TextFormField(
                  controller: _contactPhoneController,
                  decoration: const InputDecoration(
                    labelText: 'Contact Phone *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                    hintText: 'e.g., +1234567890',
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter contact phone';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Update Button
                ElevatedButton(
                  onPressed: _updateReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Update Report',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
