import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../provider/customer/staff_provider.dart';
import '../../provider/customer/service_provider.dart';
import '../../provider/customer/booking_provider.dart';
import '../../provider/customer/auth_provider.dart';
import '../../core/domain/models/staff.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'review_confirm_screen.dart';
import 'select_services_screen.dart';
import '../../widgets/staff_image_widgets.dart';

///  ADDED — responsive font helper (fixes your error)
double responsiveFont(
  BuildContext context, {
  required double min,
  required double max,
  required double factor,
}) {
  final width = MediaQuery.of(context).size.width;
  final size = width * factor;
  if (size < min) return min;
  if (size > max) return max;
  return size;
}

class SelectStaffScreen extends StatefulWidget {
  const SelectStaffScreen({super.key});

  @override
  State<SelectStaffScreen> createState() => _SelectStaffScreenState();
}

class _SelectStaffScreenState extends State<SelectStaffScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  Future<void> _fetchData({bool forceRefresh = false}) async {
    final bookingProvider = context.read<BookingProvider>();
    final serviceProvider = context.read<ServiceProvider>();
    final staffProvider = context.read<StaffProvider>();
    final authProvider = context.read<AuthProvider>();

    final selectedSlot = bookingProvider.selectedSlot;
    final manualTime = bookingProvider.manualTime;
    final selectedServices = serviceProvider.selectedServices;

    final totalDuration = selectedServices.fold<int>(
      0,
      (sum, s) => sum + s.duration,
    );
    final duration = totalDuration > 0 ? totalDuration : 30;

    DateTime appointmentTime = selectedSlot?.startTime ?? manualTime;
    String selectedTime = appointmentTime.toUtc().toIso8601String();

    await staffProvider.fetchAvailableStaff(
      selectedTime,
      duration,
      salonId: authProvider.salonId,
      forceRefresh: forceRefresh,
    );
  }

  void _goNext(BuildContext context, StaffProvider provider) {
    if (!mounted) return;
    final serviceProvider = context.read<ServiceProvider>();

    if (serviceProvider.selectedServices.isEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SelectServicesScreen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ReviewConfirmScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final sw = mq.size.width;
    final scale = sw / 375.0;
    final bottomSafeSpace =
    MediaQuery.of(context).padding.bottom + 140; 
// 140 = FAB + BottomNav + breathing space

    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,

      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => _fetchData(forceRefresh: true),
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _buildHeader(scale),
                  _buildStaffList(scale),

                  // SizedBox(height: 80 * scale),

                  SizedBox(height: bottomSafeSpace),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: 20 + MediaQuery.of(context).padding.bottom,
            left: 24,
            right: 24,
            child: Consumer<StaffProvider>(
              builder: (context, provider, _) {
                final isEnabled = provider.hasUserSelected;
                final serviceProvider = context.read<ServiceProvider>();
                final bookingProvider = context.read<BookingProvider>();
                
                final services = serviceProvider.selectedServices;
                final hasServices = services.isNotEmpty;
                final hasSlot = bookingProvider.selectedSlot != null;
                
                String leftTitleText = "";
                String leftSubtitleText = "";
                String buttonText = "Next";
                
                if (hasServices) {
                  leftTitleText = "${services.length} service${services.length > 1 ? 's' : ''}";
                  if (isEnabled) {
                    leftSubtitleText = "${services.map((s) => s.name).join(', ')} • ${provider.selectedStaff?.name ?? 'No Preference'}";
                  } else {
                    leftSubtitleText = services.map((s) => s.name).join(', ');
                  }
                  buttonText = hasSlot ? "Next" : "Select slot";
                } else if (hasSlot) {
                  leftTitleText = "Slot selected";
                  if (isEnabled) {
                    leftSubtitleText = "${bookingProvider.selectedSlot!.displayTime} • ${provider.selectedStaff?.name ?? 'No Preference'}";
                  } else {
                    leftSubtitleText = bookingProvider.selectedSlot!.displayTime;
                  }
                  buttonText = "Next";
                } else {
                  // Fallback if somehow nothing is set
                  leftTitleText = "Select Staff";
                  leftSubtitleText = "Please select a professional";
                  buttonText = "Next";
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
                        onTap: isEnabled ? () => _goNext(context, provider) : null,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 24 * scale,
                            vertical: 10 * scale,
                          ),
                          decoration: BoxDecoration(
                            color: isEnabled ? Colors.white : Colors.white.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(20 * scale),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            buttonText,
                            style: GoogleFonts.poppins(
                              color: isEnabled ? Colors.black : Colors.black.withValues(alpha: 0.5),
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

  // HEADER FIXED — title no longer hidden by floating badge
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
                "assets/Images/SelectProfessionalScreen/select_professional_background_img.jpeg",
              ),
              fit: BoxFit.cover,
            ),
          ),
        ),

        /// Gradient
        Container(
          height: 225 * scale,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              bottomRight: Radius.circular(150),
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.3),
                Colors.transparent,
                const Color(0XFFFF3502).withValues(alpha: 0.7),
              ],
            ),
          ),
        ),

        // TITLE — moved slightly left & dynamic size
        Positioned(
          left: 24 * scale,
          bottom: 20 * scale,
          right: 90 * scale,
          child: Text(
            "SELECT PROFESSIONAL",
            maxLines: 2,
            style: GoogleFonts.poppins(
              fontSize: responsiveFont(
                context,
                min: 20,
                max: 32,
                factor: 0.065,
              ),
              fontWeight: FontWeight.w500,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
        ),

        /// Floating badge (unchanged)
        Positioned(
          bottom: 5,
          right: 25,
          child: Container(
            height: 55,
            width: 55,
            decoration: const BoxDecoration(
              color: Color(0xFFFF0B01),
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: SvgPicture.asset(
                "assets/Images/TopExpertsScreen/floating_top_icon.svg",
              ),
            ),
          ),
        ),

        ///  Back Button (safe for notch phones)
        SafeArea(
          child: Padding(
            padding: EdgeInsets.only(left: 24 * scale, top: 10 * scale),
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 34 * scale,
                height: 34 * scale,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chevron_left, color: Colors.black),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStaffList(double scale) {
    return Consumer<StaffProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Padding(
            padding: EdgeInsets.all(50),
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFFFF0B01)),
            ),
          );
        }

        final staff = provider.availableStaffList;

        if (provider.error != null) {
          return Padding(
            padding: EdgeInsets.symmetric(
              vertical: 50 * scale,
              horizontal: 20 * scale,
            ),
            child: Center(
              child: Text(
                "Error: ${provider.error}",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.red),
              ),
            ),
          );
        }

        return ListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(vertical: 24 * scale),
          children: [
            _buildStaffItem(
              context,
              null,
              "No Preference",
              "For Maximum Available",
              scale,
              provider.hasUserSelected && provider.selectedStaff == null,
            ),
            if (staff.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 20 * scale, horizontal: 24 * scale),
                child: Text(
                  "No specific staff available for this time slot.",
                  style: GoogleFonts.poppins(
                    fontSize: 12 * scale,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ...staff.map(
              (s) => _buildStaffItem(
                context,
                s,
                s.name,
                "Hair Cut Technician",
                scale,
                provider.selectedStaff?.id == s.id,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStaffItem(
    BuildContext context,
    Staff? staff,
    String name,
    String role,
    double scale,
    bool isSelected,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 24 * scale,
        vertical: 12 * scale,
      ),
      child: Row(
        children: [
          StaffAvatar(
            imageAsBase64: staff?.imageAsBase64,
            gender: staff?.gender,
            size: 61 * scale,
            borderRadius: 30.5, // Circular
          ),
          SizedBox(width: 12 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 16 * scale,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  role,
                  style: GoogleFonts.poppins(
                    fontSize: 10 * scale,
                    color: const Color(0xFF8D8D8D),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.read<StaffProvider>().selectStaff(staff),
            child: Container(
              width: 70 * scale,
              height: 27 * scale,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFF0B01) : Colors.white,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFFF0B01)
                      : const Color(0xFF8D8D8D),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                isSelected ? "Selected" : "Select",
                style: GoogleFonts.poppins(
                  fontSize: 10 * scale,
                  color: isSelected ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
