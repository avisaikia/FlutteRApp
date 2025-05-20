import 'dart:io';
import 'package:final_project/core/services/shared_preferences.dart';
import 'package:final_project/modules/employee/models/employee_profile_cache.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class EmployeeProfileProvider extends ChangeNotifier {
  Map<String, dynamic>? _profile;

  Map<String, dynamic>? get profile => _profile;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController contactController = TextEditingController();

  final TextEditingController dobController = TextEditingController();

  DateTime? _selectedDate;
  DateTime? get selectedDate => _selectedDate;

  String? profilePicUrl;
  String role = 'employee';

  bool _passwordVisible = false;
  bool get passwordVisible => _passwordVisible;
  bool isUploadingPic = false;

  String get name => _profile?['name'] ?? nameController.text.trim();

  void togglePasswordVisibility() {
    _passwordVisible = !_passwordVisible;
    notifyListeners();
  }

  Future<void> loadProfile() async {
    final cached = UserProfileCache.profile;
    if (cached != null) {
      _updateProfileData(cached);
      return;
    }

    try {
      final userId = await SessionHelper.getUserId();
      if (userId == null) return;

      final supabase = Supabase.instance.client;
      final data =
          await supabase
              .from('users')
              .select(
                'name, email, dob, role, password, address, contact, profile_pic',
              )
              .eq('id', userId)
              .maybeSingle();

      if (data != null) {
        UserProfileCache.setProfile(data);
        _updateProfileData(data);
      }
    } catch (e) {
      debugPrint('Failed to load employee profile: $e');
    }
  }

  void _updateProfileData(Map<String, dynamic> data) {
    _profile = data;

    nameController.text = data['name'] ?? '';
    emailController.text = data['email'] ?? '';
    passwordController.text = data['password'] ?? '';
    addressController.text = data['address'] ?? '';
    contactController.text = (data['contact']?.toString() ?? '');

    profilePicUrl = data['profile_pic'];
    role = data['role'] ?? 'employee';

    if (data['dob'] != null) {
      final dob = DateTime.tryParse(data['dob']);
      if (dob != null && dob != _selectedDate) {
        _selectedDate = dob;
        dobController.text = DateFormat('yyyy-MM-dd').format(dob);
      }
    } else {
      dobController.text = '';
      _selectedDate = null;
    }

    notifyListeners();
  }

  Future<void> updateDate(DateTime newDate) async {
    if (newDate != _selectedDate) {
      _selectedDate = newDate;
      dobController.text = DateFormat('yyyy-MM-dd').format(newDate);
      notifyListeners();
    }
  }

  void updateProfilePic(String url) {
    if (profilePicUrl != url) {
      profilePicUrl = url;

      SessionHelper.profilePicNotifier.value = url;
      notifyListeners();
    }
  }

  Future<void> updateProfile() async {
    final supabase = Supabase.instance.client;
    final userId = await SessionHelper.getUserId();
    if (userId == null) return;

    final updates = <String, dynamic>{};

    final nameText = nameController.text.trim();
    updates['name'] = nameText.isEmpty ? null : nameText;

    final emailText = emailController.text.trim();

    if (emailText.isNotEmpty) {
      updates['email'] = emailText;
    }

    final passwordText = passwordController.text.trim();
    if (passwordText.isNotEmpty) {
      updates['password'] = passwordText;
    }

    if (_selectedDate != null) {
      updates['dob'] = _selectedDate!.toIso8601String();
    } else {
      updates['dob'] = null;
    }

    final addressText = addressController.text.trim();
    updates['address'] = addressText.isEmpty ? null : addressText;

    final contactText = contactController.text.trim();
    final contact = int.tryParse(contactText);
    updates['contact'] = contactText.isEmpty ? null : contact;

    if (profilePicUrl != null) {
      updates['profile_pic'] = profilePicUrl;
    }

    if (updates.isEmpty) {
      debugPrint('No profile fields to update.');
      return;
    }

    try {
      await supabase.from('users').update(updates).eq('id', userId);
      UserProfileCache.clear();
      await loadProfile();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to update profile: $e');
      rethrow;
    }
  }

  Future<void> pickDateOfBirth(BuildContext context) async {
    final initialDate = _selectedDate ?? DateTime(1990);
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      await updateDate(pickedDate);
    }
  }

  Future<void> pickProfilePicture() async {
    isUploadingPic = true;
    notifyListeners();

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile == null) return;

      final userId = await SessionHelper.getUserId();
      if (userId == null) {
        debugPrint('User ID not found.');
        return;
      }

      final supabase = Supabase.instance.client;
      final fileBytes = await pickedFile.readAsBytes();

      // Ensure safe file extension
      final extParts = pickedFile.path.split('.');
      final fileExt = extParts.length > 1 ? extParts.last : 'jpg';
      final fileName =
          'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      debugPrint('Uploading file: $fileName');

      // Upload to public bucket
      final uploadRes = await supabase.storage
          .from('profilepics')
          .uploadBinary(
            fileName,
            fileBytes,
            fileOptions: FileOptions(
              contentType: 'image/$fileExt',
              upsert: true,
            ),
          );

      if (uploadRes.isEmpty) {
        debugPrint('Image upload failed');
        return;
      }

      final publicUrl = supabase.storage
          .from('profilepics')
          .getPublicUrl(fileName);

      // Update database
      await supabase
          .from('users')
          .update({'profile_pic': publicUrl})
          .eq('id', userId);

      updateProfilePic(publicUrl);
      UserProfileCache.clear();
      await loadProfile();

      debugPrint('Profile picture updated.');
    } catch (e) {
      debugPrint('Error uploading profile picture: $e');
    } finally {
      isUploadingPic = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    addressController.dispose();
    contactController.dispose();
    dobController.dispose();
    super.dispose();
  }
}

OutlineInputBorder _purpleOutlineBorder() {
  return OutlineInputBorder(
    borderSide: const BorderSide(color: Colors.blueAccent),
    borderRadius: BorderRadius.circular(8),
  );
}

ImageProvider<Object>? _buildProfileImage(EmployeeProfileProvider provider) {
  final url = provider.profilePicUrl;

  if (url == null || url.isEmpty) return null;

  if (url.startsWith('http')) {
    return NetworkImage(url);
  } else if (File(url).existsSync()) {
    return FileImage(File(url));
  }

  return null;
}

class EmployeeProfileScreen extends StatelessWidget {
  const EmployeeProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<EmployeeProfileProvider>(
      create: (_) => EmployeeProfileProvider()..loadProfile(),
      child: Consumer<EmployeeProfileProvider>(
        builder: (context, provider, _) {
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
                  Center(
                    child: Stack(
                      children: [
                        GestureDetector(
                          onTap: () => provider.pickProfilePicture(),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundImage: _buildProfileImage(provider),
                            child:
                                provider.profilePicUrl == null
                                    ? const Icon(Icons.person, size: 50)
                                    : null,
                          ),
                        ),

                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () => provider.pickProfilePicture(),
                            child: const CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.blueAccent,
                              child: Icon(
                                Icons.add,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: provider.nameController,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      border: _purpleOutlineBorder(),
                      enabledBorder: _purpleOutlineBorder(),
                      focusedBorder: _purpleOutlineBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: provider.emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: _purpleOutlineBorder(),
                      enabledBorder: _purpleOutlineBorder(),
                      focusedBorder: _purpleOutlineBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: provider.passwordController,
                    obscureText: !provider.passwordVisible,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: _purpleOutlineBorder(),
                      enabledBorder: _purpleOutlineBorder(),
                      focusedBorder: _purpleOutlineBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          provider.passwordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.blueAccent,
                        ),
                        onPressed: () {
                          provider.togglePasswordVisibility();
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  TextFormField(
                    controller: provider.dobController,
                    readOnly: true,
                    onTap: () => provider.pickDateOfBirth(context),
                    decoration: InputDecoration(
                      labelText: 'Date of Birth (YYYY-MM-DD)',
                      border: _purpleOutlineBorder(),
                      enabledBorder: _purpleOutlineBorder(),
                      focusedBorder: _purpleOutlineBorder(),
                      suffixIcon: const Icon(Icons.calendar_today),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: provider.addressController,
                    decoration: InputDecoration(
                      labelText: 'Address',
                      border: _purpleOutlineBorder(),
                      enabledBorder: _purpleOutlineBorder(),
                      focusedBorder: _purpleOutlineBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: provider.contactController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Contact',
                      border: _purpleOutlineBorder(),
                      enabledBorder: _purpleOutlineBorder(),
                      focusedBorder: _purpleOutlineBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onPressed: () async {
                      try {
                        await provider.updateProfile();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Profile updated successfully'),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to update profile: $e'),
                            ),
                          );
                        }
                      }
                    },
                    child: const Text(
                      'Update Profile',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
