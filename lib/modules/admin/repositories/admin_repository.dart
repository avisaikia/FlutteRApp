import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/admin_user_model.dart';

class AdminRepository {
  final supabase = Supabase.instance.client;

  // Existing method to create a user
  //Future<void> createUser(AdminUserModel user) async {
  //  await supabase.from('users').insert(user.toJson());
  // }

  Future<void> createUser(AdminUserModel user) async {
    await Supabase.instance.client.from('users').insert(user.toJson());
  }

  // Existing method to get all users
  Future<List<AdminUserModel>> getUsers() async {
    final res = await supabase.from('users').select();
    return (res as List).map((json) => AdminUserModel.fromJson(json)).toList();
  }

  // Fetch single user by ID
  Future<AdminUserModel?> fetchUserById(String userId) async {
    final res = await supabase.from('users').select().eq('id', userId).single();
    return AdminUserModel.fromJson(res);
  }

  // Delete user by ID
  Future<void> deleteUser(String userId) async {
    await supabase.from('users').delete().eq('id', userId);
  }

  Future<void> updateUser(AdminUserModel user) async {
    await supabase
        .from('users')
        .update(user.toJson())
        .eq('id', user.id); // match by ID
  }
}
