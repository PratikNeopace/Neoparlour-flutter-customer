import 'package:flutter/material.dart';
import '../../core/utils/error_handler.dart';
import '../../core/data/services/cart_service.dart';
import '../../core/domain/models/order_model.dart';

class OrderProvider extends ChangeNotifier {
  final CartService _cartService = CartService();
  
  List<OrderModel> _orders = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 0;
  int _totalPages = 0;
  int _totalElements = 0;

  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalElements => _totalElements;

  Future<void> fetchOrders(int customerId, {int page = 0}) async {
    _isLoading = true;
    _currentPage = page;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _cartService.getOrders(customerId, page: page);
      _orders = response.content;
      _totalPages = response.page.totalPages;
      _totalElements = response.page.totalElements;
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void goToPage(int customerId, int page) {
    if (page >= 0 && page < _totalPages) {
      fetchOrders(customerId, page: page);
    }
  }
}
