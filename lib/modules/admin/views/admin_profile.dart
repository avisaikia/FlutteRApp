import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _dobController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _showPasswordFields = false;
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
      _profileImageUrl = data['profile_pic'];
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

    try {
      await Supabase.instance.client.storage
          .from('profilepics')
          .upload(
            filePath,
            _selectedImage!,
            fileOptions: const FileOptions(upsert: true),
          );

      final publicUrl = Supabase.instance.client.storage
          .from('profilepics')
          .getPublicUrl(filePath);

      setState(() {
        _profileImageUrl = publicUrl;
        _isUpdated = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _updateProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      if (_selectedImage != null) {
        await _uploadProfileImage(user.id);
      }

      await Supabase.instance.client.from('admins').upsert({
        'id': user.id,
        'name': _nameController.text,
        'email': _emailController.text,
        'dob': _selectedDate?.toIso8601String(),
        'profile_pic': _profileImageUrl ?? '',
      });

      if (_showPasswordFields) {
        final newPassword = _newPasswordController.text.trim();
        final confirmPassword = _confirmPasswordController.text.trim();

        if (newPassword != confirmPassword) {
          _showError('Passwords do not match.');
          return;
        }

        if (newPassword.length < 6) {
          _showError('Password must be at least 6 characters.');
          return;
        }

        await Supabase.instance.client.auth.updateUser(
          UserAttributes(password: newPassword),
        );
        _showSuccess('Password updated successfully.');
      }

      _isUpdated = true;
      _showSuccess('Profile updated successfully!');
      Navigator.pop(context, _isUpdated);
    } catch (e) {
      _showError('Error updating profile: $e');
    }
  }

  Widget _buildModernInputField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey[700]),
        filled: true,
        fillColor: const Color.fromARGB(255, 255, 255, 255),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 20,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.purple, // Purple outline color
            width: 2, // Thickness of the outline
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.purple.shade700, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.purple.shade300, width: 1.5),
        ),
        floatingLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _isUpdated);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Profile'),
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
                child: Text('Error loading profile: ${snapshot.error}'),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
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
                          backgroundColor: Colors.grey[200],
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.colorScheme.primary,
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.edit,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),
                  _buildModernInputField(
                    _nameController,
                    'Full Name',
                    Icons.person,
                  ),
                  const SizedBox(height: 20),
                  _buildModernInputField(
                    _emailController,
                    'Email',
                    Icons.email,
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: _pickDateOfBirth,
                    child: AbsorbPointer(
                      child: _buildModernInputField(
                        _dobController,
                        'Date of Birth',
                        Icons.calendar_today,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    initialValue: '****',
                    enabled: false,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock, color: Colors.grey[700]),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Colors.purple.shade300,
                          width: 1.5,
                        ),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Colors.purple.shade300,
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Colors.purple.shade700,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed:
                          () => setState(
                            () => _showPasswordFields = !_showPasswordFields,
                          ),
                      icon: Icon(
                        _showPasswordFields ? Icons.close : Icons.edit,
                        size: 18,
                      ),
                      label: Text(
                        _showPasswordFields
                            ? 'Cancel Password Change'
                            : 'Change Password',
                      ),
                    ),
                  ),
                  if (_showPasswordFields) ...[
                    _buildModernInputField(
                      _newPasswordController,
                      'New Password',
                      Icons.lock_open,
                    ),
                    const SizedBox(height: 20),
                    _buildModernInputField(
                      _confirmPasswordController,
                      'Confirm Password',
                      Icons.lock_outline,
                    ),
                    const SizedBox(height: 20),
                  ],
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _updateProfile,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Changes'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
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
}
