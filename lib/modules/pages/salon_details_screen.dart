import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../../provider/customer/package_provider.dart';
import '../../core/domain/models/package_model.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/data/api_client.dart';
import '../../provider/customer/staff_provider.dart';
import '../../provider/customer/booking_provider.dart';
import '../../provider/customer/service_provider.dart';
import '../../provider/customer/product_provider.dart';
import '../../core/domain/models/offer.dart';
import '../../widgets/staff_image_widgets.dart';
import '../../widgets/premium_image.dart';
import 'select_services_screen.dart';
import 'select_date_time_screen.dart';
import 'select_staff_screen.dart';
import 'top_experts_screen.dart';
import 'beauty_products_screen.dart';
import 'product_details_screen.dart';
import '../../core/domain/models/available_slot.dart';
import '../../widgets/custom_nav_bar.dart';
import '../../core/utils/flushbar_helper.dart';
import '../../provider/customer/auth_provider.dart';
import 'splash_two_screen.dart';

class SalonDetailsScreen extends StatefulWidget {
  final int salonId;

  const SalonDetailsScreen({super.key, required this.salonId});

  @override
  State<SalonDetailsScreen> createState() => _SalonDetailsScreenState();
}

class _SalonDetailsScreenState extends State<SalonDetailsScreen> {
  final ApiClient _apiClient = ApiClient();

  Map<String, dynamic>? _salon;
  List<dynamic> _offers = [];
  List<dynamic> _slots = [];
  bool _isLoading = true;
  bool _isServicesExpanded = false;
  String? _errorMessage;
  String? _slotsErrorMessage;

  String? _selectedSlot;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
    Future.microtask(() {
      if (mounted) {
        context.read<ServiceProvider>().fetchServices();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StaffProvider>().fetchStaff();
    });
    Future.microtask(() {
      if (mounted) {
        context.read<PackageProvider>().fetchPackages();
      }
    });
    Future.microtask(() {
      if (mounted) {
        context.read<ProductProvider>().fetchProducts();
      }
    });
  }

  Future<void> _fetchDetails({bool refresh = false}) async {
    if (!refresh) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _slotsErrorMessage = null;
      });
    }

    try {
      final todayStr = "${DateFormat("yyyy-MM-dd").format(DateTime.now())}T00:00:00Z";

      final salonFuture = _apiClient.dio.get('salons/${widget.salonId}');

      final offersFuture = _apiClient.dio.get('offers/public/search', queryParameters: {
        'active': true,
        'page': 0,
        'size': 10,
        'salonId': widget.salonId,
      }).catchError((e) {
        debugPrint("Error fetching offers: $e");
        return Response(requestOptions: RequestOptions(), data: {'content': []});
      });


      final slotsFuture = _apiClient.dio.get('appointments/public/salon-slots', queryParameters: {
        'salonId': widget.salonId,
        'selectedDate': todayStr,
      }).catchError((e) {
        debugPrint("Error fetching slots: $e");
        String message = "No available slots for booking today.";
        if (e is DioException && e.response?.data != null) {
          final data = e.response!.data;
          if (data is Map && data.containsKey('message')) {
            message = data['message']?.toString() ?? message;
          }
        }
        _slotsErrorMessage = message;
        return Response(requestOptions: RequestOptions(), data: <dynamic>[]);
      });

      final responses = await Future.wait([
        salonFuture,
        offersFuture,
        slotsFuture,
      ]);

      setState(() {
        _salon = responses[0].data;
        _offers = responses[1].data['content'] ?? [];
        _slots = responses[2].data ?? [];
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      debugPrint("Error loading salon details: $e");

      // Check for authentication errors (stale/expired token)
      final int? statusCode = (e is DioException) ? e.response?.statusCode : null;
      final bool isAuthError = statusCode == 401 || statusCode == 403;
      final bool isNotFound = statusCode == 404;
      final bool isRateLimit = statusCode == 429 || e.toString().toLowerCase().contains("rate limit");

      if (isAuthError || isNotFound) {
        // Token is expired/invalid, or salon doesn't exist (e.g. DB cleaned) — log out and send to onboarding
        if (mounted) {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          await authProvider.logout();
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const SplashTwoScreen()),
              (route) => false,
            );
          }
        }
        return;
      }

      String errorMsg;
      if (isRateLimit) {
        errorMsg = "Rate limit exceeded. Please try again later.";
      } else {
        errorMsg = "Failed to load salon details. Please check your connection.";
      }
      
      if (!refresh || _salon == null) {
        setState(() {
          _errorMessage = errorMsg;
          _isLoading = false;
        });
      } else {
        if (isRateLimit && mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              FlushbarHelper.error(context, "Rate limit exceeded. Please try again later.");
            }
          });
        }
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });

    final serviceProv = context.read<ServiceProvider>();
    final staffProv = context.read<StaffProvider>();
    final packageProv = context.read<PackageProvider>();

    await Future.wait([
      _fetchDetails(refresh: true),
      serviceProv.fetchServices(),
      staffProv.fetchStaff(),
      packageProv.fetchPackages(),
    ]);

    if (!mounted) return;

    final errors = [
      _errorMessage,
      serviceProv.error,
      staffProv.error,
      packageProv.errorMessage,
    ];

    final hasRateLimitError = errors.any((e) => e != null && e.toLowerCase().contains('rate limit'));

    if (hasRateLimitError) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          FlushbarHelper.error(context, "Rate limit exceeded. Please try again later.");
        }
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  String _getCategoryIconSvg(String category) {
    final categoryLower = category.toLowerCase().trim();
    if (categoryLower.contains("color") || categoryLower == "coloring") {
      return "assets/Images/HomeScreen/hair_coloring_services.svg";
    } else if (categoryLower.contains("spa") || categoryLower.contains("span")) {
      return "assets/Images/HomeScreen/hair_spa_services.svg";
    } else if (categoryLower.contains("styling")) {
      return "assets/Images/HomeScreen/hair_styling_services.svg";
    } else if (categoryLower.contains("wash")) {
      return "assets/Images/HomeScreen/hair_wash_services.svg";
    } else if (categoryLower.contains("shav")) {
      return "assets/Images/HomeScreen/shaving_services.svg";
    } else if (categoryLower.contains("straight")) {
      return "assets/Images/HomeScreen/straightning_services.svg";
    } else if (categoryLower.contains("cut") || categoryLower == "hair" || categoryLower == "hair services" || categoryLower == "hair cut") {
      return "assets/Images/HomeScreen/hair_cut_services.svg";
    } else if (categoryLower == "skin care" || categoryLower == "facial" || categoryLower.contains("skin") || categoryLower.contains("facial") || categoryLower.contains("lighting")) {
      return "assets/Images/HomeScreen/Skin care.svg";
    } else if (categoryLower == "hair removal" || categoryLower.contains("removal")) {
      return "assets/Images/HomeScreen/Hair removal.svg";
    } else if (categoryLower == "nail care" || categoryLower.contains("nail")) {
      return "assets/Images/HomeScreen/Nail care.svg";
    } else if (categoryLower == "makeup" || categoryLower.contains("makeup")) {
      return "assets/Images/HomeScreen/makeup.svg";
    } else if (categoryLower == "grooming" || categoryLower.contains("grooming")) {
      return "assets/Images/HomeScreen/grooming.svg";
    } else if (categoryLower == "spa & massage" || categoryLower.contains("massage")) {
      return "assets/Images/HomeScreen/spa & massage.svg";
    } else if (categoryLower == "hair treatment" || categoryLower.contains("treatment")) {
      return "assets/Images/HomeScreen/Hair treatment.svg";
    } else if (categoryLower == "more") {
      return "assets/Images/HomeScreen/more_services.svg";
    } else {
      return "assets/Images/HomeScreen/common_service.svg";
    }
  }
  Widget _buildCenterFAB() {
    return GestureDetector(
      onTap: () {
        // Service-first flow: reset any stale staff selection
        context.read<StaffProvider>().resetStaffState();
        context.read<BookingProvider>().setPreSelectedStaff(null);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SelectServicesScreen(),
          ),
        );
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
            "assets/Images/BottomNavigationBar/book_appointment_icon.svg",
            width: 24,
            height: 24,
            fit: BoxFit.contain,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final sw = mq.size.width;
    final scale = sw / 375.0;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Color(0XFFFF0B01)),
        ),
      );
    }

    if (_errorMessage != null || _salon == null) {
      final bool canGoBack = ModalRoute.of(context)?.canPop ?? false;
      return PopScope(
        canPop: canGoBack,
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            leading: canGoBack
                ? IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  )
                : null,
            backgroundColor: Colors.white,
            elevation: 0,
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _errorMessage ?? "Salon details not found",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshData,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0XFFFF0B01)),
                    child: Text("Retry", style: GoogleFonts.poppins(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final String salonName = _salon!['salonName'] ?? 'Salon';
    final String address = _salon!['address'] ?? _salon!['areaName'] ?? 'No address listed';
    final String area = _salon!['areaName'] ?? '';
    final String openingTime = _salon!['openingTime'] ?? '09:00';
    final String closingTime = _salon!['closingTime'] ?? '21:00';
    final String? weeklyOff = _salon!['weeklyOffDay'];
    final List<dynamic> salonImages = _salon!['salonImages'] ?? [];

    String heroImageUrl = _salon!['imageUrl']?.toString() ?? '';
    heroImageUrl = heroImageUrl.replaceFirst('http://', 'https://');

    final List<String> photosList = salonImages.map((img) {
      if (img is Map) {
        return img['imageUrl']?.toString() ?? '';
      }
      return img?.toString() ?? '';
    }).where((url) => url.isNotEmpty).toList();

    final serviceProvider = context.watch<ServiceProvider>();
    final activeServices = serviceProvider.services.where((s) => s.active).toList();
    activeServices.sort((a, b) => (a.displayOrder ?? 999).compareTo(b.displayOrder ?? 999));
    
    final hasMoreServices = activeServices.length > 8;
    final displayServices = _isServicesExpanded ? activeServices : activeServices.take(8).toList();

    final staffState = context.watch<StaffProvider>();

    return PopScope(
      canPop: Navigator.canPop(context),
      child: Scaffold(
        backgroundColor: const Color(0XFFF5F5F7),
        bottomNavigationBar: const CustomBottomNavBar(selectedLabel: "HOME"),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: _buildCenterFAB(),
        body: CustomScrollView(
          slivers: [
            // ================= SLIVER APP BAR (HERO IMAGE) =================
            SliverAppBar(
              pinned: true,
              expandedHeight: 185.0 * scale,
              backgroundColor: Colors.white,
              elevation: 0,
              leading: Navigator.canPop(context)
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    )
                  : null,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: () => _refreshData(),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: heroImageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: heroImageUrl.toString().replaceFirst('http://', 'https://'),
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.grey.shade200),
                      errorWidget: (context, url, error) => Container(color: Colors.grey.shade300),
                    )
                  : Container(
                      color: Colors.grey.shade200,
                      child: Icon(
                        Icons.store,
                        color: Colors.grey.shade500,
                        size: 64 * scale,
                      ),
                    ),
            ),
          ),

          // ================= CONTENT BODY =================
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ================= TITLE & SUBTITLE =================
                  Padding(
                    padding: const EdgeInsets.only(left: 24, right: 24, top: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "$salonName- $area",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 20,
                                  color: const Color(0XFF131313),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                address,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                  color: const Color(0XFF8D8D8D),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Share Button
                        IconButton(
                          icon: const Icon(Icons.share, color: Colors.black, size: 24),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          onPressed: () async {
                            final String shareText = "Check out $salonName on NeoParlour!\n"
                                "Download the app and book your appointment now: https://play.google.com/store/apps/details?id=com.example.neo_parlour";
                            await SharePlus.instance.share(
                              ShareParams(text: shareText),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Divider
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 15.0),
                    child: Divider(color: Colors.grey.shade200),
                  ),

                  // ================= SERVICES SECTION =================
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "SERVICES",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SelectServicesScreen(),
                              ),
                            );
                          },
                          child: Text(
                            "See More",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                              color: const Color(0XFFFF0B01),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Categories Grid (2 rows, 4 columns)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.9,
                      ),
                      itemCount: displayServices.length,
                      itemBuilder: (context, index) {
                        final service = displayServices[index];
                        return GestureDetector(
                          onTap: () {
                            context.read<StaffProvider>().resetStaffState();
                            context.read<BookingProvider>().setPreSelectedStaff(null);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SelectServicesScreen(
                                  initialCategory: service.category,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0XFFF9F9FA),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.03),
                                        blurRadius: 4,
                                      )
                                    ]
                                  ),
                                  child: SvgPicture.asset(
                                    _getCategoryIconSvg(service.category.isNotEmpty ? service.category : service.name),
                                    width: 24,
                                    height: 24,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  service.name,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 10,
                                    color: Colors.black,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (hasMoreServices) ...[
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isServicesExpanded = !_isServicesExpanded;
                        });
                      },
                      child: Center(
                        child: Text(
                          _isServicesExpanded ? "View Less" : "View More",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                            color: const Color(0XFFFF0B01),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  // ================= TOP SPECIALIST SECTION =================
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "TOP SPECIALIST",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const TopExpertsScreen()),
                            );
                          },
                          child: Text(
                            "See More",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                              color: const Color(0XFFFF0B01),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  staffState.isLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 20.0),
                            child: CircularProgressIndicator(color: Color(0XFFFF0B01)),
                          ),
                        )
                      : staffState.staffList.isNotEmpty
                          ? SizedBox(
                              height: 125,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                itemCount: staffState.staffList.length,
                                itemBuilder: (context, index) {
                                  final staff = staffState.staffList[index];
                                  return GestureDetector(
                                    onTap: () {
                                      final staffProvider = context.read<StaffProvider>();
                                      final bookingProvider = context.read<BookingProvider>();

                                      // Pre-select this specialist
                                      staffProvider.selectStaff(staff);

                                      // Clear previous service/slot state; staff-specific slots will be
                                      // fetched in SelectDateTimeScreen's initState.
                                      bookingProvider.applyOffer(null);
                                      bookingProvider.setSelectedPackage(null);
                                      bookingProvider.setPreSelectedStaff(staff.id, durationMinutes: 45);

                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const SelectDateTimeScreen(),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      width: 90,
                                      margin: const EdgeInsets.only(right: 12),
                                      child: Column(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(10),
                                            child: StaffAvatar(
                                              imageUrl: staff.imageUrl,
                                              gender: staff.gender ?? 'MALE',
                                              width: 80,
                                              height: 80,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            staff.name,
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 11,
                                              color: Colors.black,
                                            ),
                                          ),
                                          Text(
                                            'Hairstylist',
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.poppins(
                                              fontSize: 9,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                          : SizedBox(
                              height: 125,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                children: [
                                  _buildMockStaff("Aashis C", "Hairstylist", "assets/Images/HomeScreen/header_bg.jpeg"),
                                  _buildMockStaff("Prateek", "Hair Color", "assets/Images/HomeScreen/header_bg.jpeg"),
                                  _buildMockStaff("Avinash", "Hair Styling", "assets/Images/HomeScreen/header_bg.jpeg"),
                                ],
                              ),
                            ),

                  // ================= OFFERS SECTION =================
                  if (_offers.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "OFFER AVAILABLE FOR YOU",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              color: Colors.black,
                              letterSpacing: 0.5,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SelectServicesScreen(initialCategory: "Offers"),
                                ),
                              );
                            },
                            child: Text(
                              "See More",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                                color: const Color(0XFFFF0B01),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Offers Cards
                    SizedBox(
                      height: 90,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: _offers.length,
                        itemBuilder: (context, index) {
                          final offer = _offers[index];
                          final offerObj = Offer.fromJson(offer);
                          final double originalPrice = offerObj.applicableServices.fold(0.0, (sum, s) => sum + s.price);
                          double discountAmt = 0.0;
                          if (offerObj.discountType == "PERCENTAGE") {
                            discountAmt = originalPrice * (offerObj.discountValue / 100);
                          } else {
                            discountAmt = offerObj.discountValue;
                          }
                          final double discountedPrice = originalPrice - discountAmt;

                          return GestureDetector(
                            onTap: () {
                              _showOfferDetailsSheet(context, offerObj, originalPrice, discountedPrice);
                            },
                            child: Container(
                              width: 310,
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(color: Colors.black, width: 0.5),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 29,
                                    height: 29,
                                    decoration: const BoxDecoration(
                                      color: Color(0XFFFF0B01),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.local_offer, color: Colors.white, size: 14),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          offer['name']?.toUpperCase() ?? "GET DISCOUNT VIA NEOPARLOUR",
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                            color: Colors.black,
                                          ),
                                        ),
                                        if (offerObj.applicableServices.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 2),
                                            child: Text(
                                              "Services: ${offerObj.applicableServices.map((s) => s.name).join(", ")}",
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.poppins(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.black54,
                                              ),
                                            ),
                                          ),
                                        const SizedBox(height: 2),
                                        RichText(
                                          text: TextSpan(
                                            style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              color: Colors.grey.shade600,
                                            ),
                                            children: [
                                              TextSpan(
                                                text: offerObj.discountType == 'PERCENTAGE'
                                                    ? "${offerObj.discountValue.toInt()}% Off • "
                                                    : "Flat ₹${offerObj.discountValue.toInt()} Off • ",
                                                style: const TextStyle(fontWeight: FontWeight.w500),
                                              ),
                                              TextSpan(
                                                text: "₹${discountedPrice.toInt()} ",
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0XFFFF0B01),
                                                ),
                                              ),
                                              if (originalPrice > discountedPrice)
                                                TextSpan(
                                                  text: "₹${originalPrice.toInt()}",
                                                  style: TextStyle(
                                                    decoration: TextDecoration.lineThrough,
                                                    color: Colors.grey.shade400,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ================= SLOTS AVAILABILITY SECTION =================
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      "AVAILABLE SLOTS TODAY",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  _slots.isNotEmpty
                      ? SizedBox(
                          height: 48,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: _slots.length,
                            itemBuilder: (context, index) {
                              final slot = _slots[index];
                              final time = slot['displayTime'] ?? '';
                              final startTime = slot['startTime'] ?? '';
                              final discountMessage = slot['discountMessage'] as String?;
                              final hasDiscount = discountMessage != null && discountMessage.isNotEmpty;
                              final isBusy = slot['busy'] == true;
                              final isSelected = _selectedSlot == startTime;

                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: GestureDetector(
                                  onTap: isBusy
                                      ? null
                                      : () {
                                          setState(() {
                                            _selectedSlot = startTime;
                                          });
                                          
                                          final bookingProvider = context.read<BookingProvider>();
                                          final staffProvider = context.read<StaffProvider>();
                                          
                                          staffProvider.resetStaffState();
                                          bookingProvider.setPreSelectedStaff(null);
                                          
                                          final parsedTime = DateTime.parse(startTime).toLocal();
                                          final availableSlot = AvailableSlot(
                                            startTime: parsedTime,
                                            displayTime: time,
                                            discountMessage: discountMessage,
                                            discountPercentage: (slot['discountPercentage'] as num?)?.toDouble(),
                                            busy: false,
                                          );
                                          bookingProvider.selectSlot(availableSlot);
                                          
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => const SelectStaffScreen(),
                                            ),
                                          );
                                        },
                                  child: Opacity(
                                    opacity: isBusy ? 0.5 : 1.0,
                                    child: Stack(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: isBusy
                                                ? Colors.grey.shade200
                                                : isSelected
                                                    ? const Color(0XFFFF0B01)
                                                    : const Color(0XFFF5F5F7),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                time,
                                                style: GoogleFonts.poppins(
                                                  color: isBusy
                                                      ? Colors.grey.shade400
                                                      : isSelected
                                                          ? Colors.white
                                                          : Colors.black,
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 12,
                                                  decoration: isBusy
                                                      ? TextDecoration.lineThrough
                                                      : TextDecoration.none,
                                                  decorationColor: Colors.grey.shade400,
                                                ),
                                              ),
                                              if (hasDiscount && !isBusy) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  discountMessage,
                                                  style: GoogleFonts.poppins(
                                                    color: isSelected
                                                        ? Colors.white.withValues(alpha: 0.9)
                                                        : const Color(0xFF8E7CFF),
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 9,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        // Diagonal line for busy slots
                                        if (isBusy)
                                          Positioned.fill(
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(20),
                                              child: CustomPaint(
                                                painter: _BusySlotLinePainter(
                                                  color: Colors.red.shade300,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            _slotsErrorMessage ?? "No available slots for booking today.",
                            style: GoogleFonts.poppins(
                              fontSize: 12, 
                              color: (_slotsErrorMessage != null && _slotsErrorMessage!.toLowerCase().contains("closed"))
                                  ? const Color(0XFFFF0B01)
                                  : Colors.grey.shade600,
                              fontWeight: (_slotsErrorMessage != null && _slotsErrorMessage!.toLowerCase().contains("closed"))
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),

                  // ================= BEST SELLING PACKAGES SECTION =================
                  LayoutBuilder(
                    builder: (context, constraints) {
                      double sw = MediaQuery.of(context).size.width;
                      double scale = sw / 375.0; // scale reference
                      return _buildBestSellingPackages(sw, scale);
                    }
                  ),

                  // ================= POPULAR PRODUCTS SECTION =================
                  LayoutBuilder(
                    builder: (context, constraints) {
                      double sw = MediaQuery.of(context).size.width;
                      double scale = sw / 375.0;
                      return _buildPopularProducts(sw, scale);
                    }
                  ),

                  if (photosList.isNotEmpty) ...[
                    const SizedBox(height: 24),

                    // ================= PHOTOS SECTION =================
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        "PHOTOS",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: photosList.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => Dialog(
                                    backgroundColor: Colors.transparent,
                                    insetPadding: const EdgeInsets.all(16),
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      alignment: Alignment.center,
                                      children: [
                                        InteractiveViewer(
                                          child: CachedNetworkImage(
                                            imageUrl: photosList[index].toString().replaceFirst('http://', 'https://'),
                                            fit: BoxFit.contain,
                                            width: double.infinity,
                                          ),
                                        ),
                                        Positioned(
                                          top: -40,
                                          right: 0,
                                          child: IconButton(
                                            icon: const Icon(Icons.close, color: Colors.white, size: 30),
                                            onPressed: () => Navigator.pop(context),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: photosList[index].toString().replaceFirst('http://', 'https://'),
                                  width: 100,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) => Container(color: Colors.grey.shade200),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ================= OPENING TIMES SECTION =================
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      "OPENING TIMES",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0XFFF9F9FA),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          _buildOpeningDayRow("Monday", weeklyOff == "MONDAY" ? "Holiday" : "$openingTime - $closingTime", weeklyOff == "MONDAY"),
                          const Divider(height: 16),
                          _buildOpeningDayRow("Tuesday", weeklyOff == "TUESDAY" ? "Holiday" : "$openingTime - $closingTime", weeklyOff == "TUESDAY"),
                          const Divider(height: 16),
                          _buildOpeningDayRow("Wednesday", weeklyOff == "WEDNESDAY" ? "Holiday" : "$openingTime - $closingTime", weeklyOff == "WEDNESDAY"),
                          const Divider(height: 16),
                          _buildOpeningDayRow("Thursday", weeklyOff == "THURSDAY" ? "Holiday" : "$openingTime - $closingTime", weeklyOff == "THURSDAY"),
                          const Divider(height: 16),
                          _buildOpeningDayRow("Friday", weeklyOff == "FRIDAY" ? "Holiday" : "$openingTime - $closingTime", weeklyOff == "FRIDAY"),
                          const Divider(height: 16),
                          _buildOpeningDayRow("Saturday", weeklyOff == "SATURDAY" ? "Holiday" : "$openingTime - $closingTime", weeklyOff == "SATURDAY"),
                          const Divider(height: 16),
                          _buildOpeningDayRow("Sunday", weeklyOff == "SUNDAY" ? "Holiday" : "$openingTime - $closingTime", weeklyOff == "SUNDAY"),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  SizedBox(height: 35 + mq.padding.bottom),
                ],
              ),
            ),
          )
        ],
      ),
    ),
  );
}

  Widget _buildOpeningDayRow(String day, String times, bool isClosed) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              Icons.circle,
              size: 8,
              color: isClosed ? const Color(0XFFFF0B01) : Colors.green,
            ),
            const SizedBox(width: 8),
            Text(
              day,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: Colors.black,
              ),
            ),
          ],
        ),
        Text(
          times,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            fontSize: 12,
            color: isClosed ? const Color(0XFFFF0B01) : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildMockStaff(String name, String role, String imgPath) {
    return Container(
      width: 90,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 80,
              height: 80,
              color: Colors.grey.shade100,
              child: const Icon(Icons.person, color: Colors.grey, size: 30),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 11,
              color: Colors.black,
            ),
          ),
          Text(
            role,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 9,
              color: Colors.grey.shade600,
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

        final packages = provider.packages;
        if (packages.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "PACKAGES",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SelectServicesScreen(initialCategory: "Best Selling Packages"),
                        ),
                      );
                    },
                    child: Text(
                      "See More",
                      style: GoogleFonts.poppins(
                        color: const Color(0XFFFF0B01),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 160 * scale,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: packages.length,
                itemBuilder: (context, index) {
                  return _packageCard(packages[index], scale);
                },
              ),
            ),
          ],
        );
      },
    );
  }


  Widget _packageCard(PackageModel package, double scale) {
    final serviceProvider = context.read<ServiceProvider>();
    final double originalPrice = package.services.fold(0.0, (sum, s) {
      final matchedIndex = serviceProvider.services.indexWhere((element) => element.id == s.id);
      final double sPrice = matchedIndex != -1 ? serviceProvider.services[matchedIndex].price : 0.0;
      return sum + sPrice;
    });

    return GestureDetector(
      onTap: () {
        _showPackageDetailsSheet(context, package, originalPrice, scale);
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      "₹ ${package.packagePrice.toInt()}",
                      style: GoogleFonts.poppins(
                        fontSize: 24 * scale,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "₹ ${originalPrice.toInt()}",
                      style: GoogleFonts.poppins(
                        fontSize: 14 * scale,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade500,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
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
                    _showPackageDetailsSheet(context, package, originalPrice, scale);
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
      ),
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

        if (provider.error != null && provider.products.isEmpty) {
          return const SizedBox.shrink();
        }

        final products = provider.products;
        if (products.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "POPULAR PRODUCTS",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BeautyProductsScreen(),
                        ),
                      );
                    },
                    child: Text(
                      "See More",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                        color: const Color(0XFFFF0B01),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
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
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
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
                                p.stock == 0
                                    ? Text(
                                        "Out of stock",
                                        style: GoogleFonts.poppins(
                                          fontSize: 10 * scale,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey,
                                        ),
                                      )
                                    : Text(
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
            ),
          ],
        );
      },
    );
  }

  void _showOfferDetailsSheet(BuildContext context, Offer offerObj, double originalPrice, double discountedPrice) {
    final mq = MediaQuery.of(context);
    final scale = mq.size.width / 375.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        offerObj.name.toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 18 * scale,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Text(
                  offerObj.description,
                  style: GoogleFonts.poppins(
                    fontSize: 12 * scale,
                    color: const Color(0xFF8D8D8D),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Price Breakdown:",
                        style: GoogleFonts.poppins(
                          fontSize: 14 * scale,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...offerObj.applicableServices.map((s) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  s.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12 * scale,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "₹${s.price.toInt()}",
                                style: GoogleFonts.poppins(
                                  fontSize: 12 * scale,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Original Total:",
                            style: GoogleFonts.poppins(
                              fontSize: 12 * scale,
                              color: Colors.black54,
                            ),
                          ),
                          Text(
                            "₹${originalPrice.toInt()}",
                            style: GoogleFonts.poppins(
                              fontSize: 12 * scale,
                              color: Colors.black54,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Discount Applied:",
                            style: GoogleFonts.poppins(
                              fontSize: 12 * scale,
                              color: const Color(0XFFFF0B01),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            "- ₹${(originalPrice - discountedPrice).toInt()}",
                            style: GoogleFonts.poppins(
                              fontSize: 12 * scale,
                              color: const Color(0XFFFF0B01),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Final Price:",
                            style: GoogleFonts.poppins(
                              fontSize: 14 * scale,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            "₹${discountedPrice.toInt()}",
                            style: GoogleFonts.poppins(
                              fontSize: 16 * scale,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50 * scale,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0XFFFF0B01),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25 * scale),
                      ),
                    ),
                    onPressed: () async {
                      final serviceProvider = context.read<ServiceProvider>();
                      final bookingProvider = context.read<BookingProvider>();
                      context.read<StaffProvider>().resetStaffState();
                      bookingProvider.setPreSelectedStaff(null);

                      try {
                        if (serviceProvider.services.isEmpty || serviceProvider.services.any((s) => s.price == 0)) {
                          await serviceProvider.fetchServices();
                        }

                        serviceProvider.addServices(offerObj.applicableServices);
                        final serviceIds = offerObj.applicableServices
                            .map((s) => s.id)
                            .toList();

                        serviceProvider.preselectServices(serviceIds);
                        bookingProvider.applyOffer(offerObj);
                        bookingProvider.setSelectedPackage(null);
                        bookingProvider.selectSlot(null);

                        if (context.mounted) {
                          Navigator.pop(context); // Close bottom sheet
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SelectDateTimeScreen(),
                            ),
                          );
                        }
                      } catch (e) {
                        debugPrint("Error parsing offer json: $e");
                      }
                    },
                    child: Text(
                      "Book Now",
                      style: GoogleFonts.poppins(
                        fontSize: 14 * scale,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPackageDetailsSheet(BuildContext context, PackageModel package, double originalPrice, double scale) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        package.name.toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 18 * scale,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Package Includes:",
                        style: GoogleFonts.poppins(
                          fontSize: 14 * scale,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...package.services.map((s) {
                        final serviceProvider = context.read<ServiceProvider>();
                        final matchedIndex = serviceProvider.services.indexWhere((element) => element.id == s.id);
                        final double sPrice = matchedIndex != -1 ? serviceProvider.services[matchedIndex].price : 0.0;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  s.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12 * scale,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "₹${sPrice.toInt()}",
                                style: GoogleFonts.poppins(
                                  fontSize: 12 * scale,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Original Total:",
                            style: GoogleFonts.poppins(
                              fontSize: 12 * scale,
                              color: Colors.black54,
                            ),
                          ),
                          Text(
                            "₹${originalPrice.toInt()}",
                            style: GoogleFonts.poppins(
                              fontSize: 12 * scale,
                              color: Colors.black54,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Package Price:",
                            style: GoogleFonts.poppins(
                              fontSize: 14 * scale,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            "₹${package.packagePrice.toInt()}",
                            style: GoogleFonts.poppins(
                              fontSize: 16 * scale,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50 * scale,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0XFFFF0B01),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25 * scale),
                      ),
                    ),
                    onPressed: () {
                      final serviceProvider = context.read<ServiceProvider>();
                      final bookingProvider = context.read<BookingProvider>();

                      context.read<StaffProvider>().resetStaffState();
                      bookingProvider.setPreSelectedStaff(null);

                      final serviceIds = package.services.map((s) => s.id).toList();
                      serviceProvider.preselectServices(serviceIds);
                      bookingProvider.applyOffer(null);
                      bookingProvider.setSelectedPackage(package);
                      bookingProvider.selectSlot(null);

                      if (context.mounted) {
                        Navigator.pop(context); // Close bottom sheet
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const SelectDateTimeScreen()));
                      }
                    },
                    child: Text(
                      "Book Package",
                      style: GoogleFonts.poppins(
                        fontSize: 14 * scale,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Custom painter that draws a diagonal line across busy slot chips
class _BusySlotLinePainter extends CustomPainter {
  final Color color;

  _BusySlotLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, 0),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
