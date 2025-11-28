import 'package:flutter/material.dart';
import '../../../models/pet/pet_model.dart';
import '../../../services/pet_service.dart';
import '../../../utils/helpers.dart';
import '../forms/edit_vaccination_screen.dart';
import 'empty_state_widget.dart';

/// Vaccinations tab displaying vaccine records
class VaccinationTab extends StatelessWidget {
  final List<VaccinationModel> vaccinations;
  final VoidCallback onRefresh;

  const VaccinationTab({
    super.key,
    required this.vaccinations,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (vaccinations.isEmpty) {
      return const EmptyStateWidget(
        title: 'No vaccinations yet',
        subtitle: 'Tap + to add a vaccination record',
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: vaccinations.length,
        itemBuilder: (context, i) {
          final v = vaccinations[i];
          return _buildVaccinationCard(context, v);
        },
      ),
    );
  }

  Widget _buildVaccinationCard(BuildContext context, VaccinationModel v) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color.fromRGBO(124, 58, 237, 0.2),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(124, 58, 237, 0.08),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color.fromRGBO(124, 58, 237, 0.85)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.vaccines, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  v.vaccineName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[200]
                        : const Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatVaccinationDetails(v),
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[400]
                        : Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          _buildPopupMenu(context, v),
        ],
      ),
    );
  }

  String _formatVaccinationDetails(VaccinationModel v) {
    final parts = <String>[
      'Date: ${_formatDate(v.vaccinationDate)}',
      if (v.nextDueDate != null) 'Next due: ${_formatDate(v.nextDueDate!)}',
      if (v.veterinarian != null && v.veterinarian!.isNotEmpty) 'Vet: ${v.veterinarian}',
      if (v.notes != null && v.notes!.isNotEmpty) 'Notes: ${v.notes}',
    ];
    return parts.join('\n');
  }

  String _formatDate(DateTime d) => d.toIso8601String().split('T')[0];

  Widget _buildPopupMenu(BuildContext context, VaccinationModel v) {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (value == 'edit') {
          final ok = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => EditVaccinationScreen(vaccination: v),
            ),
          );
          if (ok == true) onRefresh();
        } else if (value == 'delete') {
          final confirm = await Helpers.showBlurredConfirmationDialog(
            context,
            title: 'Delete Vaccination',
            content: 'Delete "${v.vaccineName}"?',
          );
          if (confirm == true) {
            await PetService().deleteVaccination(v.id!);
            onRefresh();
          }
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'edit', child: Text('Edit')),
        PopupMenuItem(
          value: 'delete',
          child: Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}
