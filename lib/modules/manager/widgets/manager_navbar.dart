import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/shared_preferences.dart';

class ManagerNavigationDrawer extends StatelessWidget {
  const ManagerNavigationDrawer({super.key});

  void _logout(BuildContext context) async {
    // Clear user session from SharedPreferences
    await SessionHelper.clearSession();
    // Optional: if you want to log out admin from Supabase too
    await Supabase.instance.client.auth.signOut();
    // Navigate back to login screen
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text(
              'Admin Panel',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.request_page),
            title: const Text('Leave Request'),
            onTap: () => context.go('/pending-leaves'),
          ),
          ListTile(
            leading: const Icon(Icons.history_edu),
            title: const Text('Leave History'),
            onTap: () => context.go('/manager-leave-history'),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () => context.go('/manager-settings'),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}
