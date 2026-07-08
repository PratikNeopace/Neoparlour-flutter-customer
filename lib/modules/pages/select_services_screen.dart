import 'package:flutter/material.dart';
import '../../core/utils/flushbar_helper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../provider/customer/service_provider.dart';
import '../../provider/customer/staff_provider.dart';
import '../../provider/customer/booking_provider.dart';
import '../../provider/customer/auth_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'select_date_time_screen.dart';
import 'review_confirm_screen.dart';

import '../../core/data/api_client.dart';
import '../../core/domain/models/neo_service.dart';
import '../../core/domain/models/offer.dart';
import '../../core/domain/models/package_model.dart';

class SelectServicesScreen extends StatefulWidget {
  final String? initialCategory;
  const SelectServicesScreen({super.key, this.initialCategory});

  @override
  State<SelectServicesScreen> createState() => _SelectServicesScreenState();
}

class _SelectServicesScreenState extends State<SelectServicesScreen> {
  String selectedCategory = "Featured";
  final ScrollController _scrollController = ScrollController();

  List<NeoService> _services = [];
  String _selectedServiceCategory = "All";
  final List<String> _serviceCategories = [
    "All",
    "Hair Services",
    "Skin Care",
    "Hair Removal",
    "Nail Care",
    "Makeup",
    "Grooming",
    "Spa & Massage",
    "Hair Treatment"
  ];
  int _currentPage = 0;
  int _totalPages = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  List<Offer> _offersList = [];
  int _offersPage = 0;
  int _offersTotalPages = 1;
  bool _offersLoading = false;
  bool _offersHasMore = true;
  bool _offersLoadingMore = false;

  List<PackageModel> _packagesList = [];
  int _packagesPage = 0;
  int _packagesTotalPages = 1;
  bool _packagesLoading = false;
  bool _packagesHasMore = true;
  bool _packagesLoadingMore = false;

  Future<void> _fetchServices({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 0;
        _services.clear();
        _hasMore = true;
        _isLoading = true;
      });
    } else {
      if (!_hasMore || _isLoadingMore) return;
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final salonId = authProvider.salonId;
      final response = await ApiClient().dio.get(
        'services/filter?page=$_currentPage&size=100&active=true${salonId != null ? "&salonId=$salonId" : ""}',
      );
      final data = response.data;
      
      final content = data['content'] as List;
      final pageInfo = data['page'];
      
      final newServices = content.where((json) => json['active'] == true).map((json) => NeoService.fromJson(json)).toList();
      
      if (mounted) {
        context.read<ServiceProvider>().addServices(newServices);
      }
      
      setState(() {
        _totalPages = pageInfo['totalPages'] ?? 1;
        int currentNumber = pageInfo['number'] ?? 0;
        
        if (refresh) {
          _services = newServices;
        } else {
          _services.addAll(newServices);
        }
        
        _hasMore = currentNumber < _totalPages - 1;
        _currentPage = currentNumber + 1;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      debugPrint("Error fetching services: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }



  Future<void> _fetchOffers({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _offersPage = 0;
        _offersList.clear();
        _offersHasMore = true;
        _offersLoading = true;
      });
    } else {
      if (!_offersHasMore || _offersLoadingMore) return;
      setState(() {
        _offersLoadingMore = true;
      });
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final salonId = authProvider.salonId;
      final response = await ApiClient().dio.get(
        'offers/search?page=$_offersPage&size=10&active=true${salonId != null ? "&salonId=$salonId" : ""}',
      );
      final data = response.data;
      
      final content = data['content'] as List;
      final pageInfo = data['page'];
      
      final newOffers = content.where((json) => json['active'] == true).map((json) {
        return Offer(
          id: json['id'] as int? ?? 0,
          name: json['name'] as String? ?? 'Unnamed Offer',
          description: json['description'] as String? ?? '',
          discountType: json['discountType'] as String? ?? 'PERCENTAGE',
          discountValue: (json['percentage'] as num?)?.toDouble() ?? (json['discountValue'] as num?)?.toDouble() ?? 0.0,
          validFrom: json['validFrom'] != null ? DateTime.parse(json['validFrom']) : DateTime.now(),
          validTo: json['validTo'] != null ? DateTime.parse(json['validTo']) : DateTime.now(),
          applicableServices: ((json['services'] as List<dynamic>?) ?? (json['applicableServices'] as List<dynamic>?))
                  ?.map((s) => NeoService(
                    id: s['id'] as int? ?? 0,
                    name: s['name'] as String? ?? '',
                    duration: s['duration'] as int? ?? 0,
                    price: (s['price'] as num?)?.toDouble() ?? 0.0,
                    category: s['category'] as String? ?? '',
                    active: s['active'] as bool? ?? true,
                    createdAt: s['createdAt'] != null ? DateTime.parse(s['createdAt']) : DateTime.now(),
                    popularityCount: s['popularityCount'] as int? ?? 0,
                  ))
                  .toList() ??
              [],
          active: json['active'] as bool? ?? true,
          usedCount: json['usedCount'] as int? ?? 0,
          totalUsageLimit: json['totalUsageLimit'] as int?,
          usageLimitPerCustomer: json['usageLimitPerCustomer'] as int?,
        );
      }).toList();
      
      setState(() {
        _offersTotalPages = pageInfo['totalPages'] ?? 1;
        int currentNumber = pageInfo['number'] ?? 0;
        
        if (refresh) {
          _offersList = newOffers;
        } else {
          _offersList.addAll(newOffers);
        }
        
        _offersHasMore = currentNumber < _offersTotalPages - 1;
        _offersPage = currentNumber + 1;
        _offersLoading = false;
        _offersLoadingMore = false;
      });
    } catch (e) {
      debugPrint("Error fetching offers: $e");
      if (mounted) {
        setState(() {
          _offersLoading = false;
          _offersLoadingMore = false;
        });
      }
    }
  }

  Future<void> _fetchPackages({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _packagesPage = 0;
        _packagesList.clear();
        _packagesHasMore = true;
        _packagesLoading = true;
      });
    } else {
      if (!_packagesHasMore || _packagesLoadingMore) return;
      setState(() {
        _packagesLoadingMore = true;
      });
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final salonId = authProvider.salonId;
      final response = await ApiClient().dio.get(
        'packages/search?page=$_packagesPage&size=10&active=true${salonId != null ? "&salonId=$salonId" : ""}',
      );
      final data = response.data;
      
      final content = data['content'] as List;
      final pageInfo = data['page'];
      
      final newPackages = content.where((json) => json['active'] == true).map((json) => PackageModel.fromJson(json)).toList();
      
      setState(() {
        _packagesTotalPages = pageInfo['totalPages'] ?? 1;
        int currentNumber = pageInfo['number'] ?? 0;
        
        if (refresh) {
          _packagesList = newPackages;
        } else {
          _packagesList.addAll(newPackages);
        }
        
        _packagesHasMore = currentNumber < _packagesTotalPages - 1;
        _packagesPage = currentNumber + 1;
        _packagesLoading = false;
        _packagesLoadingMore = false;
      });
    } catch (e) {
      debugPrint("Error fetching packages: $e");
      if (mounted) {
        setState(() {
          _packagesLoading = false;
          _packagesLoadingMore = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Always start with "Featured" preselected as requested unless a tab is specified
    selectedCategory = "Featured";
    
    if (widget.initialCategory != null) {
      final input = widget.initialCategory!.toLowerCase().trim();
      if (input == "offers") {
        selectedCategory = "Offers";
      } else if (input == "best selling packages" || input.contains("package")) {
        selectedCategory = "Best Selling Packages";
      } else {
        selectedCategory = "Featured";
        for (final cat in _serviceCategories) {
          final catLower = cat.toLowerCase().trim();
          if (catLower == input || 
              (catLower == "hair removal" && input.contains("removal")) ||
              (catLower == "hair treatment" && input.contains("treatment")) ||
              (catLower == "hair services" && (input.contains("hair") || input.contains("cut")) && !input.contains("removal") && !input.contains("treatment")) ||
              (catLower == "skin care" && (input.contains("skin") || input.contains("facial"))) ||
              (catLower == "nail care" && input.contains("nail")) ||
              (catLower == "spa & massage" && (input.contains("spa") || input.contains("massage")))) {
            _selectedServiceCategory = cat;
            break;
          }
        }
      }
    }
    
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        if (selectedCategory == "Featured") {
          _fetchServices();
        } else if (selectedCategory == "Offers") {
          _fetchOffers();
        } else if (selectedCategory == "Best Selling Packages") {
          _fetchPackages();
        }
      }
    });
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   context.read<ServiceProvider>().fetchServices();
    //   context.read<OfferProvider>().fetchActiveOffers();
    //   context.read<PackageProvider>().fetchPackages();
    // });
     WidgetsBinding.instance.addPostFrameCallback((_) async {
    final serviceProvider = context.read<ServiceProvider>();
    final bookingProvider = context.read<BookingProvider>();
    final staffProvider = context.read<StaffProvider>();

    if (bookingProvider.preSelectedStaffId == null && bookingProvider.selectedSlot == null) {
      serviceProvider.clearSelections();     // clear services
      bookingProvider.applyOffer(null);     // clear offer
      bookingProvider.selectSlot(null);     // clear slot
      staffProvider.selectStaff(null);      // clear staff
    }

    // Fetch all active services for the current salon in background to populate cache
    serviceProvider.fetchServices();

    /// Fetch fresh data for the selected category
    if (selectedCategory == "Featured") {
      await _fetchServices(refresh: true);
    } else if (selectedCategory == "Offers") {
      await _fetchOffers(refresh: true);
    } else if (selectedCategory == "Best Selling Packages") {
      await _fetchPackages(refresh: true);
    }
  });
  }

  /// VALIDATION FUNCTION
  void _goNextIfServiceSelected() {
    final provider = context.read<ServiceProvider>();
    final staffProvider = context.read<StaffProvider>();
    final bookingProvider = context.read<BookingProvider>();

    if (provider.selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();      FlushbarHelper.show(context, "Please select at least one service");

      return;
    }

    final hasSlot = bookingProvider.selectedSlot != null;

    if (hasSlot) {
      // Slot already chosen → go straight to review
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ReviewConfirmScreen()),
      );
    } else {
      // Staff-first flow: staff was pre-selected → skip staff selection screen
      final isStaffPreSelected =
          staffProvider.hasUserSelected && staffProvider.selectedStaff != null;

      if (isStaffPreSelected) {
        // Staff already chosen, time slot already chosen → go straight to review
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ReviewConfirmScreen()),
        );
      } else {
        // Normal flow: services chosen first → pick date/time next
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SelectDateTimeScreen()),
        );
      }
    }
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return "$minutes Mins";
    }
    final int hours = minutes ~/ 60;
    final int remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) {
      return "$hours ${hours == 1 ? "Hour" : "Hours"}";
    }
    return "$hours ${hours == 1 ? "Hour" : "Hours"} $remainingMinutes Mins";
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final sw = mq.size.width;
    // Scale factor based on Figma width 375
    final scale = sw / 375.0;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              if (selectedCategory == "Featured") {
                await _fetchServices(refresh: true);
              } else if (selectedCategory == "Offers") {
                await _fetchOffers(refresh: true);
              } else {
                await _fetchPackages(refresh: true);
              }
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              controller: _scrollController,
              child: Column(
                children: [
                  _buildHeader(scale),
                  _buildCategories(scale),
                  _buildDivider(scale),
                  if (selectedCategory == "Featured") ...[
                    _buildCategoryChips(scale),
                    _buildServiceList(scale),
                  ],
                  if (selectedCategory == "Offers") _buildOfferList(scale),
                  if (selectedCategory == "Best Selling Packages") _buildPackageList(scale),

                  SizedBox(height: 160 * scale),
                ],
              ),
              
            ),
          ),
          Positioned(
            bottom: 20 + MediaQuery.of(context).padding.bottom,
            left: 24,
            right: 24,
            child: Consumer<ServiceProvider>(
              builder: (context, provider, child) {
                final services = provider.selectedServices;
                final enabled = services.isNotEmpty;

                final bookingProvider = context.read<BookingProvider>();
                final staffProvider = context.read<StaffProvider>();
                
                final hasSlot = bookingProvider.selectedSlot != null;
                final isStaffPreSelected = staffProvider.hasUserSelected && staffProvider.selectedStaff != null;
                
                String buttonText = "Select slot";
                if (hasSlot) {
                  buttonText = "Next";
                } else if (isStaffPreSelected) {
                  buttonText = "Select slot";
                }

                String leftTitleText = "";
                String leftSubtitleText = "";

                if (enabled) {
                  leftTitleText = "${services.length} service${services.length > 1 ? 's' : ''}";
                  leftSubtitleText = services.map((s) => s.name).join(', ');
                } else if (isStaffPreSelected) {
                  leftTitleText = "Staff selected";
                  if (hasSlot) {
                    leftSubtitleText = "${staffProvider.selectedStaff!.name} • ${bookingProvider.selectedSlot!.displayTime}";
                  } else {
                    leftSubtitleText = staffProvider.selectedStaff!.name;
                  }
                } else if (hasSlot) {
                  leftTitleText = "Slot selected";
                  leftSubtitleText = bookingProvider.selectedSlot!.displayTime;
                } else {
                  leftTitleText = "Select service";
                  leftSubtitleText = "Please choose a service";
                }

                return Container(
                  height: 68 * scale,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1F22),
                    borderRadius: BorderRadius.circular(34 * scale),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 20 * scale, vertical: 10 * scale),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Text(
                                  leftTitleText,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 14 * scale,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(width: 4 * scale),
                                const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ],
                            ),
                            SizedBox(height: 2 * scale),
                            Text(
                              leftSubtitleText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 11 * scale,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: enabled ? _goNextIfServiceSelected : () {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          FlushbarHelper.show(context, "Please select at least one service");
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 24 * scale,
                            vertical: 10 * scale,
                          ),
                          decoration: BoxDecoration(
                            color: enabled ? Colors.white : Colors.white.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(20 * scale),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            buttonText,
                            style: GoogleFonts.poppins(
                              color: enabled ? Colors.black : Colors.black.withValues(alpha: 0.5),
                              fontSize: 12 * scale,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(double scale) {
    return Stack(
      children: [
        Container(
          width: 375 * scale,
          height: 225 * scale,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(bottomRight: Radius.circular(150)),
            image: DecorationImage(
              image: AssetImage(
                "assets/Images/ServicesScreen/background_services.jpg",
              ),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(150),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.0),
                  const Color(0xFFFF3502).withValues(alpha: 0.8),
                ],
              ),
            ),
          ),
        ),
        // Title
        Positioned(
          left: 24 * scale,
          top: 171 * scale,
          child: Text(
            "SERVICES",
            style: GoogleFonts.poppins(
              fontSize: 25 * scale,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              letterSpacing: 0,
            ),
          ),
        ),
        // Back Button
        Positioned(
          top: 50 * scale,
          left: 24 * scale,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 32 * scale,
              height: 32 * scale,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chevron_left, color: Colors.black),
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
    );
  }

  Widget _buildCategories(double scale) {
    final categories = ["Featured", "Offers", "Best Selling Packages"];
    return Container(
      height: 37 * scale,
      margin: EdgeInsets.only(top: 24 * scale, bottom: 24 * scale),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 24 * scale),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = selectedCategory == cat;

          // Fix: Allow flexible width to prevent wrapping, but keep a minimum feel
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedCategory = cat;
              });
              if (cat == "Featured" && _services.isEmpty) {
                _fetchServices(refresh: true);
              } else if (cat == "Offers" && _offersList.isEmpty) {
                _fetchOffers(refresh: true);
              } else if (cat == "Best Selling Packages" && _packagesList.isEmpty) {
                _fetchPackages(refresh: true);
              }
            },
            child: Container(
              height: 37 * scale,
              margin: EdgeInsets.only(right: 15 * scale),
              padding: EdgeInsets.symmetric(horizontal: 20 * scale),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFFF0B01)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                cat,
                style: GoogleFonts.poppins(
                  fontSize: 16 * scale,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.black,
                  textStyle: const TextStyle(height: 1.0),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDivider(double scale) {
    return Container(
      width: 375 * scale,
      height: 1 * scale,
      decoration: const BoxDecoration(
        color: Color(0xFFF0F0F0),
        boxShadow: [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
    );
  }

  bool _serviceMatchesCategory(NeoService service, String category) {
    if (category == "All") return true;
    final serviceCat = service.category.toLowerCase().trim();
    final filterCat = category.toLowerCase().trim();

    if (filterCat == "hair services") {
      return serviceCat.contains("cut") || serviceCat == "hair" || serviceCat == "hair services" || serviceCat == "hair cut";
    } else if (filterCat == "skin care") {
      return serviceCat == "skin care" || serviceCat == "facial" || serviceCat.contains("skin") || serviceCat.contains("facial") || serviceCat.contains("lighting");
    } else if (filterCat == "hair removal") {
      return serviceCat == "hair removal" || serviceCat.contains("removal");
    } else if (filterCat == "nail care") {
      return serviceCat == "nail care" || serviceCat.contains("nail");
    } else if (filterCat == "makeup") {
      return serviceCat == "makeup" || serviceCat.contains("makeup");
    } else if (filterCat == "grooming") {
      return serviceCat == "grooming" || serviceCat.contains("grooming");
    } else if (filterCat == "spa & massage") {
      return serviceCat == "spa & massage" || serviceCat.contains("massage");
    } else if (filterCat == "hair treatment") {
      return serviceCat == "hair treatment" || serviceCat.contains("treatment");
    }

    return serviceCat == filterCat || serviceCat.contains(filterCat) || filterCat.contains(serviceCat);
  }

  Widget _buildCategoryChips(double scale) {
    return Container(
      height: 38 * scale,
      margin: EdgeInsets.only(top: 16 * scale, bottom: 8 * scale),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 24 * scale),
        itemCount: _serviceCategories.length,
        itemBuilder: (context, index) {
          final category = _serviceCategories[index];
          final isSelected = category == _selectedServiceCategory;
          return Padding(
            padding: EdgeInsets.only(right: 12.0 * scale),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedServiceCategory = category;
                });
              },
              child: Container(
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(horizontal: 24 * scale),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0XFFFF0B01) : const Color(0XFFF5F5F7),
                  borderRadius: BorderRadius.circular(100 * scale),
                ),
                child: Text(
                  category,
                  style: GoogleFonts.poppins(
                    color: isSelected ? Colors.white : const Color(0XFF767678),
                    fontWeight: FontWeight.w500,
                    fontSize: 13 * scale,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildServiceList(double scale) {
    return Consumer<ServiceProvider>(
      builder: (context, provider, child) {
        if (_isLoading) {
          return const Padding(
            padding: EdgeInsets.all(50),
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFFFF0B01)),
            ),
          );
        }

        final filteredServices = _services
            .where((s) => _serviceMatchesCategory(s, _selectedServiceCategory))
            .toList();

        if (filteredServices.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 60.0),
            child: Center(
              child: Text(
                "No services available in this category.",
                style: GoogleFonts.poppins(
                  fontSize: 14 * scale,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }

        return Column(
          children: [
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredServices.length,
              padding: EdgeInsets.symmetric(vertical: 18 * scale),
              separatorBuilder: (context, index) => Padding(
                padding: EdgeInsets.symmetric(horizontal: 24 * scale),
                child: Divider(
                  color: const Color(0xFFF0F0F0),
                  thickness: 1 * scale,
               ),
              ),
              itemBuilder: (context, index) {
                final service = filteredServices[index];
                final isSelected = provider.isServiceSelected(service.id);
                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    24 * scale,
                    8 * scale,
                    24 * scale,
                    8 * scale,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              service.name,
                              style: GoogleFonts.poppins(
                                fontSize: 16 * scale,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              _formatDuration(service.duration),
                              style: GoogleFonts.poppins(
                                fontSize: 12 * scale,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF8D8D8D),
                              ),
                            ),
                            Text(
                              "Complete ${service.name} With Blow Dry Styling",
                              style: GoogleFonts.poppins(
                                fontSize: 10 * scale,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF8D8D8D),
                              ),
                            ),
                            SizedBox(height: 8 * scale),
                            Text(
                              "₹ ${service.price.toInt()}",
                              style: GoogleFonts.poppins(
                                fontSize: 18 * scale,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          provider.toggleServiceSelection(service.id);
                          final bookingProvider = context.read<BookingProvider>();
                          bookingProvider.setSelectedPackage(null);
                          
                          if (bookingProvider.preSelectedStaffId == null && bookingProvider.selectedSlot == null) {
                            bookingProvider.selectSlot(null);
                            context.read<StaffProvider>().selectStaff(null);
                          }
                        },
                        child: Container(
                          width: 41 * scale, // Ellipse 118
                          height: 41 * scale,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFFF0B01)
                                : Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: isSelected
                                ? null
                                : [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                          ),
                          child: isSelected
                              ? Center(
                                  child: Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 24 * scale,
                                    weight: 3.0, // Vector 203 border-width 3px
                                  ),
                                )
                              : Center(
                                  child: Icon(
                                    Icons.add,
                                    color: Colors.black,
                                    size: 24 * scale,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            if (_isLoadingMore)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF0B01)),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildOfferList(double scale) {
    return Consumer<BookingProvider>(
      builder: (context, bookingProvider, child) {
        if (_offersLoading) {
          return const Padding(
            padding: EdgeInsets.all(50),
            child: Center(
              child: CircularProgressIndicator(color: Color(0XFFFF0B01)),
            ),
          );
        }

        final offers = _offersList;

        if (offers.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 60.0),
            child: Center(
              child: Text(
                "No active Offers today",
                style: GoogleFonts.poppins(
                  fontSize: 14 * scale,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }

        return Column(
          children: [
            ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: offers.length,
          padding: EdgeInsets.symmetric(vertical: 18 * scale),
          separatorBuilder: (context, index) => Padding(
            padding: EdgeInsets.symmetric(horizontal: 24 * scale),
            child: Divider(
              color: const Color(0xFFF0F0F0),
              thickness: 1 * scale,
            ),
          ),
          itemBuilder: (context, index) {
            final offer = offers[index];
            final serviceProvider = context.read<ServiceProvider>();
            
            // For offers, we consider it "selected" if it is the applied offer
            final bool isSelected = bookingProvider.appliedOffer?.id == offer.id;

            return GestureDetector(
              onTap: () {
                if (isSelected) {
                  bookingProvider.applyOffer(null);
                  serviceProvider.clearSelections();
                } else {
                  if (bookingProvider.preSelectedStaffId == null && bookingProvider.selectedSlot == null) {
                    context.read<StaffProvider>().selectStaff(null);
                    bookingProvider.selectSlot(null);
                  }
                  
                  final serviceIds = offer.applicableServices.map((s) => s.id).toList();
                  serviceProvider.preselectServices(serviceIds);
                  bookingProvider.applyOffer(offer);
                }
              },
              child: Padding(
                padding: EdgeInsets.fromLTRB(24 * scale, 8 * scale, 24 * scale, 8 * scale),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                offer.name,
                                style: GoogleFonts.poppins(
                                  fontSize: 16 * scale,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                offer.description,
                                style: GoogleFonts.poppins(
                                  fontSize: 10 * scale,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF8D8D8D),
                                ),
                              ),
                              if (offer.applicableServices.isNotEmpty && !isSelected)
                                Padding(
                                  padding: EdgeInsets.only(top: 4 * scale),
                                  child: Text(
                                    "Services: ${offer.applicableServices.map((s) => s.name).join(", ")}",
                                    style: GoogleFonts.poppins(
                                      fontSize: 10 * scale,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                              SizedBox(height: 8 * scale),
                              Text(
                                offer.discountType == "PERCENTAGE" 
                                  ? "${offer.discountValue.toInt()}% OFF"
                                  : "₹ ${offer.discountValue.toInt()} OFF",
                                style: GoogleFonts.poppins(
                                  fontSize: 18 * scale,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0XFFFF0B01),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildSelectCircle(isSelected, scale),
                      ],
                    ),
                    if (isSelected && offer.applicableServices.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Price Breakdown:",
                              style: GoogleFonts.poppins(
                                fontSize: 11 * scale,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ...offer.applicableServices.map((s) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      s.name,
                                      style: GoogleFonts.poppins(
                                        fontSize: 11 * scale,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      "₹${s.price.toInt()}",
                                      style: GoogleFonts.poppins(
                                        fontSize: 11 * scale,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const Divider(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Original Total:",
                                  style: GoogleFonts.poppins(
                                    fontSize: 11 * scale,
                                    color: Colors.black54,
                                  ),
                                ),
                                Text(
                                  "₹${offer.applicableServices.fold(0.0, (sum, s) => sum + s.price).toInt()}",
                                  style: GoogleFonts.poppins(
                                    fontSize: 11 * scale,
                                    color: Colors.black54,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Discount Saved:",
                                  style: GoogleFonts.poppins(
                                    fontSize: 11 * scale,
                                    color: Colors.green,
                                  ),
                                ),
                                Text(
                                  "- ₹${(offer.discountType == "PERCENTAGE" ? (offer.applicableServices.fold(0.0, (sum, s) => sum + s.price) * (offer.discountValue / 100)) : offer.discountValue).toInt()}",
                                  style: GoogleFonts.poppins(
                                    fontSize: 11 * scale,
                                    color: Colors.green,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Payable Amount:",
                                  style: GoogleFonts.poppins(
                                    fontSize: 11 * scale,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  "₹${(offer.applicableServices.fold(0.0, (sum, s) => sum + s.price) - (offer.discountType == "PERCENTAGE" ? (offer.applicableServices.fold(0.0, (sum, s) => sum + s.price) * (offer.discountValue / 100)) : offer.discountValue)).toInt()}",
                                  style: GoogleFonts.poppins(
                                    fontSize: 12 * scale,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0XFFFF0B01),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
        if (_offersLoadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: CircularProgressIndicator(color: Color(0XFFFF0B01)),
            ),
          ),
      ],
    );
      },
    );
  }

  Widget _buildPackageList(double scale) {
    return Consumer<ServiceProvider>(
      builder: (context, serviceProvider, child) {
        if (_packagesLoading) {
          return const Padding(
            padding: EdgeInsets.all(50),
            child: Center(
              child: CircularProgressIndicator(color: Color(0XFFFF0B01)),
            ),
          );
        }

        final packages = _packagesList;

        if (packages.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 60.0),
            child: Center(
              child: Text(
                "No active Packages today",
                style: GoogleFonts.poppins(
                  fontSize: 14 * scale,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }

        return Column(
          children: [
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: packages.length,
              padding: EdgeInsets.symmetric(vertical: 18 * scale),
              separatorBuilder: (context, index) => Padding(
                padding: EdgeInsets.symmetric(horizontal: 24 * scale),
                child: Divider(
                  color: const Color(0xFFF0F0F0),
                  thickness: 1 * scale,
                ),
              ),
              itemBuilder: (context, index) {
                final package = packages[index];
                final bookingProvider = context.read<BookingProvider>();

                // For packages, we consider it selected if all its service IDs are in the selected list
                final packageServiceIds = package.services.map((s) => s.id).toSet();
                final currentSelectedIds = serviceProvider.selectedServiceIds;
                final bool isSelected = packageServiceIds.isNotEmpty && 
                    packageServiceIds.every((id) => currentSelectedIds.contains(id)) &&
                    packageServiceIds.length == currentSelectedIds.length;

                return GestureDetector(
                  onTap: () {
                    if (isSelected) {
                      serviceProvider.clearSelections();
                      bookingProvider.setSelectedPackage(null);
                    } else {
                      if (bookingProvider.preSelectedStaffId == null && bookingProvider.selectedSlot == null) {
                        context.read<StaffProvider>().selectStaff(null);
                        bookingProvider.selectSlot(null);
                      }
                      
                      final serviceIds = package.services.map((s) => s.id).toList();
                      serviceProvider.preselectServices(serviceIds);
                      bookingProvider.applyOffer(null);
                      bookingProvider.setSelectedPackage(package);
                    }
                  },
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24 * scale, 8 * scale, 24 * scale, 8 * scale),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                package.name,
                                style: GoogleFonts.poppins(
                                  fontSize: 16 * scale,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                package.services.map((s) => s.name).join(", "),
                                style: GoogleFonts.poppins(
                                  fontSize: 10 * scale,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF8D8D8D),
                                ),
                              ),
                              SizedBox(height: 8 * scale),
                              Text(
                                "₹ ${package.packagePrice.toInt()}",
                                style: GoogleFonts.poppins(
                                  fontSize: 18 * scale,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildSelectCircle(isSelected, scale),
                      ],
                    ),
                  ),
                );
              },
            ),
            if (_packagesLoadingMore)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: CircularProgressIndicator(color: Color(0XFFFF0B01)),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSelectCircle(bool isSelected, double scale) {
    return Container(
      width: 41 * scale,
      height: 41 * scale,
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFFF0B01) : Colors.white,
        shape: BoxShape.circle,
        boxShadow: isSelected
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: isSelected
          ? Center(
              child: Icon(
                Icons.check,
                color: Colors.white,
                size: 24 * scale,
              ),
            )
          : Center(
              child: Icon(
                Icons.add,
                color: Colors.black,
                size: 24 * scale,
              ),
            ),
    );
  }
}
