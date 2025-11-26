import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/store_provider.dart';

class PetTypeMenu extends StatelessWidget {
  final List<Map<String, String>> petTypes;

  const PetTypeMenu({
    super.key,
    required this.petTypes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<StoreProvider>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: petTypes.map((petType) {
          final isSelected = petType['id'] == provider.selectedPetType;
          return ChoiceChip(
            label: Text(petType['label']!),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                // Clear search when pet type changes
                provider.setSearchQuery('');
                provider.searchAdoptions();
                provider.setSelectedPetType(petType['id']!);
              }
            },
            selectedColor: const Color(0xFFE9D8FD),
            checkmarkColor: const Color(0xFF7C3AED),
            backgroundColor: theme.brightness == Brightness.dark
                ? Colors.grey.shade800
                : Colors.grey.shade200,
            labelStyle: TextStyle(
              color: isSelected ? const Color(0xFF7C3AED) : theme.textTheme.bodyLarge?.color,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          );
        }).toList(),
      ),
    );
  }
}
