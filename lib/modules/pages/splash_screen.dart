import 'package:provider/provider.dart';
import 'package:neo_parlour/provider/customer/auth_provider.dart';
import 'package:neo_parlour/modules/pages/salon_details_screen.dart';
import 'package:neo_parlour/modules/pages/salon_id_screen.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'splash_two_screen.dart'; 

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;
  bool _isNavigated = false;

  Color skipColor = const Color(0XFF505050); 

  @override
  void initState() {
    super.initState();

    // Auto navigate after 3 seconds
    _timer = Timer(const Duration(seconds: 3), _navigateToNext);
  }

  void _navigateToNext() async {
    if (_isNavigated) return;

    _isNavigated = true;
    _timer?.cancel();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Wait for the provider to finish loading from SharedPreferences
    await authProvider.initialization;

    if (!mounted) return;

    if (authProvider.isAuthenticated) {
      if (authProvider.tenantName != null && authProvider.tenantName!.isNotEmpty) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
            final salonId = authProvider.salonId;
            if (salonId != null) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => SalonDetailsScreen(salonId: salonId)),
                (route) => false,
              );
            } else {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const SalonIDScreen()),
                (route) => false,
              );
            }
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SalonIDScreen()),
        );
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const SplashTwoScreen(),
        ),
      );
    }
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
              'assets/Images/SplashScreen/background_image.png',
              fit: BoxFit.cover,
            ),
          ),

          // 2. Logo
          Positioned(
            top: size.height * 0.35,
            left: 0,
            right: 0,
            child: Center(
              child: SvgPicture.asset(
                'assets/Images/SplashScreen/neo_parlour_logo.svg',
                height: size.height * 0.15,
              ),
            ),
          ),

          // 3. Bottom Container
          Align(
            alignment: Alignment.bottomCenter,
            child: SingleChildScrollView(
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
                      color: const Color(0xFFFF7A58).withValues(alpha: 0.35),
                      blurRadius: 60,
                      spreadRadius: 30,
                      offset: const Offset(0, -10),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
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
                        fontSize: 25,
                        height: 1.0,
                        color: const Color(0XFF626262),
                      ),
                    ),
              
                    // ONE LINE TEXT
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        "EXCLUSIVE SALON",
                        maxLines: 1,
                        softWrap: false,
                        style: GoogleFonts.imbue(
                          fontSize: 50,
                          height: 1.0,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFFFF5000),
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
              
                    Text(
                      "Management App",
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
                                  _navigateToNext();
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
          ),
        ],
      ),
    );
  }
}