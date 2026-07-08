import 'package:firebase_messaging/firebase_messaging.dart';
import '../../core/utils/flushbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../provider/customer/auth_provider.dart';
import 'login_screen.dart';
import 'otp_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool isChecked = false;
  bool isTncAccepted = false;
  bool isRegisterTab = true;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // Controllers (API placeholders)
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    mobileController.dispose();
    addressController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> openTermsAndConditions() async {
    final Uri url = Uri.parse(
      'https://www.neoparlour.com/customer/terms-and-conditions',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
    }
  }

  Future<void> openPrivacyPolicy() async {
    final Uri url = Uri.parse(
      'https://www.neoparlour.com/customer/privacy-policy',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final double bottomSafe = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/Images/SplashScreen/background_image.png',
              fit: BoxFit.cover,
            ),
          ),

          //  Logo Section
          Positioned(
            top: size.height * 0.1,
            left: 0,
            right: 0,
            child: Column(
              children: [
                SvgPicture.asset(
                  'assets/Images/RegisterScreen/neo_parlour_logo.svg',
                  height: 80,
                ),
              ],
            ),
          ),

          // Bottom Form Container
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: size.height * 0.68,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
              padding: EdgeInsets.fromLTRB(25, 25, 25, 25 + bottomSafe),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(35),
                  topRight: Radius.circular(35),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0XFFFF7A58).withValues(alpha: 0.25),
                    blurRadius: 25,
                    spreadRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),

              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                    // REGISTER | LOGIN TABS
                    Row(
                      children: [
                        _buildTabItem("REGISTER", isRegisterTab, () {
                          setState(() => isRegisterTab = true);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RegisterScreen(),
                            ),
                          );
                        }),
                        const SizedBox(width: 30),
                        _buildTabItem("LOGIN", !isRegisterTab, () {
                          setState(() => isRegisterTab = false);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LoginScreen(),
                            ),
                          );
                        }),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // Input fields
                    _svgInputField(
                      'assets/Images/RegisterScreen/username.svg',
                      'User Name',
                      controller: usernameController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Enter your name";
                        }
                        if (value.length < 3) {
                          return "Name must be at least 3 characters";
                        }
                        if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
                          return "Enter a valid name";
                        }
                        return null;
                      },
                    ),

                    _svgInputField(
                      'assets/Images/RegisterScreen/email.svg',
                      'Email Id',
                      controller: emailController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Enter your email";
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                          return "Enter a valid email";
                        }
                        return null;
                      },
                    ),

                    _svgInputField(
                      'assets/Images/HomeScreen/location_icon.svg',
                      'Address',
                      controller: addressController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Enter your address";
                        }
                        return null;
                      },
                    ),

                    _svgInputField(
                      'assets/Images/RegisterScreen/call.svg',
                      'Mobile Number',
                      controller: mobileController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Enter mobile number";
                        }
                        if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                          return "Enter valid 10 digit number";
                        }
                        return null;
                      },
                    ),

                    _svgInputField(
                      'assets/Images/RegisterScreen/password.svg',
                      'Create a password',
                      controller: passwordController,
                      obscure: !_isPasswordVisible,
                      isPassword: true,
                      onToggle: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Enter password";
                        }
                        if (value.length < 6) {
                          return "Password must be at least 6 characters";
                        }
                        return null;
                      },
                    ),

                    _svgInputField(
                      'assets/Images/RegisterScreen/password.svg',
                      'Confirm password',
                      controller: confirmPasswordController,
                      obscure: !_isConfirmPasswordVisible,
                      isPassword: true,
                      onToggle: () {
                        setState(() {
                          _isConfirmPasswordVisible =
                              !_isConfirmPasswordVisible;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Confirm your password";
                        }
                        if (value != passwordController.text) {
                          return "Passwords do not match";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),

                    // TERMS & CONDITIONS CHECKBOX ABOVE BUTTON
                    Row(
                      children: [
                        SizedBox(
                          height: 16,
                          width: 16,
                          child: Checkbox(
                            value: isTncAccepted,
                            activeColor: const Color(0XFFFF0B01),
                            onChanged: (value) =>
                                setState(() => isTncAccepted = value!),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                color: Color(0XFF8D8D8D),
                                fontSize: 12,
                              ),
                              children: [
                                const TextSpan(text: "I agree to the "),
                                TextSpan(
                                  text: "Terms & Conditions",
                                  style: const TextStyle(
                                    color: Color(0XFFFF0B01),
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = openTermsAndConditions,
                                ),
                                const TextSpan(text: " and "),
                                TextSpan(
                                  text: "Privacy Policy",
                                  style: const TextStyle(
                                    color: Color(0XFFFF0B01),
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = openPrivacyPolicy,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 49,
                      child: ElevatedButton(
                        onPressed: isTncAccepted
                            ? () => _handleSubmit(context)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isTncAccepted
                              ? const Color(0XFFFF0B01)
                              : Colors.grey.shade400,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                          elevation: 0,
                        ),
                        child: Consumer<AuthProvider>(
                          builder: (context, auth, _) {
                            if (auth.isLoading) {
                              return const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              );
                            }
                            return const Text(
                              "SUBMIT",
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "Already have account? ",
                              style: TextStyle(
                                color: Color(0XFF8D8D8D),
                                fontSize: 13,
                              ),
                            ),
                            TextSpan(
                              text: "Login",
                              style: TextStyle(
                                color: Color(0XFFFF0B01),
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const LoginScreen(),
                                    ),
                                  );
                                },
                            ),
                          ],
                        ),
                      ),
                    ),

                    SafeArea(top: false, child: const SizedBox(height: 12)),
                  ],
                ),
              ),
            ),
            ),
          ),
        ],
      ),
    );
  }



  void _handleSubmit(BuildContext context) async {
    if (!isTncAccepted) {      FlushbarHelper.show(context, "Please agree to the terms and conditions");

      return;
    }

    final fullName = usernameController.text.trim();
    final email = emailController.text.trim();
    final mobile = mobileController.text.trim();
    final address = addressController.text.trim();
    final password = passwordController.text.trim();

    // Field-specific validation
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    FocusScope.of(context).unfocus();

    final auth = context.read<AuthProvider>();

    // Trigger OTP sending before navigating
    final otpSuccess = await auth.sendOtp(mobile);
    if (!otpSuccess) {
      if (context.mounted) {        FlushbarHelper.show(context, auth.errorMessage ?? "Failed to send OTP");

      }
      return;
    }

    String? fcmToken;
    try {
      fcmToken = await FirebaseMessaging.instance.getToken();
      debugPrint("FCM Token for Registration: $fcmToken");
    } catch (e) {
      debugPrint("Error fetching FCM token: $e");
    }

    auth.setRegistrationData({
      "active": true,
      "address": address,
      "email": email,
      "fullName": fullName,
      "mobile": mobile,
      "password": password,
      "fcmToken": fcmToken,
      "tncAccepted": true,
      "tncAcceptedAt": DateTime.now().toUtc().toIso8601String(),
      "tncVersion": "v1.0",
    });

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OTPScreen(
            mobileNumber: mobile,
            countryCode: "+91",
          ),
        ),
      );
    }
  }

  // TAB ITEM WIDGET
  Widget _buildTabItem(String title, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.black : Color(0XFF9B9A9A),
            ),
          ),
          const SizedBox(height: 4),
          if (isActive)
            Container(
              height: 3,
              width: 70,
              decoration: BoxDecoration(
                color: Color(0XFFFF0B01),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
        ],
      ),
    );
  }

  // SVG INPUT FIELD
  Widget _svgInputField(
    String iconPath,
    String hint, {
    bool obscure = false,
    bool isPassword = false,
    VoidCallback? onToggle,
    TextEditingController? controller,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        validator: validator,
        style: const TextStyle(fontSize: 14), // 👈 fix text visibility
          decoration: InputDecoration(
            prefixIcon: Padding(
              padding: const EdgeInsets.all(14),
              child: SvgPicture.asset(iconPath, height: 20, width: 20),
            ),

            // 👁️ Eye Icon
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility_off : Icons.visibility,
                      color: const Color(0XFFFF0B01),
                    ),
                    onPressed: onToggle,
                  )
                : null,

            hintText: hint,
            hintStyle: const TextStyle(color: Color(0XFF8D8D8D), fontSize: 12),

            filled: true,
            fillColor: Colors.grey.shade50,

            // 👇 IMPORTANT FIX FOR TEXT CUT ISSUE
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 10,
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: Color(0XFF909090), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: Color(0XFFFF0B01), width: 1),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
          ),
        ),
    );
  }



}
