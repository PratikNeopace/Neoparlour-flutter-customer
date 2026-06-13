import 'package:flutter/foundation.dart';
import '../api_client.dart';
import '../../domain/models/neo_service.dart';

class ServiceDataService {
  final ApiClient _apiClient = ApiClient();

  Future<List<NeoService>> getServices() async {
    try {
      final response = await _apiClient.dio.get('services/active');
      if (response.data is List) {
        return (response.data as List)
            .where((json) => json['active'] == true)
            .map((json) => NeoService.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching services: $e");
      rethrow;
    }
  }
}
