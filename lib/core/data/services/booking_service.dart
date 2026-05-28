import '../api_client.dart';
import '../../domain/models/available_slot.dart';

class BookingService {
  final ApiClient _apiClient = ApiClient();

  Future<List<AvailableSlot>> getAvailableSlots(int staffId, DateTime date, int durationMinutes) async {
    try {
      final String dateStr = date.toIso8601String().split('T')[0] + 'T00:00:00Z';
      final response = await _apiClient.dio.get(
        'appointments/staff/$staffId/available-slots',
        queryParameters: {
          'selectedDate': dateStr,
          'durationMinutes': durationMinutes,
        },
      );

      if (response.data is List) {
        return (response.data as List)
            .map((json) => AvailableSlot.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print("Error fetching slots: $e");
      rethrow;
    }
  }

  Future<List<AvailableSlot>> getSalonSlots(DateTime date) async {
    try {
      final String dateStr = date.toIso8601String().split('T')[0] + 'T00:00:00Z';
      final response = await _apiClient.dio.get(
        'appointments/salon-slots?selectedDate=$dateStr',
      );

      if (response.data is List) {
        return (response.data as List)
            .map((json) => AvailableSlot.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print("Error fetching salon slots: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> bookAppointment(Map<String, dynamic> requestData) async {
    try {
      final response = await _apiClient.dio.post(
        'appointments/book',
        data: requestData,
      );
      return response.data;
    } catch (e) {
      print("Error booking appointment: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getUserAppointments(String mobile, {int page = 0, int size = 10, String? status}) async {
    try {
      final queryParams = {
        'page': page,
        'size': size,
        'mobile': mobile,
        'sort': 'appointmentAt,desc',
      };
      if (status != null) {
        queryParams['status'] = status;
      }
      final response = await _apiClient.dio.get(
        'appointments/search/advanced',
        queryParameters: queryParams,
      );
      return response.data ?? {};
    } catch (e) {
      print("Error fetching user appointments: $e");
      rethrow;
    }
  }

  Future<dynamic> rescheduleAppointment(
    int id,
    DateTime newTime,
    String? reason,
  ) async {
    try {
      final response = await _apiClient.dio.put(
        'appointments/$id/reschedule',
        queryParameters: {
          'newTime': newTime.toUtc().toIso8601String().replaceAll('Z', '+00:00'),
        },
        data: reason,
      );
      return response.data;
    } catch (e) {
      print('Reschedule Error: $e');
      rethrow;
    }
  }

  Future<dynamic> cancelAppointment(int id, String reason) async {
    try {
      final response = await _apiClient.dio.put(
        'appointments/$id/cancel',
        data: reason,
      );
      return response.data;
    } catch (e) {
      print('Cancel Error: $e');
      rethrow;
    }
  }

  Future<double> getHomeServiceCharges(int salonId) async {
    try {
      final response = await _apiClient.dio.get('salons/$salonId/home-service-charges');
      if (response.data != null) {
        return double.tryParse(response.data.toString()) ?? 0.0;
      }
      return 0.0;
    } catch (e) {
      print("Error fetching home service charges: $e");
      return 0.0;
    }
  }

  Future<String?> getWeeklyOff() async {
    try {
      final response = await _apiClient.dio.get('salons/weekly-off');
      return response.data?.toString().toUpperCase();
    } catch (e) {
      print("Error fetching weekly off: $e");
      return null;
    }
  }
}
