import 'package:flutter/material.dart';

import '../../models/ai/diet_recommendation_model.dart';
import '../../models/pet/pet_model.dart';
import '../../services/ai_service.dart';
import '../../services/pet_service.dart';
import '../../widgets/custom_app_bar.dart';

class DietRecommendationScreen extends StatefulWidget {
  const DietRecommendationScreen({super.key});

  @override
  State<DietRecommendationScreen> createState() =>
      _DietRecommendationScreenState();
}

class _DietRecommendationScreenState extends State<DietRecommendationScreen> {
  final AIService _aiService = AIService();
  final PetService _petService = PetService();

  // State
  List<PetModel> _pets = [];
  PetModel? _selectedPet;
  bool _petsLoading = true;
  bool _isLoading = false;
  String? _error;

  DietRecommendationResult? _result;

  // Optional user inputs
  final _allergiesCtrl = TextEditingController();
  final _healthCtrl = TextEditingController();
  final _specialCtrl = TextEditingController();

  // History
  List<DietRecommendationResult> _history = [];
  bool _historyLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPets();
    _loadHistory();
  }

  @override
  void dispose() {
    _allergiesCtrl.dispose();
    _healthCtrl.dispose();
    _specialCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPets() async {
    try {
      final pets = await _petService.getPets();
      if (mounted) {
        setState(() {
          _pets = pets;
          if (pets.isNotEmpty) _selectedPet = pets.first;
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
      final history = await _aiService.getDietHistory();
      if (mounted) setState(() => _history = history);
    } catch (_) {}
    if (mounted) setState(() => _historyLoading = false);
  }

  Future<void> _generateRecommendation() async {
    if (_selectedPet == null) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });

    try {
      final result = await _aiService.getDietRecommendation(
        petId: _selectedPet!.id!,
        allergies: _allergiesCtrl.text.trim(),
        healthConditions: _healthCtrl.text.trim(),
        specialConsiderations: _specialCtrl.text.trim(),
      );
      if (mounted) setState(() => _result = result);
      _loadHistory(); // refresh history
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    const accent = Color(0xFF7C3AED);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: const CustomAppBar(title: 'Diet Recommendations', showBackButton: true),
      body: _petsLoading
          ? const Center(child: CircularProgressIndicator())
          : _pets.isEmpty
              ? _buildNoPets(cs)
              : ListView(
                  physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics()),
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
                    left: 16,
                    right: 16,
                    bottom: 32,
                  ),
                  children: [
                    _buildPetSelector(theme, cs, accent),
                    if (_selectedPet != null) ...[
                      const SizedBox(height: 16),
                      _buildPetInfo(theme, cs),
                      const SizedBox(height: 16),
                      _buildOptionalInputs(theme, cs),
                      const SizedBox(height: 20),
                      _buildGenerateButton(accent),
                    ],
                    if (_isLoading) ...[
                      const SizedBox(height: 24),
                      _buildLoadingIndicator(cs),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      _buildErrorCard(theme, cs),
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

  // ─── No Pets ──────────────────────────────────────────────────────────

  Widget _buildNoPets(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pets, size: 64, color: cs.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'No pets found',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              'Add a pet in your profile first to get personalised diet recommendations.',
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Pet Selector ─────────────────────────────────────────────────────

  Widget _buildPetSelector(ThemeData theme, ColorScheme cs, Color accent) {
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
            Row(
              children: [
                Icon(Icons.pets, color: accent, size: 20),
                const SizedBox(width: 8),
                Text('Select Pet',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<PetModel>(
              initialValue: _selectedPet,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: _pets.map((pet) {
                return DropdownMenuItem(
                  value: pet,
                  child: Text('${pet.name} (${pet.breed})'),
                );
              }).toList(),
              onChanged: (pet) => setState(() {
                _selectedPet = pet;
                _result = null;
                _error = null;
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Pet Info (auto-filled) ───────────────────────────────────────────

  Widget _buildPetInfo(ThemeData theme, ColorScheme cs) {
    final pet = _selectedPet!;
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
            Text('Pet Details (auto-filled)',
                style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant)),
            const SizedBox(height: 12),
            _infoRow(Icons.pets, 'Breed', pet.breed, cs),
            _infoRow(Icons.cake, 'Age',
                pet.age != null ? '${pet.age} years' : 'Unknown', cs),
            _infoRow(Icons.monitor_weight, 'Weight', '${pet.weight} kg', cs),
            _infoRow(Icons.category, 'Type', pet.petType, cs),
            if (pet.gender.isNotEmpty)
              _infoRow(
                  pet.gender.toLowerCase() == 'male'
                      ? Icons.male
                      : Icons.female,
                  'Gender',
                  pet.gender,
                  cs),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Text('$label: ',
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: cs.onSurface)),
          Expanded(
            child: Text(value,
                style: TextStyle(color: cs.onSurfaceVariant),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  // ─── Optional Inputs ─────────────────────────────────────────────────

  Widget _buildOptionalInputs(ThemeData theme, ColorScheme cs) {
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
            Text('Additional Info (optional)',
                style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant)),
            const SizedBox(height: 12),
            _inputField(_allergiesCtrl, 'Known Allergies',
                Icons.warning_amber_rounded, cs),
            const SizedBox(height: 10),
            _inputField(
                _healthCtrl, 'Health Conditions', Icons.local_hospital, cs),
            const SizedBox(height: 10),
            _inputField(
                _specialCtrl, 'Special Considerations', Icons.note, cs),
          ],
        ),
      ),
    );
  }

  Widget _inputField(TextEditingController ctrl, String hint, IconData icon,
      ColorScheme cs) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  // ─── Generate Button ──────────────────────────────────────────────────

  Widget _buildGenerateButton(Color accent) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _generateRecommendation,
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        icon: const Icon(Icons.restaurant_menu),
        label: const Text('Get Diet Recommendation',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // ─── Loading ──────────────────────────────────────────────────────────

  Widget _buildLoadingIndicator(ColorScheme cs) {
    return Column(
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 12),
        Text('Generating personalised diet plan…',
            style: TextStyle(color: cs.onSurfaceVariant)),
      ],
    );
  }

  // ─── Error ────────────────────────────────────────────────────────────

  Widget _buildErrorCard(ThemeData theme, ColorScheme cs) {
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
              child: Text(_error!,
                  style: TextStyle(color: cs.onErrorContainer)),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Result Card ──────────────────────────────────────────────────────

  Widget _buildResultCard(ThemeData theme, ColorScheme cs, Color accent,
      [DietRecommendationResult? override]) {
    final r = override ?? _result!;
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
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.restaurant, color: accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Diet Plan',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      Text(
                        r.breedSpecificAvailable
                            ? 'Breed-specific recommendation'
                            : 'General recommendation',
                        style: TextStyle(
                            fontSize: 13, color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Quick stats
            Row(
              children: [
                _statChip('🔥 ${r.dailyCalories} kcal', cs),
                const SizedBox(width: 8),
                _statChip('🍽️ ${r.feedingFrequency}', cs),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (r.sizeCategory != null)
                  _statChip('📏 ${r.sizeCategoryLabel}', cs),
                const SizedBox(width: 8),
                _statChip('🎂 ${r.lifeStageLabel}', cs),
                const SizedBox(width: 8),
                _statChip('⚖️ ${r.weightStatusLabel}', cs),
              ],
            ),
            const SizedBox(height: 16),

            // Recommended foods
            if (r.foodTypes.isNotEmpty) ...[
              Text('Recommended Foods',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: r.foodTypes
                    .map((f) => Chip(
                          label: Text(f, style: const TextStyle(fontSize: 12)),
                          backgroundColor: Colors.green.withOpacity(0.12),
                          side: BorderSide.none,
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Foods to avoid
            if (r.foodsToAvoid.isNotEmpty) ...[
              Text('Foods to Avoid',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: r.foodsToAvoid
                    .take(10)
                    .map((f) => Chip(
                          label: Text(f, style: const TextStyle(fontSize: 12)),
                          backgroundColor: cs.errorContainer.withOpacity(0.6),
                          side: BorderSide.none,
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Supplements
            if (r.supplements.isNotEmpty) ...[
              Text('Recommended Supplements',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: r.supplements
                    .map((s) => Chip(
                          label: Text(s, style: const TextStyle(fontSize: 12)),
                          backgroundColor: Colors.blue.withOpacity(0.12),
                          side: BorderSide.none,
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Full recommendation text
            const Divider(),
            const SizedBox(height: 8),
            Text('Full Recommendation',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(r.recommendedDiet,
                style: TextStyle(
                    fontSize: 13, height: 1.5, color: cs.onSurfaceVariant)),

            // Recent detections info
            if (r.recentDetections.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.history, size: 18, color: accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Based on breed detections: ${r.recentDetections.join(", ")}',
                        style: TextStyle(fontSize: 12, color: cs.onSurface),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statChip(String text, ColorScheme cs) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text,
            style: TextStyle(fontSize: 12, color: cs.onSurface),
            overflow: TextOverflow.ellipsis),
      ),
    );
  }

  // ─── History Section ──────────────────────────────────────────────────

  Widget _buildHistorySection(ThemeData theme, ColorScheme cs, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history, color: accent, size: 20),
            const SizedBox(width: 8),
            Text('Recommendation History',
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text('No recommendations yet.',
                    style: TextStyle(color: cs.onSurfaceVariant)),
              ),
            ),
          )
        else
          ...(_history.map((h) => _buildHistoryItem(h, theme, cs, accent))),
      ],
    );
  }

  Future<void> _deleteHistoryItem(DietRecommendationResult h) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Recommendation'),
        content: const Text('Are you sure you want to delete this diet recommendation?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && h.id != null) {
      try {
        await _aiService.deleteDietRecommendation(h.id!);
        setState(() => _history.removeWhere((item) => item.id == h.id));
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete')),
          );
        }
      }
    }
  }

  Widget _buildHistoryItem(DietRecommendationResult h, ThemeData theme,
      ColorScheme cs, Color accent) {
    final date = h.createdAt != null
        ? '${h.createdAt!.day}/${h.createdAt!.month}/${h.createdAt!.year}'
        : '';
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
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showHistoryDetail(h),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.restaurant, color: accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${h.dailyCalories} kcal/day',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(h.feedingFrequency,
                        style: TextStyle(
                            fontSize: 12, color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (h.sizeCategory != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(h.sizeCategoryLabel,
                          style: TextStyle(
                              fontSize: 11,
                              color: accent,
                              fontWeight: FontWeight.w600)),
                    ),
                  const SizedBox(height: 4),
                  Text(date,
                      style: TextStyle(
                          fontSize: 11, color: cs.onSurfaceVariant)),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  void _showHistoryDetail(DietRecommendationResult h) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    const accent = Color(0xFF7C3AED);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollCtrl) {
            return ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Diet Recommendation Details',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildResultCard(theme, cs, accent, h),
              ],
            );
          },
        );
      },
    );
  }
}
