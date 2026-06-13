import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neo_parlour/provider/customer/auth_provider.dart';
import 'package:provider/provider.dart';
import '../../provider/customer/service_provider.dart';
import '../../core/domain/models/neo_service.dart';
import '../../widgets/custom_nav_bar.dart';
import 'select_services_screen.dart';
import 'services_screen.dart';
import 'select_date_time_screen.dart';
import '../../provider/customer/staff_provider.dart';
import '../../provider/customer/offer_provider.dart';
import '../../provider/customer/booking_provider.dart';
import '../../provider/customer/package_provider.dart';
import '../../provider/customer/product_provider.dart';
import '../../core/domain/models/offer.dart';
import '../../core/domain/models/package_model.dart';
import 'package:intl/intl.dart';
import '../../widgets/staff_image_widgets.dart';
import 'top_experts_screen.dart';
import 'beauty_products_screen.dart';
import 'product_details_screen.dart';
import 'custom_search_delegate.dart';
import '../../widgets/premium_image.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initLocalNotifications();
    requestPermission();
    getFCMToken();
    listenForeground();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ServiceProvider>().fetchServices();
      context.read<StaffProvider>().fetchStaff();
      context.read<OfferProvider>().fetchActiveOffers();
      context.read<PackageProvider>().fetchPackages();
      context.read<ProductProvider>().fetchProducts();
    });
  }

  void _initLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_notification');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Create high importance channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  //  Ask notification permission (Android 13+)
  void requestPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint('Permission status: ${settings.authorizationStatus}');
  }

  //  Get FCM Token 
  void getFCMToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    debugPrint("FCM Token: $token");

    if (token != null && mounted) {
      context.read<AuthProvider>().updateFcmTokenOnServer(token);
    }
  }

   //  FOREGROUND NOTIFICATION LISTENER (APP OPEN)
  void listenForeground() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'High Importance Notifications',
              channelDescription: 'This channel is used for important notifications.',
              importance: Importance.max,
              priority: Priority.high,
              icon: 'ic_notification',
            ),
          ),
        );
      }
      debugPrint("Foreground notification: ${message.notification?.title}");
    });
  }



  @override
  Widget build(BuildContext context) {
    // Design width is 375.
    final mq = MediaQuery.of(context);
    final sw = mq.size.width;
    final scale = sw / 375.0;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBody: true,
      backgroundColor: Colors.white,
      
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            context.read<ServiceProvider>().fetchServices(),
            context.read<StaffProvider>().fetchStaff(),
            context.read<OfferProvider>().fetchActiveOffers(),
            context.read<PackageProvider>().fetchPackages(),
            context.read<ProductProvider>().fetchProducts(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // ================= HEADER SECTION =================
              // Rectangle 418 + 86
              _buildHeader(sw, scale),

              // ================= SERVICES SECTION =================
              _buildSectionHeader("SERVICES", sw, scale),
              _buildServicesGrid(sw, scale),

              // ================= TOP SPECIALIST SECTION =================
              _buildSectionHeader(
                "TOP SPECIALIST",
                sw,
                scale,
                hasSeeMore: true,
                onSeeMore: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const TopExpertsScreen()),
                  );
                },
              ),
              _buildTopSpecialists(sw, scale),

              // ================= POPULAR PRODUCTS SECTION =================
              _buildSectionHeader(
                "POPULAR PRODUCTS",
                sw,
                scale,
                hasSeeMore: true,
                onSeeMore: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const BeautyProductsScreen()),
                  );
                },
              ),
              _buildPopularProducts(sw, scale),

              // ================= OFFERS SECTION =================
              _buildSectionHeader(
                "OFFERS",
                sw,
                scale,
                hasSeeMore: true,
                onSeeMore: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SelectServicesScreen(initialCategory: "Offers"),
                  ),
                ),
              ),
              _buildOffers(sw, scale),

              // ================= BEST SELLING PACKAGES SECTION =================
              _buildSectionHeader(
                "BEST SELLING PACKAGES",
                sw,
                scale,
                hasSeeMore: true,
                onSeeMore: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SelectServicesScreen(initialCategory: "Best Selling Packages"),
                  ),
                ),
              ),
              _buildBestSellingPackages(sw, scale),

              // ================= LOCATION SECTION =================
              _buildSectionHeader("LOCATION", sw, scale),
              _buildLocationGrid(scale),

              SizedBox(height: 120 * scale), 
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(),
      floatingActionButton: _buildCenterFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildHeader(double sw, double scale) {
    return SizedBox(
      height: 316,
      width: sw,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Header background with concave curve
          Positioned(
            top: -1,
            left: 0,
            right: 0,
            height: 316,
            child: ClipPath(
              clipper: HeaderClipper(),
              child: Image.asset(
                "assets/Images/HomeScreen/header_bg.jpeg",
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(color: Colors.grey.shade300),
              ),
            ),
          ),

          // Gradient overlay
          Positioned(
            top: 159,
            left: 0,
            right: 0,
            height: 156,
            child: ClipPath(
              clipper: HeaderClipper(),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(0.00, -1.00),
                    end: Alignment(0.00, 1.00),
                    colors: [Color(0x008B8B8B), Color(0xFFFF3502)],
                    stops: [0.32, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // Search Bar
          Positioned(
            top: 60 * scale,
            left: 24 * scale,
            right: 24 * scale,
            child: GestureDetector(
              onTap: () {
                showSearch(
                  context: context,
                  delegate: CustomSearchDelegate(),
                );
              },
              child: Container(
                height: 48 * scale,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x19000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Color(0XFF8D8D8D)),
                    const SizedBox(width: 8),
                    Text(
                      "Search",
                      style: GoogleFonts.poppins(
                        color: const Color(0XFF8D8D8D),
                        fontSize: 14 * scale,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // WELCOME Text
          Positioned(
            left: 24 * scale,
            bottom: 40 * scale,
            child: Text(
              "WELCOME",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 32 * scale,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          // Floating Action Badge
          Positioned(
            bottom: -5,
            right: 22,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  // Service-first flow: reset any stale staff selection
                  context.read<StaffProvider>().resetStaffState();
                  context.read<BookingProvider>().setPreSelectedStaff(null);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SelectServicesScreen(),
                    ),
                  );
                },
                child: SvgPicture.asset(
                  "assets/Images/HomeScreen/floating_action_btn.svg",
                  width: 70,
                  height: 70,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    double sw,
    double scale, {
    bool hasSeeMore = false,
    VoidCallback? onSeeMore,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24 * scale,
        30 * scale,
        24 * scale,
        16 * scale,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16 * scale,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          if (hasSeeMore)
            GestureDetector(
              onTap: onSeeMore,
              child: Text(
                "See More",
                style: GoogleFonts.poppins(
                  fontSize: 10 * scale,
                  fontWeight: FontWeight.w500,
                  color: const Color(0XFF8D8D8D),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildServicesGrid(double sw, double scale) {
    return Consumer<ServiceProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0XFFFF0B01)),
          );
        }

        if (provider.error != null) {
          return Center(
            child: Text(
              provider.error ?? "Error loading services",
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          );
        }

        final allServices = List<NeoService>.from(provider.services);
        // Sort services by ID ascending (1, 2, 3...)
        allServices.sort((a, b) => a.id.compareTo(b.id));

        final bool isOverflow = allServices.length > 7;
        final displayServices = isOverflow
            ? allServices.take(7).toList()
            : allServices;

        return Wrap(
          spacing: 16 * scale,
          runSpacing: 16 * scale,
          alignment: WrapAlignment.center,
          children: [
            ...displayServices.map((s) => _serviceCard(s, scale)),
            if (isOverflow)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ServicesScreen(),
                    ),
                  );
                },
                child: SizedBox(
                  width: 76 * scale,
                  child: Column(
                    children: [
                      Container(
                        height: 76 * scale,
                        width: 76 * scale,
                        padding: EdgeInsets.all(18 * scale),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(color: Color(0x0D000000), blurRadius: 4),
                          ],
                        ),
                        child: SvgPicture.asset(
                          "assets/Images/HomeScreen/more_services.svg",
                        ),
                      ),
                      SizedBox(height: 12 * scale),
                      Text(
                        "More",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 10 * scale,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (allServices.isEmpty) Text("No services available"),
          ],
        );
      },
    );
  }

  Widget _serviceCard(NeoService service, double scale) {
    String iconPath = "assets/Images/BookAppointmentScreen/service_icon.svg";
    String label = service.name;

    final lowerName = service.name.toLowerCase();
    if (lowerName.contains("haircut") || lowerName.contains("hair cut")) {
      iconPath = "assets/Images/HomeScreen/hair_cut_services.svg";
    } else if (lowerName.contains("color")) {
      iconPath = "assets/Images/HomeScreen/hair_coloring_services.svg";
    } else if (lowerName.contains("spa")) {
      iconPath = "assets/Images/HomeScreen/hair_spa_services.svg";
    } else if (lowerName.contains("shaving") || lowerName.contains("shave")) {
      iconPath = "assets/Images/HomeScreen/shaving_services.svg";
    } else if (lowerName.contains("wash")) {
      iconPath = "assets/Images/HomeScreen/hair_wash_services.svg";
    } else if (lowerName.contains("straightning") ||
        lowerName.contains("straighten")) {
      iconPath = "assets/Images/HomeScreen/straightning_services.svg";
    } else if (lowerName.contains("styling") || lowerName.contains("style")) {
      iconPath = "assets/Images/HomeScreen/hair_styling_services.svg";
    }else {

      // ✅ EVERYTHING ELSE

      iconPath = "assets/Images/HomeScreen/common_service.svg";

    }

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
      child: SizedBox(
        width: 76 * scale,
        child: Column(
          children: [
            Container(
              height: 76 * scale,
              width: 76 * scale,
              padding: EdgeInsets.all(18 * scale),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Color(0x0D000000), blurRadius: 4),
                ],
              ),
              child: SvgPicture.asset(iconPath),
            ),
            SizedBox(height: 12 * scale),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 10 * scale,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSpecialists(double sw, double scale) {
    return Consumer<StaffProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0XFFFF0B01)),
          );
        }

        if (provider.error != null) {
          return Center(
            child: Text(
              "Error: ${provider.error}",
              style: const TextStyle(fontSize: 10),
            ),
          );
        }

        final experts = provider.staffList;
        if (experts.isEmpty) {
          return const Center(child: Text("No specialists found"));
        }

        return SizedBox(
          height: 194 * scale,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: experts.length > 5 ? 5 : experts.length,
            itemBuilder: (context, index) {
              final e = experts[index];

              return GestureDetector(
                onTap: () {
                  final staffProvider = context.read<StaffProvider>();
                  final bookingProvider = context.read<BookingProvider>();

                  // Pre-select this specialist
                  staffProvider.selectStaff(e);

                  // Clear previous service/slot state; staff-specific slots will be
                  // fetched in SelectDateTimeScreen's initState.
                  bookingProvider.applyOffer(null);
                  bookingProvider.setSelectedPackage(null);
                  bookingProvider.setPreSelectedStaff(e.id, durationMinutes: 45);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SelectDateTimeScreen(),
                    ),
                  );
                },
                child: Container(
                  width: 137 * scale,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: const Color(0XFFD9D9D9),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: StaffAvatar(
                          imageAsBase64: e.imageAsBase64,
                          imageUrl: e.image,
                          gender: e.gender,
                          borderRadius: 16,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                      // Gradient Overlay
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                const Color(0xCCFF3502).withValues(alpha: 0.5),
                                const Color(0xCCFF3502), 
                              ],
                              stops: const [0.4, 0.75, 1.0],
                            ),
                          ),
                        ),
                      ),
                      // Text Content
                      Positioned(
                        left: 12 * scale,
                        bottom: 12 * scale,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              e.name,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 14 * scale,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              e.staffStatus,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 10 * scale,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPopularProducts(double sw, double scale) {
    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0XFFFF0B01)),
          );
        }

        if (provider.error != null) {
          return Center(
            child: Text(
              provider.error ?? "Error loading products",
              style: GoogleFonts.poppins(color: Colors.red, fontSize: 10 * scale),
            ),
          );
        }

        final products = provider.products;
        if (products.isEmpty) {
          return Center(
            child: Text(
              "No products available",
              style: GoogleFonts.poppins(color: Colors.grey, fontSize: 10 * scale),
            ),
          );
        }

        return SizedBox(
          height: 220 * scale,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: products.length > 5 ? 5 : products.length,
            itemBuilder: (context, index) {
              final p = products[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailsScreen(productId: p.id),
                    ),
                  );
                },
                child: Container(
                  width: 137 * scale,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white,
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        bottom: 40 * scale,
                        child: PremiumImageWidget(
                          imageUrl: p.imageUrl ?? p.imageBase64,
                          width: double.infinity,
                          height: double.infinity,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          fallbackWidget: Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.image, color: Colors.grey),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.favorite_border,
                            size: 16,
                            color: Colors.red,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 12 * scale,
                        bottom: 12 * scale,
                        right: 12 * scale,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              p.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 12 * scale,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              "₹${p.discountPrice.toInt()}",
                              style: GoogleFonts.poppins(
                                fontSize: 10 * scale,
                                fontWeight: FontWeight.w500,
                                color: const Color(0XFFFF0B01),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildOffers(double sw, double scale) {
    return Consumer<OfferProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0XFFFF0B01)),
          );
        }

        if (provider.errorMessage != null) {
          return Center(
            child: Text(
              provider.errorMessage ?? "Error loading offers",
              style: GoogleFonts.poppins(
                fontSize: 10 * scale,
                color: Colors.red,
              ),
            ),
          );
        }

        final offers = provider.offers;
        if (offers.isEmpty) {
          return Center(
            child: Text(
              "No active offers available",
              style: GoogleFonts.poppins(
                fontSize: 10 * scale,
                color: Colors.grey,
              ),
            ),
          );
        }

        return SizedBox(
          height: 160 * scale,
          child: PageView.builder(
            itemCount: offers.length > 5 ? 5 : offers.length,
            controller: PageController(viewportFraction: 0.9),
            itemBuilder: (context, index) {
              final offer = offers[index];
              return _offerCard(offer, scale);
            },
          ),
        );
      },
    );
  }

  Widget _offerCard(Offer offer, double scale) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final discountStr = offer.discountType == 'PERCENTAGE'
        ? "${offer.discountValue.toInt()}% OFF"
        : "₹${offer.discountValue.toInt()} OFF";

    return Container(
      width: 326 * scale,
      height: 160 * scale,
      margin: EdgeInsets.symmetric(horizontal: 8 * scale),
      decoration: BoxDecoration(
        color: const Color(0XFFFF0B01),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33FF0B01),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Opacity(
              opacity: 0.1,
              child: Text(
                offer.discountValue.toInt().toString(),
                style: GoogleFonts.poppins(
                  fontSize: 120,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20 * scale),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offer.name.toUpperCase(),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16 * scale,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4 * scale),
                Text(
                  offer.description,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 10 * scale,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (offer.applicableServices.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 4 * scale),
                    child: Text(
                      "Valid on: ${offer.applicableServices.map((s) => s.name).join(", ")}",
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 9 * scale,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () {
                        // Service-first flow: reset any stale staff selection
                        final serviceProvider = context.read<ServiceProvider>();
                        final bookingProvider = context.read<BookingProvider>();
                        context.read<StaffProvider>().resetStaffState();
                        bookingProvider.setPreSelectedStaff(null);

                        final serviceIds = offer.applicableServices
                            .map((s) => s.id)
                            .toList();

                        serviceProvider.preselectServices(serviceIds);
                        bookingProvider.applyOffer(offer);
                        bookingProvider.setSelectedPackage(null);
                        bookingProvider.selectSlot(null);

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SelectDateTimeScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16 * scale,
                          vertical: 6 * scale,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "CLAIM OFFER",
                          style: GoogleFonts.poppins(
                            color: const Color(0XFFFF0B01),
                            fontSize: 10 * scale,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          discountStr,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14 * scale,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          "Valid Till ${dateFormat.format(offer.validTo)}",
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 8 * scale,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBestSellingPackages(double sw, double scale) {
    return Consumer<PackageProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0XFFFF0B01)),
          );
        }

        if (provider.errorMessage != null) {
          return Center(
            child: Text(
              provider.errorMessage ?? "Error loading packages",
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          );
        }

        final packages = provider.packages;
        if (packages.isEmpty) {
          return const Center(child: Text("No packages available"));
        }

        return SizedBox(
          height: 160 * scale,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16 * scale),
            itemCount: packages.length > 5 ? 5 : packages.length,
            itemBuilder: (context, index) {
              return _packageCard(packages[index], scale);
            },
          ),
        );
      },
    );
  }

  Widget _packageCard(PackageModel package, double scale) {
    return GestureDetector(
      onTap: () {
        final serviceProvider = context.read<ServiceProvider>();
        final bookingProvider = context.read<BookingProvider>();

        // Service-first flow: reset any stale staff selection
        context.read<StaffProvider>().resetStaffState();
        bookingProvider.setPreSelectedStaff(null);

        final serviceIds = package.services.map((s) => s.id).toList();
        serviceProvider.preselectServices(serviceIds);
        bookingProvider.applyOffer(null);
        bookingProvider.setSelectedPackage(package);
        bookingProvider.selectSlot(null);

        Navigator.push(context, MaterialPageRoute(builder: (context) => const SelectDateTimeScreen()));
      },
      child: Container(
        width: 326 * scale,
        height: 160 * scale,
        margin: EdgeInsets.symmetric(horizontal: 8 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15 * scale),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background grey area for text
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 200 * scale,
            child: Container(color: const Color(0XFFF5F5F5)),
          ),
          // Person image
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 151 * scale,
            child: Image.asset(
              "assets/Images/HomeScreen/package_image.png",
              fit: BoxFit.cover,
            ),
          ),
          // Subtler Gradient for text blending
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.transparent,
                    const Color(0XFFFF0B01).withValues(alpha: 0.2),
                    const Color(0XFFFF0B01).withValues(alpha: 0.6),
                  ],
                  stops: const [0.5, 0.7, 1.0],
                ),
              ),
            ),
          ),

          // Content on the left
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 16 * scale,
              vertical: 12 * scale,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "₹ ${package.packagePrice.toInt()}",
                  style: GoogleFonts.poppins(
                    fontSize: 24 * scale,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 2 * scale),
                SizedBox(
                  width: 150 * scale,
                  child: Text(
                    "${package.name}\n${package.services.map((s) => s.name).join("\n")}",
                    style: GoogleFonts.poppins(
                      fontSize: 10 * scale,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                      height: 1.2,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(height: 8 * scale),
                GestureDetector(
                  onTap: () {
                    final serviceProvider = context.read<ServiceProvider>();
                    final bookingProvider = context.read<BookingProvider>();

                    // Service-first flow: reset any stale staff selection
                    context.read<StaffProvider>().resetStaffState();
                    bookingProvider.setPreSelectedStaff(null);

                    final serviceIds = package.services.map((s) => s.id).toList();
                    serviceProvider.preselectServices(serviceIds);
                    bookingProvider.applyOffer(null);
                    bookingProvider.setSelectedPackage(package);
                    // Clear any previously selected slot/staff so the new flow is fresh
                    bookingProvider.selectSlot(null);

                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SelectDateTimeScreen()));
                  },
                  child: Container(
                    width: 90 * scale,
                    height: 26 * scale,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14 * scale),
                      gradient: const LinearGradient(
                        colors: [Color(0XFFD80800), Color(0XFF990701)],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        "CLAIM OFFER",
                        style: GoogleFonts.poppins(
                          fontSize: 10 * scale,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ) );

  }

  Widget _buildLocationGrid(double scale) {
    final List<String> cities = ["PUNE", "NASHIK", "MUMBAI", "NAVI MUMBAI"];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24 * scale),
      child: GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: cities.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // 👈 2 per row
          crossAxisSpacing: 16 * scale,
          mainAxisSpacing: 16 * scale,
          childAspectRatio: 2.5, // matches sleek wide Figma design
        ),
        itemBuilder: (context, index) {
          return _locationCard(cities[index], scale);
        },
      ),
    );
  }

  Widget _locationCard(String city, double scale) {
    return Container(
      width: 156 * scale,
      height: 43 * scale,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0XFF909090)),
      ),
      child: Row(
        children: [
          Container(
            height: 25 * scale,
            width: 25 * scale,
            decoration: BoxDecoration(
              color: const Color(0XFFD9D9D9),
              borderRadius: BorderRadius.circular(3),
            ),
            padding: const EdgeInsets.all(4),
            child: SvgPicture.asset(
              "assets/Images/HomeScreen/location_icon.svg",
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  city,
                  style: GoogleFonts.poppins(
                    fontSize: 12 * scale,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "100 OUTLETS",
                  style: GoogleFonts.poppins(
                    fontSize: 8 * scale,
                    color: const Color(0XFF8D8D8D),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterFAB() {
    return GestureDetector(
      onTap: () {
        // Already on Home
      },
      child: Container(
        height: 60,
        width: 60,
        decoration: BoxDecoration(
          color: const Color(0XFFFF0B01),
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Color(0x422C2C2C),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: SvgPicture.asset(
            "assets/Images/BottomNavigationBar/home_icon.svg",
            width: 24,
            height: 24,
            fit: BoxFit.contain,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }
}

// Custom Clipper for the header curve
class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height);
    path.lineTo(size.width * 0.65, size.height);
    path.quadraticBezierTo(
      size.width * 0.85,
      size.height,
      size.width,
      size.height * 0.6,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
