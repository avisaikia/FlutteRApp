import 'package:final_project/modules/admin/controllers/dashboard_controller.dart';
import 'package:final_project/modules/admin/models/admin_user_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen>
    with SingleTickerProviderStateMixin {
  late Future<List<AdminUserModel>> _usersFuture;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _usersFuture = context.read<DashboardController>().fetchAllUsers();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Employees'), Tab(text: 'Managers')],
        ),
      ),
      body: FutureBuilder<List<AdminUserModel>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final allUsers = snapshot.data ?? [];
          final employees =
              allUsers
                  .where((u) => u.role.toLowerCase() == 'employee')
                  .toList();
          final managers =
              allUsers.where((u) => u.role.toLowerCase() == 'manager').toList();

          return TabBarView(
            controller: _tabController,
            children: [_buildUserList(employees), _buildUserList(managers)],
          );
        },
      ),
    );
  }

  Widget _buildUserList(List<AdminUserModel> users) {
    if (users.isEmpty) {
      return const Center(child: Text('No users found.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        return _UserCard(user: users[index]);
      },
    );
  }
}

class _UserCard extends StatelessWidget {
  final AdminUserModel user;

  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        title: Text(
          user.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(user.email),
        trailing: Chip(
          label: Text(user.role),
          backgroundColor:
              user.role.toLowerCase() == 'manager'
                  ? Colors.blue.shade100
                  : Colors.green.shade100,
        ),
        onTap: () => context.go('/user-details/${user.id}'),
      ),
    );
  }
}
