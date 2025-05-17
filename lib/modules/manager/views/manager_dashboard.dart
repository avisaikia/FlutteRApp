import 'package:final_project/core/services/shared_preferences.dart';
import 'package:final_project/modules/manager/controllers/manager_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../widgets/manager_navbar.dart';

class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({super.key});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialize();
      _initialized = true;
    }
  }

  Future<void> _initialize() async {
    final userId = await SessionHelper.getUserId();
    if (userId != null) {
      final provider = Provider.of<ManagerDashboardProvider>(
        context,
        listen: false,
      );
      await provider.init(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ManagerDashboardProvider>(
      builder: (context, provider, _) {
        final maxCount =
            provider.totalRequests > 0
                ? provider.totalRequests.toDouble()
                : 1.0;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Manager Dashboard'),
            actions: [
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none),
                    onPressed: () async {
                      await provider.markAllNotificationsAsRead();
                      context.go('/manager-notify/${provider.managerUserId}');
                    },
                  ),
                  if (provider.unreadNotificationCount > 0)
                    Positioned(
                      right: 11,
                      top: 11,
                      child: IgnorePointer(
                        ignoring: true, // this makes it ignore pointer events
                        child: _buildBadge(provider.unreadNotificationCount),
                      ),
                    ),
                ],
              ),
              GestureDetector(
                onTap: () => context.go('/manager-profile'),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: CircleAvatar(
                    backgroundImage: AssetImage('assets/profile_picture.png'),
                  ),
                ),
              ),
            ],
          ),
          drawer: const ManagerNavigationDrawer(),
          body:
              provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      _buildStatisticsCard(provider, maxCount),
                      const SizedBox(height: 20),

                      _buildNavigationCard(
                        icon: Icons.pending_actions,
                        iconColor: Colors.orange,
                        title: 'Pending Leave Requests',
                        subtitle: 'Approve or reject pending leave requests.',
                        route: '/pending-leaves',
                      ),
                      const SizedBox(height: 12),
                      _buildNavigationCard(
                        icon: Icons.history,
                        iconColor: Colors.blue,
                        title: 'Leave History',
                        subtitle:
                            'View history of approved and rejected leaves.',
                        route: '/manager-leave-history',
                      ),
                    ],
                  ),
        );
      },
    );
  }

  Widget _buildBadge(int count) => Container(
    padding: const EdgeInsets.all(2),
    decoration: BoxDecoration(
      color: Colors.red,
      borderRadius: BorderRadius.circular(12),
    ),
    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
    child: Text(
      '$count',
      style: const TextStyle(color: Colors.white, fontSize: 12),
      textAlign: TextAlign.center,
    ),
  );

  Widget _buildStatisticsCard(
    ManagerDashboardProvider provider,
    double maxCount,
  ) => Card(
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatRow(
            'Total Requests',
            provider.totalRequests,
            Colors.blue,
            maxCount,
          ),
          const SizedBox(height: 12),
          _buildStatRow('Approved', provider.approved, Colors.green, maxCount),
          const SizedBox(height: 12),
          _buildStatRow('Rejected', provider.rejected, Colors.red, maxCount),
          const SizedBox(height: 12),
          _buildStatRow('Pending', provider.pending, Colors.orange, maxCount),
        ],
      ),
    ),
  );

  Widget _buildStatRow(String title, int count, Color color, double maxCount) {
    final progress = count / maxCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            minHeight: 12,
            value: progress.clamp(0, 1),
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String route,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () => context.go(route),
      ),
    );
  }
}
