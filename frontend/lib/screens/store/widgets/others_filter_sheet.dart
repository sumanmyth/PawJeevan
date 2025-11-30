import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/store_provider.dart';
import 'pet_type_menu.dart';

class OthersFilterSheet extends StatefulWidget {
  const OthersFilterSheet({super.key});

  @override
  State<OthersFilterSheet> createState() => _OthersFilterSheetState();
}

class _OthersFilterSheetState extends State<OthersFilterSheet> {
  late Set<int> _tempSelected;
  late String _tempPetType;
  late double _tempWeightMin;
  late double _tempWeightMax;
  late double _tempPriceMin;
  late double _tempPriceMax;
  late TextEditingController _weightMinController;
  late TextEditingController _weightMaxController;
  late TextEditingController _priceMinController;
  late TextEditingController _priceMaxController;

  @override
  void initState() {
    super.initState();
    final p = context.read<StoreProvider>();
    _tempSelected = Set<int>.from(p.selectedStoreCategoryIds);
    _tempPetType = p.selectedProductPetType;
    _tempWeightMin = p.productWeightMin;
    _tempWeightMax = p.productWeightMax;
    _tempPriceMin = p.productPriceMin;
    _tempPriceMax = p.productPriceMax;
    _weightMinController = TextEditingController(text: _tempWeightMin.toStringAsFixed(0));
    _weightMaxController = TextEditingController(text: _tempWeightMax.toStringAsFixed(0));
    _priceMinController = TextEditingController(text: _tempPriceMin.toStringAsFixed(0));
    _priceMaxController = TextEditingController(text: _tempPriceMax.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _weightMinController.dispose();
    _weightMaxController.dispose();
    _priceMinController.dispose();
    _priceMaxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<StoreProvider>();
    final categories = p.storeCategories;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                  IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Categories', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories.map((c) {
                  final selected = _tempSelected.contains(c.id);
                  return ChoiceChip(
                    label: Text(c.name),
                    selected: selected,
                    onSelected: (_) {
                      setState(() {
                        if (selected) {
                          _tempSelected.remove(c.id);
                        } else {
                          _tempSelected.add(c.id);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              const Text('Pet Type', style: TextStyle(fontWeight: FontWeight.w600)),
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

              const SizedBox(height: 12),
              const Text('Weight (kg)', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _weightMinController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Min', suffixText: 'kg'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _weightMaxController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Max', suffixText: 'kg'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              const Text('Price', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceMinController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Min', prefixText: '\u20B9 '),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _priceMaxController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Max', prefixText: '\u20B9 '),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () {
                    setState(() {
                      _tempSelected.clear();
                      _tempPetType = 'all';
                      _tempWeightMin = 0.0;
                      _tempWeightMax = 200.0;
                      _tempPriceMin = 0.0;
                      _tempPriceMax = 10000.0;
                      _weightMinController.text = _tempWeightMin.toStringAsFixed(0);
                      _weightMaxController.text = _tempWeightMax.toStringAsFixed(0);
                      _priceMinController.text = _tempPriceMin.toStringAsFixed(0);
                      _priceMaxController.text = _tempPriceMax.toStringAsFixed(0);
                    });
                  }, child: const Text('Reset')),
                  const SizedBox(width: 8),
                  ElevatedButton(onPressed: () {
                    final provider = context.read<StoreProvider>();
                    // Parse numeric inputs (fall back to defaults)
                    double weightMin = double.tryParse(_weightMinController.text) ?? 0.0;
                    double weightMax = double.tryParse(_weightMaxController.text) ?? 200.0;
                    double priceMin = double.tryParse(_priceMinController.text) ?? 0.0;
                    double priceMax = double.tryParse(_priceMaxController.text) ?? 10000.0;
                    if (weightMin > weightMax) {
                      final tmp = weightMin; weightMin = weightMax; weightMax = tmp;
                      _weightMinController.text = weightMin.toStringAsFixed(0);
                      _weightMaxController.text = weightMax.toStringAsFixed(0);
                    }
                    if (priceMin > priceMax) {
                      final tmp = priceMin; priceMin = priceMax; priceMax = tmp;
                      _priceMinController.text = priceMin.toStringAsFixed(0);
                      _priceMaxController.text = priceMax.toStringAsFixed(0);
                    }

                    // Apply category and product filters then reload products
                    provider.setSelectedStoreCategoryIds(_tempSelected, skipLoad: true);
                    provider.setProductFilters(
                      petType: _tempPetType,
                      weightMin: weightMin,
                      weightMax: weightMax,
                      priceMin: priceMin,
                      priceMax: priceMax,
                      skipLoad: true,
                    );
                    provider.loadProducts();
                    Navigator.of(context).pop();
                  }, child: const Text('Apply')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
