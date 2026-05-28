import 'package:dio/dio.dart';
import '../api_client.dart';
import '../../domain/models/login_request.dart';
import '../../domain/models/login_response.dart';
import '../../domain/models/switch_tenant_request.dart';
import '../../domain/models/reset_password_request.dart';
import '../../domain/models/user_profile.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();

  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final response = await _apiClient.dio.post(
        'customer/login',
        data: request.toJson(),
        options: Options(extra: {'skipToken': true}),
      );
      return LoginResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<LoginResponse> switchCustomerToSalon(SwitchTenantRequest request) async {
    try {
      final response = await _apiClient.dio.post(
        'customer/switch-tenant',
        data: request.toJson(),
      );
      return LoginResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.dio.post('customer/logout');
    } catch (e) {
      rethrow;
    }
  }

  Future<UserProfile> getUserProfile(int userId) async {
    try {
      final response = await _apiClient.dio.get('customer/$userId');
      return UserProfile.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<UserProfile> updateUserProfile(int userId, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.put('customer/$userId', data: data);
      return UserProfile.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }
  Future<void> sendOtp(String mobile) async {
    try {
      await _apiClient.dio.post(
        'customer/send-otp', 
        queryParameters: {'mobile': mobile},
        options: Options(extra: {'skipToken': true}),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<UserProfile> registerWithOtp(String otp, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post(
        'customer/register-with-otp',
        queryParameters: {'otp': otp},
        data: data,
        options: Options(extra: {'skipToken': true}),
      );
      return UserProfile.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> forgotPasswordSendOtp(String mobile) async {
    try {
      await _apiClient.dio.post(
        'customer/forgot-password/send-otp',
        queryParameters: {'mobile': mobile},
        options: Options(extra: {'skipToken': true}),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> resetPasswordWithOtp(String mobile, String otp, String newPassword) async {
    try {
      final request = ResetPasswordRequest(
        mobile: mobile,
        otp: otp,
        newPassword: newPassword,
      );
      
      await _apiClient.dio.post(
        'customer/forgot-password/reset',
        data: request.toJson(),
        options: Options(extra: {'skipToken': true}),
      );
    } catch (e) {
      rethrow;
    }
  }
  Future<String> deleteAccount(int userId) async {
    try {
      final response = await _apiClient.dio.delete('customer/$userId');
      return response.data.toString();
    } catch (e) {
      rethrow;
    }
  }
}
