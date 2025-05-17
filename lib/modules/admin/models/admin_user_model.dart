class AdminUserModel {
  final String id; // UUID or serial ID from Supabase
  final String name; // Full name of the user
  final String email; // Email used for login
  final String role;
  final String password; // 'admin', 'employee', or 'manager'
  final DateTime? created_at;

  AdminUserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.password,
    this.created_at,
  });

  /// Creates an instance from a Supabase JSON response
  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    return AdminUserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      password: json['password'] as String,
      created_at:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : null,
    );
  }

  /// Converts this model into a JSON map for Supabase insertion
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'password': password, // <-- Add this
    };
  }
}
