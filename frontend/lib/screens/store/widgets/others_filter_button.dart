import 'package:flutter/material.dart';
import '../../../providers/store_provider.dart';
import 'others_filter_sheet.dart';

class OthersFilterButton extends StatelessWidget {
  final StoreProvider provider;
  const OthersFilterButton({super.key, required this.provider});

  void _showFilters(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (c) => const OthersFilterSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton.icon(
        onPressed: () => _showFilters(context),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: const Icon(Icons.filter_list),
        label: const Text('Filter'),
      ),
    );
  }
}
