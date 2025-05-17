import 'package:final_project/core/services/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmployeeProfilePage extends StatefulWidget {
  const EmployeeProfilePage({super.key});

  @override
  State<EmployeeProfilePage> createState() => _EmployeeProfilePageState();
}

class _EmployeeProfilePageState extends State<EmployeeProfilePage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactController = TextEditingController();

  final ValueNotifier<String> _dobTextNotifier = ValueNotifier('');

  DateTime? _selectedDate;
  String role = 'employee';

  @override
  void initState() {
    super.initState();
    _loadEmployeeProfile();
  }

  Future<void> _loadEmployeeProfile() async {
    final supabase = Supabase.instance.client;
    final userId = await SessionHelper.getUserId();
    if (userId == null) return;

    try {
      final data =
          await supabase
              .from('users')
              .select('name, email, dob, role, password, address, contact')
              .eq('id', userId)
              .maybeSingle();

      if (data != null) {
        _nameController.text = data['name'] ?? '';
        _emailController.text = data['email'] ?? '';
        _passwordController.text = data['password'] ?? '';
        _addressController.text = data['address'] ?? '';
        _contactController.text = data['contact']?.toString() ?? '';

        role = data['role'] ?? 'employee';

        if (data['dob'] != null) {
          _selectedDate = DateTime.tryParse(data['dob']);
          if (_selectedDate != null) {
            _dobTextNotifier.value = DateFormat(
              'yyyy-MM-dd',
            ).format(_selectedDate!);
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to load employee profile: $e');
    }
  }

  Future<void> _pickDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _selectedDate = picked;
      _dobTextNotifier.value = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  Future<void> _updateProfile() async {
    final supabase = Supabase.instance.client;
    final userId = await SessionHelper.getUserId();
    if (userId == null) return;

    try {
      final updates = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text.trim(),
        'dob': _selectedDate?.toIso8601String(),
        'address': _addressController.text.trim(),
        'contact': int.tryParse(_contactController.text.trim()),
      };

      await supabase.from('users').update(updates).eq('id', userId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      debugPrint('Failed to update profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: ${e.toString()}')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _addressController.dispose();
    _contactController.dispose();

    _dobTextNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/employee-dashboard'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Change Password'),
            ),
            ValueListenableBuilder<String>(
              valueListenable: _dobTextNotifier,
              builder: (context, value, _) {
                return TextField(
                  readOnly: true,
                  controller: TextEditingController(text: value),
                  onTap: _pickDateOfBirth,
                  decoration: const InputDecoration(
                    labelText: 'Date of Birth (YYYY-MM-DD)',
                  ),
                );
              },
            ),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
            TextField(
              controller: _contactController,
              decoration: const InputDecoration(labelText: 'Contact Number'),
              keyboardType: TextInputType.phone,
            ),

            const SizedBox(height: 10),
            Text(
              'Role: $role',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateProfile,
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
