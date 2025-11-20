import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../providers/community_provider.dart';
import '../../../widgets/custom_app_bar.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _contentController = TextEditingController();
  XFile? _pickedImage;
  bool _isPosting = false;

  final _picker = ImagePicker();

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image != null) setState(() => _pickedImage = image);
  }

  Future<void> _post() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please write something')));
      return;
    }
    setState(() => _isPosting = true);

    try {
      final provider = context.read<CommunityProvider>();
      final ok = await provider.createPost(
        _contentController.text.trim(),
        imagePath: _pickedImage?.path,
      );
      if (!mounted) return;
      if (ok) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.error ?? 'Failed to post')));
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Create Post', showBackButton: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _contentController,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'What\'s on your mind?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            if (_pickedImage != null)
              Stack(
                children: [
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: kIsWeb
                            ? NetworkImage(_pickedImage!.path)
                            : FileImage(File(_pickedImage!.path)) as ImageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4, right: 4,
                    child: IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.white70),
                      onPressed: () => setState(() => _pickedImage = null),
                    ),
                  )
                ],
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.photo_library, color: Colors.purple),
                ),
                Expanded(child: Container()),
                ElevatedButton(
                  onPressed: _isPosting ? null : _post,
                  child: _isPosting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator())
                      : const Text('Post'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}