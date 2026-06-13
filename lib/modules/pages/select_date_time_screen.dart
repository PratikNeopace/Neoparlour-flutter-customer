import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../provider/customer/booking_provider.dart';
import '../../provider/customer/service_provider.dart';
import '../../provider/customer/staff_provider.dart';
import '../../widgets/custom_nav_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'select_services_screen.dart';
import 'select_staff_screen.dart';
import 'home_screen.dart';

class SelectDateTimeScreen extends StatefulWidget {
  const SelectDateTimeScreen({super.key});

  @override
  State<SelectDateTimeScreen> createState() => _SelectDateTimeScreenState();
}

class _SelectDateTimeScreenState extends State<SelectDateTimeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bookingProvider = context.read<BookingProvider>();
      final staffProvider = context.read<StaffProvider>();
      final serviceProvider = context.read<ServiceProvider>();

      final preSelectedStaff = staffProvider.selectedStaff;

      if (preSelectedStaff != null && staffProvider.hasUserSelected) {
        // Staff pre-selected: compute duration and fetch staff-specific slots
        final totalDuration = serviceProvider.selectedServices.fold<int>(
          0, (sum, s) => sum + s.duration,
        );
        final duration = totalDuration > 0 ? totalDuration : 45;
        bookingProvider.setPreSelectedStaff(preSelectedStaff.id, durationMinutes: duration);
        bookingProvider.fetchStaffSlots(preSelectedStaff.id, duration);
      } else {
        // No staff pre-selected: use generic salon slots
        bookingProvider.setPreSelectedStaff(null);
        bookingProvider.fetchSalonSlots();
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final sw = mq.size.width;
    final scale = sw / 375.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                _buildHeader(scale),
                _buildDateSelection(scale),
                _buildTimeSlots(scale),

                // NEXT Button
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    26 * scale,
                    30 * scale,
                    25 * scale,
                    20 * scale,
                  ),
                  child: Consumer<BookingProvider>(
                    builder: (context, provider, child) {
                      final isStaffPreSelected =
                          provider.preSelectedStaffId != null;

                      return GestureDetector(
                        onTap: provider.selectedSlot == null
                            ? null
                            : () {
                                if (isStaffPreSelected) {
                                  // Staff-first flow: slot chosen → pick services
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SelectServicesScreen(),
                                    ),
                                  );
                                } else {
                                  // Normal flow: services + slot chosen → pick staff
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SelectStaffScreen(),
                                    ),
                                  );
                                }
                              },
                        child: Container(
                          height: 49 * scale,
                          width: 324 * scale,
                          decoration: BoxDecoration(
                            color: provider.selectedSlot == null
                                ? Colors.grey
                                : const Color(0xFFFF0B01),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "NEXT",
                            style: GoogleFonts.poppins(
                              fontSize: 12 * scale,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 100 * scale),
              ],
            ),
          ),

          ///  RIGHT CORNER NEXT BUTTON
          Positioned(
            bottom: 20,
            right: 18,
            child: Consumer<BookingProvider>(
              builder: (context, provider, child) {
                final enabled = provider.selectedSlot != null;
                final isStaffPreSelected =
                    provider.preSelectedStaffId != null;

                return FloatingActionButton(
                  heroTag: "nextBtn",
                  mini: true,
                  onPressed: enabled
                      ? () {
                          if (isStaffPreSelected) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const SelectServicesScreen(),
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const SelectStaffScreen(),
                              ),
                            );
                          }
                        }
                      : null,
                  backgroundColor: enabled
                      ? const Color(0xFFFF0B01)
                      : Colors.grey,
                  child: const Icon(Icons.arrow_forward, color: Colors.white),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavBar(selectedLabel: "SERVICES"),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _buildHomeFAB(context),
    );
  }

  Widget _buildHomeFAB(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      ),
      backgroundColor: const Color(0xFFFF0B01),
      elevation: 5,
      shape: const CircleBorder(),
      child: SvgPicture.asset(
        "assets/Images/BottomNavigationBar/home_icon.svg",
      ),
    );
  }

  Widget _buildHeader(double scale) {
    final headerHeight = 225 * scale;

    return SizedBox(
      height: headerHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          /// Background image
          Container(
            width: double.infinity,
            height: headerHeight,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(150),
              ),
              image: DecorationImage(
                image: AssetImage(
                  "assets/Images/SelectDateTime/select_date_time_bg_img.jpeg",
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
                    Colors.black.withValues(alpha: 0.15),
                    Colors.transparent,
                    const Color(0xFFFF3502).withValues(alpha: 0.35),
                  ],
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

          ///  Red badge — anchored to bottom-right
          Positioned(
            bottom: -10 * scale, // half outside header
            right: 24 * scale,
            child: Container(
              width: 59 * scale,
              height: 59 * scale,
              decoration: const BoxDecoration(
                color: Color(0xFFFF0B01),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SvgPicture.asset(
                  "assets/Images/MyBookingScreen/booking_floating_btn.svg",
                  width: 26 * scale,
                  height: 26 * scale,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),

          ///  TITLE — now dynamically placed from bottom
          Positioned(
            left: 24 * scale,
            bottom: 24 * scale,
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.65,
              child: Text(
                "SELECT DATE AND TIME",
                maxLines: 2,
                style: GoogleFonts.poppins(
                  fontSize: 26 * scale,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelection(double scale) {
    return Consumer<BookingProvider>(
      builder: (context, provider, child) {
        final now = DateTime.now();
        final days = List.generate(
          30,
          (index) => now.add(Duration(days: index)),
        );

        return Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                24 * scale,
                30 * scale,
                24 * scale,
                15 * scale,
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month, size: 24),
                  SizedBox(width: 8 * scale),
                  Text(
                    "DATE",
                    style: GoogleFonts.poppins(
                      fontSize: 16 * scale,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_left, size: 18),
                  Text(
                    DateFormat('MMMM').format(provider.selectedDate),
                    style: GoogleFonts.poppins(
                      fontSize: 12 * scale,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 18),
                  SizedBox(width: 8 * scale),
                  Text(
                    DateFormat('yyyy').format(provider.selectedDate),
                    style: GoogleFonts.poppins(
                      fontSize: 12 * scale,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 70 * scale,
              decoration: const BoxDecoration(color: Color(0x4DFFD7CD)),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 10 * scale),
                itemCount: days.length,
                itemBuilder: (context, index) {
                  final date = days[index];
                  final isSelected = DateUtils.isSameDay(
                    date,
                    provider.selectedDate,
                  );

                  return GestureDetector(
                    onTap: () {
                      provider.selectDate(date);
                    },
                    child: Container(
                      width: 50 * scale,
                      margin: EdgeInsets.symmetric(
                        vertical: 6 * scale,
                        horizontal: 4 * scale,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFFF0B01)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16.5 * scale),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('E').format(date).toLowerCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 10 * scale,
                              fontWeight: isSelected
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF8D8D8D),
                            ),
                          ),
                          SizedBox(height: 4 * scale),
                          Container(
                            width: 25 * scale,
                            height: 25 * scale,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              date.day.toString(),
                              style: GoogleFonts.poppins(
                                fontSize: 14 * scale,
                                fontWeight: FontWeight.w400,
                                color: Colors.black,
                              ),
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

  Widget _buildTimeSlots(double scale) {
    return Consumer<BookingProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingSlots) {
          return const Padding(
            padding: EdgeInsets.all(40.0),
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFFFF0B01)),
            ),
          );
        }

        if (provider.availableSlots.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(40.0),
            child: Center(
              child: Text(
                provider.error ?? "No slots available for this date",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: provider.error != null ? Colors.red : Colors.grey,
                  fontSize: 14 * scale,
                ),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: 24 * scale,
            vertical: 20 * scale,
          ),
          itemCount: provider.availableSlots.length,
          itemBuilder: (context, index) {
            final slot = provider.availableSlots[index];
            final isSelected = provider.selectedSlot == slot;

            return GestureDetector(
              onTap: () => provider.selectSlot(slot),
              child: Container(
                height: 48 * scale,
                margin: EdgeInsets.only(bottom: 15 * scale),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: const Color(0xFF909090), width: 1),
                ),
                padding: EdgeInsets.symmetric(horizontal: 18 * scale),
                child: Row(
                  children: [
                    Text(
                      slot.displayTime,
                      style: GoogleFonts.poppins(
                        fontSize: 14 * scale,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 16 * scale,
                      height: 16 * scale,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 1),
                        color: isSelected
                            ? const Color(0xFFFF0B01)
                            : Colors.transparent,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 10,
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
