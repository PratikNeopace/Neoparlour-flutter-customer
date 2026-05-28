import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen>
    with WidgetsBindingObserver {

  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  bool _isScanning = true;

  /// Add lifecycle observer
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  /// Handle app lifecycle 
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!controller.value.isInitialized) return;

    if (state == AppLifecycleState.resumed) {
      controller.start();
      _isScanning = true;
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      controller.stop();
    }
  }

  /// Dispose camera properly
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scanAreaSize = MediaQuery.of(context).size.width * 0.7;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [

          ///  CAMERA VIEW
          MobileScanner(
            controller: controller,
            fit: BoxFit.cover,
            onDetect: (BarcodeCapture capture) async {
              if (!_isScanning) return;

              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String? scannedValue = barcodes.first.rawValue;

                if (scannedValue != null) {
                  _isScanning = false;
                  await controller.stop();

                  if (mounted) {
                    Navigator.pop(context, scannedValue);
                  }
                }
              }
            },
          ),

          /// 🟢 SCANNER OVERLAY
          ScannerOverlay(scanAreaSize: scanAreaSize),
        ],
      ),
    );
  }
}

/// 🔳 Overlay with cutout + corner borders
class ScannerOverlay extends StatelessWidget {
  final double scanAreaSize;

  const ScannerOverlay({super.key, required this.scanAreaSize});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        /// Dark overlay with center cutout
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.6),
            BlendMode.srcOut,
          ),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  backgroundBlendMode: BlendMode.dstOut,
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Container(
                  height: scanAreaSize,
                  width: scanAreaSize,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),

        /// White scanner corners
        Align(
          alignment: Alignment.center,
          child: SizedBox(
            height: scanAreaSize,
            width: scanAreaSize,
            child: Stack(
              children: [
                _corner(top: 0, left: 0),
                _corner(top: 0, right: 0),
                _corner(bottom: 0, left: 0),
                _corner(bottom: 0, right: 0),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _corner({double? top, double? left, double? right, double? bottom}) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border(
            top: top != null ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
            left: left != null ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
            right: right != null ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
            bottom: bottom != null ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
          ),
        ),
      ),
    );
  }
}