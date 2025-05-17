import 'package:final_project/modules/employee/models/leave_request_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> submitLeaveRequest(LeaveRequestModel request) async {
  final response = await Supabase.instance.client
      .from('leave_requests')
      .insert(request.toJson());

  if (response == null) {
    throw Exception('Failed to insert leave request');
  }
}
