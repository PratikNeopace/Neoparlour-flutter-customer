import '../api_client.dart';
import '../../domain/models/product.dart';

class ProductService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Product>> getProducts() async {
    try {
      final response = await _apiClient.dio.get('products/filter?active=true&page=0&size=5');
      if (response.data is Map && response.data['content'] is List) {
        final List<dynamic> content = response.data['content'];
        return content.map((json) => Product.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print("Error fetching products: $e");
      rethrow;
    }
  }

  Future<GroupedProductsResponse> getGroupedProducts({int page = 0, int size = 3}) async {
    try {
      final response = await _apiClient.dio.get(
        'products/grouped',
        queryParameters: {
          'page': page,
          'size': size,
          'productType': 'WHOLESALE',
        },
      );
      final Map<String, List<Product>> result = {};
      bool isLast = true;
      
      if (response.data is Map) {
        final Map<String, dynamic> data = response.data;
        
        if (data.containsKey('content') && data['content'] is List) {
          isLast = data['last'] == true;
          final List<dynamic> content = data['content'];
          for (var item in content) {
            if (item is Map) {
              String? categoryKey;
              List<dynamic>? productsList;
              
              if (item.containsKey('category') && item['products'] is List) {
                categoryKey = item['category']?.toString();
                productsList = item['products'];
              } else if (item.containsKey('categoryName') && item['products'] is List) {
                categoryKey = item['categoryName']?.toString();
                productsList = item['products'];
              } else if (item.containsKey('key') && item['value'] is List) {
                categoryKey = item['key']?.toString();
                productsList = item['value'];
              } else {
                for (var entry in item.entries) {
                  if (entry.value is List) {
                    productsList = entry.value;
                  } else if (entry.value is String) {
                    categoryKey = entry.value;
                  }
                }
              }
              
              if (categoryKey != null && productsList != null) {
                final List<Product> products = productsList
                    .where((json) => json is Map && json['active'] == true)
                    .map((json) => Product.fromJson(json))
                    .toList();
                result[categoryKey] = products;
              }
            }
          }
        } else {
          isLast = true;
          data.forEach((key, value) {
            if (value is List) {
              final List<Product> products = value
                  .where((json) => json is Map && json['active'] == true)
                  .map((json) => Product.fromJson(json))
                  .toList();
              result[key] = products;
            }
          });
        }
      }
      return GroupedProductsResponse(groupedProducts: result, isLast: isLast);
    } catch (e) {
      print("Error fetching grouped products: $e");
      rethrow;
    }
  }

  Future<List<Product>> getFilteredProducts({
    String? category,
    String? productType,
    bool active = true,
    int page = 0,
    int size = 3,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        'products/filter',
        queryParameters: {
          'active': active,
          if (category != null) 'category': category,
          if (productType != null) 'productType': productType,
          'page': page,
          'size': size,
        },
      );
      if (response.data is Map && response.data['content'] is List) {
        final List<dynamic> content = response.data['content'];
        return content.map((json) => Product.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print("Error fetching filtered products: $e");
      rethrow;
    }
  }

  Future<Product> getProductById(int id) async {
    try {
      final response = await _apiClient.dio.get('products/$id');
      return Product.fromJson(response.data);
    } catch (e) {
      print("Error fetching product details: $e");
      rethrow;
    }
  }
}

class GroupedProductsResponse {
  final Map<String, List<Product>> groupedProducts;
  final bool isLast;

  GroupedProductsResponse({
    required this.groupedProducts,
    required this.isLast,
  });
}
