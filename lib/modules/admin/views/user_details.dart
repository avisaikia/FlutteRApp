import 'package:final_project/modules/admin/controllers/dashboard_controller.dart';
import 'package:final_project/modules/admin/models/admin_user_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:final_project/modules/admin/repositories/admin_repository.dart';

class UserDetailsScreen extends StatelessWidget {
  final String userId;

  const UserDetailsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final repository = context.read<AdminRepository>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/users'); // Go back to the User Management screen
          },
        ),
      ),
      body: FutureBuilder<AdminUserModel?>(
        future: repository.fetchUserById(userId), // Fetch user details by ID
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final user = snapshot.data;

          if (user == null) {
            return const Center(child: Text('User not found.'));
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Name: ${user.name}',
                  style: const TextStyle(fontSize: 18),
                ),
                Text(
                  'Email: ${user.email}',
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  'Role: ${user.role}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // Navigate to edit user screen
                    context.go('/edit-user/${user.id}');
                  },
                  child: const Text('Edit User'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    // Show delete confirmation dialog
                    _showDeleteDialog(context, user.id);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Delete User'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Delete user confirmation dialog
  void _showDeleteDialog(BuildContext context, String userId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete User'),
          content: const Text('Are you sure you want to delete this user?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await context.read<DashboardController>().deleteUser(userId);
                Navigator.of(context).pop(); // Close dialog
                context.go('/users'); // Go back to User Management screen
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
