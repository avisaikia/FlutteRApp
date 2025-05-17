class EmployeeUser {
  final String id;
  final String name;
  final String email;
  final String role;

  EmployeeUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory EmployeeUser.fromMap(Map<String, dynamic> map) {
    return EmployeeUser(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      role: map['role'],
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'email': email, 'role': role};
  }
}
