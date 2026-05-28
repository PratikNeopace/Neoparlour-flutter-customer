class PackageModel {
  final int id;
  final String name;
  final double packagePrice;
  final bool active;
  final List<PackageServiceItem> services;

  PackageModel({
    required this.id,
    required this.name,
    required this.packagePrice,
    required this.active,
    required this.services,
  });

  factory PackageModel.fromJson(Map<String, dynamic> json) {
    return PackageModel(
      id: json['id'] as int,
      name: json['name'] as String,
      packagePrice: (json['packagePrice'] as num).toDouble(),
      active: json['active'] as bool,
      services: (json['services'] as List<dynamic>)
          .map((s) => PackageServiceItem.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'packagePrice': packagePrice,
      'active': active,
      'services': services.map((s) => s.toJson()).toList(),
    };
  }
}

class PackageServiceItem {
  final String name;
  final int id;

  PackageServiceItem({
    required this.name,
    required this.id,
  });

  factory PackageServiceItem.fromJson(Map<String, dynamic> json) {
    return PackageServiceItem(
      name: json['name'] as String,
      id: json['id'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'id': id,
    };
  }
}
