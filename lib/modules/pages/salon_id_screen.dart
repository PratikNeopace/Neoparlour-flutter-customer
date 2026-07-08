import 'package:flutter/material.dart';
import 'dart:convert';
import '../../core/utils/flushbar_helper.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:neo_parlour/modules/pages/nearby_saloons.dart';
import 'package:neo_parlour/core/data/services/search_service.dart';
import '../../provider/customer/service_provider.dart';
import '../../provider/customer/staff_provider.dart';
import '../../provider/customer/offer_provider.dart';
import '../../provider/customer/package_provider.dart';
import '../../provider/customer/product_provider.dart';
import '../../provider/customer/booking_provider.dart';
import 'package:neo_parlour/provider/customer/auth_provider.dart';
import 'package:neo_parlour/core/data/api_client.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:neo_parlour/modules/pages/salon_details_screen.dart';
import 'package:neo_parlour/modules/pages/qr_scanner_screen.dart';
class SalonIDScreen extends StatefulWidget {
  const SalonIDScreen({super.key});

  @override
  State<SalonIDScreen> createState() => _SalonIDScreenState();
}

class _SalonIDScreenState extends State<SalonIDScreen> {
  final SearchService _searchService = SearchService();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController areaController = TextEditingController();
  final FocusNode cityFocusNode = FocusNode();
  final FocusNode areaFocusNode = FocusNode();

  List<Map<String, dynamic>> citySuggestions = [];
  List<Map<String, dynamic>> areaSuggestions = [];

  bool isSearchingCity = false;
  bool isSearchingArea = false;

  List<Map<String, dynamic>> _favoriteSalons = [];

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _fetchFavorites();
  }

  Future<void> _fetchFavorites() async {
    try {
      final dio = ApiClient().dio;
      final response = await dio.get('customer/favourites');
      if (response.statusCode == 200 && response.data is List) {
        setState(() {
          _favoriteSalons = List<Map<String, dynamic>>.from(response.data);
        });
      }
    } catch (e) {
      debugPrint("Error fetching favorites: $e");
    }
  }

  void _switchSalon(int salonId, String salonName) async {
    // Show loading spinner
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0XFFFF0B01)),
      ),
    );

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.switchSalon(salonId, salonName);

      if (mounted) {
        Navigator.pop(context); // Dismiss loading spinner
      }

      if (success && mounted) {
        // Clear all providers data so that old salon's data is not shown
        context.read<ServiceProvider>().clearData();
        context.read<StaffProvider>().clearData();
        context.read<OfferProvider>().clearData();
        context.read<PackageProvider>().clearData();
        context.read<ProductProvider>().clearData();
        context.read<BookingProvider>().resetBookingState();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SalonDetailsScreen(salonId: salonId),
          ),
        );
      } else if (mounted) {
        FlushbarHelper.show(context, authProvider.errorMessage ?? "Failed to switch to salon");
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Dismiss loading spinner
        FlushbarHelper.show(context, "Error: $e");
      }
    }
  }

  void _onFavoriteSalonTap(Map<String, dynamic> salon) async {
    final salonId = salon['salonId'];
    if (salonId == null) return;
    
    final salonName = salon['salonName'] ?? 'Salon';
    _switchSalon(salonId, salonName);
  }

  void _handleQRScan() async {
    final scannedValue = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerScreen()),
    );

    if (scannedValue != null && scannedValue is String) {
      debugPrint("==========================================");
      debugPrint("RAW SCANNED QR VALUE: '$scannedValue'");
      debugPrint("==========================================");
      
      int? salonId;
      String salonName = "Scanned Salon";

      // 1. Try to parse as simple integer
      salonId = int.tryParse(scannedValue.trim());

      // 2. Try to parse as JSON if integer fails
      if (salonId == null) {
        try {
          final decoded = jsonDecode(scannedValue);
          if (decoded is Map) {
            salonId = int.tryParse(decoded['salonId']?.toString() ?? decoded['id']?.toString() ?? '');
            if (decoded['salonName'] != null) salonName = decoded['salonName'];
            if (decoded['name'] != null) salonName = decoded['name'];
          }
        } catch (_) {}
      }

      // 3. If still null, try extracting number specifically after SALON-
      if (salonId == null) {
        final specificMatch = RegExp(r'SALON-(\d+)', caseSensitive: false).firstMatch(scannedValue);
        if (specificMatch != null) {
          salonId = int.tryParse(specificMatch.group(1)!);
        } else {
          // Fallback to the LAST number found in the string
          final matches = RegExp(r'\d+').allMatches(scannedValue);
          if (matches.isNotEmpty) {
            salonId = int.tryParse(matches.last.group(0)!);
          }
        }
      }

      debugPrint("EXTRACTED SALON ID: $salonId");

      if (salonId != null) {
        _switchSalon(salonId, salonName);
      } else {
        if (mounted) {
          FlushbarHelper.show(context, "Invalid QR Format: $scannedValue");
        }
      }
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    cityController.dispose();
    areaController.dispose();
    cityFocusNode.dispose();
    areaFocusNode.dispose();
    super.dispose();
  }

  void _submit() async {
    final city = cityController.text.trim();
    final area = areaController.text.trim();

    if (city.isEmpty && area.isEmpty) {
      if (mounted) {
        FlushbarHelper.show(context, "Please enter a city or area name");
      }
      return;
    }

    if (mounted) {
      // Clear all providers data so that old salon's data is not shown
      context.read<ServiceProvider>().clearData();
      context.read<StaffProvider>().clearData();
      context.read<OfferProvider>().clearData();
      context.read<PackageProvider>().clearData();
      context.read<ProductProvider>().clearData();
      context.read<BookingProvider>().resetBookingState();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => NeabySaloons(
            initialCity: city,
            initialArea: area,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final sw = mq.size.width;
    final sh = mq.size.height;
    final navBarHeight = mq.padding.bottom;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: Stack(
          children: [
            // ================= BACKGROUND IMAGE =================
            Positioned.fill(
              child: Image.asset(
                "assets/Images/SalonIDScreen/background_image.jpeg",
                fit: BoxFit.fitWidth,
                alignment: const Alignment(1.0, -2.1),
                errorBuilder: (context, error, stackTrace) =>
                    Container(color: Colors.grey.shade900),
              ),
            ),

            // ================= WHITE CARD =================
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: sw * 0.05),
                padding: EdgeInsets.only(
                  bottom: navBarHeight > 0 ? navBarHeight : sh * 0.03,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(35),
                    topRight: Radius.circular(35),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0XFFFF7A58).withValues(alpha: 0.3),
                      blurRadius: 10,
                      spreadRadius: 8,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ================= HEADER =================
                      Padding(
                        padding: EdgeInsets.all(sw * 0.05),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "ENTER YOUR SALON LOCATION",
                              style: GoogleFonts.poppins(
                                fontSize: sw * 0.038,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Please enter your city and area name",
                              style: GoogleFonts.poppins(
                                fontSize: sw * 0.028,
                                color: const Color(0XFF8D8D8D),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              height: 3,
                              width: sw * 0.18,
                              decoration: BoxDecoration(
                                color: const Color(0XFFFF0B01),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                      ),
  
                      // ================= CONTENT =================
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          sw * 0.09,
                          sh * 0.01,
                          sw * 0.09,
                          sh * 0.04,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ================= SCAN QR BUTTON =================
                            SizedBox(
                              width: double.infinity,
                              height: sh * 0.062,
                              child: OutlinedButton.icon(
                                onPressed: _handleQRScan,
                                icon: Icon(Icons.qr_code_scanner, color: const Color(0XFFFF0B01), size: sw * 0.045),
                                label: Text(
                                  "SCAN SALON QR",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.5,
                                    fontSize: sw * 0.03,
                                    color: const Color(0XFFFF0B01),
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0XFFFF0B01), width: 1.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            
                            SizedBox(height: sh * 0.02),
                            Center(
                              child: Text(
                                "OR SEARCH MANUALLY",
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade500,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                            SizedBox(height: sh * 0.02),

                            // ================= CITY NAME INPUT =================
                            Container(
                              height: sh * 0.06,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(
                                  color: const Color(0XFF909090),
                                ),
                              ),
                              child: TextField(
                                controller: cityController,
                                focusNode: cityFocusNode,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(
                                    Icons.location_city,
                                    color: Color(0XFF8B8989),
                                  ),
                                  suffixIcon: cityController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear, size: 18, color: Color(0XFF8B8989)),
                                          onPressed: () {
                                            setState(() {
                                              cityController.clear();
                                              citySuggestions = [];
                                            });
                                          },
                                        )
                                      : null,
                                  hintText: "City Name (e.g. Pune)",
                                  hintStyle: GoogleFonts.poppins(
                                    fontSize: sw * 0.03,
                                    color: const Color(0XFF8D8D8D),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                onChanged: (val) async {
                                  if (val.trim().length >= 2) {
                                    setState(() {
                                      isSearchingCity = true;
                                    });
                                    final results = await _searchService.searchExternalLocations(
                                      val,
                                      featureClass: 'city',
                                    );
                                    setState(() {
                                      citySuggestions = results;
                                      isSearchingCity = false;
                                    });
                                  } else {
                                    setState(() {
                                      citySuggestions = [];
                                    });
                                  }
                                },
                              ),
                            ),

                            // ================= CITY SUGGESTIONS =================
                            if (citySuggestions.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(top: 4, bottom: 8),
                                constraints: const BoxConstraints(maxHeight: 160),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(9),
                                  border: Border.all(color: Colors.grey.shade300),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  padding: EdgeInsets.zero,
                                  itemCount: citySuggestions.length,
                                  itemBuilder: (context, index) {
                                    final suggestion = citySuggestions[index];
                                    final name = suggestion['name'] ?? '';
                                    return ListTile(
                                      dense: true,
                                      leading: const Icon(Icons.location_city, size: 18, color: Color(0XFFFF0B01)),
                                      title: Text(
                                        name,
                                        style: GoogleFonts.poppins(
                                          fontSize: sw * 0.03,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      onTap: () {
                                        setState(() {
                                          cityController.text = name;
                                          citySuggestions = [];
                                        });
                                        areaFocusNode.requestFocus();
                                      },
                                    );
                                  },
                                ),
                              ),
  
                            SizedBox(height: sh * 0.02),
  
                            // ================= AREA NAME INPUT =================
                            Container(
                              height: sh * 0.06,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(
                                  color: const Color(0XFF909090),
                                ),
                              ),
                              child: TextField(
                                controller: areaController,
                                focusNode: areaFocusNode,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(
                                    Icons.location_on,
                                    color: Color(0XFF8B8989),
                                  ),
                                  suffixIcon: areaController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear, size: 18, color: Color(0XFF8B8989)),
                                          onPressed: () {
                                            setState(() {
                                              areaController.clear();
                                              areaSuggestions = [];
                                            });
                                          },
                                        )
                                      : null,
                                  hintText: "Area Name (e.g. Kothrud)",
                                  hintStyle: GoogleFonts.poppins(
                                    fontSize: sw * 0.03,
                                    color: const Color(0XFF8D8D8D),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                onChanged: (val) async {
                                  if (val.trim().length >= 2) {
                                    setState(() {
                                      isSearchingArea = true;
                                    });
                                    final results = await _searchService.searchExternalLocations(
                                      val,
                                      featureClass: 'area',
                                      cityName: cityController.text.trim(),
                                    );
                                    setState(() {
                                      areaSuggestions = results;
                                      isSearchingArea = false;
                                    });
                                  } else {
                                    setState(() {
                                      areaSuggestions = [];
                                    });
                                  }
                                },
                              ),
                            ),

                            // ================= AREA SUGGESTIONS =================
                            if (areaSuggestions.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(top: 4, bottom: 8),
                                constraints: const BoxConstraints(maxHeight: 160),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(9),
                                  border: Border.all(color: Colors.grey.shade300),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  padding: EdgeInsets.zero,
                                  itemCount: areaSuggestions.length,
                                  itemBuilder: (context, index) {
                                    final suggestion = areaSuggestions[index];
                                    final name = suggestion['name'] ?? '';
                                    final details = suggestion['city'] ?? '';
                                    return ListTile(
                                      dense: true,
                                      leading: const Icon(Icons.place, size: 18, color: Color(0XFFFF0B01)),
                                      title: Text(
                                        name,
                                        style: GoogleFonts.poppins(
                                          fontSize: sw * 0.03,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: details.isNotEmpty
                                          ? Text(
                                              details,
                                              style: GoogleFonts.poppins(
                                                fontSize: sw * 0.024,
                                                color: Colors.grey.shade600,
                                              ),
                                            )
                                          : null,
                                      onTap: () {
                                        setState(() {
                                          areaController.text = name;
                                          areaSuggestions = [];
                                        });
                                        FocusScope.of(context).unfocus();
                                      },
                                    );
                                  },
                                ),
                              ),
  
                            SizedBox(height: sh * 0.035),
  
                            // ================= SUBMIT BUTTON =================
                            SizedBox(
                              width: double.infinity,
                              height: sh * 0.062,
                              child: ElevatedButton(
                                onPressed: _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0XFFFF0B01),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  "SUBMIT",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 2,
                                    fontSize: sw * 0.03,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            


                            if (_favoriteSalons.isNotEmpty) ...[
                              SizedBox(height: sh * 0.04),
                              Text(
                                "YOUR FAVOURITE SALONS",
                                style: GoogleFonts.poppins(
                                  fontSize: sw * 0.038,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 100,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _favoriteSalons.length,
                                  itemBuilder: (context, index) {
                                    final salon = _favoriteSalons[index];
                                    final imageUrl = salon['imageUrl']?.toString() ?? '';
                                    final rating = salon['rating']?.toString() ?? '4.6';
                                    final name = salon['salonName'] ?? 'Salon';
                                    final location = salon['cityName'] != null && salon['areaName'] != null
                                        ? "${salon['areaName']}, ${salon['cityName']}"
                                        : (salon['cityName'] ?? 'Pune');

                                    return GestureDetector(
                                      onTap: () => _onFavoriteSalonTap(salon),
                                      child: Container(
                                        width: sw * 0.56,
                                        margin: const EdgeInsets.only(right: 16),
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: const Color(0XFFF5F5F7),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          children: [
                                            // Thumbnail
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(6),
                                              child: imageUrl.isNotEmpty
                                                  ? CachedNetworkImage(
                                                      imageUrl: imageUrl.toString().replaceFirst('http://', 'https://'),
                                                      width: 50,
                                                      height: 50,
                                                      fit: BoxFit.cover,
                                                      errorWidget: (context, url, error) => Container(color: Colors.grey.shade300),
                                                    )
                                                  : Container(
                                                      width: 50,
                                                      height: 50,
                                                      color: Colors.grey.shade300,
                                                      child: const Icon(
                                                        Icons.store,
                                                        color: Color(0XFF8B8989),
                                                        size: 24,
                                                      ),
                                                    ),
                                            ),
                                            const SizedBox(width: 10),
                                            // Details
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    name,
                                                    style: GoogleFonts.poppins(
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: 12,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  Text(
                                                    location,
                                                    style: GoogleFonts.poppins(
                                                      color: const Color(0XFF767678),
                                                      fontSize: 10,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    "View More",
                                                    style: GoogleFonts.poppins(
                                                      color: const Color(0XFFFF0B01),
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Rating
                                            Column(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                Row(
                                                  children: [
                                                    const Icon(Icons.star, color: Colors.orange, size: 10),
                                                    const SizedBox(width: 2),
                                                    Text(
                                                      rating,
                                                      style: GoogleFonts.poppins(
                                                        fontWeight: FontWeight.w700,
                                                        fontSize: 10,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
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
      ),
    );
  }
  //     padding: const EdgeInsets.all(11), // Adjust padding for icon size
  //     decoration: BoxDecoration(
  //       shape: BoxShape.circle,
  //       color: backgroundColor ?? Colors.transparent,
  //       border: Border.all(
  //         color: backgroundColor != null
  //             ? Colors.transparent
  //             : const Color(0XFFBDBDBD),
  //       ),
  //     ),
  //     child: SvgPicture.asset(
  //       path,
  //       // If background is blue (Facebook), make the icon white.
  //       // Otherwise, keep original colors (Google).
  //       colorFilter: backgroundColor != null
  //           ? const ColorFilter.mode(Colors.white, BlendMode.srcIn)
  //           : null,
  //     ),
  //   );
  // }
}
