// All imports remain the same except: remove 'file_picker'
import 'package:final_project/modules/employee/controllers/leave_balance_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class ApplyLeaveScreen extends StatefulWidget {
  const ApplyLeaveScreen({super.key});

  @override
  State<ApplyLeaveScreen> createState() => _ApplyLeaveScreenState();
}

class _ApplyLeaveScreenState extends State<ApplyLeaveScreen> {
  final _formKey = GlobalKey<FormState>();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();

  String? _selectedLeaveType;
  String? employeeId;
  String? managerId;
  bool _isBackdated = false;

  List<Map<String, dynamic>> _managers = [];

  @override
  void initState() {
    super.initState();
    _loadUserIdsAndBalance();
    _fetchManagers();
  }

  Future<void> _loadUserIdsAndBalance() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email');
    if (email == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No email found in storage')),
        );
        Navigator.of(context).pop();
      }
      return;
    }

    final response =
        await Supabase.instance.client
            .from('users')
            .select()
            .eq('email', email)
            .single();

    final userId = response['id'];
    await Provider.of<LeaveBalanceProvider>(
      context,
      listen: false,
    ).fetchBalance(userId);

    if (mounted) {
      setState(() {
        employeeId = userId;
      });
    }
  }

  Future<void> _fetchManagers() async {
    try {
      final data = await Supabase.instance.client
          .from('users')
          .select('id, name')
          .eq('role', 'manager');

      setState(() {
        _managers = List<Map<String, dynamic>>.from(data);
      });
    } catch (error) {
      print('Error fetching managers: $error');
    }
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: _isBackdated ? now.subtract(const Duration(days: 30)) : now,
      lastDate: _isBackdated ? now : now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  Future<void> _submitLeaveRequest() async {
    if (_selectedLeaveType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a leave type')),
      );
      return;
    }

    if (managerId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a manager')));
      return;
    }

    if (_startDateController.text.isEmpty || _endDateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start and end dates')),
      );
      return;
    }

    final startDate = DateTime.parse(_startDateController.text);
    final endDate = DateTime.parse(_endDateController.text);
    final now = DateTime.now();

    if (_isBackdated) {
      if (startDate.isAfter(now) || endDate.isAfter(now)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Future dates are not allowed in backdated leave'),
          ),
        );
        return;
      }

      if (startDate.isBefore(now.subtract(const Duration(days: 30)))) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backdated leave can only be within last 30 days'),
          ),
        );
        return;
      }
    } else {
      if (startDate.isBefore(now) || endDate.isBefore(now)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Past dates are not allowed in normal leave'),
          ),
        );
        return;
      }
    }

    // ✅ Validate start <= end
    if (startDate.isAfter(endDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Start date cannot be after end date')),
      );
      return;
    }

    final leaveDays = endDate.difference(startDate).inDays + 1;

    final balanceResponse =
        await Supabase.instance.client
            .from('leave_balances')
            .select()
            .eq('user_id', employeeId!)
            .single();

    final currentUsed = balanceResponse['used_leaves'] ?? 0;
    final totalLeaves = balanceResponse['total_leaves'] ?? 0;
    final remainingLeaves =
        balanceResponse['remaining_leaves'] ?? (totalLeaves - currentUsed);

    // ✅ Prevent negative balance
    if (leaveDays > remainingLeaves) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Insufficient leave balance. You have only $remainingLeaves days left.',
          ),
        ),
      );
      return;
    }

    final uuid = const Uuid().v4();

    try {
      await Supabase.instance.client.from('leave_requests').insert({
        'id': uuid,
        'employee_id': employeeId,
        'manager_id': managerId,
        'leave_type': _selectedLeaveType,
        'start_date': _startDateController.text,
        'end_date': _endDateController.text,
        'status': 'pending',
        'submitted_at': DateTime.now().toIso8601String(),
      });

      await Supabase.instance.client.from('notifications').insert({
        'recipient_id': managerId,
        'role': 'manager',
        'message': 'You have a new leave request from an employee.',
        'timestamp': DateTime.now().toIso8601String(),
        'is_read': false,
      });

      final newUsedLeaves = currentUsed + leaveDays;

      await Supabase.instance.client
          .from('leave_balances')
          .update({
            'used_leaves': newUsedLeaves,
            'remaining_leaves': totalLeaves - newUsedLeaves,
          })
          .eq('user_id', employeeId!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Leave request submitted')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error submitting request: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final leaveBalance = context.watch<LeaveBalanceProvider>().balance;

    if (leaveBalance == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Apply for Leave'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, true), // Indicate success
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Card(
                color: Colors.lightBlue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Leave Balances',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Total Leaves: ${leaveBalance.totalLeaves}'),
                      Text('Used Leaves: ${leaveBalance.usedLeaves}'),
                      Text('Remaining Leaves: ${leaveBalance.remainingLeaves}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Backdated Leave Request'),
                value: _isBackdated,
                onChanged: (value) => setState(() => _isBackdated = value),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedLeaveType,
                decoration: const InputDecoration(
                  labelText: 'Leave Type',
                  border: OutlineInputBorder(),
                ),
                items:
                    ['Casual', 'Sick', 'Other']
                        .map(
                          (type) =>
                              DropdownMenuItem(value: type, child: Text(type)),
                        )
                        .toList(),
                onChanged:
                    (value) => setState(() => _selectedLeaveType = value),
                validator:
                    (value) =>
                        value == null ? 'Please select a leave type' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: managerId,
                decoration: const InputDecoration(
                  labelText: 'Select Manager',
                  border: OutlineInputBorder(),
                ),
                items:
                    _managers
                        .map(
                          (manager) => DropdownMenuItem<String>(
                            value: manager['id'],
                            child: Text(manager['name']),
                          ),
                        )
                        .toList(),
                onChanged: (val) => setState(() => managerId = val),
                validator:
                    (value) => value == null ? 'Please select a manager' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _startDateController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Start Date',
                  border: OutlineInputBorder(),
                ),
                onTap: () => _pickDate(_startDateController),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _endDateController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'End Date',
                  border: OutlineInputBorder(),
                ),
                onTap: () => _pickDate(_endDateController),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _submitLeaveRequest();
                  }
                },
                icon: const Icon(Icons.send),
                label: const Text('Submit Leave Request'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
