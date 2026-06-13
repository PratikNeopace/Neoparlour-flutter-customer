import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/data/services/auth_service.dart';
import '../../core/domain/models/login_request.dart';
import '../../core/domain/models/switch_tenant_request.dart';
import '../../core/domain/models/user_profile.dart';
import '../../core/utils/error_handler.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final Completer<void> _initCompleter = Completer<void>();
  
  Future<void> get initialization => _initCompleter.future;
  bool _isLoading = false;
  String? _errorMessage;
  String? _token;
  String? _userName;
  String? _userPhone;
  int? _userId;
  String? _tenantName;
  UserProfile? _userProfile;
  Map<String, dynamic>? _tempRegistrationData;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _token != null;
  String? get userName => _userName;
  String? get userPhone => _userPhone;
  int? get userId => _userId;
  String? get tenantName => _tenantName;
  UserProfile? get userProfile => _userProfile;
  Map<String, dynamic>? get tempRegistrationData => _tempRegistrationData;
  bool get isLoadingProfile => _isLoadingProfile;
  bool _isLoadingProfile = false;

  AuthProvider() {
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _userName = prefs.getString('userName');
    _userPhone = prefs.getString('userPhone');
    _userId = prefs.getInt('userId');
    _tenantName = prefs.getString('tenantName');
    
    if (!_initCompleter.isCompleted) {
      _initCompleter.complete();
    }
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _setLoading(true);
    _errorMessage = null;
    
    try {
      String? fcmToken;
      try {
        if (kIsWeb) {
          fcmToken = await FirebaseMessaging.instance.getToken(
            vapidKey: "BFpo2-QNfbYmF-ByOI2VzLb4NoxoZIyN_iBmU_mt1cjPk_G9GM1B3CDM4Wd8lFkRGNONp1pc3Lq1e0XP4Y50sjY",
          );
        } else {
          fcmToken = await FirebaseMessaging.instance.getToken();
        }
        debugPrint("FCM Token for Login: $fcmToken");
      } catch (e) {
        debugPrint("Error fetching FCM token: $e");
      }

      final request = LoginRequest(
        username: username, 
        password: password,
        fcmToken: fcmToken,
      );
      
      debugPrint("Login Request Payload: ${request.toJson()}");
      
      final response = await _authService.login(request);
      
      _token = response.token;
      _userName = response.name;
      _userPhone = response.phone;
      _userId = response.id;
      _tenantName = response.tenantName;
      
      debugPrint("Login Successful for User: $_userId, Tenant: $_tenantName, Token: ${_token?.substring(0, 10)}...");

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      await prefs.setString('userName', _userName!);
      await prefs.setString('userPhone', _userPhone!);
      await prefs.setString('tenantName', _tenantName!);
      if (_userId != null) await prefs.setInt('userId', _userId!);
      
      if (_userId != null) {
        try {
          _userProfile = await _authService.getUserProfile(_userId!);
        } catch (e) {
          debugPrint("Profile fetch error in login: $e");
        }
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      debugPrint("Login Error: $_errorMessage");
      _setLoading(false);
      return false;
    }
  }

  Future<bool> switchTenant(String tenantId) async {
    if (_token == null) {
      _errorMessage = "No active session. Please login again.";
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      final request = SwitchTenantRequest(token: _token!, tenantId: tenantId);
      final response = await _authService.switchCustomerToSalon(request);
      
      // Update all fields with the new response returned by switch-tenant
      _token = response.token;
      _userName = response.name;
      _userPhone = response.phone;
      _userId = response.id;
      _tenantName = response.tenantName;
      
      debugPrint("Switch Tenant Successful. New User: $_userId, Tenant: $_tenantName, Token: ${_token?.substring(0, 10)}...");

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      await prefs.setString('userName', _userName!);
      await prefs.setString('userPhone', _userPhone!);
      await prefs.setString('tenantName', _tenantName!);
      if (_userId != null) await prefs.setInt('userId', _userId!);
      
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
    } catch (e) {
      debugPrint("Logout API Error: $e");
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userName');
    await prefs.remove('userPhone');
    await prefs.remove('userId');
    await prefs.remove('tenantName');
    _token = null;
    _userId = null;
    _tenantName = null;
    _userProfile = null;
    notifyListeners();
  }

  Future<void> fetchUserProfile() async {
    debugPrint("Fetching User Profile for ID: $_userId...");
    if (_userId == null) return;

    _isLoadingProfile = true;
    _errorMessage = null; 
    notifyListeners();

    try {
      _userProfile = await _authService.getUserProfile(_userId!);
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      debugPrint("Profile Fetch Error: $_errorMessage");
    } finally {
      _isLoadingProfile = false;
      notifyListeners();
    }
  }

  Future<bool> updateUserProfile(Map<String, dynamic> data) async {
    if (_userId == null) return false;

    _isLoadingProfile = true;
    notifyListeners();

    try {
      _userProfile = await _authService.updateUserProfile(_userId!, data);
      
      // Update other local fields that might have changed
      _userName = _userProfile?.name;
      _userPhone = _userProfile?.phone;
      
      final prefs = await SharedPreferences.getInstance();
      if (_userName != null) await prefs.setString('userName', _userName!);
      if (_userPhone != null) await prefs.setString('userPhone', _userPhone!);
      
      return true;
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      return false;
    } finally {
      _isLoadingProfile = false;
      notifyListeners();
    }
  }

  Future<void> updateFcmTokenOnServer(String token) async {
    if (_userId == null || _token == null) return;
    
    debugPrint("Updating FCM Token on server: $token");
    try {
      await _authService.updateUserProfile(_userId!, {'fcmToken': token});
    } catch (e) {
      debugPrint("Failed to update FCM token on server: $e");
    }
  }

  void setRegistrationData(Map<String, dynamic> data) {
    _tempRegistrationData = data;
    notifyListeners();
  }

  Future<bool> sendOtp(String mobile) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _authService.sendOtp(mobile);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      _setLoading(false);
      return false;
    }
  }

  Future<bool> registerWithOtp(String otp) async {
    if (_tempRegistrationData == null) {
      _errorMessage = "Registration data missing";
      return false;
    }
    
    _setLoading(true);
    _errorMessage = null;
    try {
      await _authService.registerWithOtp(otp, _tempRegistrationData!);
      
      // Auto-login after registration
      final success = await login(
        _tempRegistrationData!['mobile'], 
        _tempRegistrationData!['password']
      );
      
      _setLoading(false);
      return success;
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      _setLoading(false);
      return false;
    }
  }

  Future<bool> sendForgotPasswordOtp(String mobile) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _authService.forgotPasswordSendOtp(mobile);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      _setLoading(false);
      return false;
    }
  }

  Future<bool> resetPasswordWithOtp(String mobile, String otp, String newPassword) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _authService.resetPasswordWithOtp(mobile, otp, newPassword);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      _setLoading(false);
      return false;
    }
  }
  
  Future<bool> deleteUserAccount() async {
    if (_userId == null) return false;
    
    try {
      _isLoadingProfile = true;
      notifyListeners();

      await _authService.deleteAccount(_userId!);
      await logout();
      return true;
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      return false;
    } finally {
      _isLoadingProfile = false;
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
