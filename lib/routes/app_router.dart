import 'package:final_project/modules/admin/views/edit_user.dart';
import 'package:final_project/modules/admin/views/user_details.dart';
import 'package:final_project/modules/employee/views/employee_notify.dart';
import 'package:final_project/modules/employee/views/employee_profile.dart';
import 'package:final_project/modules/employee/views/leave_history.dart';
import 'package:final_project/modules/employee/views/leave_request.dart';
import 'package:final_project/modules/manager/views/manager_approval_screen.dart';
import 'package:final_project/modules/manager/views/manager_leave_history.dart';
import 'package:final_project/modules/manager/views/manager_profile.dart';
import 'package:final_project/modules/manager/views/manager_notify.dart';
import 'package:go_router/go_router.dart';
import '../core/services/shared_preferences.dart';
import '../modules/admin/views/dashboard_screen.dart';
import '../modules/admin/views/report_analytics.dart';
import '../modules/admin/views/settings.dart';
import '../modules/splash_screen.dart';
import '../modules/admin/views/user_management.dart';
import '../modules/admin/views/create_user.dart';
import '../modules/admin/views/admin_profile.dart';
import '../modules/employee/views/employee_dashboard.dart';
import '../modules/employee/views/employee_settings.dart';
import '../modules/login_screen.dart';
import '../modules/manager/views/manager_dashboard.dart';
import '../modules/manager/views/manager_settings.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  refreshListenable: SessionHelper.notifier,

  routes: [
    GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),

    // Admin Module
    GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
    GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
    GoRoute(path: '/analytics', builder: (_, __) => const AnalyticsScreen()),
    GoRoute(path: '/users', builder: (_, __) => const UserManagementScreen()),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),

    GoRoute(
      path: '/create-user',
      builder: (_, __) => const UserCreationScreen(),
    ),
    GoRoute(
      path: '/user-details/:userId',
      builder: (context, state) {
        final userId = state.pathParameters['userId']!;
        return UserDetailsScreen(userId: userId);
      },
    ),
    GoRoute(
      path: '/edit-user/:userId',
      builder: (context, state) {
        final userId = state.pathParameters['userId']!;
        return EditUserScreen(userId: userId);
      },
    ),

    // Employee Module
    GoRoute(
      path: '/employee-dashboard',
      builder: (_, __) => const EmployeeDashboard(),
    ),
    GoRoute(
      path: '/employee-settings',
      builder: (_, __) => const EmployeeSettings(),
    ),
    GoRoute(
      path: '/employee-profile',
      builder: (_, __) => const EmployeeProfilePage(),
    ),
    GoRoute(path: '/apply-leave', builder: (_, __) => const ApplyLeaveScreen()),
    GoRoute(
      path: '/leave-history',
      builder: (_, __) => const LeaveHistoryScreen(),
    ),

    GoRoute(path: '/manager-dashboard', builder: (_, __) => ManagerDashboard()),
    GoRoute(
      path: '/manager-notify/:userId',
      builder: (context, state) {
        final userId = state.pathParameters['userId']!;
        return NotificationsScreen(userId: userId, role: 'employee');
      },
    ),

    GoRoute(
      path: '/employee-notify/:userId',
      builder: (context, state) {
        final userId = state.pathParameters['userId']!;
        return EmployeeNotificationsScreen(userId: userId, role: 'manager');
      },
    ),

    GoRoute(
      path: '/manager-settings',
      builder: (_, __) => const ManagerSettings(),
    ),
    GoRoute(
      path: '/manager-profile',
      builder: (_, __) => const ManagerProfilePage(),
    ),
    GoRoute(
      path: '/pending-leaves',
      builder: (context, state) => const ManagerApprovalScreen(),
    ),
    GoRoute(
      path: '/manager-leave-history',
      builder: (context, state) => const ManagerLeaveHistoryScreen(),
    ),

    // Manager notifications route
    GoRoute(
      path: '/manager-notify/:id',
      builder:
          (context, state) => NotificationsScreen(
            userId: state.pathParameters['id']!,
            role: 'manager',
          ),
    ),

    // Employee notifications route
    GoRoute(
      path: '/employee-notify/:id',
      builder:
          (context, state) => EmployeeNotificationsScreen(
            userId: state.pathParameters['id']!,
            role: 'employee',
          ),
    ),
  ],
);
