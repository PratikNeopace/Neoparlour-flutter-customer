import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/utils/flushbar_helper.dart';
import 'package:flutter/services.dart';
import 'package:neo_parlour/modules/pages/salon_id_screen.dart';
import 'package:provider/provider.dart';
import '../../provider/customer/auth_provider.dart';
import 'tnc_acceptance_screen.dart';

class OTPScreen extends StatefulWidget {
  final String mobileNumber;
  final String countryCode;
  final bool isTncAccepted;

  const OTPScreen({
    super.key,
    required this.mobileNumber,
    required this.countryCode,
    this.isTncAccepted = false,
  });

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  Timer? _timer;
  int _secondsRemaining = 30;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = 30;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        setState(() {
          _canResend = true;
          _timer?.cancel();
        });
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  void _resendOtp() async {
    if (!_canResend) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.sendOtp(widget.mobileNumber);
    if (success) {
      if (mounted) {
        FlushbarHelper.show(context, "OTP resent successfully");
        _startTimer();
      }
    } else {
      if (mounted) {
        FlushbarHelper.show(context, auth.errorMessage ?? "Failed to resend OTP");
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
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
              color: Colors.black.withValues(alpha: 0.15),
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

                      Text(
                        "We sent a verification code to your\nmobile number ${widget.countryCode} ${widget.mobileNumber}",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          height: 1.5,
                        ),
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

                      const SizedBox(height: 20),

                      // Resend OTP Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _canResend ? "Didn't receive the OTP? " : "Resend OTP in ",
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                          GestureDetector(
                            onTap: _canResend ? _resendOtp : null,
                            child: Text(
                              _canResend ? "Resend OTP" : "${_secondsRemaining}s",
                              style: TextStyle(
                                color: _canResend ? Colors.red : Colors.grey.shade600,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 35),

                      // VERIFY BUTTON
                      SafeArea(
                        top: false,
                        child: SizedBox(
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
                      ),

                      const SizedBox(height: 30),
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
    if (otpStr.length < 6) {
      FlushbarHelper.show(context, "Please enter complete 6-digit OTP");
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.loginWithOtp(widget.mobileNumber, otpStr);

    if (success) {
      if (context.mounted) {
        final user = auth.userProfile;
        if (user != null && (user.tncAccepted == false || user.tncVersion != "v1.0")) {
          if (widget.isTncAccepted) {
            // Automatically accept T&C since user checked it on LoginScreen
            await auth.updateUserProfile({
              "tncAccepted": true,
              "tncAcceptedAt": DateTime.now().toUtc().toIso8601String(),
              "tncVersion": "v1.0"
            });
            Future.microtask(() {
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const SalonIDScreen()),
                  (route) => false,
                );
              }
            });
          } else {
            Future.microtask(() {
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const TncAcceptanceScreen()),
                  (route) => false,
                );
              }
            });
          }
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const SalonIDScreen()),
            (route) => false,
          );
        }
      }
    } else {
      if (context.mounted) {
        FlushbarHelper.show(context, auth.errorMessage ?? "Login failed");
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
        autofocus: index == 0,
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

}