import 'package:final_project/modules/admin/widgets/login_form.dart';
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
  bool showPassword = false;

  final supabase = Supabase.instance.client;

  void _togglePassword() => setState(() => showPassword = !showPassword);

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Future<void> _login() async {
    setState(() => isLoading = true);

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Email or password cannot be empty.');
      setState(() => isLoading = false);
      return;
    }

    // Admin login
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

        if (admin == null) {
          await supabase.from('admins').insert({
            'id': user.id,
            'email': user.email,
            'name': 'Admin',
            'created_at': DateTime.now().toIso8601String(),
          });
        }

        await SessionHelper.saveUserSession('admin', email, user.id);
        if (mounted) context.go('/dashboard');
        return;
      }
    } catch (_) {
      debugPrint('Admin login failed');
    }

    // User login
    try {
      final user =
          await supabase
              .from('users')
              .select()
              .eq('email', email)
              .eq('password', password)
              .maybeSingle();

      if (user != null) {
        final role = user['role'];
        final userId = user['id'].toString();

        await SessionHelper.saveUserSession(role, email, userId);

        if (mounted) {
          switch (role) {
            case 'employee':
              context.go('/employee-dashboard');
              break;
            case 'manager':
              context.go('/manager-dashboard');
              break;
            default:
              _showSnackBar('Unsupported role: $role');
          }
        }
      } else {
        _showSnackBar('Invalid credentials.');
      }
    } catch (_) {
      _showSnackBar('Login failed.');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: LoginForm(
              emailController: emailController,
              passwordController: passwordController,
              showPassword: showPassword,
              isLoading: isLoading,
              onTogglePassword: _togglePassword,
              onLogin: _login,
            ),
          ),
        ),
      ),
    );
  }
}
