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
          if (name != null) 'name': name,
          if (phone != null) 'phone': phone,
          if (email != null) 'email': email,
          if (status != null) 'status': status,
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
      print("Error fetching staff: $e");
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
      print("Error fetching available staff: $e");
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
      print("Error fetching all staff: $e");
      rethrow;
    }
  }
}
