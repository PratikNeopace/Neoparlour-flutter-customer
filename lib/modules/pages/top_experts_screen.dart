import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:neo_parlour/widgets/custom_nav_bar.dart';
import 'package:provider/provider.dart';
import 'home_screen.dart';
import 'select_date_time_screen.dart';
import '../../provider/customer/staff_provider.dart';
import '../../provider/customer/booking_provider.dart';
import '../../core/domain/models/staff.dart';
import '../../widgets/staff_image_widgets.dart';

class TopExpertsScreen extends StatefulWidget {
  const TopExpertsScreen({super.key});

  @override
  State<TopExpertsScreen> createState() => _TopExpertsScreenState();
}

class _TopExpertsScreenState extends State<TopExpertsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StaffProvider>().fetchAllStaff();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      bottomNavigationBar: const CustomBottomNavBar(selectedLabel: "EXPERT"),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        ),
        backgroundColor: const Color(0XFFFF0B01),
        elevation: 4,
        shape: const CircleBorder(),
        child: SvgPicture.asset(
          "assets/Images/BottomNavigationBar/home_icon.svg",
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<StaffProvider>().fetchAllStaff();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
            // ================= 1. HEADER WITH S-CURVE =================
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipPath(
                  clipper: HeaderCurveClipper(),
                  child: Container(
                    height: 225,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(
                          'assets/Images/SelectProfessionalScreen/select_professional_background_img.jpeg',
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
                            Colors.black.withOpacity(0.3),
                            Colors.transparent,
                            const Color(0XFFFF3502).withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Title Text
                const Positioned(
                  bottom: 30,
                  left: 23,
                  child: Text(
                    "TOP EXPERTS",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                // Floating Action Badge
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
                    child: Center(
                      child: SvgPicture.asset(
                        "assets/Images/TopExpertsScreen/floating_top_icon.svg",
                        width: 28,
                        height: 28,
                      ),
                    ),
                  ),
                ),

                // Back Button
                Positioned(
                  top: 50,
                  left: 20,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: CircleAvatar(
                      backgroundColor: Colors.white.withOpacity(0.4),
                      child: const Icon(
                        Icons.chevron_left,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 36),

            // ================= 2. EXPERTS GRID =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Consumer<StaffProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator(color: Color(0XFFFF0B01)));
                  }
                  
                  if (provider.error != null) {
                    return Center(child: Text("Error: ${provider.error}", style: const TextStyle(color: Colors.red)));
                  }

                  if (provider.staffList.isEmpty) {
                    return const Center(child: Text("No experts found."));
                  }

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: provider.staffList.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      childAspectRatio: 0.82,
                    ),
                    itemBuilder: (context, index) {
                      return _buildExpertCard(provider.staffList[index]);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 120),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildExpertCard(Staff staff) {
    return GestureDetector(
      onTap: () {
        final staffProvider = context.read<StaffProvider>();
        final bookingProvider = context.read<BookingProvider>();

        staffProvider.selectStaff(staff);
        // Prime the booking provider for staff-specific slot fetching.
        // Duration defaults to 45 mins; will be recalculated in SelectDateTimeScreen
        // once services are chosen.
        bookingProvider.applyOffer(null);
        bookingProvider.setPreSelectedStaff(staff.id, durationMinutes: 45);

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SelectDateTimeScreen()),
        );
      },
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color(0xFFF5F5F5),
        ),
        child: Stack(
          children: [
            // Image Layer
            Positioned.fill(
              child: StaffAvatar(
                imageAsBase64: staff.imageAsBase64,
                gender: staff.gender,
                borderRadius: 20,
                width: double.infinity,
                height: double.infinity,
              ),
            ),

            // Gradient Overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.1),
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
              ),
            ),

            // Star Rating
            Positioned(
              top: 10,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 12),
                    Text(
                      " ${staff.rating ?? '4.5'}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Expert Details
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    staff.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    staff.salonName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
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
}


// ================= CUSTOM CLIPPER =================
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