import 'package:final_project/core/services/shared_preferences.dart';
import 'package:final_project/modules/employee/models/leave_balance_model.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmployeeDashboardProvider with ChangeNotifier {
  final supabase = Supabase.instance.client;

  String? userId;
  int unreadNotificationCount = 0;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  LeaveBalance? _leaveBalance;
  LeaveBalance? get leaveBalance => _leaveBalance;

  // Simple in-memory cache to avoid refetching if data exists
  bool _hasLoadedLeaveBalance = false;

  Future<void> initialize(String userId) async {
    this.userId = userId;
    _isLoading = true;
    notifyListeners();

    await fetchUnreadNotificationCount();

    if (!_hasLoadedLeaveBalance) {
      await fetchLeaveBalance(userId);
      _hasLoadedLeaveBalance = true;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> initializeWithUserId() async {
    if (_isInitialized) return;
    final id = await SessionHelper.getUserId();
    if (id == null) return;
    await initialize(id);
    _isInitialized = true;
  }

  Future<void> fetchLeaveBalance(String userId) async {
    try {
      final response =
          await supabase
              .from('leave_balances')
              .select()
              .eq('user_id', userId)
              .maybeSingle();

      if (response != null) {
        _leaveBalance = LeaveBalance.fromJson(response);
      } else {
        _leaveBalance = LeaveBalance(
          id: '0',
          userId: userId,
          totalLeaves: 0,
          usedLeaves: 0,
        );
      }
      notifyListeners();
    } catch (e) {
      print('Error fetching leave balance: $e');
    }
  }

  Future<void> fetchUnreadNotificationCount() async {
    final response = await supabase
        .from('notifications')
        .select('id')
        .eq('recipient_id', userId!)
        .eq('role', 'employee')
        .eq('is_read', false);

    unreadNotificationCount = response.length;
  }

  Future<void> markAllNotificationsAsRead() async {
    await supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('recipient_id', userId!)
        .eq('role', 'employee')
        .eq('is_read', false);

    unreadNotificationCount = 0;
    notifyListeners();
  }

  // Future<void> markAllNotificationsAsRead() async {
  //   if (userId == null) return;

  //   try {
  //     await supabase
  //        .from('notifications')
  //         .update({'is_read': true})
  //         .eq('recipient_id', userId!)
  //        .eq('role', 'employee')
  //         .eq('is_read', false);

  //    unreadNotificationCount = 0;
  //    notifyListeners();
  //   } catch (e) {
  //     print("Error marking notifications as read: $e");
  //   }
  //  }
}
