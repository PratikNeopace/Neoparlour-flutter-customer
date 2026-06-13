import 'package:flutter/foundation.dart';
import '../api_client.dart';
import '../../domain/models/staff.dart';

class StaffDataService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Staff>> searchStaff({
    String? name,
    String? phone,
    String? email,
    String? status,
    int page = 0,
    int size = 10,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        'staff/search',
        queryParameters: {
          ?name: name,
          ?phone: phone,
          ?email: email,
          ?status: status,
          'page': page,
          'size': size,
          'sortBy': 'id',
          'direction': 'asc',
        },
      );

      if (response.data != null && response.data['content'] is List) {
        return (response.data['content'] as List)
            .where((json) => json['active'] == true)
            .map((json) => Staff.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching staff: $e");
      rethrow;
    }
  }

  Future<List<Staff>> getAvailableStaff(String selectedTime, int durationMinutes) async {
    try {
      final response = await _apiClient.dio.get(
        'appointments/available-staff',
        queryParameters: {
          'selectedTime': selectedTime,
          'durationMinutes': durationMinutes,
        },
      );

      if (response.data is List) {
        return (response.data as List)
            .map((json) => Staff.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching available staff: $e");
      rethrow;
    }
  }

  Future<List<Staff>> getAllStaff() async {
    try {
      final response = await _apiClient.dio.get('staff');

      if (response.data is List) {
        return (response.data as List)
            .where((json) => json['active'] == true)
            .map((json) => Staff.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching all staff: $e");
      rethrow;
    }
  }
}
