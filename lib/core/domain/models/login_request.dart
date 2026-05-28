class LoginRequest {
  final String username;
  final String password;
  final String? fcmToken;

  LoginRequest({
    required this.username, 
    required this.password,
    this.fcmToken,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'phone': username, // Added for backend CustomerLoginRequest compatibility
      'password': password,
      'fcmToken': fcmToken,
    };
  }
}
