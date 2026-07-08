import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:neo_parlour/core/data/services/search_service.dart';
import 'package:neo_parlour/core/data/api_client.dart';
import 'package:provider/provider.dart';
import 'package:neo_parlour/provider/customer/auth_provider.dart';
import 'package:neo_parlour/provider/customer/service_provider.dart';
import 'package:neo_parlour/provider/customer/staff_provider.dart';
import 'package:neo_parlour/provider/customer/offer_provider.dart';
import 'package:neo_parlour/provider/customer/package_provider.dart';
import 'package:neo_parlour/provider/customer/product_provider.dart';
import 'package:neo_parlour/provider/customer/booking_provider.dart';
import 'package:neo_parlour/modules/pages/salon_details_screen.dart';
import 'package:neo_parlour/modules/pages/edit_profile_screen.dart';
import 'package:neo_parlour/modules/pages/qr_scanner_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
class NeabySaloons extends StatefulWidget {
  final String? initialCity;
  final String? initialArea;

  const NeabySaloons({
    super.key,
    this.initialCity,
    this.initialArea,
  });

  @override
  State<NeabySaloons> createState() => _NeabySaloonsState();
}

class _NeabySaloonsState extends State<NeabySaloons> {
  final SearchService _searchService = SearchService();
  
  late String _currentCity;
  late String _currentArea;
  String _selectedCategory = "All";
  bool _isLoadingSalons = false;
  bool _autoLocating = false;
  
  final Map<String, bool> _bookmarkedSalons = {};
  final List<String> _categories = ["All", "Hair Services", "Skin Care", "Hair Removal", "Nail Care", "Makeup", "Grooming", "Spa & Massage", "Hair Treatment"];

  List<Map<String, dynamic>> _salons = [];
  bool _noSalonsFound = false;
  String _searchQuery = "";

  List<Map<String, dynamic>> get _filteredSalons {
    if (_searchQuery.isEmpty) return _salons;
    final query = _searchQuery.toLowerCase();
    return _salons.where((salon) {
      final name = salon['name']?.toString().toLowerCase() ?? '';
      final categoriesStr = salon['categories']?.toString().toLowerCase() ?? '';
      return name.contains(query) || categoriesStr.contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _currentCity = widget.initialCity ?? "";
    _currentArea = widget.initialArea ?? "";
    if (_currentCity.isEmpty) {
      _autoDetectLocation();
    } else {
      _fetchSalons();
    }
  }

  /// Request GPS, get coordinates, reverse-geocode via Nominatim, then fetch salons.
  Future<void> _autoDetectLocation() async {
    setState(() => _autoLocating = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        _fallbackLocation();
        return;
      }
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _fallbackLocation();
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=${position.latitude}&lon=${position.longitude}&format=json&zoom=14&addressdetails=1',
      );
      final res = await http.get(url, headers: {'User-Agent': 'NeoParlourApp/1.0'});
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final addr = data['address'] as Map<String, dynamic>? ?? {};
        final city = (addr['city'] ?? addr['town'] ?? addr['county'] ?? addr['state_district'] ?? 'Pune').toString();
        final area = (addr['suburb'] ?? addr['neighbourhood'] ?? addr['residential'] ?? addr['road'] ?? addr['village'] ?? city).toString();
        if (mounted) {
          setState(() {
            _currentCity = city;
            _currentArea = area;
            _autoLocating = false;
          });
          _fetchSalons();
        }
      } else {
        _fallbackLocation();
      }
    } catch (e) {
      debugPrint('Auto-location error: $e');
      _fallbackLocation();
    }
  }

  void _fallbackLocation() {
    if (!mounted) return;
    setState(() {
      _currentCity = "Pune";
      _currentArea = "Kothrud";
      _autoLocating = false;
    });
    _fetchSalons();
  }


  Future<void> _fetchFavorites() async {
    try {
      final dio = ApiClient().dio;
      final response = await dio.get('customer/favourites');
      if (response.statusCode == 200 && response.data is List) {
        final List<dynamic> data = response.data;
        setState(() {
          _bookmarkedSalons.clear();
          for (var item in data) {
            final salonIdStr = item['salonId']?.toString();
            if (salonIdStr != null) {
              _bookmarkedSalons[salonIdStr] = true;
            }
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching favorites: $e");
    }
  }

  Future<void> _fetchSalons() async {
    setState(() {
      _isLoadingSalons = true;
    });

    await _fetchFavorites();

    try {
      final response = await _searchService.getSalonsByLocation(_currentCity, _currentArea, category: _selectedCategory);
      if (response.isNotEmpty) {
        setState(() {
          _salons = response.map((item) {
             return {
              "id": item['salonId']?.toString() ?? item['id']?.toString() ?? '',
              "name": item['salonName'] ?? item['name'] ?? 'Salon',
              "location": item['address'] ?? item['areaName'] ?? item['area'] ?? '',
              "rating": item['rating']?.toString() ?? '',
              "imageUrl": item['imageUrl']?.toString() ?? '',
              "categories": item['categories'] ?? item['categoryList'] ?? item['categoryName'] ?? '',
            };
          }).toList();
          _noSalonsFound = false;
          _isLoadingSalons = false;
        });
      } else {
        setState(() {
          _salons = [];
          _noSalonsFound = true;
          _isLoadingSalons = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading salons: $e");
      setState(() {
        _salons = [];
        _noSalonsFound = true;
        _isLoadingSalons = false;
      });
    }
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
        if (!mounted) return;
        Navigator.pop(context); // Close the location picker modal
        _onSalonTap({'id': salonId.toString(), 'name': salonName});
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Invalid QR Format: $scannedValue")),
          );
        }
      }
    }
  }

  void _onSalonTap(Map<String, dynamic> salon) async {
    final salonIdStr = salon['id']?.toString() ?? '';
    if (salonIdStr.isEmpty) return;

    final salonId = int.tryParse(salonIdStr);
    if (salonId == null) {
      debugPrint("Invalid salon ID: $salonIdStr");
      return;
    }
    final salonName = salon['name']?.toString() ?? 'Salon';

    setState(() {
      _isLoadingSalons = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.switchSalon(salonId, salonName);

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authProvider.errorMessage ?? "Failed to switch to salon")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSalons = false;
        });
      }
    }
  }

  Future<void> _toggleFavorite(String salonIdStr) async {
    final salonId = int.tryParse(salonIdStr);
    if (salonId == null) return;

    final isFav = _bookmarkedSalons[salonIdStr] ?? false;

    // Toggle local state immediately for snappy feedback
    setState(() {
      _bookmarkedSalons[salonIdStr] = !isFav;
    });

    try {
      final dio = ApiClient().dio;
      if (!isFav) {
        // Mark as favourite
        final response = await dio.post('customer/favourites/$salonId');
        if (response.statusCode != 200) {
          throw Exception("Failed to favorite salon");
        }
        debugPrint("Successfully favorited salon $salonId");
      } else {
        // Un-favourite
        final response = await dio.delete('customer/favourites/$salonId');
        if (response.statusCode != 200) {
          throw Exception("Failed to un-favorite salon");
        }
        debugPrint("Successfully un-favorited salon $salonId");
      }
    } catch (e) {
      debugPrint("Error updating favourite: $e");
      // Revert state on error
      setState(() {
        _bookmarkedSalons[salonIdStr] = isFav;
      });
    }
  }

  void _showLocationPicker() {
    final TextEditingController cityController = TextEditingController(text: _currentCity);
    final TextEditingController areaController = TextEditingController(text: _currentArea);
    final FocusNode cityFocusNode = FocusNode();
    final FocusNode areaFocusNode = FocusNode();

    List<Map<String, dynamic>> citySuggestions = [];
    List<Map<String, dynamic>> areaSuggestions = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final mq = MediaQuery.of(context);
            final sh = mq.size.height;
            final keyboardHeight = mq.viewInsets.bottom;

            return Container(
              height: sh * 0.75 + keyboardHeight,
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: 20 + mq.padding.bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 50,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Edit Location",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 15),
                    
                    // ================= USE MY LOCATION BUTTON =================
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _autoDetectLocation();
                        },
                        icon: const Icon(Icons.my_location, color: Colors.white, size: 20),
                        label: Text(
                          "USE MY LOCATION",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0XFFFF0B01),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ================= SCAN QR BUTTON =================
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _handleQRScan,
                        icon: const Icon(Icons.qr_code_scanner, color: Color(0XFFFF0B01), size: 20),
                        label: Text(
                          "SCAN SALON QR",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                            fontSize: 12,
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
                    const SizedBox(height: 20),
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
                    const SizedBox(height: 15),

                    Text(
                      "CITY NAME",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: const Color(0XFF909090)),
                      ),
                      child: TextField(
                        controller: cityController,
                        focusNode: cityFocusNode,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.location_city, color: Color(0XFF8B8989)),
                          suffixIcon: cityController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18, color: Color(0XFF8B8989)),
                                  onPressed: () {
                                    setModalState(() {
                                      cityController.clear();
                                      citySuggestions = [];
                                    });
                                  },
                                )
                              : null,
                          hintText: "City Name (e.g. Pune)",
                          hintStyle: GoogleFonts.poppins(fontSize: 13, color: const Color(0XFF8D8D8D)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onChanged: (val) async {
                          if (val.trim().length >= 2) {
                            final results = await _searchService.searchExternalLocations(val, featureClass: 'city');
                            setModalState(() {
                              citySuggestions = results;
                            });
                          } else {
                            setModalState(() {
                              citySuggestions = [];
                            });
                          }
                        },
                      ),
                    ),

                    if (citySuggestions.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 4, bottom: 8),
                        constraints: const BoxConstraints(maxHeight: 120),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: citySuggestions.length,
                          itemBuilder: (context, index) {
                            final name = citySuggestions[index]['name'] ?? '';
                            return ListTile(
                              dense: true,
                              leading: const Icon(Icons.location_city, size: 16, color: Color(0XFFFF0B01)),
                              title: Text(name, style: GoogleFonts.poppins(fontSize: 13)),
                              onTap: () {
                                setModalState(() {
                                  cityController.text = name;
                                  citySuggestions = [];
                                });
                                areaFocusNode.requestFocus();
                              },
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 15),

                    Text(
                      "AREA NAME",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: const Color(0XFF909090)),
                      ),
                      child: TextField(
                        controller: areaController,
                        focusNode: areaFocusNode,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.location_on, color: Color(0XFF8B8989)),
                          suffixIcon: areaController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18, color: Color(0XFF8B8989)),
                                  onPressed: () {
                                    setModalState(() {
                                      areaController.clear();
                                      areaSuggestions = [];
                                    });
                                  },
                                )
                              : null,
                          hintText: "Area Name (e.g. Kothrud)",
                          hintStyle: GoogleFonts.poppins(fontSize: 13, color: const Color(0XFF8D8D8D)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onChanged: (val) async {
                          if (val.trim().length >= 2) {
                            final results = await _searchService.searchExternalLocations(
                              val,
                              featureClass: 'area',
                              cityName: cityController.text.trim(),
                            );
                            setModalState(() {
                              areaSuggestions = results;
                            });
                          } else {
                            setModalState(() {
                              areaSuggestions = [];
                            });
                          }
                        },
                      ),
                    ),

                    if (areaSuggestions.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 4, bottom: 8),
                        constraints: const BoxConstraints(maxHeight: 120),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: areaSuggestions.length,
                          itemBuilder: (context, index) {
                            final name = areaSuggestions[index]['name'] ?? '';
                            final details = areaSuggestions[index]['city'] ?? '';
                            return ListTile(
                              dense: true,
                              leading: const Icon(Icons.place, size: 16, color: Color(0XFFFF0B01)),
                              title: Text(name, style: GoogleFonts.poppins(fontSize: 13)),
                              subtitle: details.isNotEmpty ? Text(details, style: GoogleFonts.poppins(fontSize: 11)) : null,
                              onTap: () {
                                setModalState(() {
                                  areaController.text = name;
                                  areaSuggestions = [];
                                });
                                FocusScope.of(context).unfocus();
                              },
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 25),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          final city = cityController.text.trim();
                          final area = areaController.text.trim();

                          if (city.isEmpty) {
                            return;
                          }

                          setState(() {
                            _currentCity = city;
                            _currentArea = area;
                          });
                          _fetchSalons();
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0XFFFF0B01),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          "CONFIRM LOCATION",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.0,
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
      },
    ).whenComplete(() {
      cityController.dispose();
      areaController.dispose();
      cityFocusNode.dispose();
      areaFocusNode.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ================= HEADER =================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Location Selector
                    GestureDetector(
                      onTap: _autoLocating ? null : _showLocationPicker,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_autoLocating)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0XFFFF0B01),
                              ),
                            )
                          else
                            const Icon(
                              Icons.location_on,
                              color: Color(0XFFFF0B01),
                              size: 18,
                            ),
                          const SizedBox(width: 6),
                          Text(
                            _autoLocating
                                ? "Detecting location..."
                                : (_currentArea.isNotEmpty && _currentCity.isNotEmpty
                                    ? "$_currentArea, $_currentCity"
                                    : (_currentArea.isNotEmpty ? _currentArea : _currentCity)),
                            style: GoogleFonts.poppins(
                              color: const Color(0XFF767678),
                              fontWeight: FontWeight.w400,
                              fontSize: 12,
                            ),
                          ),
                          if (!_autoLocating) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.keyboard_arrow_down,
                              color: Color(0XFF767678),
                              size: 16,
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Action Icons
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EditProfileScreen(),
                              ),
                            );
                          },
                          child: const CircleAvatar(
                            radius: 18,
                            backgroundColor: Color(0XFFF5F5F7),
                            child: Icon(
                              Icons.person,
                              color: Color(0XFF767678),
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),

                // ================= SEARCH BAR =================
                Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0XFFF9F9FA),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0XFFC0C0C0), width: 1),
                  ),
                  child: TextField(
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.trim();
                      });
                    },
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, color: Color(0XFF767678)),
                      hintText: "Search near by salons",
                      hintStyle: GoogleFonts.poppins(
                        color: const Color(0XFF8D8D8D),
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                // ================= CATEGORY CHIPS =================
                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = category == _selectedCategory;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategory = category;
                            });
                            _fetchSalons();
                          },
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0XFFFF0B01) : const Color(0XFFF5F5F7),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              category,
                              style: GoogleFonts.poppins(
                                color: isSelected ? Colors.white : const Color(0XFF767678),
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 28),

                // ================= POPULAR SALONS SECTION =================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "POPULAR SALONS",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                        letterSpacing: 0.5,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // See More action
                      },
                      child: Text(
                        "See More",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0XFFFF0B01),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Grid View of Popular Salons (Dynamic or Loader)
                _isLoadingSalons
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40.0),
                          child: CircularProgressIndicator(color: Color(0XFFFF0B01)),
                        ),
                      )
                    : _noSalonsFound || _filteredSalons.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 48.0),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.store_mall_directory_outlined,
                                      size: 56, color: Colors.grey.shade300),
                                  const SizedBox(height: 12),
                                  Text(
                                    "No salons found",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Try a different search or area",
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.8,
                        ),
                        itemCount: _filteredSalons.length,
                        itemBuilder: (context, index) {
                          final salon = _filteredSalons[index];
                          final isBookmarked = _bookmarkedSalons[salon['id']] ?? false;

                          return GestureDetector(
                            onTap: () => _onSalonTap(salon),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Card Image & Bookmark
                                  Expanded(
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(8),
                                            topRight: Radius.circular(8),
                                          ),
                                          child: salon['imageUrl'] != null && salon['imageUrl'].toString().isNotEmpty
                                              ? CachedNetworkImage(
                                                  imageUrl: salon['imageUrl'].toString().replaceFirst('http://', 'https://'),
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                  placeholder: (context, url) => Container(color: Colors.grey.shade100),
                                                  errorWidget: (context, url, error) => Container(color: Colors.grey.shade200),
                                                )
                                              : Container(
                                                  color: Colors.grey.shade100,
                                                  width: double.infinity,
                                                  child: const Icon(
                                                    Icons.store,
                                                    color: Color(0XFF8B8989),
                                                    size: 32,
                                                  ),
                                                ),
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: GestureDetector(
                                            onTap: () => _toggleFavorite(salon['id']?.toString() ?? ''),
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: const BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                isBookmarked ? Icons.favorite : Icons.favorite_border,
                                                size: 16,
                                                color: isBookmarked ? const Color(0XFFFF0B01) : Colors.grey.shade600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Card Details
                                  Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                salon['name'],
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 12,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (salon['rating'] != null && salon['rating'].toString().isNotEmpty)
                                              Row(
                                                children: [
                                                  const Icon(Icons.star, color: Colors.orange, size: 12),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    salon['rating'],
                                                    style: GoogleFonts.poppins(
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          salon['location'],
                                          style: GoogleFonts.poppins(
                                            color: const Color(0XFF767678),
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
                        },
                      ),

                const SizedBox(height: 28),

                // ================= AI SECTION =================
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0XFFF0F0F2)),
                  ),
                  child: Row(
                    children: [
                      // AI/Robot Icon
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0XFFEBEBFF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.smart_toy_outlined,
                          color: Color(0XFF5B5BFF),
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Text info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "AI STYLE MATCH",
                              style: GoogleFonts.poppins(
                                color: const Color(0XFFFF0B01),
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Get your perfect cut → Coming Soon",
                              style: GoogleFonts.poppins(
                                color: const Color(0XFF767678),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SafeArea(top: false, child: const SizedBox(height: 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

