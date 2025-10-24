import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/post_model.dart';
import '../../providers/community_provider.dart';
import '../../widgets/custom_app_bar.dart';

class EditPostScreen extends StatefulWidget {
  final Post post;
  
  const EditPostScreen({super.key, required this.post});

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final _contentController = TextEditingController();
  XFile? _pickedImage;
  bool _isUpdating = false;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _contentController.text = widget.post.content;
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image != null) setState(() => _pickedImage = image);
  }

  Future<void> _update() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write something')),
      );
      return;
    }

    setState(() => _isUpdating = true);

    try {
      final provider = context.read<CommunityProvider>();
      final ok = await provider.updatePost(
        widget.post.id,
        _contentController.text.trim(),
        imagePath: _pickedImage?.path,
      );
      if (!mounted) return;
      if (ok) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Failed to update post')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Edit Post',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _contentController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'What\'s on your mind?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isUpdating ? null : _pickImage,
              icon: const Icon(Icons.photo_library),
              label: const Text('Change Photo'),
            ),
            if (_pickedImage != null) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(_pickedImage!.path),
              ),
            ] else if (widget.post.image != null) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(widget.post.image!),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isUpdating ? null : _update,
              child: _isUpdating
                  ? const CircularProgressIndicator()
                  : const Text('Update Post'),
            ),
          ],
        ),
      ),
    );
  }
}