import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:final_project/modules/admin/models/admin_user_model.dart';
import 'package:final_project/modules/admin/repositories/admin_repository.dart';

class EditUserScreen extends StatefulWidget {
  final String userId;
  const EditUserScreen({super.key, required this.userId});

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  bool _obscurePassword = true;

  String? _role;

  bool _loading = true;
  AdminUserModel? _user;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await context.read<AdminRepository>().fetchUserById(
      widget.userId,
    );

    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User not found')));
        context.go('/users');
      }
      return;
    }

    _user = user;
    _nameController.text = user.name;
    _emailController.text = user.email;
    _passwordController.text = user.password;

    _role = user.role;

    setState(() => _loading = false);
  }

  Future<void> _updateUser() async {
    if (!_formKey.currentState!.validate()) return;

    final updatedUser = AdminUserModel(
      id: _user!.id,
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      role: _role!,
      password:
          _passwordController.text.trim().isEmpty
              ? _user!.password
              : _passwordController.text.trim(),
    );

    await context.read<AdminRepository>().updateUser(updatedUser);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User updated successfully!')),
      );
      context.go('/users');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_user == null) {
      return const Scaffold(body: Center(child: Text('User not found')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit User'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/users'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator:
                    (val) => val == null || val.isEmpty ? 'Enter name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator:
                    (val) => val == null || val.isEmpty ? 'Enter email' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: const [
                  DropdownMenuItem(value: 'employee', child: Text('Employee')),
                  DropdownMenuItem(value: 'manager', child: Text('Manager')),
                ],
                onChanged: (val) => setState(() => _role = val),
                validator:
                    (val) =>
                        val == null || val.isEmpty ? 'Select a role' : null,
              ),
              const SizedBox(height: 24),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePassword,
              ),
              ElevatedButton(
                onPressed: _updateUser,
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
