import 'package:provider/provider.dart';
import 'package:neo_parlour/provider/customer/auth_provider.dart';
import 'package:neo_parlour/modules/pages/salon_details_screen.dart';
import 'package:neo_parlour/modules/pages/salon_id_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/utils/flushbar_helper.dart';

class TncAcceptanceScreen extends StatefulWidget {
  const TncAcceptanceScreen({super.key});

  @override
  State<TncAcceptanceScreen> createState() => _TncAcceptanceScreenState();
}

class _TncAcceptanceScreenState extends State<TncAcceptanceScreen> {
  bool _isLoading = false;
  bool _isChecked = false;

  Future<void> _openTermsAndConditions() async {
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

  Future<void> _openPrivacyPolicy() async {
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

  void _acceptTnc(BuildContext context) async {
    if (!_isChecked) {
      FlushbarHelper.show(context, "Please agree to the Terms & Conditions and Privacy Policy");
      return;
    }

    setState(() => _isLoading = true);
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.updateUserProfile({
      "tncAccepted": true,
      "tncAcceptedAt": DateTime.now().toUtc().toIso8601String(),
      "tncVersion": "v1.0"
    });
    setState(() => _isLoading = false);

    if (success && context.mounted) {
      Future.microtask(() {
        if (context.mounted) {
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
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const SalonIDScreen()),
              (route) => false,
            );
          }
        }
      });
    } else if (context.mounted) {
      FlushbarHelper.show(context, authProvider.errorMessage ?? "Failed to accept Terms & Conditions");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Terms & Conditions",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        color: Color(0XFFFFF5F4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.description_outlined,
                        size: 80,
                        color: Color(0XFFFF0B01),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      "Terms & Conditions Update",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Please review and accept our Terms & Conditions and Privacy Policy to continue using NeoParlour.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0XFF707070),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _isChecked,
                      activeColor: const Color(0XFFFF0B01),
                      onChanged: (v) {
                        setState(() => _isChecked = v!);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          color: Color(0XFF505050),
                          fontSize: 13,
                          height: 1.5,
                          fontFamily: 'Inter',
                        ),
                        children: [
                          const TextSpan(text: "I read and agree to the "),
                          TextSpan(
                            text: "Terms & Conditions",
                            style: const TextStyle(
                              color: Color(0XFFFF0B01),
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = _openTermsAndConditions,
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
                              ..onTap = _openPrivacyPolicy,
                          ),
                          const TextSpan(text: " of NeoParlour."),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () => _acceptTnc(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0XFFFF0B01),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Accept & Continue",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
