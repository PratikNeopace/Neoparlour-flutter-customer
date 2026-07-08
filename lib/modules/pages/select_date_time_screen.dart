import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../provider/customer/booking_provider.dart';
import '../../provider/customer/service_provider.dart';
import '../../provider/customer/staff_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'select_services_screen.dart';
import 'select_staff_screen.dart';
import '../../core/domain/models/appointment.dart';
import '../../core/utils/flushbar_helper.dart';
import '../../core/utils/error_handler.dart';
import '../../provider/customer/auth_provider.dart';

class SelectDateTimeScreen extends StatefulWidget {
  final bool isReschedule;
  final Appointment? rescheduleAppointment;

  const SelectDateTimeScreen({
    super.key,
    this.isReschedule = false,
    this.rescheduleAppointment,
  });

  @override
  State<SelectDateTimeScreen> createState() => _SelectDateTimeScreenState();
}

class _SelectDateTimeScreenState extends State<SelectDateTimeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isExpanded = false;

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

                SizedBox(height: 130 * scale),
              ],
            ),
          ),

          Positioned(
            bottom: 20 + MediaQuery.of(context).padding.bottom,
            left: 24,
            right: 24,
            child: Consumer<BookingProvider>(
              builder: (context, provider, child) {
                final enabled = provider.selectedSlot != null;
                final isStaffPreSelected = provider.preSelectedStaffId != null;
                
                final serviceProvider = context.read<ServiceProvider>();
                final staffProvider = context.read<StaffProvider>();
                
                final services = serviceProvider.selectedServices;
                final hasServices = services.isNotEmpty;
                final staff = staffProvider.selectedStaff;
                
                String leftTitleText = "";
                String leftSubtitleText = "";
                String buttonText = "Next";
                
                if (widget.isReschedule) {
                  leftTitleText = "Reschedule Appointment";
                  if (enabled) {
                    leftSubtitleText = "New Slot: ${provider.selectedSlot!.displayTime}";
                  } else {
                    leftSubtitleText = "Please choose a slot";
                  }
                  buttonText = "Confirm Reschedule";
                } else if (hasServices) {
                  leftTitleText = "${services.length} service${services.length > 1 ? 's' : ''}";
                  if (enabled) {
                    leftSubtitleText = "${services.map((s) => s.name).join(', ')} • Slot: ${provider.selectedSlot!.displayTime}";
                  } else {
                    leftSubtitleText = services.map((s) => s.name).join(', ');
                  }
                  buttonText = "Next";
                } else if (staff != null) {
                  leftTitleText = "Staff selected";
                  if (enabled) {
                    leftSubtitleText = "${staff.name} • Slot: ${provider.selectedSlot!.displayTime}";
                  } else {
                    leftSubtitleText = staff.name;
                  }
                  buttonText = "Select services";
                } else {
                  leftTitleText = "Select slot";
                  leftSubtitleText = "Please choose a slot";
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
                                Flexible(
                                  child: Text(
                                    leftTitleText,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 14 * scale,
                                      fontWeight: FontWeight.w600,
                                    ),
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
                        onTap: !enabled
                            ? null
                            : () {
                                if (widget.isReschedule) {
                                  _showRescheduleReasonDialog(context, provider);
                                } else if (isStaffPreSelected) {
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
              height: 75 * scale,
              decoration: const BoxDecoration(color: Color(0x4DFFD7CD)),
              child: Row(
                children: [
                  SizedBox(width: 20 * scale),
                  // Month pill
                  Container(
                    width: 32 * scale,
                    height: 55 * scale,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D2D2D),
                      borderRadius: BorderRadius.circular(10 * scale),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      DateFormat('MMM').format(provider.selectedDate).toUpperCase().split('').join('\n'),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 10 * scale,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                  ),
                  SizedBox(width: 8 * scale),
                  // Scrollable dates list
                  Expanded(
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 2 * scale),
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
                              vertical: 8 * scale,
                              horizontal: 4 * scale,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFFF0B01)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12 * scale),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  date.day.toString(),
                                  style: GoogleFonts.poppins(
                                    fontSize: 15 * scale,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                                SizedBox(height: 2 * scale),
                                Text(
                                  DateFormat('E').format(date),
                                  style: GoogleFonts.poppins(
                                    fontSize: 10 * scale,
                                    fontWeight: isSelected
                                        ? FontWeight.w500
                                        : FontWeight.w400,
                                    color: isSelected
                                        ? Colors.white.withValues(alpha: 0.8)
                                        : const Color(0xFF8D8D8D),
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

        final slots = provider.availableSlots;
        final bool showToggle = slots.length > 6;
        final int displayCount = showToggle && !_isExpanded ? 6 : slots.length;

        return Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 24 * scale,
                vertical: 20 * scale,
              ),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 11 * scale,
                  mainAxisSpacing: 11 * scale,
                  childAspectRatio: 2.2,
                ),
                itemCount: displayCount,
                itemBuilder: (context, index) {
                  final slot = slots[index];
                  final isSelected = provider.selectedSlot == slot;
                  final hasDiscount = slot.discountMessage != null && slot.discountMessage!.isNotEmpty;

                  return GestureDetector(
                    onTap: slot.busy ? null : () => provider.selectSlot(slot),
                    child: Opacity(
                      opacity: slot.busy ? 0.5 : 1.0,
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: slot.busy
                                  ? Colors.grey.shade100
                                  : isSelected
                                      ? const Color(0xFFFF0B01)
                                      : Colors.white,
                              borderRadius: BorderRadius.circular(9 * scale),
                              border: Border.all(
                                color: slot.busy
                                    ? Colors.grey.shade300
                                    : isSelected
                                        ? const Color(0xFFFF0B01)
                                        : const Color(0xFFDFDFDF),
                                width: 1,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  slot.displayTime,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13 * scale,
                                    fontWeight: isSelected && !slot.busy
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: slot.busy
                                        ? Colors.grey.shade400
                                        : isSelected
                                            ? Colors.white
                                            : const Color(0xFF2D2D2D),
                                    decoration: slot.busy
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                    decorationColor: Colors.grey.shade400,
                                  ),
                                ),
                                if (hasDiscount && !slot.busy) ...[
                                  SizedBox(height: 2 * scale),
                                  Text(
                                    slot.discountMessage!,
                                    style: GoogleFonts.poppins(
                                      fontSize: 9.5 * scale,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white.withValues(alpha: 0.9)
                                          : const Color(0xFF8E7CFF),
                                    ),
                                  ),
                                ],
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
            if (showToggle)
              Padding(
                padding: EdgeInsets.only(bottom: 10 * scale),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16 * scale,
                      vertical: 8 * scale,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isExpanded ? "View less" : "View all slots",
                          style: GoogleFonts.poppins(
                            fontSize: 13 * scale,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF2D2D2D),
                          ),
                        ),
                        SizedBox(width: 4 * scale),
                        Icon(
                          _isExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          size: 18 * scale,
                          color: const Color(0xFF2D2D2D),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showRescheduleReasonDialog(BuildContext context, BookingProvider provider) {
    if (widget.rescheduleAppointment == null || provider.selectedSlot == null) return;
    
    final TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Reschedule Reason"),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(hintText: "Why are you rescheduling?"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("BACK")),
          TextButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) return;
              
              Navigator.pop(dialogContext); // Close dialog
              
              final auth = context.read<AuthProvider>();
              final newDateTime = provider.selectedSlot!.startTime;
              
              try {
                await provider.rescheduleAppointment(
                  widget.rescheduleAppointment!.id,
                  newDateTime,
                  reason,
                  auth.userPhone ?? '',
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  FlushbarHelper.show(context, "Appointment rescheduled successfully", isSuccess: true);
                }
              } catch (e) {
                final msg = ErrorHandler.getErrorMessage(e);
                if (context.mounted) {
                  FlushbarHelper.show(context, msg);
                }
              }
            },
            child: const Text("CONFIRM"),
          ),
        ],
      ),
    );
  }
}
