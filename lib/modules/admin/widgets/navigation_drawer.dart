import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/shared_preferences.dart';

class AdminNavigationDrawer extends StatelessWidget {
  const AdminNavigationDrawer({super.key});

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
            child: Text('Admin Panel', style: TextStyle(color: Colors.white, fontSize: 24)),
          ),
          ListTile(
            leading: const Icon(Icons.analytics_outlined),
            title: const Text('Report Analytics'),
            onTap: () => context.go('/analytics'),
          ),
          ListTile(
            leading: const Icon(Icons.topic_outlined),
            title: const Text('User Management'),
            onTap: () => context.go('/users'),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () => context.go('/settings'),
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
