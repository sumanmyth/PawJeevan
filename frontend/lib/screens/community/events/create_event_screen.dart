import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../../utils/file_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/country_city_selector.dart';
import '../../../widgets/app_dropdown_field.dart';
import '../../../widgets/loading_overlay.dart';
import '../../../widgets/app_form_card.dart';
import '../../../utils/constants.dart';
import '../../../utils/helpers.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _addressController = TextEditingController();
  final _maxAttendeesController = TextEditingController();
  
  String _selectedType = 'meetup';
  DateTime? _startDateTime;
  DateTime? _endDateTime;
  XFile? _coverImage;
  Uint8List? _imageBytes;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _coverImage = pickedFile;
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _selectDateTime(bool isStart) async {
    final date = await Helpers.showBlurredDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        final dateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );

        setState(() {
          if (isStart) {
            _startDateTime = dateTime;
            // If end is before start, adjust it
            if (_endDateTime != null && _endDateTime!.isBefore(dateTime)) {
              _endDateTime = dateTime.add(const Duration(hours: 2));
            }
          } else {
            _endDateTime = dateTime;
          }
        });
      }
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Not selected';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _createEvent() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startDateTime == null || _endDateTime == null) {
      Helpers.showInstantSnackBar(
        context,
        const SnackBar(content: Text('Please select start and end date/time')),
      );
      return;
    }

    if (_endDateTime!.isBefore(_startDateTime!)) {
      Helpers.showInstantSnackBar(
        context,
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final dio = Dio();

      FormData formData = FormData.fromMap({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'event_type': _selectedType,
        'location': _locationController.text.trim(),
        'address': _addressController.text.trim(),
        'start_datetime': _startDateTime!.toIso8601String(),
        'end_datetime': _endDateTime!.toIso8601String(),
      });

      // Add max attendees if specified
      if (_maxAttendeesController.text.trim().isNotEmpty) {
        final maxAttendees = int.tryParse(_maxAttendeesController.text.trim());
        if (maxAttendees != null && maxAttendees > 0) {
          formData.fields.add(MapEntry('max_attendees', maxAttendees.toString()));
        }
      }

      // Add cover image if selected
      if (_coverImage != null) {
        final mp = await multipartFileFromXFile(_coverImage!);
        formData.files.add(MapEntry('cover_image', mp));
      }

      await dio.post(
        '${ApiConstants.baseUrl}${ApiConstants.events}',
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (mounted) {
        Navigator.pop(context, true);
        Helpers.showInstantSnackBar(
          context,
          const SnackBar(content: Text('Event created successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Error creating event';
        if (e is DioException && e.response != null) {
          final data = e.response!.data;
          if (data is Map) {
            errorMessage = data.values.first.toString();
          }
        }
        Helpers.showInstantSnackBar(
          context,
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
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    _maxAttendeesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const CustomAppBar(
        title: 'Create Event',
        showBackButton: true,
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: AppFormCard(
          padding: EdgeInsets.only(top: topPadding + 16, left: 16, right: 16, bottom: 16),
          maxWidth: 800,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cover Image Picker
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
                          : null,
                    ),
                    child: _imageBytes == null
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate,
                                size: 50,
                                color: Color(0xFF7C3AED),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Add Cover Image',
                                style: TextStyle(
                                  color: Color(0xFF7C3AED),
                                ),
                              ),
                            ],
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 24),

                // Event Title
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Event Title *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter event title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Event Type
                AppDropdownFormField<String>(
                  initialValue: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Event Type *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'meetup', child: Text('Pet Meetup')),
                    DropdownMenuItem(value: 'training', child: Text('Training Session')),
                    DropdownMenuItem(value: 'adoption', child: Text('Adoption Drive')),
                    DropdownMenuItem(value: 'fundraiser', child: Text('Fundraiser')),
                    DropdownMenuItem(value: 'competition', child: Text('Competition')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value!;
                    });
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
                    alignLabelWithHint: true,
                  ),
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter event description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Start Date & Time
                InkWell(
                  onTap: () => _selectDateTime(true),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Start Date & Time *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _formatDateTime(_startDateTime),
                      style: TextStyle(
                        color: _startDateTime == null ? Colors.grey : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // End Date & Time
                InkWell(
                  onTap: () => _selectDateTime(false),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'End Date & Time *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _formatDateTime(_endDateTime),
                      style: TextStyle(
                        color: _endDateTime == null ? Colors.grey : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Location Name (use country->city selector)
                TextFormField(
                  controller: _locationController,
                  readOnly: true,
                  onTap: () async {
                    final res = await showCountryCitySelector(context, initialLocation: _locationController.text);
                    if (res != null) setState(() => _locationController.text = res);
                  },
                  decoration: InputDecoration(
                    labelText: 'Location Name *',
                    hintText: 'e.g., Central Park',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.location_on),
                    suffixIcon: _locationController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() => _locationController.clear()),
                          )
                        : null,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter location name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Address
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address *',
                    hintText: 'Full address with city and state',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.place),
                  ),
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Max Attendees (Optional)
                TextFormField(
                  controller: _maxAttendeesController,
                  decoration: const InputDecoration(
                    labelText: 'Max Attendees (Optional)',
                    hintText: 'Leave empty for unlimited',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.people),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      final number = int.tryParse(value.trim());
                      if (number == null || number <= 0) {
                        return 'Please enter a valid number';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Create Button
                ElevatedButton(
                  onPressed: _createEvent,
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                    ),
                  child: const Text(
                    'Create Event',
                    style: TextStyle(fontSize: 16, color: Colors.white),
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
