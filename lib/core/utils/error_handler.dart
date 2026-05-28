import 'dart:convert';
import 'package:dio/dio.dart';

class ErrorHandler {
  static String getErrorMessage(dynamic error) {
    if (error is DioException) {
      if (error.response?.data != null) {
        dynamic data = error.response!.data;
        
        // Try parsing string to JSON map if needed
        if (data is String) {
          try {
            data = jsonDecode(data);
          } catch (_) {}
        }

        if (data is Map && data.containsKey('message') && data['message'] != null) {
          final msg = data['message'].toString().trim();
          if (msg.isNotEmpty) {
            return msg;
          }
        }
      }

      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return "Connection timed out. Please check your internet.";
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          if (statusCode == 401) return "Session expired. Please login again.";
          if (statusCode == 403) return "Access denied (403).";
          if (statusCode == 404) return "Resource not found (404).";
          if (statusCode == 500) return "Server error (500). Please try again later.";
          return "Server returned an error ($statusCode).";
        case DioExceptionType.cancel:
          return "Request cancelled.";
        case DioExceptionType.connectionError:
          return "No internet connection.";
        default:
          return "Something went wrong. Please try again.";
      }
    }
    
    final str = error.toString();
    if (str.contains('Failed host lookup') || 
        str.contains('SocketException') || 
        str.contains('Network is unreachable') || 
        str.contains('connection error') ||
        str.contains('Connection refused')) {
      return "Please check your internet connection and try again.";
    }
    
    return str.replaceAll('Exception: ', '');
  }
}
