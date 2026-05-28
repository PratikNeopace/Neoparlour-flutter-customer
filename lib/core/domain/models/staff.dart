class Staff {
  final int id;
  final String name;
  final String phone;
  final String email;
  final String staffStatus;
  final int salonId;
  final String salonName;
  final String? address;
  final double? rating;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? image;
  final bool active;
  final String? imageAsBase64;
  final bool? inactive;
  final bool? busy;
  final int? userId;
  final String? gender;

  Staff({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.staffStatus,
    required this.salonId,
    required this.salonName,
    this.address,
    this.rating,
    required this.createdAt,
    this.updatedAt,
    this.image,
    required this.active,
    this.imageAsBase64,
    this.inactive,
    this.busy,
    this.userId,
    this.gender,
  });

  factory Staff.fromJson(Map<String, dynamic> json) {
    // Handle slim /available-staff response: { staffId, staffName, phone, imageBase64, rating }
    final isSlimResponse = json.containsKey('staffId') && !json.containsKey('id');
    return Staff(
      id: isSlimResponse ? (json['staffId'] as int) : (json['id'] as int),
      name: isSlimResponse ? (json['staffName'] as String) : (json['name'] as String),
      phone: (json['phone'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      staffStatus: (json['staffStatus'] as String?) ?? 'ACTIVE',
      salonId: (json['salonId'] as int?) ?? 0,
      salonName: (json['salonName'] as String?) ?? '',
      address: json['address'] as String?,
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
      image: json['image'] as String?,
      active: (json['active'] as bool?) ?? true,
      imageAsBase64: (json['imageBase64'] as String?) ?? (json['imageAsBase64'] as String?),
      inactive: json['inactive'] as bool?,
      busy: json['busy'] as bool?,
      userId: json['userId'] as int?,
      gender: json['gender'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'staffStatus': staffStatus,
      'salonId': salonId,
      'salonName': salonName,
      'address': address,
      'rating': rating,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'image': image,
      'active': active,
      'imageAsBase64': imageAsBase64,
      'inactive': inactive,
      'busy': busy,
      'userId': userId,
      'gender': gender,
    };
  }
}
