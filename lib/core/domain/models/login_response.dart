class LoginResponse {
  final int id;
  final String token;
  final String name;
  final String phone;
  final String role;
  final String tenantName;

  LoginResponse({
    required this.id,
    required this.token,
    required this.name,
    required this.phone,
    required this.role,
    required this.tenantName,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      id: json['id'] ?? 0,
      token: json['token'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? '',
      tenantName: json['tenantName'] ?? '',
    );
  }
}
