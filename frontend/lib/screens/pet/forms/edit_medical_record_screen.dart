import 'package:flutter/material.dart';
import '../../../models/pet/pet_model.dart';
import '../../../services/pet_service.dart';
import '../../../utils/helpers.dart';
import '../../../utils/currency.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show File;
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
  late TextEditingController _clinicController;
  late TextEditingController _prescriptionController;
  late TextEditingController _costController;
  late String _recordType;
  late DateTime _date;
  bool _isSaving = false;

  final _service = PetService();
  XFile? _newAttachment;

  @override
  void initState() {
    super.initState();
    final r = widget.record;
    _titleController = TextEditingController(text: r.title);
    _descController = TextEditingController(text: r.description);
    _vetController = TextEditingController(text: r.veterinarian ?? '');
    _clinicController = TextEditingController(text: r.clinicName ?? '');
    _prescriptionController = TextEditingController(text: r.prescription ?? '');
    _costController = TextEditingController(text: r.cost?.toString() ?? '');
    _recordType = r.recordType;
    _date = r.date;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _vetController.dispose();
    _clinicController.dispose();
    _prescriptionController.dispose();
    _costController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final dt = await Helpers.showBlurredDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (dt != null) setState(() => _date = dt);
  }

  Future<void> _pickFromGallery() async {
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) setState(() => _newAttachment = picked);
    } catch (e) {
      Helpers.showInstantSnackBar(context, SnackBar(content: Text('Error picking attachment: $e')));
    }
  }

  Future<void> _pickFromCamera() async {
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(source: ImageSource.camera);
      if (picked != null) setState(() => _newAttachment = picked);
    } catch (e) {
      Helpers.showInstantSnackBar(context, SnackBar(content: Text('Error picking attachment: $e')));
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
                await _pickFromGallery();
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
          clinicName: _clinicController.text.trim().isEmpty ? null : _clinicController.text.trim(),
          prescription: _prescriptionController.text.trim().isEmpty ? null : _prescriptionController.text.trim(),
      );
      if (_newAttachment != null) {
        await _service.updateMedicalRecordMultipart(widget.record.id!, updated, attachments: [_newAttachment!]);
      } else {
        await _service.updateMedicalRecord(widget.record.id!, updated);
      }
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
                controller: _clinicController,
                decoration: const InputDecoration(
                  labelText: 'Clinic Name (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.local_hospital),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _prescriptionController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Prescription (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.medical_information),
                ),
              ),
              const SizedBox(height: 12),
              // Existing remote attachments (read-only thumbnails)
              if (widget.record.attachments != null && widget.record.attachments!.isNotEmpty)
                SizedBox(
                  height: 84,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.record.attachments!.length,
                    itemBuilder: (context, i) {
                      final url = widget.record.attachments![i];
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.grey.shade200),
                        child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(url, fit: BoxFit.cover)),
                      );
                    },
                  ),
                ),
              if (_newAttachment != null)
                SizedBox(
                  height: 84,
                  child: Row(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade200,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: kIsWeb ? Image.network(_newAttachment!.path, fit: BoxFit.cover) : Image.file(File(_newAttachment!.path), fit: BoxFit.cover),
                        ),
                      ),
                      Expanded(child: Text(_newAttachment!.name)),
                      IconButton(onPressed: () => setState(() => _newAttachment = null), icon: const Icon(Icons.close)),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _showAttachmentOptions,
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Add Attachment (optional)'),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _costController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Cost (optional)',
                  border: const OutlineInputBorder(),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 12, right: 8),
                    child: Text(
                      kCurrencySymbol,
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 24),
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