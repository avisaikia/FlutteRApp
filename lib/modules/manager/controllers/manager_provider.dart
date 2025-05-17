import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManagerDashboardProvider extends ChangeNotifier {
  final SupabaseClient supabase = Supabase.instance.client;

  String? managerUserId;
  bool _isLoading = false;
  bool _dataLoaded = false;

  int unreadNotificationCount = 0;
  int totalRequests = 0;
  int approved = 0;
  int rejected = 0;
  int pending = 0;
  List<Map<String, dynamic>> recentRequests = [];

  bool get isLoading => _isLoading;
  bool get isDataLoaded => _dataLoaded;

  Future<void> init(String userId) async {
    managerUserId = userId;
    await refreshData();
    _dataLoaded = true;
  }

  Future<void> refreshData({bool showLoader = false}) async {
    if (showLoader) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      await Future.wait([
        fetchUnreadNotificationCount(),
        fetchLeaveStatistics(),
      ]);
      _dataLoaded = true;
    } catch (e) {
      debugPrint('Error refreshing data: $e');
    } finally {
      if (showLoader) {
        _isLoading = false;
        notifyListeners();
      } else {
        notifyListeners();
      }
    }
  }

  Future<void> fetchUnreadNotificationCount() async {
    final response = await supabase
        .from('notifications')
        .select('id')
        .eq('recipient_id', managerUserId!)
        .eq('role', 'manager')
        .eq('is_read', false);

    unreadNotificationCount = response.length;
  }

  Future<void> markAllNotificationsAsRead() async {
    await supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('recipient_id', managerUserId!)
        .eq('role', 'manager')
        .eq('is_read', false);

    unreadNotificationCount = 0;
    notifyListeners();
  }

  Future<void> fetchLeaveStatistics() async {
    final data = await supabase
        .from('leave_requests')
        .select('status')
        .eq('manager_id', managerUserId!);

    totalRequests = data.length;
    approved = data.where((e) => e['status'] == 'approved').length;
    rejected = data.where((e) => e['status'] == 'rejected').length;
    pending = data.where((e) => e['status'] == 'pending').length;
  }
}
