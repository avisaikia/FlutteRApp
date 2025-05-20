import 'package:final_project/core/services/shared_preferences.dart';
import 'package:final_project/modules/employee/controllers/employee_dash_provider.dart';
import 'package:final_project/modules/employee/views/employee_profile.dart';

import 'package:final_project/modules/employee/widgets/employee_navbar.dart';

import 'package:final_project/modules/employee/widgets/leave_balance_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class EmployeeDashboard extends StatefulWidget {
  const EmployeeDashboard({super.key});

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
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
      final dashboardProvider = Provider.of<EmployeeDashboardProvider>(
        context,
        listen: false,
      );
      await dashboardProvider.initialize(userId);

      final profileProvider = Provider.of<EmployeeProfileProvider>(
        context,
        listen: false,
      );
      await profileProvider.loadProfile();

      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EmployeeDashboardProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Employee Dashboard'),
            actions: [
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none),
                    onPressed: () async {
                      await provider.markAllNotificationsAsRead();
                      context.go('/employee-notify/${provider.userId}');
                    },
                  ),
                  if (provider.unreadNotificationCount > 0)
                    Positioned(
                      right: 11,
                      top: 11,
                      child: IgnorePointer(
                        ignoring: true,
                        child: _buildBadge(provider.unreadNotificationCount),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 7),
            ],
          ),
          drawer: const EmployeeNavigationDrawer(),
          body:
              provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (provider.leaveBalance != null)
                        LeaveBalanceCard(leaveBalance: provider.leaveBalance!),

                      const SizedBox(height: 20),

                      _buildActionCard(
                        icon: Icons.note_add,
                        label: 'Apply for Leave',
                        onTap: () async {
                          if (!mounted) return;
                          final result = await context.push('/apply-leave');
                          FocusScope.of(context).unfocus();
                          if (result == true &&
                              mounted &&
                              provider.userId != null) {
                            await provider.fetchLeaveBalance(provider.userId!);
                          }
                        },
                      ),

                      const SizedBox(height: 12),

                      _buildActionCard(
                        icon: Icons.history,
                        label: 'Leave History',
                        onTap: () async {
                          final result = await context.push('/leave-history');
                          if (result == true &&
                              mounted &&
                              provider.userId != null) {
                            await provider.fetchLeaveBalance(provider.userId!);
                          }
                        },
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

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) => Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    elevation: 4,
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: onTap,
      child: SizedBox(
        height: 150,
        child: Center(child: _ActionCardContent(icon: icon, label: label)),
      ),
    ),
  );
}

class _ActionCardContent extends StatelessWidget {
  const _ActionCardContent({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 40, color: Theme.of(context).primaryColor),
        const SizedBox(height: 12),
        Text(label, style: const TextStyle(fontSize: 16)),
      ],
    );
  }
}
