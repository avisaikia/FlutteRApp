import 'package:final_project/core/services/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfileForm extends StatefulWidget {
  final String role;

  const UserProfileForm({super.key, required this.role});

  @override
  State<UserProfileForm> createState() => _UserProfileFormState();
}

class _UserProfileFormState extends State<UserProfileForm> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactController = TextEditingController();
  final ValueNotifier<String> _dobTextNotifier = ValueNotifier('');

  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
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
      debugPrint('Failed to load profile: $e');
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
    return ListView(
      padding: const EdgeInsets.all(16.0),
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
          'Role: ${widget.role}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _updateProfile,
          child: const Text('Save Changes'),
        ),
      ],
    );
  }
}
