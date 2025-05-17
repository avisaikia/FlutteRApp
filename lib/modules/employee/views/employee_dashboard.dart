import 'package:final_project/core/services/shared_preferences.dart';
import 'package:final_project/modules/employee/widgets/employee_navbar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmployeeDashboard extends StatefulWidget {
  const EmployeeDashboard({super.key});

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  final supabase = Supabase.instance.client;
  String? employeeUserId;
  int unreadNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    loadEmployeeIdAndNotifications();
  }

  Future<void> loadEmployeeIdAndNotifications() async {
    final id = await SessionHelper.getUserId();
    if (id != null) {
      setState(() {
        employeeUserId = id;
      });
      await fetchUnreadNotificationCount();
    }
  }

  Future<void> fetchUnreadNotificationCount() async {
    if (employeeUserId == null) return;

    final response = await supabase
        .from('notifications')
        .select('id')
        .eq('recipient_id', employeeUserId!)
        .eq('role', 'employee')
        .eq('is_read', false);

    if (mounted) {
      setState(() {
        unreadNotificationCount = response.length;
      });
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    if (employeeUserId == null) return;

    await Supabase.instance.client
        .from('notifications')
        .update({'is_read': true})
        .eq('recipient_id', employeeUserId!)
        .eq('role', 'employee')
        .eq('is_read', false);

    if (mounted) {
      setState(() {
        unreadNotificationCount = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Dashboard'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none),
                tooltip: 'Notifications',
                onPressed: () async {
                  if (employeeUserId != null) {
                    // Mark notifications as read and clear badge immediately
                    await markAllNotificationsAsRead();
                    // Navigate after clearing count
                    context.go('/employee-notify/$employeeUserId');
                  }
                },
              ),
              if (unreadNotificationCount > 0)
                Positioned(
                  right: 11,
                  top: 11,
                  child: IgnorePointer(
                    ignoring: true, // makes the badge not block taps
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        '$unreadNotificationCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: GestureDetector(
              onTap: () => context.go('/employee-profile'),
              child: const CircleAvatar(
                backgroundImage: AssetImage('assets/profile_picture.png'),
              ),
            ),
          ),
        ],
      ),
      drawer: const EmployeeNavigationDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text(
              'Welcome Back!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    LeaveStat(title: "Taken", value: "4"),
                    LeaveStat(title: "Remaining", value: "10"),
                    LeaveStat(title: "Pending", value: "2"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _DashboardActionCard(
                    icon: Icons.note_add,
                    label: 'Apply for Leave',
                    onTap: () => context.go('/apply-leave'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _DashboardActionCard(
                    icon: Icons.history,
                    label: 'Leave History',
                    onTap: () => context.go('/leave-history'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class LeaveStat extends StatelessWidget {
  final String title;
  final String value;

  const LeaveStat({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}

class _DashboardActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DashboardActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 32, color: Theme.of(context).primaryColor),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
