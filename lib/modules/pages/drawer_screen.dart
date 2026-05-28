import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'login_screen.dart';
import 'my_booking_screen.dart';
import 'my_orders_screen.dart';
import 'salon_id_screen.dart';
import '../../provider/customer/auth_provider.dart';

class DrawerScreen extends StatelessWidget {
  const DrawerScreen({super.key});

  /// Call this to open drawer
  static void show(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Drawer',
      barrierColor: Colors.black.withOpacity(0.15),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => const DrawerScreen(),
      transitionBuilder: (_, animation, __, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOut),
          ),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context), // close when tapping outside
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () {}, // prevent close when tapping drawer
            child: _drawerContent(context),
          ),
        ),
      ),
    );
  }

  /// Drawer UI
  Widget _drawerContent(BuildContext context) {
    final drawerWidth = MediaQuery.of(context).size.width * 0.78;

    return Container(
      width: drawerWidth,
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            /// Back Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        size: 18,
                        color: Color(0XFF2D2D2D),
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),

            const SizedBox(height: 12),

            /// Logo
            SvgPicture.asset(
              "assets/Images/SplashScreen/neo_parlour_logo.svg",
              height: 75,
              width: 85,
            ),

            const SizedBox(height: 42),

            /// First Group
            _buildGroupContainer([
              _buildRow(
                "assets/Images/DrawerScreen/profile_icon.svg",
                'Profile',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                ),
              ),
              _divider(),
              _buildRow(
                "assets/Images/DrawerScreen/about_us_icon.svg",
                'About Us',
              ),
              _divider(),
              _buildRow(
                "assets/Images/DrawerScreen/support_icon.svg",
                'Support',
              ),
              _divider(),
              _buildRow(
                "assets/Images/DrawerScreen/booking_icon.svg",
                'My Bookings',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyBookingScreen()),
                ),
              ),
              _divider(),
              _buildRow(
                "assets/Images/DrawerScreen/Order-icon.svg",
                'My Orders',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
                ),
              ),
            ]),

            const SizedBox(height: 24),

            /// Second Group
            _buildGroupContainer([
              _buildRowIcon(
                Icons.storefront_outlined,
                'Switch Saloon',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SalonIDScreen()),
                  );
                },
              ),
              _divider(),
              _buildRow(
                "assets/Images/DrawerScreen/logout_icon.svg",
                'LOGOUT',
                onTap: () async {
                  await context.read<AuthProvider>().logout();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(),
                      ),
                      (_) => false,
                    );
                  }
                },
              ),
            ]),

            const Spacer(),

            /// Footer
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0XFF626262),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Powered By Neopaceinfotech LLP',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0XFF626262),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helpers
  Widget _buildGroupContainer(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: const Color(0XFFDFDFDF)),
        ),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildRow(String icon, String title, {VoidCallback? onTap}) {
    return ListTile(
      visualDensity: const VisualDensity(vertical: -2),
      leading: SvgPicture.asset(icon),
      title: Text(
        title,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        size: 15,
        color: Color(0XFF868686),
      ),
      onTap: onTap,
    );
  }

  Widget _buildRowPng(String icon, String title, {VoidCallback? onTap}) {
    return ListTile(
      visualDensity: const VisualDensity(vertical: -2),
      leading: Image.asset(icon, width: 20, height: 20),
      title: Text(
        title,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        size: 15,
        color: Color(0XFF868686),
      ),
      onTap: onTap,
    );
  }

  Widget _buildRowIcon(IconData iconData, String title, {VoidCallback? onTap}) {
    return ListTile(
      visualDensity: const VisualDensity(vertical: -2),
      leading: Icon(iconData, size: 20, color: const Color(0XFF2D2D2D)),
      title: Text(
        title,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        size: 15,
        color: Color(0XFF868686),
      ),
      onTap: onTap,
    );
  }

  Widget _divider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey.shade100,
    );
  }
}