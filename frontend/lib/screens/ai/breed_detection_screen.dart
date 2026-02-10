import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/ai/breed_detection_model.dart';
import '../../services/ai_service.dart';
import '../../widgets/custom_app_bar.dart';

class BreedDetectionScreen extends StatefulWidget {
  const BreedDetectionScreen({super.key});

  @override
  State<BreedDetectionScreen> createState() => _BreedDetectionScreenState();
}

class _BreedDetectionScreenState extends State<BreedDetectionScreen> {
  final AIService _aiService = AIService();
  final ImagePicker _picker = ImagePicker();

  XFile? _selectedImage;
  List<int>? _imageBytes;
  BreedDetectionResult? _result;
  bool _isLoading = false;
  String? _error;

  // History
  List<BreedDetectionResult> _history = [];
  bool _historyLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _historyLoading = true);
    try {
      final history = await _aiService.getBreedDetectionHistory();
      if (mounted) {
        setState(() {
          _history = history.where((h) => h.isSuccessful).toList();
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _historyLoading = false);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        // Always read bytes for consistent display on all platforms
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImage = image;
          _imageBytes = bytes;
          _result = null;
          _error = null;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to pick image: $e';
      });
    }
  }

  Future<void> _detectBreed() async {
    if (_selectedImage == null) {
      setState(() {
        _error = 'Please select an image first';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });

    try {
      BreedDetectionResult result;
      if (kIsWeb && _imageBytes != null) {
        result = await _aiService.detectBreedFromBytes(
          imageBytes: _imageBytes!,
          fileName: _selectedImage!.name,
        );
      } else {
        result = await _aiService.detectBreed(imageFile: _selectedImage!);
      }
      setState(() {
        _result = result;
      });
      // Refresh history after new detection
      _loadHistory();
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _reset() {
    setState(() {
      _selectedImage = null;
      _imageBytes = null;
      _result = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'AI Breed Detection',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(
                      Icons.pets,
                      size: 48,
                      color: Color(0xFF7C3AED),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Dog Breed Detector',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Upload a photo of a dog to identify its breed using AI',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Image preview
            if (_selectedImage != null) ...[
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: _imageBytes != null
                          ? Image.memory(
                              Uint8List.fromList(_imageBytes!),
                              fit: BoxFit.cover,
                            )
                          : const Center(child: CircularProgressIndicator()),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton.icon(
                            onPressed: _reset,
                            icon: const Icon(Icons.close),
                            label: const Text('Clear'),
                          ),
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _detectBreed,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.search),
                            label: Text(
                                _isLoading ? 'Analyzing...' : 'Detect Breed'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Image picker buttons
            if (_selectedImage == null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate,
                                size: 48,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Select an image',
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _pickImage(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Gallery'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF7C3AED),
                                side: const BorderSide(color: Color(0xFF7C3AED)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _pickImage(ImageSource.camera),
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Camera'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            // Error message
            if (_error != null) ...[
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Theme.of(context).colorScheme.error),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Results
            if (_result != null) ...[
              _buildResultCard(),
              const SizedBox(height: 16),
              if (_result!.alternativeBreeds.isNotEmpty)
                _buildAlternativesCard(),
            ],

            // Detection History
            const SizedBox(height: 24),
            _buildHistorySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(
              'Detection History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            if (_history.isNotEmpty)
              TextButton(
                onPressed: _loadHistory,
                child: const Text('Refresh'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_historyLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_history.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.pets, size: 40, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
                    const SizedBox(height: 8),
                    Text(
                      'No detections yet',
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Upload a photo to detect a breed!',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...(_history.map((item) => _buildHistoryItem(item, isDark))),
      ],
    );
  }

  Future<void> _deleteHistoryItem(BreedDetectionResult item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Detection'),
        content: const Text('Are you sure you want to delete this breed detection?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && item.id != null) {
      try {
        await _aiService.deleteBreedDetection(item.id!);
        setState(() => _history.removeWhere((h) => h.id == item.id));
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete')),
          );
        }
      }
    }
  }

  Widget _buildHistoryItem(BreedDetectionResult item, bool isDark) {
    final theme = Theme.of(context);
    return Dismissible(
      key: ValueKey(item.id ?? item.hashCode),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        await _deleteHistoryItem(item);
        return false; // we handle removal ourselves
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _showHistoryDetail(item),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: item.imageUrl != null
                    ? Image.network(
                        item.imageUrl!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 56,
                          height: 56,
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: Icon(Icons.pets, color: theme.colorScheme.onSurfaceVariant),
                        ),
                      )
                    : Container(
                        width: 56,
                        height: 56,
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Icon(Icons.pets, color: theme.colorScheme.onSurfaceVariant),
                      ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.formattedBreed,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.createdAt != null
                          ? _formatDate(item.createdAt!)
                          : '',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Confidence badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.confidencePercent,
                  style: TextStyle(
                    color: isDark ? const Color(0xFFB794F4) : const Color(0xFF7C3AED),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  void _showHistoryDetail(BreedDetectionResult item) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            if (item.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  item.imageUrl!,
                  height: 250,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 250,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Center(child: Icon(Icons.broken_image, size: 48)),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              item.formattedBreed,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Confidence', item.confidencePercent),
            if (item.processingTime != null)
              _buildDetailRow('Processing Time', '${item.processingTime!.toStringAsFixed(2)}s'),
            _buildDetailRow('Model', item.modelVersion),
            if (item.createdAt != null)
              _buildDetailRow('Date', _formatDate(item.createdAt!)),
            if (item.alternativeBreeds.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Alternative Breeds',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              ...item.alternativeBreeds.map((alt) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Expanded(child: Text(alt.formattedBreed)),
                        Text(
                          alt.confidencePercent,
                          style: TextStyle(
                            color: theme.brightness == Brightness.dark
                                ? const Color(0xFFB794F4)
                                : const Color(0xFF7C3AED),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final h = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final ampm = date.hour >= 12 ? 'PM' : 'AM';
    return '${months[date.month - 1]} ${date.day}, ${date.year} at $h:${date.minute.toString().padLeft(2, '0')} $ampm';
  }

  Widget _buildResultCard() {
    final result = _result!;
    final isSuccess = result.isSuccessful;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      color: isSuccess
          ? (isDark ? const Color(0xFF1B3A2D) : Colors.green[50])
          : (isDark ? const Color(0xFF3A2E1B) : Colors.orange[50]),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSuccess ? Icons.check_circle : Icons.warning,
                  color: isSuccess ? Colors.green : Colors.orange,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  isSuccess ? 'Breed Detected!' : 'Detection Result',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isSuccess
                        ? (isDark ? Colors.green[300] : Colors.green[800])
                        : (isDark ? Colors.orange[300] : Colors.orange[800]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isSuccess) ...[
              _buildResultRow('Breed', result.formattedBreed),
              _buildResultRow('Confidence', result.confidencePercent),
              if (result.isDog == true)
                _buildResultRow('Type', '🐕 Dog detected'),
              if (result.isHuman == true)
                _buildResultRow('Type', '👤 Human face (resembles breed)'),
              if (result.processingTime != null)
                _buildResultRow(
                  'Processing Time',
                  '${result.processingTime!.toStringAsFixed(2)}s',
                ),
              _buildResultRow('Model', result.modelVersion),
            ] else ...[
              Text(
                result.error ?? 'Could not detect breed in this image',
                style: TextStyle(color: isDark ? Colors.orange[300] : Colors.orange[800]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlternativesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Alternative Breeds',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...(_result!.alternativeBreeds.map((alt) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(child: Text(alt.formattedBreed)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          alt.confidencePercent,
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFFB794F4)
                                : const Color(0xFF7C3AED),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ))),
          ],
        ),
      ),
    );
  }
}
