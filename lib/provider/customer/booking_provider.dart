import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/data/services/booking_service.dart';
import '../../core/domain/models/available_slot.dart';
import '../../core/domain/models/staff.dart';
import '../../core/domain/models/neo_service.dart';
import '../../core/domain/models/appointment.dart';
import '../../core/domain/models/offer.dart';
import '../../core/utils/error_handler.dart';
import '../../core/domain/models/package_model.dart';

class BookingProvider extends ChangeNotifier {
  final BookingService _bookingService = BookingService();

  DateTime _selectedDate = DateTime.now();
  AvailableSlot? _selectedSlot;
  List<AvailableSlot> _availableSlots = [];
  bool _isLoadingSlots = false;
  String? _error;
  int? _preSelectedStaffId; // Set when staff is pre-selected from home/expert screen
  int? _preSelectedStaffDuration; // Duration used for staff slot query
  Map<String, dynamic>? _lastBookingResponse;
  
  List<Appointment> _userAppointments = [];
  bool _isLoadingAppointments = false;
  
  int _currentPage = 0;
  int _totalPages = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  String? _currentStatus;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  String? get currentStatus => _currentStatus;

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  Offer? _appliedOffer;

  // Home Service state
  bool _isHomeService = false;
  double _homeServiceCharge = 0.0;
  String? _homeAddress;
  double? _latitude;
  double? _longitude;

  bool get isHomeService => _isHomeService;
  double get homeServiceCharge => _homeServiceCharge;
  String? get homeAddress => _homeAddress;
  double? get latitude => _latitude;
  double? get longitude => _longitude;

  DateTime get selectedDate => _selectedDate;
  AvailableSlot? get selectedSlot => _selectedSlot;
  List<AvailableSlot> get availableSlots => _availableSlots;
  bool get isLoadingSlots => _isLoadingSlots;
  String? get error => _error;
  Map<String, dynamic>? get lastBookingResponse => _lastBookingResponse;
  List<Appointment> get userAppointments => _userAppointments;
  bool get isLoadingAppointments => _isLoadingAppointments;
  Offer? get appliedOffer => _appliedOffer;
  int? get preSelectedStaffId => _preSelectedStaffId;

  PackageModel? _selectedPackage;
  PackageModel? get selectedPackage => _selectedPackage;

  void setSelectedPackage(PackageModel? pkg) {
    _selectedPackage = pkg;
    notifyListeners();
  }

  String? _weeklyOff;
  String? get weeklyOff => _weeklyOff;
  bool _isHoliday = false;
  bool get isHoliday => _isHoliday;

  Future<void> fetchWeeklyOff() async {
    if (_weeklyOff != null) return;
    _weeklyOff = await _bookingService.getWeeklyOff();
    notifyListeners();
  }

  void selectDate(DateTime date) {
    _selectedDate = date;
    _selectedSlot = null;
    _manualTime = null;
    // If a staff is pre-selected, fetch staff-specific slots; otherwise fetch salon slots
    if (_preSelectedStaffId != null) {
      fetchStaffSlots(_preSelectedStaffId!, _preSelectedStaffDuration ?? 45);
    } else {
      fetchSalonSlots();
    }
    notifyListeners();
  }

  /// Call this when a staff is pre-selected to set up staff-specific slot fetching.
  void setPreSelectedStaff(int? staffId, {int durationMinutes = 45}) {
    _preSelectedStaffId = staffId;
    _preSelectedStaffDuration = durationMinutes;
    _slotsCache.clear(); // Clear cache so the next fetch uses new staff context
    _errorCache.clear();
    _availableSlots = [];
    _selectedSlot = null;
    notifyListeners();
  }

  void selectSlot(AvailableSlot? slot) {
    _selectedSlot = slot;
    if (slot != null) {
      _manualTime = slot.startTime;
    }
    notifyListeners();
  }

  void applyOffer(Offer? offer) {
    _appliedOffer = offer;
    notifyListeners();
  }

  void toggleHomeService(bool value) {
    _isHomeService = value;
    notifyListeners();
  }

  void setHomeAddress(String address, {double? lat, double? lng}) {
    _homeAddress = address;
    _latitude = lat;
    _longitude = lng;
    notifyListeners();
  }

  Future<void> fetchHomeServiceCharges(int salonId) async {
    try {
      _homeServiceCharge = await _bookingService.getHomeServiceCharges(salonId);
      notifyListeners();
    } catch (e) {
      print("Error fetching home service charges in provider: $e");
    }
  }

  final Map<String, List<AvailableSlot>> _slotsCache = {};
  final Map<String, String?> _errorCache = {};

  Future<void> fetchSalonSlots() async {
    await fetchWeeklyOff();
    final dayName = DateFormat('EEEE').format(_selectedDate).toUpperCase();
    if (_weeklyOff != null && _weeklyOff == dayName) {
      _isHoliday = true;
      _availableSlots = [];
      _error = "The salon is closed on ${DateFormat('EEEE').format(_selectedDate)}s. Please choose another date.";
      notifyListeners();
      return;
    }
    _isHoliday = false;

    final cacheKey = _selectedDate.toIso8601String().split('T')[0];
    if (_slotsCache.containsKey(cacheKey)) {
      _availableSlots = _slotsCache[cacheKey]!;
      _error = _errorCache[cacheKey];
      notifyListeners();
      return;
    }

    _availableSlots = [];
    _isLoadingSlots = true;
    _error = null;
    notifyListeners();

    try {
      final allSlots = await _bookingService.getSalonSlots(_selectedDate);
      _availableSlots = allSlots;
      _slotsCache[cacheKey] = allSlots;
      _errorCache[cacheKey] = null;
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      _slotsCache[cacheKey] = [];
      _errorCache[cacheKey] = _error;
    } finally {
      _isLoadingSlots = false;
      notifyListeners();
    }
  }

  /// Fetch slots for a specific staff member using their available-slots endpoint.
  Future<void> fetchStaffSlots(int staffId, int durationMinutes) async {
    await fetchWeeklyOff();
    final dayName = DateFormat('EEEE').format(_selectedDate).toUpperCase();
    if (_weeklyOff != null && _weeklyOff == dayName) {
      _isHoliday = true;
      _availableSlots = [];
      _error = "The salon is closed on ${DateFormat('EEEE').format(_selectedDate)}s. Please choose another date.";
      notifyListeners();
      return;
    }
    _isHoliday = false;

    final cacheKey = 'staff_${staffId}_${_selectedDate.toIso8601String().split('T')[0]}_$durationMinutes';
    if (_slotsCache.containsKey(cacheKey)) {
      _availableSlots = _slotsCache[cacheKey]!;
      _error = _errorCache[cacheKey];
      notifyListeners();
      return;
    }

    _availableSlots = [];
    _isLoadingSlots = true;
    _error = null;
    notifyListeners();

    try {
      final slots = await _bookingService.getAvailableSlots(staffId, _selectedDate, durationMinutes);
      _availableSlots = slots;
      _slotsCache[cacheKey] = slots;
      _errorCache[cacheKey] = null;
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      _slotsCache[cacheKey] = [];
      _errorCache[cacheKey] = _error;
    } finally {
      _isLoadingSlots = false;
      notifyListeners();
    }
  }

  DateTime? _manualTime;
  DateTime get manualTime => _manualTime ?? _selectedDate;

  void setManualTime(DateTime dt) {
    _manualTime = dt;
    _selectedSlot = null; // Manual time overrides slot
    notifyListeners();
  }

  Future<Map<String, dynamic>> confirmBooking({
    Staff? staff,
    required List<NeoService> selectedServices,
    String? salonId,
  }) async {
    if (_selectedSlot == null && _manualTime == null) {
      throw Exception("No time slot or manual time selected");
    }

    final appointmentTime = _selectedSlot?.startTime ?? manualTime;
    
    // originalTotalPrice is always sum of individual services
    final originalTotalPrice = selectedServices.fold<double>(0, (sum, item) => sum + item.price);
    
    // packageSavings is originalTotalPrice - packagePrice if package is selected
    final packageSavings = _selectedPackage != null
        ? (originalTotalPrice - _selectedPackage!.packagePrice)
        : 0.0;

    // basePrice for offer discount calculation is packagePrice if package is selected, otherwise originalTotalPrice
    final basePrice = _selectedPackage != null 
        ? _selectedPackage!.packagePrice 
        : originalTotalPrice;

    double offerDiscountAmount = 0.0;
    if (_appliedOffer != null) {
      if (_appliedOffer!.discountType == 'PERCENTAGE') {
        offerDiscountAmount = basePrice * (_appliedOffer!.discountValue / 100);
      } else {
        offerDiscountAmount = _appliedOffer!.discountValue;
      }
    }

    final totalDiscountAmount = packageSavings + offerDiscountAmount;
    final finalAmount = (originalTotalPrice - totalDiscountAmount) + (_isHomeService ? _homeServiceCharge : 0.0);

    // Use provided salonId, or staff's salonId, or default to "1" (as requested for tenantName)
    // The backend expects a Long, so we ensure it's a numeric-compatible value.
    final effectiveSalonId = salonId ?? staff?.salonId?.toString() ?? "1";

    final requestData = {
      "salonId": int.tryParse(effectiveSalonId) ?? 1, 
      "staffId": staff?.id ?? 0, // Use 0 for No Preference if no staff is provided
      "staffName": staff?.name ?? "No Preference",
      "appointmentAt": appointmentTime.toUtc().toIso8601String(),
      "homeService": _isHomeService,
      "address": _homeAddress,
      "latitude": _latitude,
      "longitude": _longitude,
      "services": selectedServices.map((s) => {
        "serviceId": s.id.toString(),
        "serviceName": s.name,
        "duration": s.duration,
        "price": s.price,
      }).toList(),
      "totalPrice": originalTotalPrice,
      "discountAmount": totalDiscountAmount,
      "finalAmount": finalAmount,
      "offerId": _appliedOffer?.id.toString(),
      "offerName": _appliedOffer?.name,
      "discountType": _appliedOffer?.discountType,
      "discountValue": _appliedOffer?.discountValue,
      "packageId": _selectedPackage?.id,
      "packageName": _selectedPackage?.name,
      "homeCharge": _isHomeService ? _homeServiceCharge : null,
      "status": "booked"
    };

    _lastBookingResponse = await _bookingService.bookAppointment(requestData);
    return _lastBookingResponse!;
  }

  List<Appointment> get upcomingAppointments =>
      _userAppointments.where((a) {
        final st = a.status.toLowerCase();
        return st == 'booked' || st == 'rescheduled';
      }).toList();

  List<Appointment> get cancelledAppointments =>
      _userAppointments.where((a) => a.status.toLowerCase() == 'cancelled').toList();

  List<Appointment> get completedAppointments =>
      _userAppointments.where((a) => a.status.toLowerCase() == 'completed').toList();

  Future<void> fetchUserAppointments(String mobile, {bool refresh = false, int? page, String? status}) async {
    if (status != _currentStatus) {
      _currentStatus = status;
      _currentPage = 0;
      _userAppointments.clear();
      _hasMore = true;
      refresh = true;
    }

    if (page != null) {
      _currentPage = page;
    } else if (refresh) {
      _currentPage = 0;
    }

    if (refresh || page != null) {
      _hasMore = true;
      _userAppointments.clear();
      _isLoadingAppointments = true;
    } else {
      if (!_hasMore || _isLoadingMore) return;
      _isLoadingMore = true;
    }
    
    _error = null;
    notifyListeners();

    try {
      final data = await _bookingService.getUserAppointments(
        mobile, 
        page: _currentPage, 
        size: 10,
        status: _currentStatus,
      );
      final List<dynamic> content = data['content'] ?? [];
      final newAppointments = content.map((json) => Appointment.fromJson(json)).toList();
      
      final pageInfo = data['page'];
      if (pageInfo != null) {
        _totalPages = pageInfo['totalPages'] ?? 0;
        int currentNumber = pageInfo['number'] ?? 0;
        _hasMore = currentNumber < _totalPages - 1;
        _currentPage = currentNumber;
      } else {
        _hasMore = newAppointments.length == 10;
      }
      
      if (refresh || page != null) {
        _userAppointments = newAppointments;
      } else {
        _userAppointments.addAll(newAppointments);
      }
      
      if (page == null && !refresh) {
        _currentPage++;
      }
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      print("Error in fetchUserAppointments: $e");
    } finally {
      _isLoadingAppointments = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> rescheduleAppointment(int id, DateTime newTime, String? reason, String mobile) async {
    _isLoadingAppointments = true;
    notifyListeners();
    try {
      await _bookingService.rescheduleAppointment(id, newTime, reason);
      await fetchUserAppointments(mobile, refresh: true);
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      rethrow; // Rethrow to allow UI to catch and show error
    } finally {
      _isLoadingAppointments = false;
      notifyListeners();
    }
  }

  Future<void> cancelAppointment(int id, String reason, String mobile) async {
    _isLoadingAppointments = true;
    notifyListeners();
    try {
      await _bookingService.cancelAppointment(id, reason);
      await fetchUserAppointments(mobile, refresh: true);
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      rethrow; // Rethrow to allow UI to catch and show error
    } finally {
      _isLoadingAppointments = false;
      notifyListeners();
    }
  }

  void resetBookingState() {
    _selectedDate = DateTime.now();
    _selectedSlot = null;
    _manualTime = null;
    _availableSlots = [];
    _appliedOffer = null;
    _selectedPackage = null;
    _error = null;
    _lastBookingResponse = null;
    _preSelectedStaffId = null;
    _preSelectedStaffDuration = null;
    _slotsCache.clear(); // force fresh fetch on next booking
    _errorCache.clear();
    _isHomeService = false;
    _homeServiceCharge = 0.0;
    _homeAddress = null;
    _latitude = null;
    _longitude = null;
    _currentPage = 0;
    _hasMore = true;
    _isLoadingMore = false;
    notifyListeners();
  }
}
