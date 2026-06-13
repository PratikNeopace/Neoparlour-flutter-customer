import 'package:flutter/foundation.dart';
import '../api_client.dart';

class FeedbackService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> submitFeedback(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post(
        'feedback',
        data: data,
      );
      return response.data;
    } catch (e) {
      debugPrint("Error submitting feedback: $e");
      rethrow;
    }
  }
}
