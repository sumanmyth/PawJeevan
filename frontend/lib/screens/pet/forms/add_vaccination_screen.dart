import '../../../utils/helpers.dart';
import 'package:flutter/material.dart';
import '../../../models/pet/pet_model.dart';
import '../../../services/pet_service.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/app_form_card.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show File;

class AddVaccinationScreen extends StatefulWidget {
  final int petId;
  const AddVaccinationScreen({super.key, required this.petId});

  @override
  State<AddVaccinationScreen> createState() => _AddVaccinationScreenState();
}

class _AddVaccinationScreenState extends State<AddVaccinationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vaccineController = TextEditingController();
  final _vetController = TextEditingController();
  final _notesController = TextEditingController();
  final _clinicController = TextEditingController();
  XFile? _certificate;
  DateTime _vaccinationDate = DateTime.now();
  DateTime? _nextDueDate;
  bool _isSaving = false;

  final _service = PetService();

  @override
  void dispose() {
    _vaccineController.dispose();
    _vetController.dispose();
    _notesController.dispose();
    _clinicController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isNextDue) async {
    final dt = await Helpers.showBlurredDatePicker(
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

  Future<void> _pickAttachments() async {
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) setState(() => _certificate = picked);
    } catch (e) {
      Helpers.showInstantSnackBar(context, SnackBar(content: Text('Error picking certificate: $e')));
    }
  }

  Future<void> _pickFromCamera() async {
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(source: ImageSource.camera);
      if (picked != null) setState(() => _certificate = picked);
    } catch (e) {
      Helpers.showInstantSnackBar(context, SnackBar(content: Text('Error picking certificate: $e')));
    }
  }

  Future<void> _showAttachmentOptions() async {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Pick from Gallery'),
              onTap: () async {
                Navigator.pop(ctx);
                await _pickAttachments();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(ctx);
                await _pickFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final v = VaccinationModel(
        vaccineName: _vaccineController.text.trim(),
        vaccinationDate: _vaccinationDate,
        nextDueDate: _nextDueDate,                 // null allowed
        veterinarian: _vetController.text.trim(),  // '' allowed
        notes: _notesController.text.trim(),       // '' allowed
        clinicName: _clinicController.text.trim().isEmpty ? null : _clinicController.text.trim(),
      );
      if (_certificate != null) {
        await _service.addVaccinationMultipart(widget.petId, v, certificates: [_certificate!]);
      } else {
        await _service.addVaccination(widget.petId, v);
      }

      if (!mounted) return;
          Helpers.showInstantSnackBar(
            context,
            const SnackBar(content: Text('Vaccination added')),
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
      appBar: const CustomAppBar(title: 'Add Vaccination', showBackButton: true),
      body: AppFormCard(
        padding: EdgeInsets.only(top: topPadding + 16, left: 16, right: 16, bottom: 16),
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
                controller: _clinicController,
                decoration: const InputDecoration(
                  labelText: 'Clinic Name (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.local_hospital),
                ),
              ),
              const SizedBox(height: 12),

              // Certificate picker
              if (_certificate != null)
                SizedBox(
                  height: 84,
                  child: Row(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.grey.shade200),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: kIsWeb ? Image.network(_certificate!.path, fit: BoxFit.cover) : Image.file(File(_certificate!.path), fit: BoxFit.cover),
                        ),
                      ),
                      Expanded(child: Text(_certificate!.name)),
                      IconButton(onPressed: () => setState(() => _certificate = null), icon: const Icon(Icons.close)),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _showAttachmentOptions,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Add Certificate (optional)'),
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
                    backgroundColor: const Color(0xFF7C3AED),
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