import 'package:provider/provider.dart';
import 'package:neo_parlour/provider/customer/auth_provider.dart';
import 'package:neo_parlour/modules/pages/salon_details_screen.dart';
import 'package:neo_parlour/modules/pages/salon_id_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppointmentBookedScreen extends StatelessWidget {
  final Map<String, dynamic> bookingData;

  const AppointmentBookedScreen({super.key, required this.bookingData});

  @override
  Widget build(BuildContext context) {
    final appointmentAt = DateTime.parse(bookingData['appointmentAt']).toLocal();
    final formattedDate = DateFormat('dd-MM-yyyy').format(appointmentAt);
    final formattedTime = DateFormat('hh:mma').format(appointmentAt);
    
    final staffName = bookingData['staffName'] ?? "N/A";
    final finalAmount = bookingData['finalAmount']?.toString() ?? "0";
    
    // Get service name
    final services = bookingData['services'] as List?;
    String serviceDisplay = "No Service";
    if (services != null && services.isNotEmpty) {
      if (services.length == 1) {
        serviceDisplay = services[0]['serviceName'];
      } else {
        serviceDisplay = "${services[0]['serviceName']} +${services.length - 1}";
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFE0E0E0),
      body: SafeArea(
        child: Column(
          children: [
            // Removed back button

            const SizedBox(height: 40),

            // Success Animation
            Center(
              child: Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0XFFFFB1AE).withValues(alpha: 0.5),
                ),
                child: Center(
                  child: Container(
                    height: 90,
                    width: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0XFFFFB1AE).withValues(alpha: 0.5),
                    ),
                    child: Center(
                      child: Container(
                        height: 75,
                        width: 75,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0XFFFF756F).withValues(alpha: 0.7),
                        ),
                        child: Center(
                          child: Container(
                            height: 70,
                            width: 70,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0XFFFF0B01),
                            ),
                            child: const Icon(Icons.check, color: Colors.white, size: 40),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              "APPOINTMENT BOOKED",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
              ),
            ),

            if (bookingData['discountAmount'] != null && (bookingData['discountAmount'] as num) > 0) ...[
              const SizedBox(height: 8),
              Text(
                "You've saved ₹${(bookingData['discountAmount'] as num).toInt()} with this offer",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0XFFFF0B01),
                ),
              ),
            ],

            if (bookingData['weekdayDiscountAmount'] != null && (bookingData['weekdayDiscountAmount'] as num) > 0) ...[
              const SizedBox(height: 4),
              Text(
                "You've saved ₹${(bookingData['weekdayDiscountAmount'] as num).toInt()} with slot discount",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ],

            const SizedBox(height: 28),

            // Ticket Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ClipPath(
                clipper: TicketClipper(),
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      // User Info Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircleAvatar(
                              radius: 40,
                              backgroundImage: AssetImage('assets/Images/HistoryPopUpScreen/image.jpg'),
                            ),
                            const SizedBox(width: 15),
                            Consumer<AuthProvider>(
                              builder: (context, auth, child) {
                                return Text(
                                  (auth.userName ?? "USER").toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Dashed Divider
                      Row(
                        children: List.generate(
                          60,
                          (index) => Expanded(
                            child: Container(
                              height: 1,
                              color: index % 2 == 0 ? Colors.transparent : const Color(0XFFDADADA),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      // Service Details
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildColumn("Service Name", serviceDisplay),
                          _buildVerticalDivider(),
                          _buildColumn("Date & Time", "$formattedDate\n$formattedTime"),
                          _buildVerticalDivider(),
                          _buildColumn("Stylist name", staffName, price: "₹ $finalAmount"),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 34),

            TextButton(
              onPressed: () {
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
            },
              child: const Text(
                "Explore More Services",
                style: TextStyle(
                    color: Color(0xFFFF0B01),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    decoration: TextDecoration.underline,
                    decorationColor: Color(0XFFFF0B01),
                    decorationThickness: 1.5
                ),
              ),
            ),
            SafeArea(top: false, child: const SizedBox(height: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(height: 40, width: 1, color: Colors.grey[200]);
  }

  Widget _buildColumn(String title, String value, {String? price}) {
    return Expanded(
      child: Column(
        children: [
          Text(title, maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 10)),
          const SizedBox(height: 8),
          Text(value, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w400)),
          if (price != null) ...[
            const SizedBox(height: 4),
            Text(price, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ]
        ],
      ),
    );
  }
}

class TicketClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0.0, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0.0);
    path.addOval(Rect.fromCircle(center: Offset(size.width, size.height * 0.55), radius: 12));
    path.addOval(Rect.fromCircle(center: Offset(0, size.height * 0.55), radius: 12));
    path.fillType = PathFillType.evenOdd;
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
