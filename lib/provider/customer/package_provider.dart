import 'package:flutter/material.dart';
import '../../core/utils/error_handler.dart';
import '../../core/data/services/package_service.dart';
import '../../core/domain/models/package_model.dart';

class PackageProvider extends ChangeNotifier {
  final PackageService _packageService = PackageService();

  List<PackageModel> _packages = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<PackageModel> get packages => _packages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void clearData() {
    _packages = [];
    notifyListeners();
  }

  Future<void> fetchPackages() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _packages = await _packageService.getPackages();
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
