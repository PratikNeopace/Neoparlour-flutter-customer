class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final double discountPrice;
  final String category;
  final String? imageBase64;
  final List<String> additionalImagesBase64;
  final int stock;
  final int restockLevel;
  final int salonId;
  final bool active;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.discountPrice,
    required this.category,
    this.imageBase64,
    required this.additionalImagesBase64,
    required this.stock,
    required this.restockLevel,
    required this.salonId,
    required this.active,
    required this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      discountPrice: (json['discountPrice'] ?? 0).toDouble(),
      category: json['category'] ?? '',
      imageBase64: json['imageBase64'],
      additionalImagesBase64: List<String>.from(json['additionalImagesBase64'] ?? []),
      stock: json['stock'] ?? 0,
      restockLevel: json['restockLevel'] ?? 0,
      salonId: json['salonId'] ?? 0,
      active: json['active'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'discountPrice': discountPrice,
      'category': category,
      'imageBase64': imageBase64,
      'additionalImagesBase64': additionalImagesBase64,
      'stock': stock,
      'restockLevel': restockLevel,
      'salonId': salonId,
      'active': active,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
