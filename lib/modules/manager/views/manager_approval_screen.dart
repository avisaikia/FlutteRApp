import 'package:final_project/core/services/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManagerApprovalScreen extends StatefulWidget {
  const ManagerApprovalScreen({super.key});

  @override
  State<ManagerApprovalScreen> createState() => _ManagerApprovalScreenState();
}

class _ManagerApprovalScreenState extends State<ManagerApprovalScreen> {
  List<dynamic> _leaveRequests = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPendingRequests();
  }

  Future<void> _fetchPendingRequests() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final supabase = Supabase.instance.client;
      final managerId = await SessionHelper.getUserId();
      print("Manager id is: $managerId");
      if (managerId == null) throw Exception('Manager ID not found.');

      final response = await supabase
          .from('leave_requests')
          .select(
            'id, status, start_date, end_date,  employee:users!leave_requests_employee_id_fkey(name)',
          )
          .eq('manager_id', managerId)
          .eq('status', 'pending');

      setState(() {
        _leaveRequests = response;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching pending requests: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleDecision(String requestId, String decision) async {
    try {
      final supabase = Supabase.instance.client;

      // Step 1: Get employee_id for the given request
      final leaveResponse =
          await supabase
              .from('leave_requests')
              .select('employee_id')
              .eq('id', requestId)
              .single();

      final String employeeId =
          leaveResponse['employee_id']; // ✅ Proper declaration

      // Step 2: Update the leave request status
      final updateResponse =
          await supabase
              .from('leave_requests')
              .update({
                'status': decision,
                'decision_date': DateTime.now().toIso8601String(),
              })
              .eq('id', requestId)
              .select();

      if (updateResponse.isEmpty) {
        debugPrint('Update failed or no rows affected.');
      } else {
        debugPrint('Request $requestId updated to $decision');
      }

      // Step 3: Insert notification to employee
      await supabase.from('notifications').insert({
        'recipient_id': employeeId,
        'role': 'employee',
        'message':
            'Your leave request has been ${decision == 'approved' ? 'approved' : 'rejected'}.',
        'timestamp': DateTime.now().toIso8601String(),
        'is_read': false,
      });

      // Step 4: Refresh UI
      await _fetchPendingRequests();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Leave request ${decision.toUpperCase()}')),
      );
    } catch (e) {
      debugPrint('Error handling decision: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update leave request')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Leave Requests'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/manager-dashboard'),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _leaveRequests.isEmpty
              ? const Center(child: Text('No pending requests.'))
              : ListView.builder(
                itemCount: _leaveRequests.length,
                itemBuilder: (context, index) {
                  final request = _leaveRequests[index];
                  final userName = request['employee']['name'];

                  return Card(
                    margin: const EdgeInsets.all(8),
                    child: ListTile(
                      title: Text(
                        '$userName: ${request['start_date']} → ${request['end_date']}',
                      ),

                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed:
                                () =>
                                    _handleDecision(request['id'], 'approved'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed:
                                () =>
                                    _handleDecision(request['id'], 'rejected'),
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
