import 'package:flutter/material.dart';
import '../../models/pet/pet_model.dart';
import '../../widgets/custom_app_bar.dart';
import '../../utils/currency.dart';
import 'widgets/full_screen_image.dart';

class MedicalRecordDetailScreen extends StatelessWidget {
  final MedicalRecordModel record;
  const MedicalRecordDetailScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Medical Record', showBackButton: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${record.recordType.toUpperCase()} • ${record.title}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _detailRow(context, 'Date', _fmtDate(record.date)),
            if (record.veterinarian != null && record.veterinarian!.isNotEmpty) _detailRow(context, 'Veterinarian', record.veterinarian!),
            if (record.clinicName != null && record.clinicName!.isNotEmpty) _detailRow(context, 'Clinic', record.clinicName!),
            if (record.cost != null) _detailRow(context, 'Cost', '$kCurrencySymbol${record.cost!.toStringAsFixed(2)}'),
            if (record.prescription != null && record.prescription!.isNotEmpty) _detailRow(context, 'Prescription', record.prescription!),
            const SizedBox(height: 8),
            const Text('Description', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(record.description),
            const SizedBox(height: 12),
            if (record.attachments != null && record.attachments!.isNotEmpty) ...[
              const Text('Attachments', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              SizedBox(
                height: 84,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, i) {
                    final url = record.attachments![i];
                    return GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FullScreenImage(imageUrl: url))),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(url, width: 84, height: 84, fit: BoxFit.cover),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemCount: record.attachments!.length,
                ),
              ),
            ],
          ],
        ),
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
