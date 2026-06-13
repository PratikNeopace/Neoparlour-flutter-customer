import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/customer/auth_provider.dart';
import '../../core/utils/flushbar_helper.dart';
import 'home_screen.dart';
import 'salon_id_screen.dart';

class TncAcceptanceScreen extends StatefulWidget {
  const TncAcceptanceScreen({super.key});

  @override
  State<TncAcceptanceScreen> createState() => _TncAcceptanceScreenState();
}

class _TncAcceptanceScreenState extends State<TncAcceptanceScreen> {
  bool _isLoading = false;

  void _acceptTnc(BuildContext context) async {
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
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
            );
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
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(15.0),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const SingleChildScrollView(
                    child: Text(
                      "Welcome to NeoParlour!\n\n"
                      "Please read these Terms and Conditions carefully before using our application. By accessing or using the service, you agree to be bound by these terms.\n\n"
                      "1. User Account & Security\n"
                      "You are responsible for maintaining the confidentiality of your account credentials and password. You agree to accept responsibility for all activities that occur under your account.\n\n"
                      "2. Booking & Cancellation Policy\n"
                      "Appointments booked through NeoParlour are subject to the availability of the salon and staff. Cancellations and reschedules should be made within the salon's policy time limits.\n\n"
                      "3. Privacy Policy\n"
                      "Your privacy is important to us. Please review our Privacy Policy to understand how we collect, use, and protect your personal information.\n\n"
                      "4. Pricing & Payments\n"
                      "Prices listed on the app are subject to change without prior notice. The final price calculated at confirm booking will be charged for the rendered services.\n\n"
                      "5. Limitation of Liability\n"
                      "NeoParlour and its affiliates shall not be liable for any direct, indirect, incidental, or consequential damages resulting from the use or inability to use the services.\n\n"
                      "6. Updates to Terms\n"
                      "We reserve the right to modify these terms at any time. Your continued use of the application after changes constitute acceptance of the updated terms.",
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0XFF505050),
                        height: 1.6,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
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
