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
      print("Error adding to cart: $e");
      rethrow;
    }
  }

  Future<CartResponse> getCart() async {
    try {
      final response = await _apiClient.dio.get('cart');
      print("CART RESPONSE: ${response.data}");
      return CartResponse.fromJson(response.data);
    } catch (e) {
      print("Error getting cart: $e");
      rethrow;
    }
  }

  Future<void> removeCartItem(int productId) async {
    try {
      await _apiClient.dio.delete('cart/remove/$productId');
    } catch (e) {
      print("Error removing item from cart: $e");
      rethrow;
    }
  }

  Future<void> clearCart() async {
    try {
      await _apiClient.dio.delete('cart/clear');
    } catch (e) {
      print("Error clearing cart: $e");
      rethrow;
    }
  }

  Future<dynamic> checkout({int? productId}) async {
    try {
      String url = productId != null ? 'cart/checkout/$productId' : 'cart/checkout';
      final response = await _apiClient.dio.post(url);
      return response.data;
    } catch (e) {
      print("Error during checkout: $e");
      rethrow;
    }
  }

  Future<dynamic> placeOrder(Map<String, dynamic> orderData) async {
    try {
      final response = await _apiClient.dio.post('orders', data: orderData);
      return response.data;
    } catch (e) {
      print("Error placing order: $e");
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
      print("Error getting orders: $e");
      rethrow;
    }
  }
}
