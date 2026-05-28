import 'package:flutter/material.dart';
import '../../core/utils/flushbar_helper.dart';
import 'package:flutter_svg/svg.dart';
import 'package:neo_parlour/widgets/custom_nav_bar.dart';

import 'package:neo_parlour/core/domain/models/appointment.dart';
import 'package:neo_parlour/provider/customer/auth_provider.dart';
import 'package:neo_parlour/provider/customer/feedback_provider.dart';
import 'package:provider/provider.dart';

class FeedbackScreen extends StatefulWidget {
  final Appointment appointment;
  const FeedbackScreen({super.key, required this.appointment});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  int selectedRating = 4; // default = Amazing (5 stars usually)
  final TextEditingController _commentController = TextEditingController();

  final List<Map<String, dynamic>> ratings = [
    {
      "label": "Terrible",
      "icon": Icons.sentiment_very_dissatisfied,
      "value": 1,
    },
    {"label": "Bad", "icon": Icons.sentiment_dissatisfied, "value": 2},
    {"label": "Okay", "icon": Icons.sentiment_neutral, "value": 3},
    {"label": "Good", "icon": Icons.sentiment_satisfied, "value": 4},
    {"label": "Amazing", "icon": Icons.sentiment_very_satisfied, "value": 5},
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFF8F8F8),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0XFFFF0B01),
        elevation: 4,
        shape: const CircleBorder(),
        onPressed: () => Navigator.pop(context),
        child: SvgPicture.asset(
          "assets/Images/BottomNavigationBar/home_icon.svg",
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const CustomBottomNavBar(),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildForm()),
        ],
      ),
    );
  }

  // HEADER
  Widget _buildHeader() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipPath(
          clipper: HeaderCurveClipper(),
          child: Container(
            height: 225,
            width: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                  'assets/Images/FeedbackScreen/background_image.jpg',
                ),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.transparent,
                    const Color(0XFFFF3502).withOpacity(0.6),
                  ],
                ),
              ),
              padding: const EdgeInsets.only(left: 20, bottom: 20),
              alignment: Alignment.bottomLeft,
              child: const Text(
                "FEEDBACK",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 50,
          left: 20,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.4),
              child: const Icon(Icons.chevron_left, color: Colors.black),
            ),
          ),
        ),

        // Floating Cart Icon on the curve
        Positioned(
          bottom: -5,
          right: 30,
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: const BoxDecoration(
              color: Color(0xFFFF0B01),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: SvgPicture.asset(
              "assets/Images/MyBookingScreen/booking_floating_btn.svg",
            ),
          ),
        ),
      ],
    );
  }

  // FORM AREA
  Widget _buildForm() {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        40,
        20,
        MediaQuery.of(context).padding.bottom + 100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Appointment Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Staff: ${widget.appointment.staffName}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  "Services: ${widget.appointment.serviceNames.join(', ')}",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          const Text(
            "Rate Service",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),

          // Rating Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(ratings.length, (index) {
              final isSelected = selectedRating == index;
              return GestureDetector(
                onTap: () => setState(() => selectedRating = index),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0XFFFF0B01) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        ratings[index]["icon"],
                        color: isSelected ? Colors.white : Colors.grey,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ratings[index]["label"],
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected ? Colors.white : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 25),
          const Text(
            "Share your experience",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _commentController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: "Write your comment here...",
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 30),

          // SUBMIT BUTTON
          Consumer<FeedbackProvider>(
            builder: (context, feedbackProv, _) {
              return SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0XFFFF0B01),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: feedbackProv.isLoading
                      ? null
                      : () async {
                          final authProv = context.read<AuthProvider>();
                          final customerId =
                              widget.appointment.customerId ?? authProv.userId;
                          final staffId = widget.appointment.staffId;

                          if (staffId == null || customerId == null) {                            FlushbarHelper.show(context, "Missing staff or customer information",);

                            return;
                          }

                          final success = await feedbackProv.submitFeedback(
                            appointmentId: widget.appointment.id,
                            customerId: customerId,
                            staffId: staffId,
                            comment: _commentController.text,
                            rating: ratings[selectedRating]["value"],
                          );

                          if (success && mounted) {
                            await FlushbarHelper.show(
                              context,
                              "Feedback submitted successfully!",
                              isSuccess: true,
                            );

                            if (mounted) {
                              Future.microtask(() => Navigator.pop(context));
                            }
                          } else if (mounted) {
                            await FlushbarHelper.show(
                              context,
                              feedbackProv.errorMessage ?? "Failed to submit feedback",
                            );
                          }
                        },
                  child: feedbackProv.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "SUBMIT",
                          style: TextStyle(
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// SAME HEADER CLIPPER USED IN MY BOOKING
class HeaderCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height);
    path.lineTo(size.width * 0.55, size.height);
    path.quadraticBezierTo(
      size.width,
      size.height,
      size.width,
      size.height * 0.35,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
