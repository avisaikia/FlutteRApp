import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/admin_summary_card.dart';
import '../widgets/navigation_drawer.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardController>().loadDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notification_important_rounded),
                onPressed: () {
                  // You can later navigate to notifications screen here
                },
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: const Text(
                    '3', // Static for now
                    style: TextStyle(color: Colors.white, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
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

                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: const Color.fromARGB(255, 255, 250, 206),
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
                            leading: const Icon(Icons.person_4),
                            title: Text(user.name),
                            subtitle: Text('${user.email} - ${user.role}'),
                            trailing: Text(
                              user.created_at != null
                                  ? user.created_at!
                                      .toLocal()
                                      .toString()
                                      .split(' ')
                                      .first
                                  : '',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                AdminSummaryCard(
                  title: 'Create User',
                  value: 'Tap to add new employee or manager',
                  icon: Icons.person_add,
                  color: Colors.purple,
                  onTap: () => context.go('/create-user'),
                ),

                const SizedBox(height: 16),

                AdminSummaryCard(
                  title: 'Reports',
                  value: 'See Reports',
                  icon: Icons.report,
                  color: Colors.deepOrangeAccent,
                  //  onTap: () => context.go(''),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
