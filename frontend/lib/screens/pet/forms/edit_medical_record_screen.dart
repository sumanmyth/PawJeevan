import 'package:flutter/material.dart';
import '../../../models/pet/pet_model.dart';
import '../../../services/pet_service.dart';
import '../../../utils/helpers.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/app_dropdown_field.dart';
import '../../../widgets/app_form_card.dart';

class EditMedicalRecordScreen extends StatefulWidget {
  final MedicalRecordModel record;
  const EditMedicalRecordScreen({super.key, required this.record});

  @override
  State<EditMedicalRecordScreen> createState() => _EditMedicalRecordScreenState();
}

class _EditMedicalRecordScreenState extends State<EditMedicalRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _vetController;
  late TextEditingController _costController;
  late String _recordType;
  late DateTime _date;
  bool _isSaving = false;

  final _service = PetService();

  @override
  void initState() {
    super.initState();
    final r = widget.record;
    _titleController = TextEditingController(text: r.title);
    _descController = TextEditingController(text: r.description);
    _vetController = TextEditingController(text: r.veterinarian ?? '');
    _costController = TextEditingController(text: r.cost?.toString() ?? '');
    _recordType = r.recordType;
    _date = r.date;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _vetController.dispose();
    _costController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final dt = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (dt != null) setState(() => _date = dt);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final updated = MedicalRecordModel(
        id: widget.record.id,
        recordType: _recordType,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        date: _date,
        veterinarian: _vetController.text.trim(), // '' allowed
        cost: _costController.text.trim().isEmpty
            ? null
            : double.tryParse(_costController.text.trim()),
      );
      await _service.updateMedicalRecord(widget.record.id!, updated);
      if (!mounted) return;
      Helpers.showInstantSnackBar(
        context,
        const SnackBar(content: Text('Medical record updated')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      Helpers.showInstantSnackBar(
        context,
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar:
          const CustomAppBar(title: 'Edit Medical Record', showBackButton: true),
      body: AppFormCard(
        padding: EdgeInsets.only(top: topPadding + 16, left: 16, right: 16, bottom: 16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              AppDropdownFormField<String>(
                initialValue: _recordType,
                items: const [
                  DropdownMenuItem(value: 'checkup', child: Text('Checkup')),
                  DropdownMenuItem(value: 'treatment', child: Text('Treatment')),
                  DropdownMenuItem(value: 'surgery', child: Text('Surgery')),
                  DropdownMenuItem(value: 'emergency', child: Text('Emergency')),
                  DropdownMenuItem(value: 'dental', child: Text('Dental')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (v) => setState(() => _recordType = v ?? 'checkup'),
                decoration: const InputDecoration(
                  labelText: 'Record Type',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              _dateField(label: 'Date', dateText: _fmtDate(_date), onTap: _pickDate),
              const SizedBox(height: 12),

              TextFormField(
                controller: _vetController,
                decoration: const InputDecoration(
                  labelText: 'Veterinarian (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.local_hospital),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _costController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Cost (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? 'Saving...' : 'Save'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateField({
    required String label,
    required String dateText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.date_range),
        ),
        child: Text(dateText),
      ),
    );
  }

  String _fmtDate(DateTime d) => d.toIso8601String().split('T')[0];
}