import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Support",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              SvgPicture.asset(
                "assets/Images/SplashScreen/neo_parlour_logo.svg",
                height: 100,
                width: 110,
              ),
              const SizedBox(height: 30),
              const Text(
                "Support",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "We’re here to help you every step of the way.",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _buildSupportInfoRow(
                      Icons.email_outlined,
                      "Email",
                      "jeevan.j@neopaceinfotech.com",
                      onTap: () async {
                        final Uri emailUri = Uri(
                          scheme: 'mailto',
                          path: 'jeevan.j@neopaceinfotech.com',
                        );
                        try {
                          await launchUrl(emailUri);
                        } catch (e) {
                          debugPrint("Could not launch email: $e");
                        }
                      },
                    ),
                    const Divider(height: 24),
                    _buildSupportInfoRow(
                      Icons.phone_outlined,
                      "Phone",
                      "9119591956",
                      onTap: () async {
                        final Uri phoneUri = Uri(
                          scheme: 'tel',
                          path: '9119591956',
                        );
                        try {
                          await launchUrl(phoneUri);
                        } catch (e) {
                          debugPrint("Could not launch phone: $e");
                        }
                      },
                    ),
                    const Divider(height: 24),
                    _buildSupportInfoRow(
                      Icons.access_time_outlined,
                      "Working Hours",
                      "10 am to 7pm",
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Text(
                "We aim to provide fast, reliable, and friendly support to ensure your experience with Neo Parlour is always smooth and hassle-free.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.6,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupportInfoRow(IconData icon, String label, String value, {VoidCallback? onTap}) {
    final rowContent = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0XFFFF0B01), size: 22),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF2D2D2D),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        if (onTap != null)
          const Icon(
            Icons.open_in_new,
            size: 14,
            color: Colors.grey,
          ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
          child: rowContent,
        ),
      );
    }

    return rowContent;
  }
}
