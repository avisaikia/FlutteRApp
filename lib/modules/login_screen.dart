import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/services/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  String? errorText;

  final double _fieldSpacing = 16.0;
  final double _formPadding = 24.0;

  //login for admins and users
  void _login() async {
    setState(() {
      isLoading = true;
      errorText = null;
    });

    final supabase = Supabase.instance.client;
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Email or password cannot be empty.');
      setState(() => isLoading = false);
      return;
    }

    //checks with supabase auth
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;

      if (user != null) {
        final admin =
            await supabase
                .from('admins')
                .select()
                .eq('id', user.id)
                .maybeSingle();

        //new admin then upadate details
        if (admin == null) {
          await supabase.from('admins').insert({
            'id': user.id,
            'email': user.email,
            'name': 'Admin',
            'created_at': DateTime.now().toIso8601String(),
          });
        }

        await SessionHelper.saveUserSession('admin', email, user.id);
        context.go('/dashboard');
        return;
      }
    } catch (e) {
      debugPrint('Supabase Auth login failed or not admin');
    }

    //checks in users table without auth
    try {
      final userResponse =
          await supabase
              .from('users')
              .select()
              .eq('email', email)
              .eq('password', password)
              .maybeSingle();

      if (userResponse != null) {
        final role = userResponse['role'] as String?;
        final userId = userResponse['id']?.toString();

        // Check if the role and userId are valid
        if (role != null && userId != null) {
          await SessionHelper.saveUserSession(role, email, userId);

          // Navigate based on role
          if (role == 'employee') {
            context.go('/employee-dashboard');
          } else if (role == 'manager') {
            context.go('/manager-dashboard');
          } else {
            _showSnackBar('Unsupported role: $role');
          }
        } else {
          _showSnackBar('Invalid user data received.');
        }
      } else {
        _showSnackBar('Invalid Credentials');
      }
    } catch (e) {
      _showSnackBar('Invalid Credentials');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    final snackBar = SnackBar(
      content: Text(message, style: const TextStyle(color: Colors.white)),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.redAccent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      duration: const Duration(seconds: 3),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(_formPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Welcome Back',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: _fieldSpacing),
            _buildTextField(controller: emailController, label: 'Email'),
            SizedBox(height: _fieldSpacing),
            _buildTextField(
              controller: passwordController,
              label: 'Password',
              isPassword: true,
            ),
            SizedBox(height: _fieldSpacing + 8),
            isLoading
                ? const CircularProgressIndicator()
                : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _login,
                    child: const Text('Login', style: TextStyle(fontSize: 16)),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: _buildLoginForm(),
          ),
        ),
      ),
    );
  }
}
