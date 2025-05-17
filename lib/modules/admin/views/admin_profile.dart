import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _dobController = TextEditingController();

  DateTime? _selectedDate;
  File? _selectedImage;
  String? _profileImageUrl;
  late Future<void> _profileFuture;

  bool _isUpdated = false;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadAndSetUserProfile();
  }

  Future<void> _loadAndSetUserProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final data =
          await Supabase.instance.client
              .from('admins')
              .select('name, email, dob, profile_pic')
              .eq('id', user.id)
              .maybeSingle();

      if (data != null) {
        _nameController.text = data['name'] ?? '';
        _emailController.text = data['email'] ?? '';
        if (data['dob'] != null) {
          _selectedDate = DateTime.tryParse(data['dob']);
          _dobController.text =
              _selectedDate != null
                  ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
                  : '';
        }
        _profileImageUrl = data['profile_pic']; // 🔁 Fixed incorrect key
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _pickDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadProfileImage(String userId) async {
    if (_selectedImage == null) return;

    final filePath = 'profile_pic/$userId.jpg';
    final storage = Supabase.instance.client.storage;

    try {
      // Upload the image to Supabase Storage
      await storage
          .from('profilepics')
          .upload(
            filePath,
            _selectedImage!,
            fileOptions: const FileOptions(upsert: true),
          );

      // Get the public URL of the uploaded file
      final publicUrl = storage.from('profilepics').getPublicUrl(filePath);
      print('Uploaded image URL: $publicUrl');

      setState(() {
        _profileImageUrl = publicUrl;
        _isUpdated = true;
      });
    } catch (e) {
      print('Error uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload profile image: $e')),
      );
    }
  }

  Future<void> _updateProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      if (_selectedImage != null) {
        await _uploadProfileImage(user.id);
      }

      // Ensure that the profile image URL is being updated correctly
      await Supabase.instance.client.from('admins').upsert({
        'id': user.id,
        'name': _nameController.text,
        'email': _emailController.text,
        'dob': _selectedDate?.toIso8601String(),
        'profile_pic':
            _profileImageUrl ?? '', // Ensure it's updated with the URL
      });

      _isUpdated = true;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );

      await Future.delayed(const Duration(milliseconds: 500));
      Navigator.pop(context, _isUpdated);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _isUpdated);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Profile'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _isUpdated),
          ),
        ),
        body: FutureBuilder<void>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Text('Failed to load profile: ${snapshot.error}'),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage:
                          _selectedImage != null
                              ? FileImage(_selectedImage!)
                              : (_profileImageUrl != null
                                      ? NetworkImage(_profileImageUrl!)
                                      : const AssetImage(
                                        'assets/default_avatar.png',
                                      ))
                                  as ImageProvider,
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: CircleAvatar(
                          backgroundColor: Colors.white,
                          radius: 20,
                          child: const Icon(
                            Icons.edit,
                            size: 20,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildProfileField(_nameController, 'Name', Icons.person),
                  const SizedBox(height: 16),
                  _buildProfileField(_emailController, 'Email', Icons.email),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _pickDateOfBirth,
                    child: AbsorbPointer(
                      child: _buildProfileField(
                        _dobController,
                        'Date of Birth',
                        Icons.calendar_today,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: _updateProfile,
                    icon: const Icon(Icons.save),
                    label: const Text('Update Profile'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.blueAccent,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.blue[50],
      ),
    );
  }
}
