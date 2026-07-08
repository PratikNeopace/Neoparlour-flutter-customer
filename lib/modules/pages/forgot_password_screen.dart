import 'package:flutter/material.dart';
import '../../core/utils/flushbar_helper.dart';
import 'package:flutter_svg/svg.dart';
import 'package:neo_parlour/core/utils/validator.dart';
import 'package:provider/provider.dart';
import '../../provider/customer/auth_provider.dart';
import 'login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _otpSent = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _mobileController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSendOtp() async {
    final mobile = _mobileController.text.trim();
    String? error = Validators.validateMobile(mobile);
    if (error != null) {      FlushbarHelper.show(context, error);

      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.sendForgotPasswordOtp(mobile);
    if (!mounted) return;
    if (success) {
      setState(() => _otpSent = true);
      FlushbarHelper.show(context, "OTP sent successfully to WhatsApp", isSuccess: true);
    } else {
      FlushbarHelper.show(context, auth.errorMessage ?? "Failed to send OTP");
    }
  }

  void _handleSubmit() async {
    final mobile = _mobileController.text.trim();
    final otp = _otpController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    String? error =
        Validators.validateRequired(otp, "OTP") ??
        Validators.validatePassword(newPassword) ??
        Validators.validateConfirmPassword(newPassword, confirmPassword);

    if (error != null) {      FlushbarHelper.show(context, error);

      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.resetPasswordWithOtp(mobile, otp, newPassword);
    if (!mounted) return;
    if (success) {
      FlushbarHelper.show(context, "Password reset successful. Please login.", isSuccess: true);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } else {
      FlushbarHelper.show(context, auth.errorMessage ?? "Reset failed");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ================= 1. HEADER SECTION =================
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipPath(
                  clipper: ForgotPasswordHeaderClipper(),
                  child: Container(
                    height: 225,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(
                          'assets/Images/ForgotPasswordScreen/background_forgot_password.jpg',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.1),
                            Colors.transparent,
                            const Color(0XFFFF3502).withValues(alpha: 0.6),
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.only(left: 20, bottom: 20),
                      alignment: Alignment.bottomLeft,
                      child: const Text(
                        "FORGOT PASSWORD",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

                // Floating Lock Icon
                Positioned(
                  bottom: 15,
                  right: 25,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF0B01),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.lock_reset,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),

                // Back Button
                Positioned(
                  top: 50,
                  left: 20,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: CircleAvatar(
                      backgroundColor: Colors.white.withValues(alpha: 0.4),
                      child: const Icon(
                        Icons.chevron_left,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ================= 2. FORM SECTION =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _otpSent ? "Verification Details" : "Reset Your Password",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // WhatsApp Number
                  _buildInputField(
                    hint: "Enter WhatsApp Number",
                    controller: _mobileController,
                    iconPath: 'assets/Images/RegisterScreen/call.svg',
                    readOnly: _otpSent,
                  ),
                  const SizedBox(height: 15),

                  if (!_otpSent)
                    // Send OTP Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: Consumer<AuthProvider>(
                        builder: (context, auth, _) {
                          return ElevatedButton(
                            onPressed: auth.isLoading ? null : _handleSendOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF0B01),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9),
                              ),
                              elevation: 0,
                            ),
                            child: auth.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    "SEND OTP",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 2,
                                    ),
                                  ),
                          );
                        },
                      ),
                    ),

                  if (_otpSent) ...[
                    // OTP Field
                    _buildInputField(
                      hint: "Enter 6-Digit OTP",
                      controller: _otpController,
                      iconPath: 'assets/Images/RegisterScreen/username.svg',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 15),

                    // New Password
                    _buildPasswordField(
                      hint: "Create New Password",
                      controller: _newPasswordController,
                      isObscured: _obscureNew,
                      onToggle: () =>
                          setState(() => _obscureNew = !_obscureNew),
                    ),
                    const SizedBox(height: 15),

                    // Confirm Password
                    _buildPasswordField(
                      hint: "Confirm New Password",
                      controller: _confirmPasswordController,
                      isObscured: _obscureConfirm,
                      onToggle: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),

                    const SizedBox(height: 35),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: Consumer<AuthProvider>(
                        builder: (context, auth, _) {
                          return ElevatedButton(
                            onPressed: auth.isLoading ? null : _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF0B01),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9),
                              ),
                              elevation: 0,
                            ),
                            child: auth.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    "SUBMIT",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 2,
                                    ),
                                  ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SafeArea(top: false, child: const SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String hint,
    required TextEditingController controller,
    required String iconPath,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0XFF8D8D8D),
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: const Color(0xFFF8F8F8),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12),
          child: SvgPicture.asset(iconPath, height: 20, width: 20),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: Color(0XFFF8F8F8), width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: Color(0XFFFF0B01), width: 1),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required String hint,
    required TextEditingController controller,
    required bool isObscured,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: isObscured,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0XFF8D8D8D),
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: const Color(0xFFF8F8F8),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12),
          child: SvgPicture.asset(
            'assets/Images/RegisterScreen/password.svg',
            height: 20,
            width: 20,
          ),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            isObscured
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: const Color(0XFF8D8D8D),
          ),
          onPressed: onToggle,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: Color(0XFFF8F8F8), width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: Color(0XFFFF0B01), width: 1),
        ),
      ),
    );
  }
}

class ForgotPasswordHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height);
    path.lineTo(size.width * 0.65, size.height);
    path.quadraticBezierTo(
      size.width * 0.85,
      size.height,
      size.width,
      size.height * 0.55,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
