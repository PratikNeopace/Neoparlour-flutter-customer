import 'package:flutter/material.dart';
import '../../core/utils/error_handler.dart';
import '../../core/data/services/cart_service.dart';
import '../../core/domain/models/cart_item.dart';

class CartProvider with ChangeNotifier {
  final CartService _cartService = CartService();
  bool _isLoading = false;
  String? _error;
  List<CartItem> _cartItems = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<CartItem> get cartItems => _cartItems;

  double get subtotal => _cartItems.fold(0, (sum, item) => sum + item.lineTotal);

  Future<void> fetchCart() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _cartService.getCart();
      _cartItems = response.items;
      _cartItems.sort((a, b) => a.productId.compareTo(b.productId));
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addToCart(int productId, int quantity) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _cartService.addToCart(productId, quantity);
      await fetchCart();
      return true;
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeFromCart(int productId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _cartService.removeCartItem(productId);
      await fetchCart();
      return true;
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> clearCart() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _cartService.clearCart();
      _cartItems = [];
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> checkout({int? productId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _cartService.checkout(productId: productId);
      await fetchCart();
      return true;
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> placeOrder({
    required int customerId,
    required int salonId,
    required double totalAmount,
    required List<Map<String, dynamic>> items,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final orderData = {
        "customerId": customerId,
        "salonId": salonId,
        "totalAmount": totalAmount,
        "status": "ordered",
        "items": items,
      };
      await _cartService.placeOrder(orderData);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
