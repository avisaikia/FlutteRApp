import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/admin_user_model.dart';
import '../repositories/admin_repository.dart';

class DashboardController extends ChangeNotifier {
  int totalUsers = 0;
  int totalEmployees = 0;
  int totalManagers = 0;

  final AdminRepository _repo = AdminRepository();
  List<AdminUserModel> _recentUsers = [];
  List<AdminUserModel> get recentUsers => _recentUsers;

  DashboardController() {
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    try {
      final users = await _repo.getUsers();

      totalUsers = users.length;
      totalEmployees = users.where((user) => user.role == 'employee').length;
      totalManagers = users.where((user) => user.role == 'manager').length;
      _recentUsers = await fetchRecentUsers();

      notifyListeners();
    } catch (e) {
      print('Error loading dashboard data: $e');
    }
  }

  Future<void> createUser(AdminUserModel user) async {
    await _repo.createUser(user);
    await loadDashboardData(); // Refresh counts after new user is added
  }

  Future<void> deleteUser(String userId) async {
    await _repo.deleteUser(userId);
    await loadDashboardData(); // Refresh after deletion
  }

  Future<List<AdminUserModel>> fetchRecentUsers() async {
    final response = await Supabase.instance.client
        .from('users')
        .select()
        .order('created_at', ascending: false)
        .limit(5);

    return (response as List)
        .map((json) => AdminUserModel.fromJson(json))
        .toList();
  }

  Future<List<AdminUserModel>> fetchAllUsers() => _repo.getUsers();
}
