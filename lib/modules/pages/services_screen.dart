import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import '../../provider/customer/service_provider.dart';
import '../../provider/customer/staff_provider.dart';
import '../../provider/customer/booking_provider.dart';
import '../../core/domain/models/neo_service.dart';
import '../../widgets/custom_nav_bar.dart';
import 'home_screen.dart';
import 'select_date_time_screen.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ServiceProvider>().fetchServices();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      bottomNavigationBar: const CustomBottomNavBar(selectedLabel: "SERVICES"),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        },
        backgroundColor: const Color(0xFFFF0B01),
        elevation: 5,
        shape: const CircleBorder(),
        child: SvgPicture.asset(
          "assets/Images/BottomNavigationBar/home_icon.svg",
        ),
      ),
      body: Consumer<ServiceProvider>(
        builder: (context, provider, child) {
          return RefreshIndicator(
            onRefresh: () async {
              await context.read<ServiceProvider>().fetchServices();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // --- 1. HEADER SECTION ---
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipPath(
                        clipper: ServiceHeaderClipper(),
                        child: Container(
                          height: 225,
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage(
                                'assets/Images/ServicesScreen/background_services.jpg',
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
                                  Color(0XFF8B8B8B).withValues(alpha: 0.5),
                                  Color(0xFFFF3502).withValues(alpha: 0.5),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Title
                      const Positioned(
                        bottom: 35,
                        left: 20,
                        child: Text(
                          "SERVICES",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      // Back Button
                      Positioned(
                        top: 55,
                        left: 20,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.white.withValues(alpha: 0.4),
                            child: const Icon(
                              Icons.chevron_left,
                              color: Colors.black,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                      // Red Floating Bag Icon
                      Positioned(
                        bottom: 5,
                        right: 25,
                        child: Container(
                          height: 55,
                          width: 55,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF0B01),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: SvgPicture.asset(
                              "assets/Images/TopExpertsScreen/floating_top_icon.svg",
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // --- 2. GRID SECTION ---
                  if (provider.isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 50),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFFF0B01),
                        ),
                      ),
                    )
                  else if (provider.error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 50),
                      child: Center(child: Text("Error: ${provider.error}")),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: provider.services.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 15,
                              mainAxisSpacing: 15,
                              childAspectRatio: 1.0,
                            ),
                        itemBuilder: (context, index) {
                          final service = provider.services[index];
                          return _buildServiceCard(service);
                        },
                      ),
                    ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildServiceCard(NeoService service) {
    return GestureDetector(
      onTap: () {
        final serviceProvider = context.read<ServiceProvider>();
        final bookingProvider = context.read<BookingProvider>();

        // Service-first flow: reset any stale staff selection
        context.read<StaffProvider>().resetStaffState();
        bookingProvider.setPreSelectedStaff(null);

        // Clear previous and set new selection
        serviceProvider.preselectServices([service.id]);
        bookingProvider.applyOffer(null);
        bookingProvider.setSelectedPackage(null);

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SelectDateTimeScreen()),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFFF5F5F5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // 1. The Image
            Positioned.fill(child: _buildServiceImage(service.image)),

            // 2. The Gradient Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      const Color(0xFFFF0B01).withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
            ),

            // 3. The Text
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  service.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

Widget _buildServiceImage(String? imagePath) {
  const String defaultImage = "assets/Images/ServicesScreen/watermark.png";

  // 1️⃣ If no image from backend → show default image
  if (imagePath == null || imagePath.isEmpty) {
    return Image.asset(defaultImage, fit: BoxFit.cover);
  }

  // 2️⃣ If image is from internet
  if (imagePath.startsWith('http')) {
    return Image.network(
      imagePath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(defaultImage, fit: BoxFit.cover);
      },
    );
  }

  // 3️⃣ If image is local asset path from backend
  return Image.asset(
    imagePath,
    fit: BoxFit.cover,
    errorBuilder: (context, error, stackTrace) {
      return Image.asset(defaultImage, fit: BoxFit.cover);
    },
  );
}

// --- FIXED CLIPPER ---
class ServiceHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height);
    path.lineTo(
      size.width * 0.65,
      size.height,
    ); // Adjusted for a smoother S-start

    // The "S" curve transition
    path.quadraticBezierTo(
      size.width * 0.85,
      size.height, // Control Point
      size.width,
      size.height * 0.7, // End Point
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
