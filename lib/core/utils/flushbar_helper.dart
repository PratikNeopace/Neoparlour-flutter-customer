import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar.dart';

class FlushbarHelper {
  /// Backward compatibility for existing codebase
  static Future<dynamic>? show(
    BuildContext context,
    String message, {
    bool isSuccess = false,
  }) {
    if (isSuccess) {
      return success(context, message);
    } else {
      return error(context, message);
    }
  }

  /// Displays a success notification
  static Future<dynamic>? success(BuildContext context, String message) {
    return _showBase(
      context: context,
      message: message,
      backgroundColor: Colors.green.shade700,
      iconData: Icons.check_circle,
    );
  }

  /// Displays an error notification
  static Future<dynamic>? error(BuildContext context, String message) {
    return _showBase(
      context: context,
      message: message,
      backgroundColor: Colors.red.shade700,
      iconData: Icons.error,
    );
  }

  /// Displays an info/neutral notification
  static Future<dynamic>? info(BuildContext context, String message) {
    return _showBase(
      context: context,
      message: message,
      backgroundColor: Colors.blue.shade700,
      iconData: Icons.info,
    );
  }

  static Flushbar? _currentFlushbar;

  /// Core rendering logic for the standardized Flushbar
  static Future<dynamic>? _showBase({
    required BuildContext context,
    required String message,
    required Color backgroundColor,
    required IconData iconData,
  }) {
    if (!context.mounted) return null;

    // Prevent notification stacking
    _currentFlushbar?.dismiss();

    final flush = Flushbar(
      messageText: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 1.4, // Improves readability for multi-line text
        ),
        softWrap: true,
      ),
      icon: Icon(
        iconData,
        color: Colors.white,
        size: 24,
      ),
      shouldIconPulse: false, // Cleaner, more premium feel
      flushbarPosition: FlushbarPosition.TOP,
      backgroundColor: backgroundColor,
      margin: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + kToolbarHeight * 0.8,
        left: 16,
        right: 16,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      maxWidth: 600, // Constrains width beautifully on tablets/web
      borderRadius: BorderRadius.circular(12),
      duration: const Duration(seconds: 3),
      forwardAnimationCurve: Curves.easeOutCubic,
      reverseAnimationCurve: Curves.easeInCubic,
      boxShadows: const [
        BoxShadow(
          color: Colors.black12,
          offset: Offset(0, 4),
          blurRadius: 10,
        ),
      ],
    );

    _currentFlushbar = flush;
    return flush.show(context);
  }
}
