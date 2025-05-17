class LeaveRequestModel {
  final String id;
  final String employeeId;
  final String managerId;
  final String leaveType;
  final String startDate;
  final String endDate;
  final String reason;
  final String status;

  final DateTime createdAt;

  LeaveRequestModel({
    required this.id,
    required this.employeeId,
    required this.managerId,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.reason,

    this.status = 'Pending',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'employee_id': employeeId,
    'manager_id': managerId,
    'leave_type': leaveType,
    'start_date': startDate,
    'end_date': endDate,
    'reason': reason,
    'status': status,

    'created_at': createdAt.toIso8601String(),
  };

  static fromJson(leaveHistory) {}
}
