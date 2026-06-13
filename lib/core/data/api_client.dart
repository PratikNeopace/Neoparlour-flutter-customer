import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/foundation.dart';

class ApiClient {
  static const String baseUrl = 'https://sb.neoparlour.com/api/';
  late Dio dio;

  ApiClient() {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Skip token for public endpoints if extra['skipToken'] is set
        if (options.extra['skipToken'] == true) {
          debugPrint("API Request: ${options.method} ${options.uri} (Skipping Token)");
          return handler.next(options);
        }

        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        
        debugPrint("API Request: ${options.method} ${options.uri}");
        return handler.next(options);
      },
      onError: (e, handler) {
        // Handle global errors here
        debugPrint("API Error: [${e.response?.statusCode}] ${e.response?.data ?? e.message}");
        return handler.next(e);
      },
    ));
  }
}
