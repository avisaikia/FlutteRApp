import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class LeaveHistoryScreen extends StatefulWidget {
  const LeaveHistoryScreen({super.key});

  @override
  State<LeaveHistoryScreen> createState() => _LeaveHistoryScreenState();
}

class _LeaveHistoryScreenState extends State<LeaveHistoryScreen> {
  List<dynamic> _leaveRequests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLeaveHistory();
  }

  Future<void> _loadLeaveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.getString('user_email');
    final userId = prefs.getString('user_id');

    if (userId == null) {
      return;
    }

    final leaveResponse = await Supabase.instance.client
        .from('leave_requests')
        .select('*')
        .order('submitted_at', ascending: false);

    print('All leave requests: $leaveResponse');

    print('Leave requests response: $leaveResponse');
    print('Type: ${leaveResponse.runtimeType}');

    setState(() {
      _leaveRequests = leaveResponse;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/employee-dashboard'),
        ),
      ),
      body:
          _leaveRequests.isEmpty
              ? const Center(child: Text('No leave requests found.'))
              : ListView.builder(
                itemCount: _leaveRequests.length,
                itemBuilder: (context, index) {
                  final leave = _leaveRequests[index];
                  final formattedStart = DateFormat(
                    'MMM d, yyyy',
                  ).format(DateTime.parse(leave['start_date']));
                  final formattedEnd = DateFormat(
                    'MMM d, yyyy',
                  ).format(DateTime.parse(leave['end_date']));

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      title: Text('${leave['leave_type']} Leave'),
                      subtitle: Text(
                        '$formattedStart → $formattedEnd\n${leave['reason'] ?? ''}',
                      ),
                      trailing: Text(
                        leave['status'].toString().toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(leave['status']),
                        ),
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }
}
