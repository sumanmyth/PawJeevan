import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/ai/disease_detection_model.dart';
import '../../models/pet/pet_model.dart';
import '../../services/ai_service.dart';
import '../../services/pet_service.dart';
import '../../widgets/custom_app_bar.dart';

class DiseaseDetectionScreen extends StatefulWidget {
  const DiseaseDetectionScreen({super.key});

  @override
  State<DiseaseDetectionScreen> createState() => _DiseaseDetectionScreenState();
}

class _DiseaseDetectionScreenState extends State<DiseaseDetectionScreen> {
  final AIService _aiService = AIService();
  final PetService _petService = PetService();
  final ImagePicker _picker = ImagePicker();

  // State
  List<int>? _imageBytes;
  DiseaseDetectionResult? _result;
  bool _isLoading = false;
  String? _error;

  // Form fields
  String _diseaseType = 'general';
  PetModel? _selectedPet;
  List<PetModel> _pets = [];
  bool _petsLoading = true;
  final _symptomsController = TextEditingController();

  // History
  List<DiseaseDetectionResult> _history = [];
  bool _historyLoading = true;

  final List<Map<String, dynamic>> _diseaseTypes = [
    {'value': 'general', 'label': 'General Health', 'icon': Icons.health_and_safety},
    {'value': 'skin', 'label': 'Skin/Coat', 'icon': Icons.texture},
    {'value': 'eye', 'label': 'Eye Issue', 'icon': Icons.visibility},
    {'value': 'ear', 'label': 'Ear Problem', 'icon': Icons.hearing},
    {'value': 'dental', 'label': 'Dental/Mouth', 'icon': Icons.mood},
  ];

  @override
  void initState() {
    super.initState();
    _loadPets();
    _loadHistory();
  }

  @override
  void dispose() {
    _symptomsController.dispose();
    super.dispose();
  }

  Future<void> _loadPets() async {
    try {
      final pets = await _petService.getPets();
      if (mounted) {
        setState(() {
          _pets = pets;
          _petsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _petsLoading = false);
    }
  }

  Future<void> _loadHistory() async {
    setState(() => _historyLoading = true);
    try {
      final history = await _aiService.getDiseaseHistory();
      if (mounted) setState(() => _history = history);
    } catch (_) {}
    if (mounted) setState(() => _historyLoading = false);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _result = null;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _analyzeImage() async {
    if (_imageBytes == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });

    try {
      final result = await _aiService.detectDiseaseFromBytes(
        imageBytes: _imageBytes!,
        diseaseType: _diseaseType,
        petId: _selectedPet?.id,
        symptoms: _symptomsController.text.trim(),
      );
      if (mounted) {
        setState(() => _result = result);
        _loadHistory();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteHistoryItem(DiseaseDetectionResult item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Detection'),
        content: const Text('Are you sure you want to delete this detection?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && item.id != null) {
      try {
        await _aiService.deleteDiseaseDetection(item.id!);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    const accent = Color(0xFF7C3AED);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: const CustomAppBar(
        title: 'Disease Detection',
        showBackButton: true,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
          left: 16,
          right: 16,
          bottom: 32,
        ),
        children: [
          _buildImageSection(theme, cs, accent),
          const SizedBox(height: 16),
          _buildOptionsSection(theme, cs, accent),
          const SizedBox(height: 20),
          _buildAnalyzeButton(accent),
          if (_isLoading) ...[
            const SizedBox(height: 24),
            _buildLoadingIndicator(cs),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            _buildErrorCard(cs),
          ],
          if (_result != null) ...[
            const SizedBox(height: 24),
            _buildResultCard(theme, cs, accent),
          ],
          const SizedBox(height: 32),
          _buildHistorySection(theme, cs, accent),
        ],
      ),
    );
  }

  Widget _buildImageSection(ThemeData theme, ColorScheme cs, Color accent) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant),
      ),
      color: cs.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_imageBytes != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  Uint8List.fromList(_imageBytes!),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: Icon(Icons.camera_alt, color: accent),
                    label: const Text('Camera'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: accent,
                      side: BorderSide(color: accent),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: Icon(Icons.photo_library, color: accent),
                    label: const Text('Gallery'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: accent,
                      side: BorderSide(color: accent),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsSection(ThemeData theme, ColorScheme cs, Color accent) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant),
      ),
      color: cs.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Analysis Options',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            // Disease type selector
            Text('Area of Concern', style: TextStyle(color: cs.onSurfaceVariant)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _diseaseTypes.map((t) {
                final isSelected = _diseaseType == t['value'];
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(t['icon'] as IconData,
                          size: 16,
                          color: isSelected ? Colors.white : cs.onSurface),
                      const SizedBox(width: 4),
                      Text(t['label'] as String),
                    ],
                  ),
                  selected: isSelected,
                  selectedColor: accent,
                  onSelected: (_) => setState(() => _diseaseType = t['value']),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Pet selector
            if (!_petsLoading && _pets.isNotEmpty) ...[
              Text('Select Pet (optional)',
                  style: TextStyle(color: cs.onSurfaceVariant)),
              const SizedBox(height: 8),
              DropdownButtonFormField<PetModel?>(
                value: _selectedPet,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('No pet selected')),
                  ..._pets.map((pet) => DropdownMenuItem(
                        value: pet,
                        child: Text('${pet.name} (${pet.breed})'),
                      )),
                ],
                onChanged: (pet) => setState(() => _selectedPet = pet),
              ),
              const SizedBox(height: 16),
            ],
            // Symptoms
            Text('Describe Symptoms (optional)',
                style: TextStyle(color: cs.onSurfaceVariant)),
            const SizedBox(height: 8),
            TextField(
              controller: _symptomsController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'E.g., scratching, redness, discharge...',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyzeButton(Color accent) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _imageBytes == null || _isLoading ? null : _analyzeImage,
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: accent.withOpacity(0.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        icon: const Icon(Icons.search),
        label: const Text('Analyze Image',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildLoadingIndicator(ColorScheme cs) {
    return Column(
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 12),
        Text('Analyzing with AI...',
            style: TextStyle(color: cs.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildErrorCard(ColorScheme cs) {
    return Card(
      elevation: 0,
      color: cs.errorContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: cs.error),
            const SizedBox(width: 12),
            Expanded(
                child:
                    Text(_error!, style: TextStyle(color: cs.onErrorContainer))),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(ThemeData theme, ColorScheme cs, Color accent) {
    final r = _result!;
    final severityColor = {
      'low': Colors.green,
      'medium': Colors.orange,
      'high': Colors.red,
      'critical': Colors.red.shade900,
    }[r.severity.toLowerCase()] ?? Colors.grey;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: cs.surface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: severityColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.medical_services, color: severityColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.detectedDisease,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      Text(r.diseaseTypeLabel,
                          style: TextStyle(
                              fontSize: 13, color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: severityColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    r.severityLabel,
                    style: TextStyle(
                        color: severityColor, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Confidence
            Row(
              children: [
                Text('Confidence: ',
                    style: TextStyle(color: cs.onSurfaceVariant)),
                Text(r.confidencePercent,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 16),
                if (r.aiPowered) ...[
                  Icon(Icons.auto_awesome, size: 16, color: accent),
                  const SizedBox(width: 4),
                  Text('AI Powered',
                      style: TextStyle(fontSize: 12, color: accent)),
                ],
              ],
            ),
            const SizedBox(height: 16),
            // Recommendations
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.tips_and_updates,
                          size: 18, color: cs.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Text('Recommendations',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(r.recommendations,
                      style: TextStyle(
                          height: 1.5, color: cs.onSurfaceVariant)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Vet recommendation
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: r.shouldSeeVet
                    ? Colors.orange.withOpacity(0.12)
                    : Colors.green.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    r.shouldSeeVet ? Icons.local_hospital : Icons.check_circle,
                    color: r.shouldSeeVet ? Colors.orange : Colors.green,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      r.shouldSeeVet
                          ? 'We recommend consulting a veterinarian'
                          : 'No immediate vet visit required, but monitor closely',
                      style: TextStyle(
                        color: r.shouldSeeVet ? Colors.orange.shade900 : Colors.green.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Disclaimer
            const SizedBox(height: 16),
            Text(
              '⚠️ This is AI-assisted analysis and not a substitute for professional veterinary care.',
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection(ThemeData theme, ColorScheme cs, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history, color: accent, size: 20),
            const SizedBox(width: 8),
            Text('Detection History',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        if (_historyLoading)
          const Center(
              child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(strokeWidth: 2),
          ))
        else if (_history.isEmpty)
          Card(
            elevation: 0,
            color: cs.surfaceContainerHighest,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text('No detections yet.',
                    style: TextStyle(color: cs.onSurfaceVariant)),
              ),
            ),
          )
        else
          ...(_history.map((h) => _buildHistoryItem(h, theme, cs, accent))),
      ],
    );
  }

  Widget _buildHistoryItem(DiseaseDetectionResult h, ThemeData theme,
      ColorScheme cs, Color accent) {
    final date = h.createdAt != null
        ? '${h.createdAt!.day}/${h.createdAt!.month}/${h.createdAt!.year}'
        : '';
    final severityColor = {
      'low': Colors.green,
      'medium': Colors.orange,
      'high': Colors.red,
    }[h.severity.toLowerCase()] ?? Colors.grey;

    return Dismissible(
      key: ValueKey(h.id ?? h.hashCode),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        await _deleteHistoryItem(h);
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: cs.outlineVariant),
        ),
        color: cs.surface,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Thumbnail
              if (h.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    h.imageUrl!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 48,
                      height: 48,
                      color: cs.surfaceContainerHighest,
                      child: Icon(Icons.medical_services,
                          color: cs.onSurfaceVariant),
                    ),
                  ),
                )
              else
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: severityColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.medical_services, color: severityColor),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(h.detectedDisease,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(h.diseaseTypeLabel,
                        style: TextStyle(
                            fontSize: 12, color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: severityColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(h.severityLabel,
                        style: TextStyle(
                            fontSize: 11,
                            color: severityColor,
                            fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 4),
                  Text(date,
                      style:
                          TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
