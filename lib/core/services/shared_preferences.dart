import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionHelper {
  // Holds a string like "Role: manager, Email: example@xyz.com"
  static final ValueNotifier<String?> notifier = ValueNotifier<String?>(null);

  // Call this once at app launch (e.g., in main()) to restore the session
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedRole = prefs.getString('user_role');
    final savedEmail = prefs.getString('user_email');

    if (savedRole != null && savedEmail != null) {
      notifier.value = 'Role: $savedRole, Email: $savedEmail';
    } else {
      notifier.value = null;
    }
  }

  // Save session for any user role: admin, employee, manager
  static Future<void> saveUserSession(
    String role,
    String email,
    String userId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role', role);
    await prefs.setString('user_email', email);
    await prefs.setString('user_id', userId); // New line
    notifier.value = 'Role: $role, Email: $email';
  }

  // Clear all saved session values
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_role');
    await prefs.remove('user_email');
    await prefs.remove('user_id'); // Clear stored ID
    notifier.value = null;
  }

  // Get only the role (admin, employee, manager)
  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_role');
  }

  // Get only the email
  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_email');
  }

  // Get user ID from the email stored in session
  // Get user ID from SharedPreferences
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id'); //
  }

  Future<void> saveLoggedInEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('logged_in_email', email);
  }

  Future<void> logoutUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('logged_in_email');
  }
}
