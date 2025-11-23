import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/country_city_selector.dart';
import '../../widgets/app_form_card.dart';
import '../../utils/helpers.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController  = TextEditingController();
  final _usernameController  = TextEditingController();
  final _phoneController     = TextEditingController();
  final _bioController       = TextEditingController();
  final _locationController  = TextEditingController();

  final _picker = ImagePicker();
  XFile? _pickedImage;
  bool _isSaving = false;
  bool _avatarUploading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _usernameController.text  = user?.username ?? '';
    _firstNameController.text = user?.firstName ?? '';
    _lastNameController.text  = user?.lastName ?? '';
    _phoneController.text     = user?.phone ?? '';
    _bioController.text       = user?.bio ?? '';
    _locationController.text  = user?.location ?? '';
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (image == null) return;
      if (!mounted) return;
      setState(() => _pickedImage = image);
    } catch (e) {
      if (!mounted) return;
      Helpers.showInstantSnackBar(context, SnackBar(content: Text('Image pick error: $e')));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();

    setState(() => _isSaving = true);

    try {
      // 1) Upload avatar if picked
      if (_pickedImage != null) {
        setState(() => _avatarUploading = true);
        bool ok;
        if (kIsWeb) {
          final bytes = await _pickedImage!.readAsBytes();
          ok = await auth.updateAvatar(imageBytes: bytes, fileName: _pickedImage!.name);
        } else {
          ok = await auth.updateAvatar(imagePath: _pickedImage!.path);
        }
        if (!mounted) return;
        setState(() => _avatarUploading = false);

        if (!ok) {
          final err = auth.error ?? 'Failed to update avatar';
          Helpers.showInstantSnackBar(context, SnackBar(content: Text(err)));
          // Continue saving textual fields even if avatar fails
        }
      }

      // 2) Save textual fields (PATCH)
      final ok = await auth.updateProfile(
        username: _usernameController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phone: _phoneController.text.trim(),
        bio: _bioController.text.trim(),
        location: _locationController.text.trim(),
      );

      if (!mounted) return;

      if (ok) {
        Helpers.showInstantSnackBar(context, const SnackBar(content: Text('Profile updated successfully')));
        Navigator.pop(context, true);
      } else {
        final err = auth.error ?? 'Failed to update profile';
        Helpers.showInstantSnackBar(context, SnackBar(content: Text(err)));
      }
    } catch (e) {
      if (!mounted) return;
      Helpers.showInstantSnackBar(context, SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;

    ImageProvider? preview;
    if (_pickedImage != null) {
      preview = kIsWeb
          ? NetworkImage(_pickedImage!.path)
          : FileImage(File(_pickedImage!.path)) as ImageProvider;
    } else if (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty) {
      preview = NetworkImage(user.avatarUrl!);
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const CustomAppBar(title: 'Edit Profile', showBackButton: true),
      body: AppFormCard(
        padding: EdgeInsets.only(top: topPadding + 16, left: 16, right: 16, bottom: 16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar
              Stack(
                children: [
                  CircleAvatar(
                    radius: 56,
                    backgroundColor: const Color.fromRGBO(124, 58, 237, 0.04),
                    backgroundImage: preview,
                    child: preview == null
                        ? const Icon(Icons.person, size: 56, color: Color(0xFF7C3AED))
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: _avatarUploading ? null : _pickImage,
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _avatarUploading ? Colors.grey : Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x26000000),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: _avatarUploading
                            ? const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.camera_alt, color: Color(0xFF7C3AED)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Editable username & read-only email
              if (user != null) ...[
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Username cannot be empty';
                    if (v.trim().length < 3) return 'Username is too short';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _roField(label: 'Email', value: user.email, icon: Icons.email_outlined),
                const SizedBox(height: 12),
              ],

              // Editable fields
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationController,
                readOnly: true,
                onTap: () async {
                  final res = await showCountryCitySelector(context, initialLocation: _locationController.text);
                  if (res != null) setState(() => _locationController.text = res);
                },
                decoration: InputDecoration(
                  labelText: 'Location (optional)',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  suffixIcon: _locationController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _locationController.clear()),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bioController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Bio (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.info_outline),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
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

  Widget _roField({required String label, required String value, required IconData icon}) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
      ),
      child: Text(value),
    );
  }
}