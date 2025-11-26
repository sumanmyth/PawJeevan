import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'verify_otp_screen.dart';
import '../../providers/auth_provider.dart';
import '../common/main_screen.dart';
import '../../utils/helpers.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController  = TextEditingController();
  final _emailController     = TextEditingController();
  final _phoneController     = TextEditingController();
  final _passwordController  = TextEditingController();
  final _confirmController   = TextEditingController();

  bool _obscurePassword      = true;
  bool _obscureConfirm       = true;
  bool _errorClearScheduled = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final result = await auth.register(
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      firstName: _firstNameController.text.trim().isEmpty ? null : _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim().isEmpty ? null : _lastNameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
    );

    if (!mounted) return;

    if (result == null) {
      Helpers.showInstantSnackBar(
        context,
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(auth.error ?? 'Registration failed')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    if (result is Map && (result['requires_verification'] == true)) {
      final pendingId = result['pending_id'] as int?;
      final userId = pendingId ?? result['user_id'] as int?;
      final verifiedUser = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => VerifyOtpScreen(email: _emailController.text.trim(), userId: userId)),
      );

      if (verifiedUser != null) {
        auth.updateLocalUser(verifiedUser);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setInt('user_id', verifiedUser.id);

        Helpers.showInstantSnackBar(
          context,
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Registration complete — email verified')),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
          (route) => false,
        );
        return;
      } else {
        Helpers.showInstantSnackBar(
          context,
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(auth.error ?? 'Verification required')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
        return;
      }
    }

    if (result is Map) {
      final user = result['user'] as dynamic;
      if (user != null) {
        Helpers.showInstantSnackBar(
          context,
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Registration successful! Welcome to PawJeevan')),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
          (route) => false,
        );
        return;
      }
    }

    Helpers.showInstantSnackBar(
      context,
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(auth.error ?? 'Registration failed')),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (auth.error == null) {
      _errorClearScheduled = false;
    } else if (!_errorClearScheduled) {
      _errorClearScheduled = true;
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) context.read<AuthProvider>().clearError();
      });
    }

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
                    // Background decorative paw prints
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
                    // Main content card
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade900 : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Logo with gradient
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF7C3AED),
                                    Color.fromRGBO(124, 58, 237, 0.85),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color.fromRGBO(124, 58, 237, 0.3),
                                    blurRadius: 15,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.pets,
                                size: 50,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            // Heading
                            const Text(
                              'Join PawJeevan',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF7C3AED),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Create your account to get started',
                              style: TextStyle(color: isDark ? Colors.white : Colors.grey[600]),
                            ),
                            const SizedBox(height: 24),

                            // Username
                            TextFormField(
                              controller: _usernameController,
                              style: TextStyle(color: isDark ? Colors.white : Colors.black),
                              decoration: InputDecoration(
                                labelText: 'Username',
                                labelStyle: TextStyle(color: isDark ? Colors.grey[300] : null),
                                hintStyle: TextStyle(color: isDark ? Colors.grey[400] : null),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Color.fromRGBO(124, 58, 237, isDark ? 0.95 : 1.0), width: 2),
                                ),
                                prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF7C3AED)),
                                filled: true,
                                fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter username' : null,
                            ),
                            const SizedBox(height: 12),

                            // First Name then Last Name (stacked)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextFormField(
                                  controller: _firstNameController,
                                  decoration: InputDecoration(
                                    labelText: 'First Name (optional)',
                                    labelStyle: TextStyle(color: isDark ? Colors.grey[300] : null),
                                    hintStyle: TextStyle(color: isDark ? Colors.grey[400] : null),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Color.fromRGBO(124, 58, 237, isDark ? 0.95 : 1.0), width: 2),
                                    ),
                                    prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF7C3AED)),
                                    filled: true,
                                    fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _lastNameController,
                                  decoration: InputDecoration(
                                    labelText: 'Last Name (optional)',
                                    labelStyle: TextStyle(color: isDark ? Colors.grey[300] : null),
                                    hintStyle: TextStyle(color: isDark ? Colors.grey[400] : null),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Color.fromRGBO(124, 58, 237, isDark ? 0.95 : 1.0), width: 2),
                                    ),
                                    prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF7C3AED)),
                                    filled: true,
                                    fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Email
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                labelStyle: TextStyle(color: isDark ? Colors.grey[300] : null),
                                hintStyle: TextStyle(color: isDark ? Colors.grey[400] : null),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Color.fromRGBO(124, 58, 237, isDark ? 0.95 : 1.0), width: 2),
                                ),
                                prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF7C3AED)),
                                filled: true,
                                fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Please enter email';
                                if (!v.contains('@')) return 'Please enter a valid email';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            // Phone (optional)
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: 'Phone (optional)',
                                labelStyle: TextStyle(color: isDark ? Colors.grey[300] : null),
                                hintStyle: TextStyle(color: isDark ? Colors.grey[400] : null),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Color.fromRGBO(124, 58, 237, isDark ? 0.95 : 1.0), width: 2),
                                ),
                                prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF7C3AED)),
                                filled: true,
                                fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Password
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                labelStyle: TextStyle(color: isDark ? Colors.grey[300] : null),
                                hintStyle: TextStyle(color: isDark ? Colors.grey[400] : null),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Color.fromRGBO(124, 58, 237, isDark ? 0.95 : 1.0), width: 2),
                                ),
                                prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF7C3AED)),
                                filled: true,
                                fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    color: const Color(0xFF7C3AED),
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Please enter password';
                                if (v.length < 6) return 'Password must be at least 6 characters';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            // Confirm Password
                            TextFormField(
                              controller: _confirmController,
                              obscureText: _obscureConfirm,
                              decoration: InputDecoration(
                                labelText: 'Confirm Password',
                                labelStyle: TextStyle(color: isDark ? Colors.grey[300] : null),
                                hintStyle: TextStyle(color: isDark ? Colors.grey[400] : null),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Color.fromRGBO(124, 58, 237, isDark ? 0.95 : 1.0), width: 2),
                                ),
                                prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF7C3AED)),
                                filled: true,
                                fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    color: const Color(0xFF7C3AED),
                                  ),
                                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Please confirm password';
                                if (v != _passwordController.text) return 'Passwords do not match';
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // Error box
                            if (auth.error != null)
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
                                    Expanded(
                                      child: Text(
                                        auth.error!,
                                        style: TextStyle(color: Colors.red.shade700),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // Register button with gradient
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: auth.isLoading ? null : _handleRegister,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF7C3AED),
                                  foregroundColor: Colors.white,
                                  elevation: 8,
                                  shadowColor: const Color.fromRGBO(124, 58, 237, 0.4),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: auth.isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Create Account',
                                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                          ),
                                          SizedBox(width: 8),
                                          Icon(Icons.arrow_forward, size: 20),
                                        ],
                                      ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Back button
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
                            const SizedBox(height: 8),
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