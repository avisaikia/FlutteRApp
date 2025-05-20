import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/admin_user_model.dart';
import '../repositories/admin_repository.dart';

class DashboardController extends ChangeNotifier {
  int totalUsers = 0;
  int totalEmployees = 0;
  int totalManagers = 0;

  final AdminRepository _repo = AdminRepository();

  List<AdminUserModel> _allUsers = [];
  List<AdminUserModel> get allUsers => _allUsers;

  List<AdminUserModel> _recentUsers = [];
  List<AdminUserModel> get recentUsers => _recentUsers;

  DashboardController() {
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    try {
      _allUsers = await _repo.getUsers();

      totalUsers = _allUsers.length;
      totalEmployees =
          _allUsers
              .where((user) => user.role.toLowerCase() == 'employee')
              .length;
      totalManagers =
          _allUsers
              .where((user) => user.role.toLowerCase() == 'manager')
              .length;
      _recentUsers = await fetchRecentUsers();

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    }
  }

  Future<void> createUser(AdminUserModel user) async {
    await _repo.createUser(user);
    await loadDashboardData(); // Refresh counts and list after new user is added
  }

  Future<void> deleteUser(String userId) async {
    await _repo.deleteUser(userId);
    await loadDashboardData(); // Refresh list and counts after deletion
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
}
