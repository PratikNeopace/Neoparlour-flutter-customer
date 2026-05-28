import 'package:flutter/material.dart';
import '../../core/utils/flushbar_helper.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../provider/customer/booking_provider.dart';
import '../../provider/customer/auth_provider.dart';
import '../../core/domain/models/appointment.dart';
import '../../core/utils/error_handler.dart';
import '../../widgets/custom_nav_bar.dart';
import 'home_screen.dart';
import 'feedback_screen.dart';

class MyBookingScreen extends StatefulWidget {
  const MyBookingScreen({super.key});

  @override
  State<MyBookingScreen> createState() => _MyBookingScreenState();
}

class _MyBookingScreenState extends State<MyBookingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.userPhone != null) {
        context.read<BookingProvider>().fetchUserAppointments(
          authProvider.userPhone!, 
          refresh: true,
          status: "booked",
        );
      }
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.userPhone != null) {
        final status = _getStatusFromIndex(_tabController.index);
        context.read<BookingProvider>().fetchUserAppointments(
          authProvider.userPhone!, 
          status: status,
        );
      }
    }
  }

  String? _getStatusFromIndex(int index) {
    switch (index) {
      case 0:
        return "booked";
      case 1:
        return "cancelled";
      case 2:
        return "completed";
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: const Color(0xFFF8F8F8),
        extendBody: true,
        body: Column(
          children: [
            _buildHeader(context),
            TabBar(
              controller: _tabController,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0XFFFF0B01),
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(text: "UPCOMING"),
                Tab(text: "CANCELLED"),
                Tab(text: "COMPLETED"),
              ],
            ),
            Expanded(
              child: Consumer<BookingProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoadingAppointments) {
                    return const Center(child: CircularProgressIndicator(color: Color(0XFFFF0B01)));
                  }
                  
                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildList(provider.upcomingAppointments, "No upcoming bookings", provider),
                      _buildList(provider.cancelledAppointments, "No cancelled bookings", provider),
                      _buildList(provider.completedAppointments, "No completed bookings", provider),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: const CustomBottomNavBar(selectedLabel: "SERVICES"),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: FloatingActionButton(
          onPressed: () {
             Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
            );
          },
          backgroundColor: const Color(0XFFFF0B01),
          elevation: 4,
          shape: const CircleBorder(),
          child: SvgPicture.asset(
            "assets/Images/BottomNavigationBar/home_icon.svg",
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }

  Widget _buildList(List<Appointment> appointments, String emptyMsg, BookingProvider provider) {
    if (appointments.isEmpty && !provider.isLoadingAppointments) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emptyMsg,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 20),
            _buildPagination(provider),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 180),
      itemCount: appointments.length + 1,
      itemBuilder: (itemContext, index) {
        if (index == appointments.length) {
          return _buildPagination(provider);
        }
        return BookingCard(
          appointment: appointments[index],
          parentContext: context,
        );
      },
    );
  }

 Widget _buildPagination(BookingProvider provider) {
  if (provider.totalPages <= 1) return const SizedBox.shrink();

  final authProvider = context.read<AuthProvider>();

  void loadPage(int page) {
    if (authProvider.userPhone != null) {
      provider.fetchUserAppointments(
        authProvider.userPhone!,
        page: page,
        status: provider.currentStatus,
      );
    }
  }

  return Container(
    height: 60,
    alignment: Alignment.center,
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min, // ⭐ keeps row centered
        children: [

          /// ⬅️ PREVIOUS BUTTON
          _navButton(
            icon: Icons.arrow_back_ios_new_rounded,
            enabled: provider.currentPage > 0,
            onTap: () => loadPage(provider.currentPage - 1),
          ),

          const SizedBox(width: 6),

          /// PAGE NUMBERS
          ...List.generate(provider.totalPages, (index) {
            final isSelected = index == provider.currentPage;

            return GestureDetector(
              onTap: () => loadPage(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 5),
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0XFFFF0B01) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0XFFFF0B01)
                        : Colors.grey.shade300,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0XFFFF0B01).withOpacity(0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    "${index + 1}",
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }),

          const SizedBox(width: 6),

          /// NEXT BUTTON ➡️
          _navButton(
            icon: Icons.arrow_forward_ios_rounded,
            enabled: provider.currentPage < provider.totalPages - 1,
            onTap: () => loadPage(provider.currentPage + 1),
          ),
        ],
      ),
    ),
  );
}
Widget _navButton({
  required IconData icon,
  required bool enabled,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: enabled ? onTap : null,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: enabled ? Colors.white : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: enabled ? Colors.grey.shade300 : Colors.grey.shade200,
        ),
      ),
      child: Icon(
        icon,
        size: 16,
        color: enabled ? Colors.black87 : Colors.grey,
      ),
    ),
  );
}

  Widget _buildHeader(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipPath(
          clipper: HeaderCurveClipper(),
          child: Container(
            height: 225,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                  'assets/Images/MyBookingScreen/booking_bg_img.jpeg',
                ),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                    const Color(0XFFFF3502).withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ),
        ),
        const Positioned(
          bottom: 20,
          left: 23,
          child: Text(
            "MY BOOKINGS",
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Positioned(
          top: 50,
          left: 20,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.4),
              child: const Icon(Icons.chevron_left, color: Colors.black),
            ),
          ),
        ),
         // Floating Cart Icon on the curve
        Positioned(
          bottom: -5,
          right: 30,
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child:SvgPicture.asset("assets/Images/MyBookingScreen/booking_floating_btn.svg")
          ),
        ),
        
      ],
    );
  }
}

class BookingCard extends StatelessWidget {
  final Appointment appointment;
  final BuildContext parentContext;
  const BookingCard({
    super.key,
    required this.appointment,
    required this.parentContext,
  });

  @override
  Widget build(BuildContext context) {
    final status = appointment.status.toLowerCase();
    final bool isUpcoming = status == 'booked' || status == 'rescheduled';
    final dateStr = DateFormat('dd MMM yyyy').format(appointment.appointmentAt);
    final timeStr = DateFormat('hh:mm a').format(appointment.appointmentAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 25,
                backgroundColor: Color(0xFFF0F0F0),
                child: Icon(Icons.person, color: Colors.grey),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.staffName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      appointment.serviceNames.join(", "),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildIconText(Icons.calendar_today, dateStr),
                  _buildIconText(Icons.access_time, timeStr),
                  Text(
                    "₹${appointment.finalAmount.toInt()}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
          if (isUpcoming) ...[
            const SizedBox(height: 20),
            Visibility(
              visible: !isPastAppointment(appointment.appointmentAt.toIso8601String()),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0XFFFF0B01),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _handleReschedule(context),
                      child: const Text("RESCHEDULE", style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[600],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _handleCancel(context),
                      child: const Text("CANCEL", style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (status == 'completed') ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FeedbackScreen(appointment: appointment),
                    ),
                  );
                },
                child: const Text("GIVE FEEDBACK", style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIconText(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: Colors.grey),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  void _handleReschedule(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: appointment.appointmentAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );

    if (pickedDate != null && context.mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(appointment.appointmentAt),
      );

      if (pickedTime != null && context.mounted) {
        final newDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        // Now ask for reason
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
                  
                  Navigator.pop(dialogContext);
                  final provider = parentContext.read<BookingProvider>();
                  final auth = parentContext.read<AuthProvider>();
                  
                  try {
                    await provider.rescheduleAppointment(
                      appointment.id,
                      newDateTime,
                      reason,
                      auth.userPhone!,
                    );
                    if (parentContext.mounted) {
                      FlushbarHelper.show(parentContext, "Appointment rescheduled successfully", isSuccess: true);
                    }
                  } catch (e) {
                    final msg = ErrorHandler.getErrorMessage(e);
                    if (parentContext.mounted) {
                      FlushbarHelper.show(parentContext, msg);
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
  }

  void _handleCancel(BuildContext context) {
    final TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Cancel Appointment"),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(hintText: "Reason for cancellation"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("BACK")),
          TextButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) return;
              
              Navigator.pop(dialogContext);
              final provider = parentContext.read<BookingProvider>();
              final auth = parentContext.read<AuthProvider>();
              
              try {
                await provider.cancelAppointment(
                  appointment.id,
                  reason,
                  auth.userPhone!,
                );
                if (parentContext.mounted) {
                  FlushbarHelper.show(parentContext, "Appointment cancelled successfully", isSuccess: true);
                }
              } catch (e) {
                final msg = ErrorHandler.getErrorMessage(e);
                if (parentContext.mounted) {
                  FlushbarHelper.show(parentContext, msg);
                }
              }
            },
            child: const Text("CONFIRM", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class HeaderCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height);
    path.lineTo(size.width * 0.55, size.height);
    path.quadraticBezierTo(
      size.width,
      size.height,
      size.width,
      size.height * 0.35,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

bool isPastAppointment(String? appointmentAt) {
  try {
    if (appointmentAt == null) return true;
    final appointmentDate = DateTime.parse(appointmentAt).toLocal();
    final now = DateTime.now();
    return appointmentDate.isBefore(now);
  } catch (e) {
    return true; // fail-safe → hide buttons
  }
}