import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/store_provider.dart';
import 'location_filter_menu.dart';
import 'pet_type_menu.dart';

class FilterSheet extends StatefulWidget {
  const FilterSheet({super.key});

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late String _tempLocation;
  late String _tempPetType;

  @override
  void initState() {
    super.initState();
    final p = context.read<StoreProvider>();
    _tempLocation = p.selectedLocationFilter;
    _tempPetType = p.selectedPetType;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              const Text('Location', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              LocationFilterMenu(
                selected: _tempLocation,
                onChanged: (v) => setState(() => _tempLocation = v),
              ),
              const SizedBox(height: 12),

              const Text('Type', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              PetTypeMenu(
                petTypes: const [
                  {'id': 'all', 'label': 'All'},
                  {'id': 'dog', 'label': 'Dogs'},
                  {'id': 'cat', 'label': 'Cats'},
                  {'id': 'bird', 'label': 'Birds'},
                ],
                selected: _tempPetType,
                onChanged: (v) => setState(() => _tempPetType = v),
              ),

              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _tempLocation = 'all';
                        _tempPetType = 'all';
                      });
                    },
                    child: const Text('Reset'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final p = context.read<StoreProvider>();
                      // Apply buffered selections and reload
                      p.setLocationFilter(_tempLocation);
                      p.setSelectedPetType(_tempPetType, skipReload: true);
                      p.setSearchQuery('');
                      p.loadAdoptions();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Apply'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
