import 'package:flutter/material.dart';
import '../../core/utils/error_handler.dart';
import '../../core/domain/models/offer.dart';
import '../../core/data/services/offer_data_service.dart';

class OfferProvider extends ChangeNotifier {
  final OfferDataService _offerDataService = OfferDataService();
  
  List<Offer> _offers = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Offer> get offers => _offers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void clearData() {
    _offers = [];
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> fetchActiveOffers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _offers = await _offerDataService.fetchActiveOffers();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = "Failed to load offers: ${ErrorHandler.getErrorMessage(e)}";
      _isLoading = false;
      notifyListeners();
    }
  }
}
