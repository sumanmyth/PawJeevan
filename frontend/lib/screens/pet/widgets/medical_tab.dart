import 'package:flutter/material.dart';
import '../../../models/pet/pet_model.dart';
import '../../../services/pet_service.dart';
import '../forms/edit_medical_record_screen.dart';
import 'empty_state_widget.dart';

/// Medical records tab displaying health records
class MedicalTab extends StatelessWidget {
  final List<MedicalRecordModel> medicalRecords;
  final VoidCallback onRefresh;

  const MedicalTab({
    super.key,
    required this.medicalRecords,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (medicalRecords.isEmpty) {
      return const EmptyStateWidget(
        title: 'No medical records yet',
        subtitle: 'Tap + to add a medical record',
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: medicalRecords.length,
        itemBuilder: (context, i) {
          final m = medicalRecords[i];
          return _buildMedicalCard(context, m);
        },
      ),
    );
  }

  Widget _buildMedicalCard(BuildContext context, MedicalRecordModel m) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6B46C1).withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B46C1).withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6B46C1), Color(0xFF9F7AEA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.medical_services, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${m.recordType.toUpperCase()} • ${m.title}',
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
                  _formatMedicalDetails(m),
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
          _buildPopupMenu(context, m),
        ],
      ),
    );
  }

  String _formatMedicalDetails(MedicalRecordModel m) {
    final parts = <String>[
      'Date: ${_formatDate(m.date)}',
      if (m.veterinarian != null && m.veterinarian!.isNotEmpty) 'Vet: ${m.veterinarian}',
      if (m.cost != null) 'Cost: ${m.cost}',
      if (m.description.isNotEmpty) m.description,
    ];
    return parts.join('\n');
  }

  String _formatDate(DateTime d) => d.toIso8601String().split('T')[0];

  Widget _buildPopupMenu(BuildContext context, MedicalRecordModel m) {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (value == 'edit') {
          final ok = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => EditMedicalRecordScreen(record: m),
            ),
          );
          if (ok == true) onRefresh();
        } else if (value == 'delete') {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Delete Medical Record'),
              content: Text('Delete "${m.title}"?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
          if (confirm == true) {
            await PetService().deleteMedicalRecord(m.id!);
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
