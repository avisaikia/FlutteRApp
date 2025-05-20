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
  Set<String> _selectedLeaveIds = {};

  bool _isSelectionMode = false;

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

  Future<void> _deleteSelectedLeaves() async {
    if (_selectedLeaveIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Deletion'),
            content: Text(
              'Are you sure you want to delete ${_selectedLeaveIds.length} selected leave(s)?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    try {
      await Supabase.instance.client
          .from('leave_requests')
          .delete()
          .filter('id', 'in', _selectedLeaveIds.toList());
      setState(() {
        _leaveRequests.removeWhere(
          (leave) => _selectedLeaveIds.contains(leave['id']),
        );
        _selectedLeaveIds.clear();
        _isSelectionMode = false;
      });
    } catch (e) {
      print('Error deleting leave requests: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isSelectionMode ? 'Select Leaves' : 'Leave History'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.go('/employee-dashboard'),
        ),

        actions: [
          if (!_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.select_all),
              tooltip: 'Select Leaves',
              onPressed: () {
                setState(() {
                  _isSelectionMode = true;
                });
              },
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.select_all),
              tooltip: 'Select All',
              onPressed: () {
                setState(() {
                  _selectedLeaveIds =
                      _leaveRequests
                          .map<String>((leave) => leave['id'] as String)
                          .toSet();
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Delete Selected',
              onPressed:
                  _selectedLeaveIds.isEmpty ? null : _deleteSelectedLeaves,
            ),
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Cancel Selection',
              onPressed: () {
                setState(() {
                  _isSelectionMode = false;
                  _selectedLeaveIds.clear();
                });
              },
            ),
          ],
        ],
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
                  final leaveId = leave['id'];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color:
                        _selectedLeaveIds.contains(leaveId)
                            ? Colors.blue.shade100
                            : null,

                    child: ListTile(
                      onLongPress: () {
                        setState(() {
                          _isSelectionMode = true;
                          _selectedLeaveIds.add(leaveId);
                        });
                      },
                      onTap: () {
                        if (_isSelectionMode) {
                          setState(() {
                            if (_selectedLeaveIds.contains(leaveId)) {
                              _selectedLeaveIds.remove(leaveId);
                            } else {
                              _selectedLeaveIds.add(leaveId);
                            }
                          });
                        }
                      },
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
