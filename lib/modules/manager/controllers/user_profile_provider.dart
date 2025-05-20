import 'dart:io';

import 'package:final_project/core/services/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfileProvider extends ChangeNotifier {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final addressController = TextEditingController();
  final contactController = TextEditingController();
  final dobNotifier = ValueNotifier<String>('');
  DateTime? selectedDate;
  String? role;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool passwordVisible = false;

  void togglePasswordVisibility() {
    passwordVisible = !passwordVisible;
    notifyListeners();
  }

  final profilePicNotifier = ValueNotifier<String?>(null);

  Future<void> loadProfilePicture() async {
    final userId = await SessionHelper.getUserId();
    if (userId == null) return;

    final url = Supabase.instance.client.storage
        .from('manager-pics')
        .getPublicUrl('$userId.jpg');

    // This can be null if image doesn't exist
    profilePicNotifier.value = url;
  }

  Future<void> loadProfile() async {
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
        nameController.text = data['name'] ?? '';
        emailController.text = data['email'] ?? '';
        passwordController.text = data['password'] ?? '';
        addressController.text = data['address'] ?? '';
        contactController.text = data['contact']?.toString() ?? '';
        role = data['role'];

        if (data['dob'] != null) {
          selectedDate = DateTime.tryParse(data['dob']);
          if (selectedDate != null) {
            dobNotifier.value = DateFormat('yyyy-MM-dd').format(selectedDate!);
          }
        }
      }
      // Load profile picture URL
      await loadProfilePicture();
    } catch (e) {
      debugPrint('Failed to load profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> pickAndUploadProfilePicture() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final file = File(image.path);
    final userId = await SessionHelper.getUserId();
    if (userId == null) return;

    try {
      await Supabase.instance.client.storage
          .from('manager-pics')
          .upload(
            '$userId.jpg',
            file,
            fileOptions: const FileOptions(upsert: true),
          );

      await loadProfilePicture();
    } catch (e) {
      debugPrint('Error uploading profile picture: $e');
    }
  }

  Future<void> updateProfile(BuildContext context) async {
    final supabase = Supabase.instance.client;
    final userId = await SessionHelper.getUserId();
    if (userId == null) return;

    try {
      final updates = {
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'password': passwordController.text.trim(),
        'dob': selectedDate?.toIso8601String(),
        'address': addressController.text.trim(),
        'contact': int.tryParse(contactController.text.trim()),
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

  Future<void> pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      selectedDate = picked;
      dobNotifier.value = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    addressController.dispose();
    contactController.dispose();
    dobNotifier.dispose();
    profilePicNotifier.dispose();
    super.dispose();
  }
}
