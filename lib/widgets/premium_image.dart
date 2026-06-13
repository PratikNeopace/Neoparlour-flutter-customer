import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

class PremiumImageWidget extends StatelessWidget {
  final String? imageUrl;
  final double width;
  final double height;
  final BoxShape shape;
  final BorderRadiusGeometry? borderRadius;
  final Widget? fallbackWidget;

  // In-memory cache for fetched image bytes to avoid duplicate fetches
  static final Map<String, Uint8List> _imageCache = {};

  const PremiumImageWidget({
    super.key,
    required this.imageUrl,
    this.width = 80.0,
    this.height = 80.0,
    this.shape = BoxShape.rectangle,
    this.borderRadius,
    this.fallbackWidget,
  });

  static Future<Uint8List> _fetchImageBytes(String url, String? token) async {
    if (_imageCache.containsKey(url)) {
      return _imageCache[url]!;
    }
    final dio = Dio();
    final options = Options(
      responseType: ResponseType.bytes,
      headers: token != null && token.isNotEmpty
          ? {'Authorization': 'Bearer $token'}
          : null,
    );
    try {
      final response = await dio.get(url, options: options);
      final bytes = Uint8List.fromList(response.data as List<int>);
      _imageCache[url] = bytes;
      return bytes;
    } on DioException catch (e) {
      debugPrint("PremiumImageWidget: Failed to load image from $url. Status: ${e.response?.statusCode}, Error: ${e.message}");
      rethrow;
    } catch (e) {
      debugPrint("PremiumImageWidget: Unexpected error loading image from $url: $e");
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fallbackIcon = fallbackWidget ?? Icon(
      Icons.storefront_outlined,
      color: Colors.grey[400],
      size: width * 0.4,
    );

    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      return _buildPlaceholder(fallbackIcon);
    }

    final trimmedUrl = imageUrl!.trim();

    // Check if it is a Base64 string
    if (!trimmedUrl.startsWith('http') && !trimmedUrl.startsWith('assets/')) {
      try {
        String cleanBase64 = trimmedUrl;
        if (cleanBase64.contains(',')) {
          cleanBase64 = cleanBase64.split(',')[1];
        }
        final Uint8List bytes = base64Decode(cleanBase64.trim());
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            shape: shape,
            borderRadius: shape == BoxShape.circle ? null : (borderRadius ?? BorderRadius.circular(12)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.memory(
            bytes,
            width: width,
            height: height,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildPlaceholder(fallbackIcon),
          ),
        );
      } catch (_) {
        // Fall through to network if decoding fails
      }
    }

    return FutureBuilder<String?>(
      future: SharedPreferences.getInstance().then((prefs) => prefs.getString('token')),
      builder: (context, tokenSnapshot) {
        final token = tokenSnapshot.data;

        return FutureBuilder<Uint8List>(
          future: _fetchImageBytes(trimmedUrl, token),
          builder: (context, bytesSnapshot) {
            if (bytesSnapshot.connectionState == ConnectionState.waiting) {
              return _buildShimmer();
            }
            if (bytesSnapshot.hasError || !bytesSnapshot.hasData) {
              return _buildPlaceholder(fallbackIcon);
            }

            return Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                shape: shape,
                borderRadius: shape == BoxShape.circle ? null : (borderRadius ?? BorderRadius.circular(12)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.memory(
                bytesSnapshot.data!,
                width: width,
                height: height,
                fit: BoxFit.cover,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: shape,
          borderRadius: shape == BoxShape.circle ? null : (borderRadius ?? BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(Widget fallback) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        shape: shape,
        borderRadius: shape == BoxShape.circle ? null : (borderRadius ?? BorderRadius.circular(12)),
      ),
      child: Center(child: fallback),
    );
  }
}
