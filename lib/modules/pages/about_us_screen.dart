import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: Text(
          "ABOUT US",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              
              // Logo
              SvgPicture.asset(
                "assets/Images/SplashScreen/neo_parlour_logo.svg",
                height: 90,
                width: 100,
              ),
              
              const SizedBox(height: 32),
              
              // Content Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0XFFDFDFDF)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "About Neo Parlour",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0XFF2D2D2D),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 50,
                      height: 3,
                      decoration: BoxDecoration(
                        color: const Color(0XFFFF0B01),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    Text(
                      "Neo Parlour is a smart salon management application built to simplify the way salons operate. We understand that managing a salon involves juggling multiple tasks—appointment bookings, inventory tracking, and staff coordination—all at the same time. These everyday challenges can create confusion and take focus away from what truly matters: growing your business and serving your customers.",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: const Color(0XFF626262),
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Text(
                      "That’s where Neo Parlour comes in.",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0XFF2D2D2D),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    Text(
                      "Our platform brings everything together in one place, allowing salon owners to efficiently manage appointments, monitor inventory, and organize staff schedules with ease. By reducing manual work and minimizing errors, Neo Parlour helps bring clarity, structure, and control to your daily operations.",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: const Color(0XFF626262),
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Version & Branding Info
              Text(
                'Version 1.0.0',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0XFF868686),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Powered By Neopaceinfotech LLP',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0XFF868686),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
