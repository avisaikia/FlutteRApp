class NotificationModel {
  final String id;
  final String recipientId;
  final String role;
  final String message;
  final bool isRead;
  final DateTime timestamp;

  NotificationModel({
    required this.id,
    required this.recipientId,
    required this.role,
    required this.message,
    this.isRead = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      recipientId: json['recipient_id'],
      role: json['role'],
      message: json['message'],
      isRead: json['is_read'] ?? false,
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'recipient_id': recipientId,
    'role': role,
    'message': message,
    'is_read': isRead,
    'timestamp': timestamp.toIso8601String(),
  };
}
