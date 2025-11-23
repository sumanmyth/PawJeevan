import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/app_dropdown_field.dart';
import '../../../widgets/loading_overlay.dart';
import '../../../widgets/app_form_card.dart';
import '../../../utils/constants.dart';
import '../../../models/community/event_model.dart';
import '../../../utils/helpers.dart';

class EditEventScreen extends StatefulWidget {
  final Event event;

  const EditEventScreen({super.key, required this.event});

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late final TextEditingController _addressController;
  late final TextEditingController _maxAttendeesController;
  
  late String _selectedType;
  late DateTime _startDateTime;
  late DateTime _endDateTime;
  XFile? _coverImage;
  Uint8List? _imageBytes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize with existing event data
    _titleController = TextEditingController(text: widget.event.title);
    _descriptionController = TextEditingController(text: widget.event.description);
    _locationController = TextEditingController(text: widget.event.location);
    _addressController = TextEditingController(text: widget.event.address);
    _maxAttendeesController = TextEditingController(
      text: widget.event.maxAttendees?.toString() ?? ''
    );
    _selectedType = widget.event.eventType;
    _startDateTime = widget.event.startDatetime;
    _endDateTime = widget.event.endDatetime;
  }

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
    final date = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDateTime : _endDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(isStart ? _startDateTime : _endDateTime),
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
            if (_endDateTime.isBefore(dateTime)) {
              _endDateTime = dateTime.add(const Duration(hours: 2));
            }
          } else {
            _endDateTime = dateTime;
          }
        });
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _updateEvent() async {
    if (!_formKey.currentState!.validate()) return;

    if (_endDateTime.isBefore(_startDateTime)) {
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
        'start_datetime': _startDateTime.toIso8601String(),
        'end_datetime': _endDateTime.toIso8601String(),
      });

      // Add max attendees if specified
      if (_maxAttendeesController.text.trim().isNotEmpty) {
        final maxAttendees = int.tryParse(_maxAttendeesController.text.trim());
        if (maxAttendees != null && maxAttendees > 0) {
          formData.fields.add(MapEntry('max_attendees', maxAttendees.toString()));
        }
      }

      // Add cover image if a new one was selected
      if (_coverImage != null) {
        final bytes = await _coverImage!.readAsBytes();
        formData.files.add(MapEntry(
          'cover_image',
          MultipartFile.fromBytes(
            bytes,
            filename: _coverImage!.name,
          ),
        ));
      }

      await dio.patch(
        '${ApiConstants.baseUrl}${ApiConstants.events}${widget.event.id}/',
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (mounted) {
        Helpers.showInstantSnackBar(
          context,
          const SnackBar(content: Text('Event updated successfully!')),
        );
        // Wait a bit for the snackbar to show before popping
        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Error updating event';
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
        title: 'Edit Event',
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
                          : (widget.event.coverImage != null && widget.event.coverImage!.isNotEmpty)
                              ? DecorationImage(
                                  image: NetworkImage(widget.event.coverImage!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                    ),
                    child: _imageBytes == null && (widget.event.coverImage == null || widget.event.coverImage!.isEmpty)
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
                                style: TextStyle(color: Color(0xFF7C3AED)),
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
                    child: Text(_formatDateTime(_startDateTime)),
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
                    child: Text(_formatDateTime(_endDateTime)),
                  ),
                ),
                const SizedBox(height: 16),

                // Location Name
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location Name *',
                    hintText: 'e.g., Central Park',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
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

                // Update Button
                ElevatedButton(
                  onPressed: _updateEvent,
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                    ),
                  child: const Text(
                    'Update Event',
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
