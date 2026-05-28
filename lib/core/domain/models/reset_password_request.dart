class ResetPasswordRequest {
  final String mobile;
  final String otp;
  final String newPassword;

  ResetPasswordRequest({
    required this.mobile,
    required this.otp,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'mobile': mobile,
      'otp': otp,
      'newPassword': newPassword,
    };
  }
}
