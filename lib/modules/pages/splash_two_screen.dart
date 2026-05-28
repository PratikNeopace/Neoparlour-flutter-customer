import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neo_parlour/modules/pages/splash_three_screen.dart';
import 'splash_two_screen.dart';

class SplashTwoScreen extends StatefulWidget {
  const SplashTwoScreen({super.key});

  @override
  State<SplashTwoScreen> createState() => _SplashTwoScreenState();
}

class _SplashTwoScreenState extends State<SplashTwoScreen> {
  Timer? _timer;
  bool _isNavigated = false;
  Color skipColor = const Color(0XFF505050);

  @override
  void initState() {
    super.initState();

    // Auto navigate after 3 seconds
    _timer = Timer(const Duration(seconds: 3), _navigateToNext);
  }

  void _navigateToNext() {
    if (_isNavigated) return;

    _isNavigated = true;
    _timer?.cancel();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const SplashThreeScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/Images/SplashScreen/background_two_splash_image.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // 3. Bottom Container
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: size.width * 0.92,
              height: size.height * 0.28 + bottomPadding,
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 30,
                bottom: bottomPadding + 10,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(50),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF7A58).withOpacity(0.35),
                    blurRadius: 60,
                    spreadRadius: 30,
                    offset: const Offset(0, -10),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    "Your",
                    style: GoogleFonts.habibi(
                      height: 1.0,
                      fontSize: 25,
                      color: const Color(0XFF626262),
                    ),
                  ),
                
                  // ONE LINE TEXT
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "PARLOUR",
                      maxLines: 1,
                      softWrap: false,
                      style: GoogleFonts.imbue(
                        height: 1.0,
                        fontSize: 50,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFFF5000),
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),

                  Text(
                    "Platter",
                    style: GoogleFonts.habibi(
                      fontSize: 25,
                      color: const Color(0XFF626262),
                    ),
                  ),

                  const Spacer(),

                  // 4. Skip Button
                  GestureDetector(
                    onTap: _navigateToNext,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: (){
                                setState((){
                                  skipColor = const Color(0XFFFF0B01);
                              });
                             Future.delayed(const Duration(milliseconds: 200), (){
                                if (!context.mounted) return;
                                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SplashThreeScreen()));
                              });
                            },
                            child: Text(
                              "Skip ",
                              style: GoogleFonts.poppins(
                                color: skipColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: Color(0XFFC1BDBD),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Text(
                    "Version 1.0.0 | Powered By Neopaceinfotech LLP",
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: const Color(0XFF626262),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
