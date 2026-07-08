class NeoService {
  final int id;
  final String name;
  final int duration;
  final double price;
  final String? image;
  final String? pdfUrl;
  final String category;
  final bool active;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int popularityCount;
  final int? displayOrder;

  NeoService({
    required this.id,
    required this.name,
    required this.duration,
    required this.price,
    this.image,
    this.pdfUrl,
    required this.category,
    required this.active,
    required this.createdAt,
    this.updatedAt,
    required this.popularityCount,
    this.displayOrder,
  });

  factory NeoService.fromJson(Map<String, dynamic> json) {
    return NeoService(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      duration: json['duration'] as int? ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      image: json['image'] as String?,
      pdfUrl: json['pdfUrl'] as String?,
      category: json['category'] as String? ?? '',
      active: json['active'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String) 
          : null,
      popularityCount: json['popularityCount'] as int? ?? 0,
      displayOrder: json['displayOrder'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'duration': duration,
      'price': price,
      'image': image,
      'pdfUrl': pdfUrl,
      'category': category,
      'active': active,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'popularityCount': popularityCount,
      'displayOrder': displayOrder,
    };
  }
}
