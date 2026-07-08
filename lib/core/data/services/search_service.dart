import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../api_client.dart';

class SearchService {
  final ApiClient _apiClient = ApiClient();

  /// Search for city names from backend
  Future<List<String>> searchCities(String keyword) async {
    try {
      final response = await _apiClient.dio.get(
        'salons/search/cities',
        queryParameters: {'keyword': keyword},
      );
      if (response.data is List) {
        return List<String>.from(response.data.map((item) => item.toString()));
      }
      return [];
    } catch (error) {
      debugPrint('Error searching cities: $error');
      rethrow;
    }
  }

  /// Search for area names within a city from backend
  Future<List<String>> searchAreas(String cityName, String keyword) async {
    try {
      final response = await _apiClient.dio.get(
        'salons/search/areas',
        queryParameters: {'cityName': cityName, 'keyword': keyword},
      );
      if (response.data is List) {
        return List<String>.from(response.data.map((item) => item.toString()));
      }
      return [];
    } catch (error) {
      debugPrint('Error searching areas: $error');
      rethrow;
    }
  }

  /// Get salons by city, area and optional category
  Future<List<dynamic>> getSalonsByLocation(String cityName, String areaName, {String? category}) async {
    try {
      final Map<String, dynamic> params = {
        'cityName': cityName,
      };
      if (areaName.isNotEmpty) {
        params['areaName'] = areaName;
      }
      if (category != null && category.isNotEmpty && category.toLowerCase() != 'all') {
        params['category'] = category;
      }

      final response = await _apiClient.dio.get(
        'salons/location-search',
        queryParameters: params,
      );
      if (response.data is List) {
        return response.data;
      }
      return [];
    } catch (error) {
      debugPrint('Error fetching salons by location: $error');
      rethrow;
    }
  }

  /// Search for locations using Komoot Photon Autocomplete geocoding API (OSM backed)
  Future<List<Map<String, dynamic>>> searchExternalLocations(
    String query, {
    String featureClass = '',
    String cityName = '',
  }) async {
    if (query.trim().length < 2) return [];

    String normalizeCity(String name) {
      final lower = name.toLowerCase().trim();
      if (lower == 'bangalore' || lower == 'bengaluru') return 'bengaluru';
      if (lower == 'mumbai' || lower == 'bombay') return 'mumbai';
      if (lower == 'calcutta' || lower == 'kolkata') return 'kolkata';
      if (lower == 'madras' || lower == 'chennai') return 'chennai';
      return lower;
    }

    try {
      String searchQuery = query;
      if (cityName.isNotEmpty && featureClass == 'area') {
        searchQuery = '$query $cityName';
      }

      // Public endpoint, use raw Dio client with custom User-Agent to prevent Cloudflare/WAF block on mobile
      final dioClient = Dio();
      dioClient.options.headers['User-Agent'] =
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36';

      final response = await dioClient.get(
        'https://photon.komoot.io/api',
        queryParameters: {
          'q': searchQuery,
          'countrycode': 'in', // Target India strictly
          'limit': 15,
        },
      );

      var responseData = response.data;
      if (responseData is String) {
        responseData = jsonDecode(responseData);
      }
      final List<dynamic> features = responseData['features'] ?? [];
      final List<Map<String, dynamic>> results = [];
      final Set<String> seen = {};

      for (final feature in features) {
        final Map<String, dynamic> props = feature['properties'] ?? {};

        // Extract city identifier (with rich fallback)
        final String city = props['city'] ?? props['town'] ?? props['district'] ?? props['state_district'] ?? props['county'] ?? '';

        // Extract clean primary area name without street prefix hierarchies
        final String rawName = props['name'] ?? '';
        final String cleanName = rawName.split(',').first.trim();

        if (featureClass == 'city') {
          // Priority clean city matching
          final String matchedCity = props['city'] ?? ((props['osm_value'] == 'city' || props['osm_value'] == 'town') ? props['name'] : '');
          if (matchedCity.isNotEmpty && !seen.contains(matchedCity.toLowerCase())) {
            final normCity = matchedCity.toLowerCase();
            final normQuery = query.toLowerCase().trim();

            // Ensure the city name itself matches the query string (prefix or substring)
            if (normCity.contains(normQuery)) {
              seen.add(matchedCity.toLowerCase());
              results.add({'name': matchedCity, 'type': 'city'});
            }
          }
        } else if (featureClass == 'area') {
          final normSelectedCity = normalizeCity(cityName);

          // Verify if result belongs to selected metropolitan boundaries
          final List<String?> checkList = [
            props['city'],
            props['town'],
            props['district'],
            props['state_district'],
            props['county'],
            props['state'],
            rawName,
          ];
          final bool matchesCity = cityName.isEmpty || checkList.any((val) => val != null && normalizeCity(val).contains(normSelectedCity));

          // Skip if suggestions are exactly duplicate of the city name
          if (cleanName.toLowerCase() == cityName.toLowerCase()) {
            continue;
          }

          if (cleanName.isNotEmpty && matchesCity) {
            final String subLocality = props['district'] ?? props['locality'] ?? props['suburb'] ?? '';
            final String parentCity = city.isNotEmpty && normalizeCity(city) != normSelectedCity ? '$city, $cityName' : (city.isNotEmpty ? city : cityName);
            final String displayCity = subLocality.isNotEmpty ? '$subLocality, $parentCity' : parentCity;

            final uniqueKey = '${cleanName.toLowerCase()}_${displayCity.toLowerCase()}';
            if (!seen.contains(uniqueKey)) {
              seen.add(uniqueKey);
              results.add({
                'name': cleanName,
                'city': displayCity,
                'type': 'area',
              });
            }
          }
        } else {
          // Unstructured fallback search
          if (cleanName.isNotEmpty) {
            final String label = city.isNotEmpty ? '$cleanName, $city' : cleanName;
            if (!seen.contains(label.toLowerCase())) {
              seen.add(label.toLowerCase());
              results.add({'label': label, 'city': city, 'area': cleanName});
            }
          }
        }
      }

      // Sort results to prioritize exact prefix matches of the user's typed area query
      final String lowerQuery = query.toLowerCase().trim();
      results.sort((a, b) {
        final String nameA = ((a['name'] ?? a['label'] ?? '') as String).toLowerCase();
        final String nameB = ((b['name'] ?? b['label'] ?? '') as String).toLowerCase();

        final bool startsA = nameA.startsWith(lowerQuery);
        final bool startsB = nameB.startsWith(lowerQuery);

        if (startsA && !startsB) return -1;
        if (!startsA && startsB) return 1;

        final bool containsA = nameA.contains(lowerQuery);
        final bool containsB = nameB.contains(lowerQuery);

        if (containsA && !containsB) return -1;
        if (!containsA && containsB) return 1;

        return 0; // Maintain original Photon relevance score ranking
      });

      return results;
    } catch (error) {
      debugPrint('Error searching external locations via Photon: $error');
      // Fallback to backend salons search
      try {
        if (featureClass == 'city') {
          final backendCities = await searchCities(query);
          return backendCities.map((name) => {'name': name, 'type': 'city'}).toList();
        } else if (featureClass == 'area') {
          final backendAreas = await searchAreas(cityName, query);
          return backendAreas.map((name) => {
            'name': name,
            'city': cityName,
            'type': 'area',
          }).toList();
        }
      } catch (fallbackError) {
        debugPrint('Fallback search failed: $fallbackError');
      }
      return [];
    }
  }

  /// Reverse geocode coordinates to find city and area names using Komoot Photon API
  Future<Map<String, String>> reverseGeocode(double lat, double lon) async {
    try {
      final dioClient = Dio();
      final response = await dioClient.get(
        'https://photon.komoot.io/reverse',
        queryParameters: {'lat': lat, 'lon': lon},
      );

      final List<dynamic> features = response.data['features'] ?? [];
      if (features.isEmpty) {
        return {'city': '', 'area': ''};
      }

      final Map<String, dynamic> props = features[0]['properties'] ?? {};

      // Helper to extract a clean city name from county or city properties
      String extractCleanCity(Map<String, dynamic> p) {
        final List<String?> candidates = [
          p['county'],
          p['city'],
          p['town'],
          p['state_district'],
          p['district'],
        ];
        final List<RegExp> stopwords = [
          RegExp(r'\bsubdistrict\b', caseSensitive: false),
          RegExp(r'\bdistrict\b', caseSensitive: false),
          RegExp(r'\bcity\b', caseSensitive: false),
          RegExp(r'\burban\b', caseSensitive: false),
          RegExp(r'\bsuburban\b', caseSensitive: false),
          RegExp(r'\btown\b', caseSensitive: false),
          RegExp(r'\bdivision\b', caseSensitive: false),
          RegExp(r'\bcorporation\b', caseSensitive: false),
          RegExp(r'\bmunicipal\b', caseSensitive: false),
        ];

        for (final candidate in candidates) {
          if (candidate == null) continue;

          String name = candidate.split(',').last.trim();
          for (final regex in stopwords) {
            name = name.replaceAll(regex, '');
          }
          name = name.replaceAll(RegExp(r'\s+'), ' ').trim();

          if (name.isNotEmpty && name.length > 2) {
            final String lower = name.toLowerCase();
            if (lower == 'bengaluru' || lower == 'bangalore') return 'Bengaluru';
            if (lower == 'mumbai' || lower == 'bombay') return 'Mumbai';
            if (lower == 'calcutta' || lower == 'kolkata') return 'Kolkata';
            if (lower == 'madras' || lower == 'chennai') return 'Chennai';
            return name;
          }
        }
        return '';
      }

      final String city = extractCleanCity(props).isNotEmpty ? extractCleanCity(props) : (props['city'] ?? '');
      final String area = props['locality'] ?? props['suburb'] ?? props['district'] ?? props['name'] ?? props['street'] ?? '';

      return {
        'city': city.trim(),
        'area': area.trim(),
      };
    } catch (error) {
      debugPrint('Error reverse geocoding via Photon: $error');
      rethrow;
    }
  }
}
