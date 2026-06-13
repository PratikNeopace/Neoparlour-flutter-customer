import 'package:flutter/gestures.dart';
import '../../core/utils/flushbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:neo_parlour/modules/pages/register_screen.dart';
import 'package:neo_parlour/modules/pages/salon_id_screen.dart';
import 'package:neo_parlour/modules/pages/forgot_password_screen.dart';
import 'package:provider/provider.dart';
import 'package:neo_parlour/provider/customer/auth_provider.dart';
import 'package:neo_parlour/modules/pages/tnc_acceptance_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isChecked = false;
  bool isLoginTab = true;
  bool _isPasswordVisible = false;

  final TextEditingController whatsappController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    whatsappController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  //  API INTEGRATION FUNCTION
  void _loginApi() async {
    final username = whatsappController.text.trim();
    final password = passwordController.text.trim();

    //  MUST TICK CHECKBOX FIRST
    if (!isChecked) {      FlushbarHelper.show(context, "I agree with terms of use");

      return;
    }

    // Field-specific validation
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    FocusScope.of(context).unfocus();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(username, password);

    if (success && mounted) {
      final user = authProvider.userProfile;
      if (user != null && (user.tncAccepted == false || user.tncVersion != "v1.0")) {
        Future.microtask(() {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const TncAcceptanceScreen()),
            );
          }
        });
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SalonIDScreen()),
        );
      }
    } else if (mounted) {
      if (authProvider.errorMessage?.contains("Terms & Conditions not accepted") == true) {
        FlushbarHelper.show(context, "Please accept Terms & Conditions to continue");
      } else {
        FlushbarHelper.show(context, authProvider.errorMessage ?? "Login failed");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/Images/LoginScreen/login_background.png',
              fit: BoxFit.cover,
            ),
          ),

          // Form Container
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: size.height * 0.48,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 25),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tabs
                    Row(
                      children: [
                        _buildTabItem("REGISTER", !isLoginTab, () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RegisterScreen(),
                            ),
                          );
                        }),
                        const SizedBox(width: 30),
                        _buildTabItem("LOGIN", isLoginTab, () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LoginScreen(),
                            ),
                          );
                        }),
                      ],
                    ),

                    const SizedBox(height: 35),

                    // WhatsApp Input
                    _svgInputField(
                      'assets/Images/RegisterScreen/call.svg',
                      'Whatsapp Number',
                      controller: whatsappController,
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

                    // Password Input
                    _svgInputField(
                      'assets/Images/RegisterScreen/password.svg',
                      'Password',
                      controller: passwordController,
                      obscure: true,
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

                    const SizedBox(height: 10),

                    // SUBMIT BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 49,
                      child: Consumer<AuthProvider>(
                        builder: (context, auth, _) {
                          return ElevatedButton(
                            onPressed: (!isChecked || auth.isLoading)
                                ? null
                                : () => _loginApi(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0XFFFF0B01),
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
                                    "LOGIN",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Remember Me
                    Row(
                      children: [
                        SizedBox(
                          height: 18,
                          width: 18,
                          child: Checkbox(
                            value: isChecked,
                            activeColor: const Color(0XFFFF0B01),
                            side: const BorderSide(color: Color(0XFF909090)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            onChanged: (value) {
                              setState(() => isChecked = value!);

                              // TODO: Save remember-me preference
                              // Example: SharedPreferences
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "Remember me next time",
                          style: TextStyle(
                            color: Color(0XFF8D8D8D),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Forgot Password
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ForgotPasswordScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        "Forgot Password?",
                        style: TextStyle(
                          color: Color(0XFFFF0B01),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),
                    
                     /// Register
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            color: Color(0XFF909090),
                            fontSize: 12,
                          ),
                          children: [
                            const TextSpan(text: "Don't have an account? "),
                            TextSpan(
                              text: "Register",
                              style: const TextStyle(
                                color: Color(0XFFFF0B01),
                                fontWeight: FontWeight.bold,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => RegisterScreen(),
                                    ),
                                  );
                                },
                            ),
                          ],
                        ),
                      ),
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

  // ---------- UI HELPERS (UNCHANGED) ----------

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
              color: isActive ? Colors.black : const Color(0XFF9B9A9A),
            ),
          ),
          const SizedBox(height: 4),
          if (isActive)
            Container(
              height: 3,
              width: 40,
              decoration: BoxDecoration(
                color: const Color(0XFFFF0B01),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
        ],
      ),
    );
  }

  Widget _svgInputField(
    String iconPath,
    String hint, {
    bool obscure = false,
    TextEditingController? controller,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        obscureText: obscure ? !_isPasswordVisible : false,
        textAlignVertical: TextAlignVertical.center,
        validator: validator,
        decoration: InputDecoration(
            isDense: true,
            prefixIcon: Padding(
              padding: const EdgeInsets.all(12),
              child: SvgPicture.asset(iconPath, height: 20, width: 20),
            ),

            //  ADD THIS PART
            suffixIcon: obscure
                ? IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.grey,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  )
                : null,

            hintText: hint,
            hintStyle: const TextStyle(color: Color(0XFF8D8D8D), fontSize: 12),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: EdgeInsets.zero,
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
