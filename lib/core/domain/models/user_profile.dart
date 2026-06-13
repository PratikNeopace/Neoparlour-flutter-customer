class UserProfile {
  final int id;
  final String name;
  final String phone;
  final String email;
  final String? salonName;
  final String? dbName;
  final String? address;
  final String? birthdate;
  final double? latitude;
  final double? longitude;
  final String role;
  final bool active;
  final String? imageUrl;
  final String? imageBase64;
  final String? fcmToken;
  final bool? tncAccepted;
  final String? tncAcceptedAt;
  final String? tncVersion;

  UserProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    this.salonName,
    this.dbName,
    this.address,
    this.birthdate,
    this.latitude,
    this.longitude,
    required this.role,
    required this.active,
    this.imageUrl,
    this.imageBase64,
    this.fcmToken,
    this.tncAccepted,
    this.tncAcceptedAt,
    this.tncVersion,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      name: json['fullName'] ?? json['name'] ?? '',
      phone: json['mobile'] ?? json['phone'] ?? '',
      email: json['email'] ?? '',
      salonName: json['salonName'],
      dbName: json['dbName'],
      address: json['address'],
      birthdate: json['birthDate'] ?? json['birthdate'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      role: json['role'] ?? 'CUSTOMER', // Default to customer if missing
      active: json['active'] ?? false,
      imageUrl: json['imageUrl'] ?? json['imageBase64'],
      imageBase64: json['imageBase64'],
      fcmToken: json['fcmToken'],
      tncAccepted: json['tncAccepted'],
      tncAcceptedAt: json['tncAcceptedAt'],
      tncVersion: json['tncVersion'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': name,
      'mobile': phone,
      'email': email,
      'salonName': salonName,
      'dbName': dbName,
      'address': address,
      'birthDate': birthdate,
      'latitude': latitude,
      'longitude': longitude,
      'role': role,
      'active': active,
      'imageUrl': imageUrl,
      'imageBase64': imageBase64,
      'fcmToken': fcmToken,
      'tncAccepted': tncAccepted,
      'tncAcceptedAt': tncAcceptedAt,
      'tncVersion': tncVersion,
    };
  }
}
