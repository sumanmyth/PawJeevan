import 'package:flutter/material.dart';
import '../../models/pet/pet_model.dart';
import '../../widgets/custom_app_bar.dart';
import 'widgets/full_screen_image.dart';

class VaccinationDetailScreen extends StatelessWidget {
  final VaccinationModel vaccination;
  const VaccinationDetailScreen({super.key, required this.vaccination});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Vaccination', showBackButton: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(vaccination.vaccineName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _detailRow(context, 'Date', _fmtDate(vaccination.vaccinationDate)),
          if (vaccination.nextDueDate != null) _detailRow(context, 'Next due', _fmtDate(vaccination.nextDueDate!)),
          if (vaccination.veterinarian != null && vaccination.veterinarian!.isNotEmpty) _detailRow(context, 'Veterinarian', vaccination.veterinarian!),
          if (vaccination.clinicName != null && vaccination.clinicName!.isNotEmpty) _detailRow(context, 'Clinic', vaccination.clinicName!),
          if (vaccination.notes != null && vaccination.notes!.isNotEmpty) _detailRow(context, 'Notes', vaccination.notes!),
          const SizedBox(height: 12),
          if (vaccination.certificate != null && vaccination.certificate!.isNotEmpty) ...[
            const Text('Certificate', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FullScreenImage(imageUrl: vaccination.certificate!))),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(vaccination.certificate!, width: double.infinity, height: 220, fit: BoxFit.cover),
              ),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) => d.toIso8601String().split('T')[0];
}
