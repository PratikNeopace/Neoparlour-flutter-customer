import '../api_client.dart';
import '../../domain/models/offer.dart';

class OfferDataService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Offer>> fetchActiveOffers() async {
    try {
      final response = await _apiClient.dio.get('offers/active');
      
      if (response.data is List) {
        return (response.data as List)
            .where((json) => json['active'] == true)
            .map((json) => Offer.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print("Error fetching active offers: $e");
      rethrow;
    }
  }
}
