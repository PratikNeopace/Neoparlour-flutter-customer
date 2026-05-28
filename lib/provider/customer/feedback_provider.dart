import 'package:flutter/material.dart';
import '../../core/data/services/feedback_service.dart';
import '../../core/utils/error_handler.dart';

class FeedbackProvider extends ChangeNotifier {
  final FeedbackService _feedbackService = FeedbackService();
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> submitFeedback({
    required int appointmentId,
    required int customerId,
    required int staffId,
    required String comment,
    required int rating,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = {
        "appointmentId": appointmentId,
        "customerId": customerId,
        "staffId": staffId,
        "comment": comment,
        "rating": rating,
        "createdAt": DateTime.now().toUtc().toIso8601String(),
        "approved": false,
      };

      await _feedbackService.submitFeedback(data);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
