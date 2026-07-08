import 'package:provider/provider.dart';
import 'package:neo_parlour/provider/customer/auth_provider.dart';
import 'package:neo_parlour/modules/pages/salon_details_screen.dart';
import 'package:neo_parlour/modules/pages/salon_id_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../modules/pages/services_screen.dart';
import '../modules/pages/top_experts_screen.dart';
import '../modules/pages/notification_screen.dart';
import '../modules/pages/drawer_screen.dart';

class CustomBottomNavBar extends StatefulWidget {
  final String? selectedLabel;
  const CustomBottomNavBar({super.key, this.selectedLabel});

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
  String? hoveredLabel;

  void _onTap(String label) {
    if (label == widget.selectedLabel) return;

    if (label == "SERVICES") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ServicesScreen()),
      );
    } else if (label == "HOME") {
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
    } else if (label == "EXPERT") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const TopExpertsScreen()),
      );
    } else if (label == "NOTIFICATION") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const NotificationScreen()),
      );
    } else if (label == "SETTINGS") {
      DrawerScreen.show(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double systemNavBar = MediaQuery.of(context).padding.bottom;
    const double navHeight = 70;
    const double notchRadius = 28;
    const double notchMargin = 6;

    return SizedBox(
      height: navHeight + notchMargin + systemNavBar,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: Size(double.infinity, navHeight + notchMargin + systemNavBar),
              painter: _NavBarPainter(
                notchRadius: notchRadius,
                notchMargin: notchMargin,
                systemNavBar: systemNavBar,
              ),
              child: SizedBox(
                height: navHeight + notchMargin + systemNavBar,
                child: Column(
                  children: [
                    const SizedBox(height: notchMargin),
                    SizedBox(
                      height: navHeight,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _navItem(
                            "assets/Images/BottomNavigationBar/services_icon.svg",
                            "SERVICES",
                          ),
                          _navItem(
                            "assets/Images/BottomNavigationBar/experts_icon.svg",
                            "EXPERT",
                          ),
                          const SizedBox(width: 80), // FAB space
                          _navItem(
                            "assets/Images/BottomNavigationBar/notification_icon.svg",
                            "NOTIFICATION",
                          ),
                          _navItem(
                            "assets/Images/BottomNavigationBar/settings_icon.svg",
                            "SETTINGS",
                          ),
                        ],
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

  Widget _navItem(String iconPath, String label) {
    final bool isActive = widget.selectedLabel == label;
    final bool isHovered = hoveredLabel == label;
    final Color itemColor = (isActive || isHovered) ? const Color(0xFFFF0B01) : const Color(0XFF868686);

    return InkWell(
      onTap: () => _onTap(label),
      onHover: (hovering) {
        setState(() {
          hoveredLabel = hovering ? label : null;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: SvgPicture.asset(
                iconPath,
                fit: BoxFit.contain,
                colorFilter: ColorFilter.mode(itemColor, BlendMode.srcIn),
                placeholderBuilder: (context) => const Icon(Icons.image, size: 20),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              label,
              style: TextStyle(
                color: itemColor,
                fontSize: 9,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavBarPainter extends CustomPainter {
  final double notchRadius;
  final double notchMargin;
  final double systemNavBar;

  const _NavBarPainter({
    required this.notchRadius,
    required this.notchMargin,
    required this.systemNavBar,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final double cx = size.width / 2;
    final double m = notchMargin;
    final double top = m;

    final path = Path()
      ..moveTo(0, top)
      ..lineTo(cx - 70, top)
      ..quadraticBezierTo(cx - 45, top, cx - 38, top + 7)
      ..arcToPoint(
        Offset(cx + 38, top + 7),
        radius: const Radius.circular(38),
        clockwise: false,
      )
      ..quadraticBezierTo(cx + 45, top, cx + 70, top)
      ..lineTo(size.width, top)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, shadowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}