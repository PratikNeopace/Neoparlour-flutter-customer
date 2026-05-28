import 'package:flutter/material.dart';
import '../../core/utils/flushbar_helper.dart';
import '../../core/domain/models/neo_service.dart';

class BookingPage extends StatelessWidget {
  final NeoService selectedService;

  const BookingPage({super.key, required this.selectedService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Book Appointment"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_today, size: 80, color: Color(0XFFFF0B01)),
            const SizedBox(height: 24),
            Text(
              "Booking for:",
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              selectedService.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              "Price: ₹${selectedService.price}",
              style: const TextStyle(
                fontSize: 20,
                color: Color(0XFFFF0B01),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {                FlushbarHelper.show(context, "Booking ${selectedService.name}...");

              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0XFFFF0B01),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text("Confirm Selection", style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
