import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
// helpers import removed (unused)
import 'verify_otp_screen.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final AuthService _auth = AuthService();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _auth.sendOtp(email: _emailController.text.trim());
      if (!mounted) return;
      // Navigate to verify screen. When verify succeeds it will return a User and
      // AuthService will have stored tokens, allowing reset password call.
      final user = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => VerifyOtpScreen(email: _emailController.text.trim())),
      );

      if (user != null && mounted) {
        // Move to reset password screen. We navigate to the named route
        // so the reset screen can replace the current flow stack.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF7C3AED),
              Color.fromRGBO(124, 58, 237, 0.85),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Positioned(
                      right: -50,
                      top: -30,
                      child: Opacity(
                        opacity: 0.05,
                        child: Icon(
                          Icons.pets,
                          size: 160,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Positioned(
                      left: -40,
                      bottom: 50,
                      child: Opacity(
                        opacity: 0.05,
                        child: Icon(
                          Icons.pets,
                          size: 120,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade900 : null,
                        gradient: isDark
                            ? null
                            : const LinearGradient(
                                colors: [Color(0xFFFFFFFF), Color(0xFFF7F7FB)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [Color(0xFF7C3AED), Color.fromRGBO(124, 58, 237, 0.85)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: const Icon(Icons.mark_email_read_outlined, size: 36, color: Colors.white),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Forgot password',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Enter the email associated with your account. We will send a verification code to reset your password.',
                              style: TextStyle(color: isDark ? Colors.grey[300] : Colors.grey[700]),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: TextStyle(color: isDark ? Colors.white : Colors.black),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF7C3AED)),
                                labelText: 'Email',
                                labelStyle: TextStyle(color: isDark ? Colors.grey[300] : null),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 2),
                                ),
                                filled: true,
                                fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Please enter your email';
                                if (!v.contains('@')) return 'Please enter a valid email';
                                return null;
                              },
                            ),

                            const SizedBox(height: 12),
                            if (_error != null)
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.red.shade100),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.error_outline, color: Colors.red.shade700),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(_error!, style: TextStyle(color: Colors.red.shade700))),
                                  ],
                                ),
                              ),

                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _loading ? null : _sendOtp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7C3AED),
                                foregroundColor: Colors.white,
                                elevation: 6,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: _loading
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text('Send verification code', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),

                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFF7C3AED), width: 2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.arrow_back, color: Color(0xFF7C3AED), size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Back to Login',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Color(0xFF7C3AED),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
