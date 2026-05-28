import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../provider/customer/booking_provider.dart';
import '../../widgets/custom_nav_bar.dart';
import 'review_confirm_screen.dart';
import 'home_screen.dart';

class ManualDateTimeScreen extends StatefulWidget {
  const ManualDateTimeScreen({super.key});

  @override
  State<ManualDateTimeScreen> createState() => _ManualDateTimeScreenState();
}

class _ManualDateTimeScreenState extends State<ManualDateTimeScreen> {
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    // Default manual time to now + 1 hour as a sensible starting point
    final now = DateTime.now().add(const Duration(hours: 1));
    _selectedTime = TimeOfDay.fromDateTime(now);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateManualDateTime();
    });
  }

  void _updateManualDateTime() {
    final booking = context.read<BookingProvider>();
    final date = booking.selectedDate;
    final dt = DateTime(date.year, date.month, date.day, _selectedTime.hour, _selectedTime.minute);
    booking.setManualTime(dt);
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: const Color(0xFFFF0B01),
            colorScheme: const ColorScheme.light(primary: Color(0xFFFF0B01)),
            buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
      _updateManualDateTime();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final sw = mq.size.width;
    final scale = sw / 375.0;
    final bookingProvider = context.watch<BookingProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(scale),
            _buildDateSelection(scale),
            
            Padding(
              padding: EdgeInsets.fromLTRB(24 * scale, 40 * scale, 24 * scale, 20 * scale),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    children: [
                      const Icon(Icons.access_time, size: 24),
                      SizedBox(width: 8 * scale),
                      Text(
                        "SELECT TIME",
                        style: GoogleFonts.poppins(
                          fontSize: 16 * scale,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (bookingProvider.isHoliday && bookingProvider.error != null)
                    Padding(
                      padding: EdgeInsets.only(top: 20 * scale),
                      child: Text(
                        bookingProvider.error!,
                        style: GoogleFonts.poppins(
                          fontSize: 14 * scale,
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  else ...[
                    SizedBox(height: 20 * scale),
                    GestureDetector(
                      onTap: () => _selectTime(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.grey[50],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedTime.format(context),
                              style: GoogleFonts.poppins(
                                fontSize: 18 * scale,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFFF0B01),
                              ),
                            ),
                            const Icon(Icons.edit, color: Color(0xFFFF0B01)),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 10 * scale),
                    Text(
                      "Please select a convenient time for your appointment.",
                      style: GoogleFonts.poppins(
                        fontSize: 12 * scale,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // NEXT Button
            Padding(
              padding: EdgeInsets.fromLTRB(26 * scale, 30 * scale, 25 * scale, 40 * scale),
              child: GestureDetector(
                onTap: bookingProvider.isHoliday ? null : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ReviewConfirmScreen()),
                  );
                },
                child: Container(
                  height: 49 * scale,
                  width: 324 * scale,
                  decoration: BoxDecoration(
                    color: bookingProvider.isHoliday ? Colors.grey : const Color(0xFFFF0B01),
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
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(selectedLabel: "SERVICES"),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        ),
        backgroundColor: const Color(0xFFFF0B01),
        elevation: 5,
        shape: const CircleBorder(),
        child: SvgPicture.asset("assets/Images/BottomNavigationBar/home_icon.svg"),
      ),
    );
  }

  Widget _buildDateSelection(double scale) {
    return Consumer<BookingProvider>(
      builder: (context, provider, child) {
        final now = DateTime.now();
        final days = List.generate(30, (index) => now.add(Duration(days: index)));

        return Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(24 * scale, 30 * scale, 24 * scale, 15 * scale),
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
                  Text(
                    DateFormat('MMMM yyyy').format(provider.selectedDate),
                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
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
                  final isSelected = DateUtils.isSameDay(date, provider.selectedDate);
                  
                  return GestureDetector(
                    onTap: () {
                      // Just update the date state, manually update combined DT
                      provider.selectDate(date);
                      _updateManualDateTime();
                    },
                    child: Container(
                      width: 50 * scale,
                      margin: EdgeInsets.symmetric(vertical: 6 * scale, horizontal: 4 * scale),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFFF0B01) : Colors.transparent,
                        borderRadius: BorderRadius.circular(16.5 * scale),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('E').format(date).toLowerCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 10 * scale,
                              fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                              color: isSelected ? Colors.white : const Color(0xFF8D8D8D),
                            ),
                          ),
                          SizedBox(height: 4 * scale),
                          Container(
                            width: 25 * scale,
                            height: 25 * scale,
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : Colors.transparent,
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
                    Colors.black.withOpacity(0.15),
                    Colors.transparent,
                    const Color(0xFFFF3502).withOpacity(0.35),
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
                    color: Colors.white.withOpacity(0.35),
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
                  "assets/Images/SelectDateTime/date_floating_btn.svg",
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
}
