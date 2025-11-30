import 'package:flutter/material.dart';
import '../../../models/pet/pet_model.dart';
import '../../../services/pet_service.dart';
import '../../../utils/helpers.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/app_form_card.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show File;

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
  late TextEditingController _clinicController;
  XFile? _newCertificate;
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
    _clinicController = TextEditingController(text: v.clinicName ?? '');
    _vaccinationDate = v.vaccinationDate;
    _nextDueDate = v.nextDueDate;
  }

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
      if (picked != null) {
        setState(() => _newCertificate = picked);
      }
    } catch (e) {
      Helpers.showInstantSnackBar(context, SnackBar(content: Text('Error picking certificate: $e')));
    }
  }

  Future<void> _pickFromCamera() async {
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(source: ImageSource.camera);
      if (picked != null) setState(() => _newCertificate = picked);
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
      final updated = VaccinationModel(
        id: widget.vaccination.id,
        vaccineName: _vaccineController.text.trim(),
        vaccinationDate: _vaccinationDate,
        nextDueDate: _nextDueDate,
        veterinarian: _vetController.text.trim(),
        notes: _notesController.text.trim(),
        clinicName: _clinicController.text.trim().isEmpty ? null : _clinicController.text.trim(),
      );
      if (_newCertificate != null) {
        await _service.updateVaccinationMultipart(widget.vaccination.id!, updated, certificates: [_newCertificate!]);
      } else {
        await _service.updateVaccination(widget.vaccination.id!, updated);
      }
      if (!mounted) return;
      Helpers.showInstantSnackBar(
        context,
        const SnackBar(content: Text('Vaccination updated')),
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
      appBar: const CustomAppBar(title: 'Edit Vaccination', showBackButton: true),
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

              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note_alt_outlined),
                ),
              ),
              const SizedBox(height: 12),

              // Existing certificate preview (if any)
              if (widget.vaccination.certificate != null && widget.vaccination.certificate!.isNotEmpty)
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
                          child: Image.network(widget.vaccination.certificate!, fit: BoxFit.cover),
                        ),
                      ),
                      const Expanded(child: Text('Existing certificate')),
                    ],
                  ),
                ),
              const SizedBox(height: 8),

              // New certificate picker (supports multiple)
              if (_newCertificate != null)
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
                          child: kIsWeb ? Image.network(_newCertificate!.path, fit: BoxFit.cover) : Image.file(File(_newCertificate!.path), fit: BoxFit.cover),
                        ),
                      ),
                      Expanded(child: Text(_newCertificate!.name)),
                      IconButton(onPressed: () => setState(() => _newCertificate = null), icon: const Icon(Icons.close)),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _showAttachmentOptions,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Add/Replace Certificate (optional)'),
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