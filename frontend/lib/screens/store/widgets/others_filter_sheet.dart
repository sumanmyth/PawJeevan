import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/store_provider.dart';

class OthersFilterSheet extends StatefulWidget {
  const OthersFilterSheet({super.key});

  @override
  State<OthersFilterSheet> createState() => _OthersFilterSheetState();
}

class _OthersFilterSheetState extends State<OthersFilterSheet> {
  late Set<int> _tempSelected;

  @override
  void initState() {
    super.initState();
    final p = context.read<StoreProvider>();
    _tempSelected = Set<int>.from(p.selectedStoreCategoryIds);
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
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () {
                    setState(() { _tempSelected.clear(); });
                  }, child: const Text('Reset')),
                  const SizedBox(width: 8),
                  ElevatedButton(onPressed: () {
                    final provider = context.read<StoreProvider>();
                    provider.setSelectedStoreCategoryIds(_tempSelected);
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
