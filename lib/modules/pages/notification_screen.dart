import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import '../../provider/customer/booking_provider.dart';
import '../../provider/customer/auth_provider.dart';
import '../../core/domain/models/appointment.dart';
import '../../widgets/custom_nav_bar.dart';
import 'home_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final phone = context.read<AuthProvider>().userPhone;
      if (phone != null) {
        context.read<BookingProvider>().fetchUserAppointments(phone);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      bottomNavigationBar: const CustomBottomNavBar(selectedLabel: "NOTIFICATION"),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        ),
        backgroundColor: const Color(0XFFFF0B01),
        elevation: 4,
        shape: const CircleBorder(),
        child: SvgPicture.asset("assets/Images/BottomNavigationBar/home_icon.svg"),
      ),
      body: Column(
        children: [
          // 1. Header Section
          _buildHeader(context),

          // 2. Notification List Section
          Expanded(
            child: Consumer2<BookingProvider, AuthProvider>(
              builder: (context, booking, auth, child) {
                if (booking.isLoadingAppointments) {
                  return const Center(child: CircularProgressIndicator(color: Color(0XFFFF0B01)));
                }

                if (auth.userPhone == null) {
                  return const Center(child: Text("Please login to see notifications."));
                }

                if (booking.userAppointments.isEmpty) {
                  return const Center(child: Text("No notifications yet."));
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    if (auth.userPhone != null) {
                      await booking.fetchUserAppointments(auth.userPhone!);
                    }
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 30, 20, 120),
                    itemCount: booking.userAppointments.length,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final appointment = booking.userAppointments[index];
                      
                      // Alternating colors logic
                      // Even: Red sidebar, Grey background
                      // Odd: Green sidebar, Light Green background
                      final bool isEven = index % 2 == 0;
                      final Color sideColor = isEven ? const Color(0XFFFF0B01) : const Color(0XFF43A047);
                      final Color bgColor = isEven ? const Color(0XFFE2E2E2) : const Color(0XFFE5FFE7);
  
                      return _notificationItem(
                        appointment: appointment,
                        sideColor: sideColor,
                        bgColor: bgColor,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 225,
          width: double.infinity,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              bottomRight: Radius.circular(150),
            ),
            image: DecorationImage(
              image: AssetImage(
                'assets/Images/NotificationScreen/background_notification.jpeg',
              ),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(150),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                  const Color(0XFFFF3502).withOpacity(0.7),
                ],
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
        const Positioned(
          bottom: 30,
          left: 23,
          child: Text(
            "NOTIFICATIONS",
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Positioned(
          bottom: -5,
          right: 22,
          child: Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: const Color(0XFFFF0B01),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.notifications, color: Colors.white, size: 28),
          ),
        ),
      ],
    );
  }

  Widget _notificationItem({
    required Appointment appointment,
    required Color sideColor,
    required Color bgColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: sideColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appointment.displayMessage,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            appointment.formattedDateTime,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.close,
                      size: 24,
                      color: sideColor.withOpacity(0.8),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


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
