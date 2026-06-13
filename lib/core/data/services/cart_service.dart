import 'package:flutter/foundation.dart';
import '../../domain/models/cart_item.dart';
import '../../domain/models/order_model.dart';
import '../api_client.dart';

class CartService {
  final ApiClient _apiClient = ApiClient();

  Future<void> addToCart(int productId, int quantity) async {
    try {
      await _apiClient.dio.post('cart/add', queryParameters: {
        'productId': productId,
        'quantity': quantity,
      });
    } catch (e) {
      debugPrint("Error adding to cart: $e");
      rethrow;
    }
  }

  Future<CartResponse> getCart() async {
    try {
      final response = await _apiClient.dio.get('cart');
      debugPrint("CART RESPONSE: ${response.data}");
      return CartResponse.fromJson(response.data);
    } catch (e) {
      debugPrint("Error getting cart: $e");
      rethrow;
    }
  }

  Future<void> removeCartItem(int productId) async {
    try {
      await _apiClient.dio.delete('cart/remove/$productId');
    } catch (e) {
      debugPrint("Error removing item from cart: $e");
      rethrow;
    }
  }

  Future<void> clearCart() async {
    try {
      await _apiClient.dio.delete('cart/clear');
    } catch (e) {
      debugPrint("Error clearing cart: $e");
      rethrow;
    }
  }

  Future<dynamic> checkout({int? productId}) async {
    try {
      String url = productId != null ? 'cart/checkout/$productId' : 'cart/checkout';
      final response = await _apiClient.dio.post(url);
      return response.data;
    } catch (e) {
      debugPrint("Error during checkout: $e");
      rethrow;
    }
  }

  Future<dynamic> placeOrder(Map<String, dynamic> orderData) async {
    try {
      final response = await _apiClient.dio.post('orders', data: orderData);
      return response.data;
    } catch (e) {
      debugPrint("Error placing order: $e");
      rethrow;
    }
  }

  Future<OrderResponse> getOrders(int customerId, {int page = 0, int size = 10}) async {
    try {
      final response = await _apiClient.dio.get('orders', queryParameters: {
        'customerId': customerId,
        'page': page,
        'size': size,
      });
      return OrderResponse.fromJson(response.data);
    } catch (e) {
      debugPrint("Error getting orders: $e");
      rethrow;
    }
  }
}
