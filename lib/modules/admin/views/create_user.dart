import 'package:final_project/modules/admin/controllers/dashboard_controller.dart';
import 'package:final_project/modules/admin/models/admin_user_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class UserCreationScreen extends StatefulWidget {
  const UserCreationScreen({super.key});

  @override
  UserCreationScreenState createState() => UserCreationScreenState();
}

class UserCreationScreenState extends State<UserCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _role = 'employee';

  Future<void> _createUser() async {
    final controller = context.read<DashboardController>();

    final newUser = AdminUserModel(
      id: Uuid().v4(), // Or use Supabase-generated ID if needed
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      role: _role!, // This must be non-null
    );

    try {
      await controller.createUser(newUser); // Uses DashboardController
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User created successfully!')),
        );
        context.go('/dashboard');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create User'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed:
              () => context.go('/dashboard'), // Manual back using GoRouter
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Please enter the name'
                            : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Please enter the email'
                            : null,
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Please enter the password'
                            : null,
              ),
              DropdownButton<String>(
                value: _role,
                onChanged: (String? newValue) {
                  setState(() {
                    _role = newValue!;
                  });
                },
                items:
                    ['employee', 'manager'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _createUser();
                  }
                },
                child: const Text('Create User'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
