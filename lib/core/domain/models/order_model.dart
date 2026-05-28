class OrderModel {
  final int id;
  final DateTime createdAt;
  final int customerId;
  final String customerName;
  final String customerMobile;
  final int salonId;
  final String status;
  final double totalAmount;
  final List<OrderItem> items;

  OrderModel({
    required this.id,
    required this.createdAt,
    required this.customerId,
    required this.customerName,
    required this.customerMobile,
    required this.salonId,
    required this.status,
    required this.totalAmount,
    required this.items,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] ?? 0,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      customerId: json['customerId'] ?? 0,
      customerName: json['customerName'] ?? '',
      customerMobile: json['customerMobile'] ?? '',
      salonId: json['salonId'] ?? 0,
      status: json['status'] ?? '',
      totalAmount: (json['totalAmount'] ?? 0.0).toDouble(),
      items: (json['items'] as List?)
              ?.map((i) => OrderItem.fromJson(i))
              .toList() ??
          [],
    );
  }
}

class OrderItem {
  final int id;
  final int productId;
  final String productName;
  final int quantity;
  final double price;

  OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] ?? 0,
      productId: json['productId'] ?? 0,
      productName: json['productName'] ?? '',
      quantity: json['quantity'] ?? 0,
      price: (json['price'] ?? 0.0).toDouble(),
    );
  }
}

class OrderResponse {
  final List<OrderModel> content;
  final OrderPageInfo page;

  OrderResponse({required this.content, required this.page});

  factory OrderResponse.fromJson(Map<String, dynamic> json) {
    return OrderResponse(
      content: (json['content'] as List?)
              ?.map((i) => OrderModel.fromJson(i))
              .toList() ??
          [],
      page: OrderPageInfo.fromJson(json['page'] ?? {}),
    );
  }
}

class OrderPageInfo {
  final int size;
  final int number;
  final int totalElements;
  final int totalPages;

  OrderPageInfo({
    required this.size,
    required this.number,
    required this.totalElements,
    required this.totalPages,
  });

  factory OrderPageInfo.fromJson(Map<String, dynamic> json) {
    return OrderPageInfo(
      size: json['size'] ?? 0,
      number: json['number'] ?? 0,
      totalElements: json['totalElements'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
    );
  }
}
