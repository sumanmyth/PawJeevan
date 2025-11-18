import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../../widgets/custom_app_bar.dart';
import '../../../services/api_service.dart';
import '../../../widgets/loading_overlay.dart';
import '../../../models/group_model.dart';

class EditGroupScreen extends StatefulWidget {
  final Group group;
  
  const EditGroupScreen({super.key, required this.group});

  @override
  State<EditGroupScreen> createState() => _EditGroupScreenState();
}

class _EditGroupScreenState extends State<EditGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _joinKeyController;
  late String _selectedType;
  late bool _isPrivate;
  XFile? _coverImage;
  Uint8List? _imageBytes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize with existing group data
    _nameController = TextEditingController(text: widget.group.name);
    _descriptionController = TextEditingController(text: widget.group.description);
    _joinKeyController = TextEditingController(text: widget.group.joinKey ?? '');
    _selectedType = widget.group.groupType;
    _isPrivate = widget.group.isPrivate;
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

  Future<void> _updateGroup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final formData = <String, dynamic>{
        'name': _nameController.text.trim(),
        'description': _descriptionController.text,
        'group_type': _selectedType,
        'is_private': _isPrivate,
        'is_active': true,
      };

      // Join key is required for private groups
      if (_isPrivate) {
        if (_joinKeyController.text.trim().isEmpty) {
          throw Exception('Join key is required for private groups');
        }
        formData['join_key'] = _joinKeyController.text.trim();
      }

      if (_coverImage != null) {
        formData['cover_image'] = _coverImage!;
      }

      await ApiService.updateGroup(widget.group.slug, formData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group updated successfully!')),
        );
        // Wait a bit for the snackbar to show before popping
        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating group: $e')),
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
    _nameController.dispose();
    _descriptionController.dispose();
    _joinKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Edit Group',
        showBackButton: true,
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                      image: _imageBytes != null
                          ? DecorationImage(
                              image: MemoryImage(_imageBytes!),
                              fit: BoxFit.cover,
                            )
                          : (widget.group.coverImage != null && widget.group.coverImage!.isNotEmpty)
                              ? DecorationImage(
                                  image: NetworkImage(widget.group.coverImage!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                    ),
                    child: _imageBytes == null && (widget.group.coverImage == null || widget.group.coverImage!.isEmpty)
                        ? Icon(Icons.add_photo_alternate, size: 50, color: isDark ? Colors.grey[400] : Colors.grey[600])
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Group Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a group name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Group Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'breed', child: Text('Breed-Specific')),
                    DropdownMenuItem(value: 'location', child: Text('Location-Based')),
                    DropdownMenuItem(value: 'interest', child: Text('Interest-Based')),
                    DropdownMenuItem(value: 'support', child: Text('Support Group')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Private Group'),
                  subtitle: const Text('Only approved members can join and view content'),
                  value: _isPrivate,
                  onChanged: (bool value) {
                    setState(() {
                      _isPrivate = value;
                    });
                  },
                ),
                if (_isPrivate) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _joinKeyController,
                    decoration: const InputDecoration(
                      labelText: 'Join Key *',
                      hintText: 'Enter a key for users to join this private group',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (_isPrivate && (value == null || value.isEmpty)) {
                        return 'Join key is required for private groups';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _updateGroup,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Update Group',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
