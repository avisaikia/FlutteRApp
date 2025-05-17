import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/services/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  void _checkSession() async {
    await Future.delayed(const Duration(seconds: 3)); // Optional splash delay

    final supabaseSession = Supabase.instance.client.auth.currentSession;
    final savedRole = await SessionHelper.getUserRole();

    if (!mounted) return;

    if (savedRole == 'admin' && supabaseSession != null) {
      context.go('/dashboard'); // Admin Dashboard
    } else if (savedRole == 'employee') {
      context.go('/employee-dashboard'); // Employee Dashboard
    } else if (savedRole == 'manager') {
      context.go('/manager-dashboard'); // Manager Dashboard
    } else {
      context.go('/login'); // No session found
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF5F6FA,
      ), // Set a background color for the splash screen
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // App name with style
            const Text(
              'Leave App',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.blue, // You can change the color
              ),
            ),
            const SizedBox(height: 20), // Space between name and loader
            const CircularProgressIndicator(
              strokeWidth: 4, // You can adjust the stroke width
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.blue,
              ), // Adjust the loading color
            ),
          ],
        ),
      ),
    );
  }
}
