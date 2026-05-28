import 'package:flutter/material.dart';
import '../../core/utils/flushbar_helper.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:neo_parlour/modules/pages/qr_scanner_screen.dart';
import 'package:provider/provider.dart';
import 'package:neo_parlour/modules/pages/home_screen.dart';
import '../../provider/customer/auth_provider.dart';
import '../../provider/customer/service_provider.dart';
import '../../provider/customer/staff_provider.dart';
import '../../provider/customer/offer_provider.dart';
import '../../provider/customer/package_provider.dart';
import '../../provider/customer/product_provider.dart';
import '../../provider/customer/booking_provider.dart';
class SalonIDScreen extends StatefulWidget {
  const SalonIDScreen({super.key});

  @override
  State<SalonIDScreen> createState() => _SalonIDScreenState();
}

class _SalonIDScreenState extends State<SalonIDScreen> {
  final TextEditingController salonIdController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    salonIdController.dispose();
    super.dispose();
  }

  // QR Scan Logic
  Future<void> _handleScan() async {
    // Ensure you handle the result from your QRScannerPage
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerScreen()),
    );
    if (result != null && mounted) {
      setState(() => salonIdController.text = result);
      _submit(); // Auto-submit after scanning
    }
  }

  // Gallery Upload Logic
  Future<void> _handleGalleryUpload() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null && mounted) {
      final MobileScannerController scannerController = MobileScannerController();
      try {
        final BarcodeCapture? capture = await scannerController.analyzeImage(image.path);
        if (capture != null && capture.barcodes.isNotEmpty) {
          final String? scannedValue = capture.barcodes.first.rawValue;
          if (scannedValue != null) {
            setState(() {
              salonIdController.text = scannedValue;
            });
            _submit(); // Auto-submit after decoding
          }
        } else {
          if (mounted) {            FlushbarHelper.show(context, "No QR code found in the selected image.");

          }
        }
      } catch (e) {
        if (mounted) {          FlushbarHelper.show(context, "Failed to analyze image: $e");

        }
      } finally {
        scannerController.dispose();
      }
    }
  }

  void _submit() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isLoading) return;

    final salonId = salonIdController.text.trim();
    if (salonId.isEmpty) {
      if (mounted) {        FlushbarHelper.show(context, "Please enter Salon ID");

      }
      return;
    }
    final success = await authProvider.switchTenant(salonId);

    if (success && mounted) {
      // Clear all providers data so that old salon's data is not shown
      context.read<ServiceProvider>().clearData();
      context.read<StaffProvider>().clearData();
      context.read<OfferProvider>().clearData();
      context.read<PackageProvider>().clearData();
      context.read<ProductProvider>().clearData();
      context.read<BookingProvider>().resetBookingState();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else if (mounted) {      FlushbarHelper.show(context, authProvider.errorMessage ?? "Switch failed");

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
                              "SALON ID",
                              style: GoogleFonts.poppins(
                                fontSize: sw * 0.038,
                                fontWeight: FontWeight.w500,
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
                            // ================= SALON ID INPUT =================
                            Container(
                              height: sh * 0.06,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(
                                  color: const Color(0XFF909090),
                                ),
                              ),
                              child: TextField(
                                controller: salonIdController,
                                decoration: InputDecoration(
                                  prefixIcon: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: SvgPicture.asset(
                                      "assets/Images/SalonIDScreen/user_name.svg",
                                      colorFilter: const ColorFilter.mode(
                                        Color(0XFF8B8989),
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                  ),
                                  hintText: "Salon ID",
                                  hintStyle: GoogleFonts.poppins(
                                    fontSize: sw * 0.03,
                                    color: const Color(0XFF8D8D8D),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ),
  
                            SizedBox(height: sh * 0.02),
  
                            // ================= SCAN / UPLOAD =================
                            Row(
                              children: [
                                _actionButton(
                                  image: "assets/Images/SalonIDScreen/scan.svg",
                                  label: "Scan QR",
                                  sw: sw,
                                  sh: sh,
                                  onTap: _handleScan,
                                ),
                                SizedBox(width: sw * 0.04),
                                _actionButton(
                                  image: "assets/Images/SalonIDScreen/upload.svg",
                                  label: "Upload",
                                  sw: sw,
                                  sh: sh,
                                  onTap: _handleGalleryUpload,
                                ),
                              ],
                            ),
  
                            SizedBox(height: sh * 0.025),
  
                            // ================= SUBMIT BUTTON =================
                            Consumer<AuthProvider>(
                              builder: (context, auth, _) {
                                return SizedBox(
                                  width: double.infinity,
                                  height: sh * 0.062,
                                  child: ElevatedButton(
                                    onPressed: auth.isLoading ? null : _submit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0XFFFF0B01),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: auth.isLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(
                                            "SUBMIT",
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 2,
                                              fontSize: sw * 0.03,
                                              color: Colors.white,
                                            ),
                                          ),
                                  ),
                                );
                              },
                            ),
  
                            SizedBox(height: sh * 0.02),
  

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

  // ================= ACTION BUTTON =================
  Widget _actionButton({
    required String image,
    required String label,
    required double sw,
    required double sh,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: sh * 0.055,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0XFFBDBDBD)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(image, height: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: sw * 0.028,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= SOCIAL ICON HELPER =================
  // Widget _socialIcon(String path, {Color? backgroundColor}) {
  //   return Container(
  //     height: 44,
  //     width: 44,
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