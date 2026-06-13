import 'package:flutter/material.dart';
import '../../core/utils/flushbar_helper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../provider/customer/booking_provider.dart';
import '../../provider/customer/staff_provider.dart';
import '../../provider/customer/service_provider.dart';
import '../../provider/customer/auth_provider.dart';
import '../../widgets/custom_nav_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/utils/error_handler.dart';
import 'home_screen.dart';
import 'appointment_booked_screen.dart';

class ReviewConfirmScreen extends StatefulWidget {
  const ReviewConfirmScreen({super.key});

  @override
  State<ReviewConfirmScreen> createState() => _ReviewConfirmScreenState();
}

class _ReviewConfirmScreenState extends State<ReviewConfirmScreen> {
  bool _isConfirming = false;
  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final bookingProvider = context.read<BookingProvider>();
      final salonIdStr = authProvider.tenantName;
      final salonId = int.tryParse(salonIdStr!) ?? 1;
      bookingProvider.fetchHomeServiceCharges(salonId);
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    setState(() => _isConfirming = true);

    final staffProvider = context.read<StaffProvider>();
    final serviceProvider = context.read<ServiceProvider>();
    final bookingProvider = context.read<BookingProvider>();
    final authProvider = context.read<AuthProvider>();

    final selectedStaff = staffProvider.selectedStaff;
    final selectedServices = serviceProvider.selectedServices;
    final salonId = authProvider.tenantName;

    if (selectedServices.isEmpty) {      FlushbarHelper.show(context, "Error: No services selected");

      setState(() => _isConfirming = false);
      return;
    }

    if (bookingProvider.isHomeService) {
      if (_addressController.text.trim().isEmpty) {        FlushbarHelper.show(context, "Please enter your address for home service");

        setState(() => _isConfirming = false);
        return;
      }
      bookingProvider.setHomeAddress(_addressController.text.trim());
    }

    try {
      final response = await bookingProvider.confirmBooking(
        staff: selectedStaff,
        selectedServices: selectedServices,
        salonId: salonId,
      );

      if (mounted) {
        // Clear state after successful booking
        serviceProvider.clearSelections();
        staffProvider.resetStaffState();
        bookingProvider.resetBookingState();

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                AppointmentBookedScreen(bookingData: response),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = ErrorHandler.getErrorMessage(e);        FlushbarHelper.show(context, errorMessage);

      }
    } finally {
      if (mounted) setState(() => _isConfirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final sw = mq.size.width;
    final scale = sw / 375.0;

    final staff = context.watch<StaffProvider>().selectedStaff;
    final services = context.watch<ServiceProvider>().selectedServices;
    final booking = context.watch<BookingProvider>();
    final bool homeServiceAvailable = booking.homeServiceCharge > 0;

    final subtotal = services.fold<double>(0, (sum, item) => sum + item.price);
    final basePrice = booking.selectedPackage != null 
        ? booking.selectedPackage!.packagePrice 
        : subtotal;
    final packageSavings = booking.selectedPackage != null
        ? (subtotal - booking.selectedPackage!.packagePrice)
        : 0.0;

    double discountAmount = 0.0;
    if (booking.appliedOffer != null) {
      if (booking.appliedOffer!.discountType == 'PERCENTAGE') {
        discountAmount = basePrice * (booking.appliedOffer!.discountValue / 100);
      } else {
        discountAmount = booking.appliedOffer!.discountValue;
      }
    }
    final subtotalAfterDiscount = basePrice - discountAmount;
    final homeCharge = booking.isHomeService ? booking.homeServiceCharge : 0.0;
    final finalTotal = subtotalAfterDiscount + homeCharge;

    final primaryService = services.isNotEmpty ? services.first : null;
    final dateFormatted = DateFormat(
      'EEEE d MMMM',
    ).format(booking.selectedDate);
    final timeStart = booking.selectedSlot != null
        ? booking.selectedSlot!.displayTime
        : DateFormat('hh:mm a').format(booking.manualTime);

    final totalDuration = services.fold<int>(
      0,
      (sum, item) => sum + item.duration,
    );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(scale),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 24 * scale,
                vertical: 30 * scale,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    staff?.name.toUpperCase() ?? "NO PREFERENCE",
                    style: GoogleFonts.poppins(
                      fontSize: 22 * scale,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 10 * scale),

                  // Services List
                  const Divider(color: Color(0xFFF0F0F0)),
                  ...services.map(
                    (service) => Padding(
                      padding: EdgeInsets.symmetric(vertical: 8 * scale),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              service.name,
                              style: GoogleFonts.poppins(
                                fontSize: 16 * scale,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Text(
                            "₹ ${service.price.toInt()}",
                            style: GoogleFonts.poppins(
                              fontSize: 16 * scale,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Divider(color: Color(0xFFF0F0F0)),
                  SizedBox(height: 10 * scale),
                  Text(
                    "${totalDuration ~/ 60} Hour ${totalDuration % 60 > 0 ? '${totalDuration % 60} Min' : ''} With ${staff?.name ?? 'No Preference'}",
                    style: GoogleFonts.poppins(
                      fontSize: 12 * scale,
                      color: const Color(0xFF8D8D8D),
                    ),
                  ),
                  SizedBox(height: 25 * scale),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 20,
                        color: Color(0xFF8D8D8D),
                      ),
                      SizedBox(width: 15 * scale),
                      Text(
                        dateFormatted,
                        style: GoogleFonts.poppins(
                          fontSize: 14 * scale,
                          color: const Color(0xFF8D8D8D),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12 * scale),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 20,
                        color: Color(0xFF8D8D8D),
                      ),
                      SizedBox(width: 15 * scale),
                      Text(
                        "$timeStart ($totalDuration Min Duration)",
                        style: GoogleFonts.poppins(
                          fontSize: 14 * scale,
                          color: const Color(0xFF8D8D8D),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 25 * scale),
                  const Divider(color: Color(0xFFF0F0F0)),
                  SizedBox(height: 10 * scale),

                  // Breakdown
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Subtotal",
                        style: GoogleFonts.poppins(
                          fontSize: 14 * scale,
                          color: const Color(0xFF8D8D8D),
                        ),
                      ),
                      Text(
                        "₹ ${subtotal.toInt()}",
                        style: GoogleFonts.poppins(
                          fontSize: 14 * scale,
                          color: const Color(0xFF8D8D8D),
                        ),
                      ),
                    ],
                  ),
                  if (booking.selectedPackage != null && packageSavings > 0) ...[
                    SizedBox(height: 8 * scale),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Package Discount (${booking.selectedPackage!.name})",
                          style: GoogleFonts.poppins(
                            fontSize: 14 * scale,
                            color: const Color(0xFFFF0B01),
                          ),
                        ),
                        Text(
                          "- ₹ ${packageSavings.toInt()}",
                          style: GoogleFonts.poppins(
                            fontSize: 14 * scale,
                            color: const Color(0xFFFF0B01),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (discountAmount > 0) ...[
                    SizedBox(height: 8 * scale),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Discount (${booking.appliedOffer?.name ?? 'Offer'})",
                          style: GoogleFonts.poppins(
                            fontSize: 14 * scale,
                            color: const Color(0xFFFF0B01),
                          ),
                        ),
                        Text(
                          "- ₹ ${discountAmount.toInt()}",
                          style: GoogleFonts.poppins(
                            fontSize: 14 * scale,
                            color: const Color(0xFFFF0B01),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (booking.isHomeService &&
                      booking.homeServiceCharge > 0) ...[
                    SizedBox(height: 8 * scale),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Home Service Charge",
                          style: GoogleFonts.poppins(
                            fontSize: 14 * scale,
                            color: const Color(0xFF8D8D8D),
                          ),
                        ),
                        Text(
                          "₹ ${booking.homeServiceCharge.toInt()}",
                          style: GoogleFonts.poppins(
                            fontSize: 14 * scale,
                            color: const Color(0xFF8D8D8D),
                          ),
                        ),
                      ],
                    ),
                  ],
                  SizedBox(height: 10 * scale),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Total",
                        style: GoogleFonts.poppins(
                          fontSize: 16 * scale,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        "₹ ${finalTotal.toInt()}",
                        style: GoogleFonts.poppins(
                          fontSize: 18 * scale,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 40 * scale),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Get Home Service",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (!homeServiceAvailable)
                            Text(
                              "Not available for this salon",
                              style: GoogleFonts.poppins(
                                fontSize: 11 * scale,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                      Switch(
                        value: booking.isHomeService
                            ? booking.isHomeService
                            : false,
                        onChanged: homeServiceAvailable
                            ? (val) => booking.toggleHomeService(val)
                            : null,
                        activeThumbColor: Colors.red,
                      ),
                    ],
                  ),
                  if (booking.isHomeService) ...[
                    SizedBox(height: 10 * scale),
                    TextField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        hintText: "Enter your full address",
                        hintStyle: GoogleFonts.poppins(fontSize: 14 * scale),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFF0F0F0),
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12 * scale,
                          vertical: 8 * scale,
                        ),
                      ),
                      maxLines: 2,
                    ),
                    SizedBox(height: 10 * scale),
                  ],

                  const Divider(color: Color(0xFFF0F0F0)),
                  SizedBox(height: 10 * scale),

                  // Bottom horizontal bar with button
                  SafeArea(
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  services.length > 1
                                      ? "${primaryService?.name ?? 'Service'} +${services.length - 1}"
                                      : primaryService?.name ?? "Service",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16 * scale,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  "Total: ₹ ${finalTotal.toInt()}",
                                  style: GoogleFonts.poppins(
                                    fontSize: 12 * scale,
                                    color: const Color(0xFF8D8D8D),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: _isConfirming ? null : _handleConfirm,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 25 * scale,
                                vertical: 12 * scale,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF0B01),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: _isConfirming
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      "Confirm",
                                      style: GoogleFonts.poppins(
                                        fontSize: 14 * scale,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 375 * scale,
          height: 225 * scale,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(bottomRight: Radius.circular(150)),
            image: DecorationImage(
              image: AssetImage(
                "assets/Images/ReviewTimeScreen/review_bg_img.jpeg",
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

        // Responsive Title (auto fit)
        Positioned(
          left: 24 * scale,
          bottom: 24 * scale,
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.65,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                "REVIEW AND CONFIRM",
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
        ),
        // Red Circle with Clock Icon (Ellipse 59x59)
        Positioned(
          left: 291 * scale,
          top: 166 * scale,
          child: Container(
            width: 59 * scale,
            height: 59 * scale,
            decoration: const BoxDecoration(
              color: Color(0xFFFF0B01),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SvgPicture.asset(
                "assets/Images/ReviewTimeScreen/review_floating_btn.svg",
                width: 24,
                height: 24,
                fit: BoxFit.contain,
              ),
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
      ],
    );
  }
}
