import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
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
  final _reasonController = TextEditingController();

  String? _selectedLeaveType;
  String? employeeId;
  String? managerId; // selected manager id
  bool _loading = true;

  List<Map<String, dynamic>> _managers = [];

  @override
  void initState() {
    super.initState();
    _loadUserIds();
    _fetchManagers();
  }

  Future<void> _loadUserIds() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email');

    if (email == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No email found in storage')),
        );
        context.go('/login');
      }
      return;
    }

    final response =
        await Supabase.instance.client
            .from('users')
            .select()
            .eq('email', email)
            .single();

    setState(() {
      employeeId = response['id'];
      _loading = false;
    });
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
      // handle error here
      print('Error fetching managers: $error');
    }
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  Future<void> _submitLeaveRequest() async {
    if (managerId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a manager')));
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
        'reason': _reasonController.text,
        'status': 'pending',
        'submitted_at': DateTime.now().toIso8601String(),
      });

      final response = await Supabase.instance.client
          .from('notifications')
          .insert({
            'recipient_id': managerId,
            'role': 'manager',
            'message': 'You have a new leave request from an employee.',
            'timestamp': DateTime.now().toIso8601String(),
            'is_read': false,
          });

      print('Notification insert response: $response');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Leave request submitted')),
        );
        context.go('/employee-dashboard');
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
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Apply for Leave'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/employee-dashboard'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                value: _selectedLeaveType,
                items:
                    ['Casual', 'Sick', 'Earned', 'Maternity', 'Other']
                        .map(
                          (type) =>
                              DropdownMenuItem(value: type, child: Text(type)),
                        )
                        .toList(),
                onChanged:
                    (value) => setState(() => _selectedLeaveType = value),
                decoration: const InputDecoration(
                  labelText: 'Leave Type',
                  border: OutlineInputBorder(),
                ),
                validator:
                    (value) =>
                        value == null ? 'Please select a leave type' : null,
              ),
              const SizedBox(height: 16),

              // ** Manager Selection Dropdown **
              DropdownButtonFormField<String>(
                value: managerId,
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
                decoration: const InputDecoration(
                  labelText: 'Select Manager',
                  border: OutlineInputBorder(),
                ),
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
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Select a start date'
                            : null,
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
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Select an end date'
                            : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Reason (optional)',
                  border: OutlineInputBorder(),
                ),
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
