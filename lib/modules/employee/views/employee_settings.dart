import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EmployeeSettings extends StatelessWidget {
  const EmployeeSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/employee-dashboard'),
        ),
      ),
      body: const Center(
        child: Text('Settings Options will be added here.'),
      ),
    );
  }
}