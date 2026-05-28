import 'package:flutter/material.dart';
import '../../core/utils/error_handler.dart';
import '../../core/data/services/service_data_service.dart';
import '../../core/domain/models/neo_service.dart';

class ServiceProvider extends ChangeNotifier {
  final ServiceDataService _serviceDataService = ServiceDataService();
  
  List<NeoService> _services = [];
  final Set<int> _selectedServiceIds = {};
  bool _isLoading = false;
  String? _error;

  List<NeoService> get services => _services;
  Set<int> get selectedServiceIds => _selectedServiceIds;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<NeoService> get selectedServices => 
      _services.where((s) => _selectedServiceIds.contains(s.id)).toList();

  void toggleServiceSelection(int id) {
    if (_selectedServiceIds.contains(id)) {
      _selectedServiceIds.remove(id);
    } else {
      _selectedServiceIds.add(id);
    }
    notifyListeners();
  }

  bool isServiceSelected(int id) => _selectedServiceIds.contains(id);

  void clearSelections() {
    _selectedServiceIds.clear();
    notifyListeners();
  }

  void preselectServices(List<int> ids) {
    _selectedServiceIds.clear();
    _selectedServiceIds.addAll(ids);
    notifyListeners();
  }

  void clearData() {
    _services = [];
    _selectedServiceIds.clear();
    _error = null;
    notifyListeners();
  }

  Future<void> fetchServices() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _services = await _serviceDataService.getServices();
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
