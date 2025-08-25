import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:pharmafinderadmin/screens/dashboard/admin_dashboard.dart';
import 'package:pharmafinderadmin/services/auth_services.dart';
import 'registration_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AdminAuthService _authService = AdminAuthService();
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final user = await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (user != null) {
        String adminId = user.uid;

        // ✅ Check if store exists for this admin
        DatabaseEvent storeEvent = await _dbRef.child("stores/$adminId").once();

        if (!storeEvent.snapshot.exists) {
          // ✅ Create store entry automatically
          await _dbRef.child("stores/$adminId").set({
            "storeId": adminId,
            "storeName": "My Medical Store", // default name
            "ownerEmail": user.email,
            "createdAt": DateTime.now().toIso8601String(),
          });
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackbar(_getFirebaseErrorMessage(e));
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackbar('Something went wrong');
    }
  }

  String _getFirebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Admin not found';
      case 'wrong-password':
        return 'Incorrect password';
      default:
        return 'Authentication failed';
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade50, Colors.green.shade50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  _buildAdminIcon(),
                  const SizedBox(height: 20),
                  Text(
                    'Admin Portal',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildInputField(
                          controller: _emailController,
                          label: 'Admin Email',
                          icon: Icons.email,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter email';
                            }
                            if (!value.contains('@')) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildInputField(
                          controller: _passwordController,
                          label: 'Password',
                          icon: Icons.lock,
                          isPassword: true,
                          obscureText: _obscurePassword,
                          toggleObscure: () {
                            setState(
                              () => _obscurePassword = !_obscurePassword,
                            );
                          },
                          validator: (value) =>
                              (value == null || value.length < 6)
                              ? 'Password must be at least 6 characters'
                              : null,
                        ),
                        const SizedBox(height: 30),
                        _buildLoginButton(),
                        const SizedBox(height: 20),
                        _buildRegisterText(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdminIcon() {
    return Container(
      height: 120,
      width: 120,
      decoration: BoxDecoration(
        color: Colors.green.shade700,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.admin_panel_settings,
        size: 60,
        color: Colors.white,
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? toggleObscure,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.green.shade600),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                  color: Colors.green.shade400,
                ),
                onPressed: toggleObscure,
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green.shade400, width: 2),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade700,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'LOGIN',
                style: TextStyle(color: Colors.white), // ✅ White text
              ),
      ),
    );
  }

  Widget _buildRegisterText() {
    return TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RegistrationScreen()),
        );
      },
      child: RichText(
        text: TextSpan(
          text: 'No admin account? ',
          style: Theme.of(context).textTheme.bodyMedium,
          children: [
            TextSpan(
              text: 'Register',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 94, 98, 94),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
