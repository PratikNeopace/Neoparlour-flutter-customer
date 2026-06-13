import 'package:flutter/foundation.dart';
import '../api_client.dart';
import '../../domain/models/package_model.dart';

class PackageService {
  final ApiClient _apiClient = ApiClient();

  Future<List<PackageModel>> getPackages() async {
    try {
      final response = await _apiClient.dio.get('packages/search');
      final List<dynamic> content = response.data['content'];
      return content
          .where((json) => json['active'] == true)
          .map((json) => PackageModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint("Error fetching packages: $e");
      rethrow;
    }
  }
}
