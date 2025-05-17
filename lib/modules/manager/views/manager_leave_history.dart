import 'package:final_project/core/services/shared_preferences.dart';
import 'package:final_project/modules/manager/controllers/manager_provider.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManagerLeaveHistoryScreen extends StatefulWidget {
  const ManagerLeaveHistoryScreen({super.key});

  @override
  State<ManagerLeaveHistoryScreen> createState() =>
      _ManagerLeaveHistoryScreenState();
}

class _ManagerLeaveHistoryScreenState extends State<ManagerLeaveHistoryScreen> {
  List<dynamic> _leaveHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLeaveHistory();
  }

  Future<void> _fetchLeaveHistory() async {
    try {
      final supabase = Supabase.instance.client;
      final managerId = await SessionHelper.getUserId();
      if (managerId == null) throw Exception("Manager ID not found.");

      final data = await supabase
          .from('leave_requests')
          .select(
            '*, employee:users!leave_requests_employee_id_fkey(name), manager:users!leave_requests_manager_id_fkey(name)',
          )
          .eq('manager_id', managerId)
          .neq('status', 'pending');

      setState(() {
        _leaveHistory = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching leave history: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteLeaveRequest(String leaveRequestId) async {
    try {
      final supabase = Supabase.instance.client;

      await supabase.from('leave_requests').delete().eq('id', leaveRequestId);

      setState(() {
        _leaveHistory.removeWhere(
          (element) => element['id'].toString() == leaveRequestId,
        );
      });

      // Refresh stats
      final provider = Provider.of<ManagerDashboardProvider>(
        context,
        listen: false,
      );
      await provider.refreshData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Leave request deleted successfully')),
      );
    } catch (e) {
      debugPrint('Error deleting leave request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete leave request. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/manager-dashboard'),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _leaveHistory.isEmpty
              ? const Center(child: Text('No leave decisions found.'))
              : ListView.builder(
                itemCount: _leaveHistory.length,
                itemBuilder: (context, index) {
                  final request = _leaveHistory[index];
                  final userName =
                      request['employee']?['name'] ?? 'Unknown Employee';
                  final status = request['status'] ?? 'unknown';
                  final startDate = request['start_date'] ?? '';
                  final endDate = request['end_date'] ?? '';
                  final reason = request['reason'] ?? '';

                  return Card(
                    margin: const EdgeInsets.all(8),
                    child: ListTile(
                      title: Text('$userName: $startDate → $endDate'),
                      subtitle: Text(
                        'Status: ${status.toUpperCase()}\nReason: $reason',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            status == 'approved'
                                ? Icons.check_circle
                                : Icons.cancel,
                            color:
                                status == 'approved'
                                    ? Colors.green
                                    : Colors.red,
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder:
                                    (context) => AlertDialog(
                                      title: const Text('Delete Leave Request'),
                                      content: const Text(
                                        'Are you sure you want to delete this leave request?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () =>
                                                  Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed:
                                              () =>
                                                  Navigator.pop(context, true),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                              );

                              if (confirm == true) {
                                await _deleteLeaveRequest(
                                  request['id'].toString(),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
