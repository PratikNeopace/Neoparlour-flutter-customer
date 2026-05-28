import 'package:flutter/material.dart';
import '../../core/utils/error_handler.dart';
import '../../core/data/services/product_service.dart';
import '../../core/domain/models/product.dart';

class ProductProvider with ChangeNotifier {
  final ProductService _productService = ProductService();

  List<Product> _products = [];
  Map<String, List<Product>> _groupedProducts = {};
  bool _isLoading = false;
  String? _error;

  List<Product> get products => _products;
  Map<String, List<Product>> get groupedProducts => _groupedProducts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int _groupedPage = 0;
  bool _hasMoreGrouped = true;
  bool _isLoadingMoreGrouped = false;

  int get groupedPage => _groupedPage;
  bool get hasMoreGrouped => _hasMoreGrouped;
  bool get isLoadingMoreGrouped => _isLoadingMoreGrouped;

  Map<String, int> _categoryPages = {};
  Map<String, bool> _categoryHasMore = {};
  Map<String, bool> _categoryLoadingMore = {};

  int getCategoryPage(String category) => _categoryPages[category] ?? 0;
  bool getCategoryHasMore(String category) => _categoryHasMore[category] ?? true;
  bool getCategoryLoadingMore(String category) => _categoryLoadingMore[category] ?? false;

  Product? _selectedProduct;
  Product? get selectedProduct => _selectedProduct;

  Future<void> fetchProductById(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedProduct = await _productService.getProductById(id);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearData() {
    _products = [];
    notifyListeners();
  }

  Future<void> fetchProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _products = await _productService.getProducts();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchGroupedProducts({bool refresh = false}) async {
    if (refresh) {
      _groupedPage = 0;
      _hasMoreGrouped = true;
      _groupedProducts = {};
      _categoryPages = {};
      _categoryHasMore = {};
      _categoryLoadingMore = {};
      _isLoading = true;
      _error = null;
      notifyListeners();
    } else {
      if (!_hasMoreGrouped || _isLoadingMoreGrouped) return;
      _isLoadingMoreGrouped = true;
      notifyListeners();
    }

    try {
      final response = await _productService.getGroupedProducts(
        page: _groupedPage,
        size: 3,
      );

      final newGrouped = response.groupedProducts;
      
      if (newGrouped.isEmpty || response.isLast) {
        _hasMoreGrouped = false;
      }

      if (newGrouped.isNotEmpty) {
        newGrouped.forEach((key, products) {
          final initialProducts = products.take(3).toList();
          
          if (_groupedProducts.containsKey(key)) {
            final existingIds = _groupedProducts[key]!.map((p) => p.id).toSet();
            final uniqueNewProducts = initialProducts.where((p) => !existingIds.contains(p.id)).toList();
            _groupedProducts[key]!.addAll(uniqueNewProducts);
          } else {
            _groupedProducts[key] = initialProducts;
          }
          _categoryPages[key] = 0;
          _categoryHasMore[key] = true;
          _categoryLoadingMore[key] = false;
        });
        _groupedPage++;
      }
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      if (refresh) {
        _isLoading = false;
      } else {
        _isLoadingMoreGrouped = false;
      }
      notifyListeners();
      return;
    }

    _isLoading = false;
    _isLoadingMoreGrouped = false;
    notifyListeners();
  }

  Future<void> fetchMoreProductsForCategory(String category) async {
    final isLoadingMore = _categoryLoadingMore[category] ?? false;
    final hasMore = _categoryHasMore[category] ?? true;
    
    if (isLoadingMore || !hasMore) return;
    
    _categoryLoadingMore[category] = true;
    notifyListeners();
    
    final nextPage = (_categoryPages[category] ?? 0) + 1;
    
    try {
      final newProducts = await _productService.getFilteredProducts(
        category: category,
        productType: 'WHOLESALE',
        active: true,
        page: nextPage,
        size: 3,
      );
      
      if (newProducts.isEmpty) {
        _categoryHasMore[category] = false;
      } else {
        if (_groupedProducts.containsKey(category)) {
          final existingIds = _groupedProducts[category]!.map((p) => p.id).toSet();
          final uniqueNew = newProducts.where((p) => !existingIds.contains(p.id)).toList();
          _groupedProducts[category]!.addAll(uniqueNew);
        } else {
          _groupedProducts[category] = newProducts;
        }
        _categoryPages[category] = nextPage;
        if (newProducts.length < 3) {
          _categoryHasMore[category] = false;
        }
      }
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
    } finally {
      _categoryLoadingMore[category] = false;
      notifyListeners();
    }
  }
}
