import 'package:flutter/material.dart';
import '../../../providers/store_provider.dart';

class PetTypeMenu extends StatelessWidget {
  final StoreProvider provider;
  final List<Map<String, String>> petTypes;

  const PetTypeMenu({
    super.key,
    required this.provider,
    required this.petTypes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: petTypes.length,
        itemBuilder: (context, index) {
          final petType = petTypes[index];
          final isSelected = petType['id'] == provider.selectedPetType;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
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
            ),
          );
        },
      ),
    );
  }
}
