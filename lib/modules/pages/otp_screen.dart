import 'package:flutter/material.dart';
import '../../core/utils/flushbar_helper.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:neo_parlour/modules/pages/salon_id_screen.dart';
import 'package:provider/provider.dart';
import '../../provider/customer/auth_provider.dart';
import 'home_screen.dart';

class OTPScreen extends StatefulWidget {
  const OTPScreen({super.key});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          //  SVG BACKGROUND (FIXED)
          Positioned.fill(
            child: Image.asset(
              'assets/Images/OTPScreen/background_otp_screen.jpg',
              fit: BoxFit.cover,
            ),
          ),

          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.15),
            ),
          ),

          // OTP CARD
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedPadding(
              padding: EdgeInsets.only(bottom: keyboardHeight),
              duration: const Duration(milliseconds: 200),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 35),
                margin: const EdgeInsets.fromLTRB(20, 100, 20, 0), 
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(45),
                    topRight: Radius.circular(45),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 20,
                      spreadRadius: 5,
                    )
                  ],
                ),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "VERIFY OTP",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(height: 3, width: 70, color: Colors.redAccent),
                      const SizedBox(height: 25),

                      Consumer<AuthProvider>(
                        builder: (context, auth, _) {
                          final mobile = auth.tempRegistrationData?['mobile'] ?? "********12";
                          return Text(
                            "We sent a verification code to your\nmobile number $mobile",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              height: 1.5,
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 30),

                      // OTP BOXES
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          6,
                          (index) => _otpBox(context, index),
                        ),
                      ),

                      const SizedBox(height: 35),

                      // VERIFY BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () => _handleVerify(context),
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
                                "VERIFY",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Center(
                      //   child: Column(
                      //     children: [
                      //       const Text(
                      //         "or sign in with",
                      //         style: TextStyle(color: Colors.grey, fontSize: 13),
                      //       ),
                      //       const SizedBox(height: 15),
                      //       Row(
                      //         mainAxisAlignment: MainAxisAlignment.center,
                      //         children: [
                      //           // _socialIcon(Icons.apple, Colors.black),
                      //           // const SizedBox(width: 20),
                      //           _socialIcon(Icons.facebook, const Color(0xFF3B5998)),
                      //           const SizedBox(width: 20),
                      //           _socialIcon(null, Colors.white, isGoogle: true),
                      //         ],
                      //       ),
                      //     ],
                      //   ),
                      // ),
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

  // OTP BOX
  void _handleVerify(BuildContext context) async {
    final otpStr = _otp;
    if (otpStr.length < 6) {      FlushbarHelper.show(context, "Please enter complete 6-digit OTP");

      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.registerWithOtp(otpStr);

    if (success) {
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const SalonIDScreen()),
          (route) => false,
        );
      }
    } else {
      if (context.mounted) {        FlushbarHelper.show(context, auth.errorMessage ?? "Registration failed");

      }
    }
  }

  // OTP BOX
  Widget _otpBox(BuildContext context, int index) {
    return Container(
      height: 50,
      width: 42,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _focusNodes[index].hasFocus ? Colors.redAccent : Colors.grey.shade300,
        ),
      ),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        onChanged: (value) {
          if (value.length == 1 && index < 5) {
            FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
          }
          if (value.isEmpty && index > 0) {
            FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
          }
          setState(() {}); // Update border color
        },
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        inputFormatters: [
          LengthLimitingTextInputFormatter(1),
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: "-",
        ),
      ),
    );
  }

  // SOCIAL ICON
  Widget _socialIcon(IconData? icon, Color bgColor, {bool isGoogle = false}) {
    return Container(
      height: 42,
      width: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor,
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: isGoogle
            ? const Icon(Icons.g_mobiledata, color: Colors.red, size: 30)
            : Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}