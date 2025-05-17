import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/employee_user_model.dart';

class EmployeeRepository {
  final supabase = Supabase.instance.client;

  Future<EmployeeUser?> fetchEmployeeProfile() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await supabase
        .from('users')
        .select()
        .eq('id', userId)
        .eq('role', 'employee')
        .single();

    return EmployeeUser.fromMap(response);
  }
}
