import 'package:flutter/material.dart';
import '../../../providers/store_provider.dart';
import 'filter_sheet.dart';

class FilterButton extends StatelessWidget {
  final StoreProvider provider;

  const FilterButton({super.key, required this.provider});

  void _showFilters(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (c) => const FilterSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show current selections briefly on the button label
    final loc = provider.selectedLocationFilter;
    final type = provider.selectedPetType;
    String label = 'Filter';
    if (loc != 'all' || type != 'all') {
      final parts = <String>[];
      if (loc != 'all') parts.add(loc.replaceAll('_', ' ').toUpperCase());
      if (type != 'all') parts.add(type.toUpperCase());
      label = parts.isNotEmpty ? parts.join(' · ') : 'Filter';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton.icon(
        onPressed: () => _showFilters(context),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: const Icon(Icons.filter_list),
        label: Text(label),
      ),
    );
  }
}
