import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/admin_summary_card.dart';
import '../widgets/navigation_drawer.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardController>().loadDashboardData();
    });
  }

  Future<void> _loadProfileImage() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final data =
          await Supabase.instance.client
              .from('admins')
              .select('profile_pic')
              .eq('id', user.id)
              .maybeSingle();

      setState(() {
        _profileImageUrl = data?['profile_pic'] ?? '';
      });
    } catch (e) {
      print('Error fetching profile image: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load profile image')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () async {
                final updated = await context.push('/profile');
                if (updated == true) {
                  _loadProfileImage(); // Refresh profile image on return
                }
              },
              child: CircleAvatar(
                radius: 22,
                backgroundImage:
                    _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                        ? NetworkImage(_profileImageUrl!)
                        : const AssetImage('assets/default_avatar.png')
                            as ImageProvider,
              ),
            ),
          ),
        ],
      ),
      drawer: const AdminNavigationDrawer(),
      body: Consumer<DashboardController>(
        builder: (context, controller, _) {
          return RefreshIndicator(
            onRefresh: () => controller.loadDashboardData(),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                AnalyticsSummaryCard(
                  title: 'User Analytics',
                  totalUsers: controller.totalUsers,
                  totalEmployees: controller.totalEmployees,
                  totalManagers: controller.totalManagers,
                  icon: Icons.analytics,
                  onTap: () => context.go('/analytics'),
                ),
                const SizedBox(height: 16),
                const SizedBox(height: 16),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Recently Added Users',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...controller.recentUsers.map((user) {
                          return ListTile(
                            leading: const Icon(Icons.person_outline),
                            title: Text(user.name),
                            subtitle: Text('${user.email} - ${user.role}'),
                            trailing: Text(
                              user.created_at != null
                                  ? '${user.created_at!.toLocal().toString().split(' ').first}'
                                  : '',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            onTap: () => context.go('/user-details/${user.id}'),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const SizedBox(height: 16),

                AdminSummaryCard(
                  title: 'Create User',
                  value: 'Tap to add new employee or manager',
                  icon: Icons.person_add,
                  onTap: () => context.go('/create-user'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
