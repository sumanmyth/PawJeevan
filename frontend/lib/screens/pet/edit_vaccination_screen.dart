import 'package:flutter/material.dart';
import '../../models/pet_model.dart';
import '../../services/pet_service.dart';
import '../../widgets/custom_app_bar.dart';

class EditVaccinationScreen extends StatefulWidget {
  final VaccinationModel vaccination;
  const EditVaccinationScreen({super.key, required this.vaccination});

  @override
  State<EditVaccinationScreen> createState() => _EditVaccinationScreenState();
}

class _EditVaccinationScreenState extends State<EditVaccinationScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _vaccineController;
  late TextEditingController _vetController;
  late TextEditingController _notesController;
  late DateTime _vaccinationDate;
  DateTime? _nextDueDate;
  bool _isSaving = false;

  final _service = PetService();

  @override
  void initState() {
    super.initState();
    final v = widget.vaccination;
    _vaccineController = TextEditingController(text: v.vaccineName);
    _vetController = TextEditingController(text: v.veterinarian ?? '');
    _notesController = TextEditingController(text: v.notes ?? '');
    _vaccinationDate = v.vaccinationDate;
    _nextDueDate = v.nextDueDate;
  }

  @override
  void dispose() {
    _vaccineController.dispose();
    _vetController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isNextDue) async {
    final dt = await showDatePicker(
      context: context,
      initialDate: isNextDue ? (_nextDueDate ?? DateTime.now()) : _vaccinationDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (dt != null) {
      setState(() {
        if (isNextDue) {
          _nextDueDate = dt;
        } else {
          _vaccinationDate = dt;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final updated = VaccinationModel(
        id: widget.vaccination.id,
        vaccineName: _vaccineController.text.trim(),
        vaccinationDate: _vaccinationDate,
        nextDueDate: _nextDueDate,
        veterinarian: _vetController.text.trim(),
        notes: _notesController.text.trim(),
      );
      await _service.updateVaccination(widget.vaccination.id!, updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vaccination updated')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Edit Vaccination', showBackButton: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _vaccineController,
                decoration: const InputDecoration(
                  labelText: 'Vaccine Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.vaccines),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              _dateField(
                label: 'Vaccination Date',
                dateText: _fmtDate(_vaccinationDate),
                onTap: () => _pickDate(false),
              ),
              const SizedBox(height: 12),

              _dateField(
                label: 'Next Due Date (optional)',
                dateText: _nextDueDate != null ? _fmtDate(_nextDueDate!) : 'Not set',
                onTap: () => _pickDate(true),
              ),
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
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note_alt_outlined),
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
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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