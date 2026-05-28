class CartItem {
  final int productId;
  final String productName;
  final String? productImageBase64;
  final double price;
  final double lineTotal;
  final int quantity;
  final int availableStock;
  final bool inStock;

  CartItem({
    required this.productId,
    required this.productName,
    this.productImageBase64,
    required this.price,
    required this.lineTotal,
    required this.quantity,
    required this.availableStock,
    required this.inStock,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productId: json['productId'] ?? 0,
      productName: json['productName'] ?? '',
      productImageBase64: json['productImageBase64'],
      price: (json['price'] ?? 0.0).toDouble(),
      lineTotal: (json['lineTotal'] ?? 0.0).toDouble(),
      quantity: json['quantity'] ?? 0,
      availableStock: json['availableStock'] ?? 0,
      inStock: json['inStock'] ?? false,
    );
  }
}

class CartResponse {
  final List<CartItem> items;

  CartResponse({required this.items});

  factory CartResponse.fromJson(Map<String, dynamic> json) {
    return CartResponse(
      items: (json['items'] as List?)?.map((i) => CartItem.fromJson(i)).toList() ?? [],
    );
  }
}
