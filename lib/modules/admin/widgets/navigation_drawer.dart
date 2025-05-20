import 'package:final_project/modules/admin/widgets/admin_profile_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/shared_preferences.dart';

class AdminNavigationDrawer extends StatefulWidget {
  const AdminNavigationDrawer({super.key});

  @override
  State<AdminNavigationDrawer> createState() => _AdminNavigationDrawerState();
}

class _AdminNavigationDrawerState extends State<AdminNavigationDrawer> {
  late String? _profileImageUrl;
  late final VoidCallback _profilePicListener;

  @override
  void initState() {
    super.initState();
    loadProfilePicFromSupabase();

    _profilePicListener = () {
      final newValue = SessionHelper.profilePicNotifier.value;
      if (newValue != _profileImageUrl) {
        setState(() {
          _profileImageUrl = newValue;
        });
      }
    };

    SessionHelper.profilePicNotifier.addListener(_profilePicListener);
  }

  @override
  void dispose() {
    SessionHelper.profilePicNotifier.removeListener(_profilePicListener);
    super.dispose();
  }

  Future<void> loadProfilePicFromSupabase() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final response =
        await Supabase.instance.client
            .from('admins')
            .select('profile_pic')
            .eq('id', userId)
            .maybeSingle();

    if (response != null && response['profile_pic'] != null) {
      String url = response['profile_pic'] as String;
      SessionHelper.profilePicNotifier.value = url;
    }
  }

  void _logout(BuildContext context) async {
    await SessionHelper.clearSession();
    await Supabase.instance.client.auth.signOut();
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFF9FAFB),
      child: Column(
        children: [
          const SizedBox(height: 60),
          Center(
            child: Column(
              children: [
                AdminProfileImage(),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => context.push('/profile'),
                  child: const Text(
                    'Edit Profile',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Divider(thickness: 0.5),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 8),
              children: [
                _drawerTile(
                  icon: Icons.analytics_outlined,
                  title: 'Analytics',
                  onTap: () => context.go('/analytics'),
                ),
                _drawerTile(
                  icon: Icons.group_outlined,
                  title: 'User Management',
                  onTap: () => context.go('/users'),
                ),
                _drawerTile(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  onTap: () => context.go('/settings'),
                ),
              ],
            ),
          ),
          const Divider(thickness: 0.5),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: _drawerTile(
              icon: Icons.logout_rounded,
              title: 'Logout',
              iconColor: Colors.redAccent,
              textColor: Colors.redAccent,
              onTap: () => _logout(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color iconColor = Colors.blueAccent,
    Color textColor = Colors.black87,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          leading: Icon(icon, color: iconColor),
          title: Text(
            title,
            style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
          ),
          onTap: onTap,
          hoverColor: Colors.blue.withOpacity(0.1),
          tileColor: Colors.white,
        ),
      ),
    );
  }
}
