import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_app_bar.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await context.read<AuthProvider>().changePassword(
        currentPassword: _current.text,
        newPassword: _new.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Change Password', showBackButton: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _pwdField(label: 'Current Password', controller: _current),
              const SizedBox(height: 12),
              _pwdField(label: 'New Password', controller: _new),
              const SizedBox(height: 12),
              _pwdField(label: 'Confirm New Password', controller: _confirm, mustMatch: _new),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? 'Saving...' : 'Save'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
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

  Widget _pwdField({
    required String label,
    required TextEditingController controller,
    TextEditingController? mustMatch,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: _obscure,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Required';
        if (mustMatch != null && v != mustMatch.text) return 'Passwords do not match';
        if (label.startsWith('New') && v.length < 6) return 'Min 6 characters';
        return null;
      },
    );
  }
}