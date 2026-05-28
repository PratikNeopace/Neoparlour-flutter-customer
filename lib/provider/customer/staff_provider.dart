import 'package:flutter/material.dart';
import '../../core/utils/error_handler.dart';
import '../../core/data/services/staff_data_service.dart';
import '../../core/domain/models/staff.dart';

class StaffProvider extends ChangeNotifier {
  final StaffDataService _staffDataService = StaffDataService();

  List<Staff> _staffList = [];
  List<Staff> _availableStaffList = [];
  Staff? _selectedStaff;
  bool _isLoading = false;
  String? _error;

  bool _hasUserSelected = false;
  bool get hasUserSelected => _hasUserSelected;

  List<Staff> get staffList => _staffList;
  List<Staff> get availableStaffList => _availableStaffList;
  Staff? get selectedStaff => _selectedStaff;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void selectStaff(Staff? staff) {
    _selectedStaff = staff;
    _hasUserSelected = true;
    notifyListeners();
  }

  Future<void> fetchStaff() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _staffList = await _staffDataService.searchStaff();
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  final Map<String, List<Staff>> _staffCache = {};

  Future<void> fetchAvailableStaff(String selectedTime, int durationMinutes, {bool forceRefresh = false}) async {
    final cacheKey = '${selectedTime}_$durationMinutes';
    if (!forceRefresh && _staffCache.containsKey(cacheKey)) {
      _availableStaffList = _staffCache[cacheKey]!;
      _selectedStaff = null;
      _hasUserSelected = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    _selectedStaff = null;
    _hasUserSelected = false;
    notifyListeners();

    try {
      _availableStaffList = await _staffDataService.getAvailableStaff(selectedTime, durationMinutes);
      _staffCache[cacheKey] = _availableStaffList;
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllStaff() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _staffList = await _staffDataService.getAllStaff();
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void resetStaffState() {
    _availableStaffList = [];
    _selectedStaff = null;
    _hasUserSelected = false;
    _error = null;
    _staffCache.clear(); // force fresh fetch on next booking
    notifyListeners();
  }

  void clearData() {
    _staffList = [];
    _availableStaffList = [];
    _selectedStaff = null;
    _hasUserSelected = false;
    _error = null;
    _staffCache.clear();
    notifyListeners();
  }
}
