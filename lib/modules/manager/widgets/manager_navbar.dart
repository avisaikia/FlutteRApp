import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/shared_preferences.dart';

class ManagerNavigationDrawer extends StatefulWidget {
  const ManagerNavigationDrawer({super.key});

  @override
  State<ManagerNavigationDrawer> createState() =>
      _ManagerNavigationDrawerState();
}

class _ManagerNavigationDrawerState extends State<ManagerNavigationDrawer> {
  String? _profileImageUrl;
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
            .from('users')
            .select('manager-pics')
            .eq('id', userId)
            .maybeSingle();

    if (response != null && response['manager-pics'] != null) {
      String url = response['manager-pics'] as String;
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
                ValueListenableBuilder<String?>(
                  valueListenable: SessionHelper.profilePicNotifier,
                  builder: (context, imageUrl, _) {
                    return CircleAvatar(
                      radius: 60,
                      backgroundImage:
                          (imageUrl != null && imageUrl.isNotEmpty)
                              ? NetworkImage(imageUrl)
                              : const AssetImage(
                                    'assets/images/default_avatar.png',
                                  )
                                  as ImageProvider,
                    );
                  },
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => context.push('/manager-profile'),
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
                  icon: Icons.pending_actions_outlined,
                  title: 'Pending Requests',
                  onTap: () => context.go('/pending-leaves'),
                ),
                _drawerTile(
                  icon: Icons.history,
                  title: 'Leave History',
                  onTap: () => context.go('/manager-leave-history'),
                ),
                _drawerTile(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  onTap: () => context.go('/manager-settings'),
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
