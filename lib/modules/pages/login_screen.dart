import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/utils/flushbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:neo_parlour/modules/pages/otp_screen.dart';
import 'package:provider/provider.dart';
import 'package:neo_parlour/provider/customer/auth_provider.dart';

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

  void _handleContinue() async {
    if (!isChecked) {
      FlushbarHelper.show(context, "Please agree to the Terms & Conditions and Privacy Policy");
      return;
    }

    // Field-specific validation
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    FocusScope.of(context).unfocus();

    final mobile = whatsappController.text.trim();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final success = await authProvider.sendOtp(mobile);

    if (success && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OTPScreen(
            mobileNumber: mobile,
            countryCode: "+91",
            isTncAccepted: true,
          ),
        ),
      );
    } else if (mounted) {
      FlushbarHelper.show(context, authProvider.errorMessage ?? "Failed to send OTP");
    }
  }

  @override
  Widget build(BuildContext context) {
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
              width: double.infinity,
              margin: EdgeInsets.only(
                left: 18,
                right: 18,
                top: 15,
                bottom: 15 + MediaQuery.of(context).padding.bottom,
              ),
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Tabs
                      Row(
                        children: [
                          _buildTabItem("LOGIN", isLoginTab, () {}),
                        ],
                      ),

                      const SizedBox(height: 35),

                      // Country Code & Mobile Number Input
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Country Code Dropdown (+91)
                          Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(color: const Color(0XFF909090), width: 1),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: "+91",
                                items: const [
                                  DropdownMenuItem(
                                    value: "+91",
                                    child: Text(
                                      "+91",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                                onChanged: (val) {},
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Mobile number input
                          Expanded(
                            child: _svgInputField(
                              'assets/Images/RegisterScreen/call.svg',
                              'Mobile Number',
                              controller: whatsappController,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(10),
                                FilteringTextInputFormatter.digitsOnly,
                              ],
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
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      // TERMS & CONDITIONS CHECKBOX
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 20,
                            width: 20,
                            child: Checkbox(
                              value: isChecked,
                              activeColor: const Color(0XFFFF0B01),
                              onChanged: (value) =>
                                  setState(() => isChecked = value!),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  color: Color(0XFF8D8D8D),
                                  fontSize: 11,
                                  fontFamily: 'Inter',
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
                                  const TextSpan(text: " of NeoParlour."),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      // CONTINUE BUTTON
                      SafeArea(
                        top: false,
                        child: SizedBox(
                          width: double.infinity,
                          height: 49,
                          child: Consumer<AuthProvider>(
                            builder: (context, auth, _) {
                              return ElevatedButton(
                                onPressed: auth.isLoading
                                    ? null
                                    : () => _handleContinue(),
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
                                        "CONTINUE",
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
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        obscureText: obscure ? !_isPasswordVisible : false,
        textAlignVertical: TextAlignVertical.center,
        validator: validator,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
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
