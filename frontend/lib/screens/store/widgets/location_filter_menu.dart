import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/store_provider.dart';

class LocationFilterMenu extends StatelessWidget {
  final String? selected;
  final void Function(String)? onChanged;

  const LocationFilterMenu({super.key, this.selected, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<StoreProvider>();
    final items = [
      {'id': 'all', 'label': 'All'},
      {'id': 'my_city', 'label': 'My City'},
      {'id': 'my_country', 'label': 'My Country'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items.map((it) {
          final current = selected ?? provider.selectedLocationFilter;
          final isSelected = it['id'] == current;
          return ChoiceChip(
            label: Text(it['label']!),
            selected: isSelected,
            onSelected: (s) {
              if (s) {
                if (onChanged != null) {
                  onChanged!(it['id']!);
                } else {
                  provider.setLocationFilter(it['id']!);
                }
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
