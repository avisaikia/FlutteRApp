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

  final String employeeName; // <--- Add this field for manager use

  LeaveRequestModel({
    required this.id,
    required this.employeeId,
    required this.managerId,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.reason,
    this.status = 'Pending',
    this.employeeName = 'Unknown',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory LeaveRequestModel.fromJson(Map<String, dynamic> json) {
    return LeaveRequestModel(
      id: json['id'],
      employeeId: json['employee_id'],
      managerId: json['manager_id'],
      leaveType: json['leave_type'],
      startDate: json['start_date'],
      endDate: json['end_date'],
      reason: json['reason'],
      status: json['status'] ?? 'Pending',
      employeeName: json['employee']?['name'] ?? 'Unknown',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

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
}
