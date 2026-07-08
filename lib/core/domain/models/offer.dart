import '../../domain/models/neo_service.dart';

class Offer {
  final int id;
  final String name;
  final String description;
  final String discountType;
  final double discountValue;
  final DateTime validFrom;
  final DateTime validTo;
  final List<NeoService> applicableServices;
  final bool active;
  final int usedCount;
  final int? totalUsageLimit;
  final int? usageLimitPerCustomer;

  Offer({
    required this.id,
    required this.name,
    required this.description,
    required this.discountType,
    required this.discountValue,
    required this.validFrom,
    required this.validTo,
    required this.applicableServices,
    required this.active,
    required this.usedCount,
    this.totalUsageLimit,
    this.usageLimitPerCustomer,
  });

  factory Offer.fromJson(Map<String, dynamic> json) {
    return Offer(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Unnamed Offer',
      description: json['description'] as String? ?? '',
      discountType: json['discountType'] as String? ?? 'PERCENTAGE',
      discountValue: (json['percentage'] as num?)?.toDouble() ?? (json['discountValue'] as num?)?.toDouble() ?? 0.0,
      validFrom: json['validFrom'] != null ? DateTime.parse(json['validFrom'] as String) : DateTime.now(),
      validTo: json['validTo'] != null ? DateTime.parse(json['validTo'] as String) : DateTime.now(),
      applicableServices: ((json['services'] as List<dynamic>?) ?? (json['applicableServices'] as List<dynamic>?))
              ?.map((s) => NeoService.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      active: json['active'] as bool? ?? true,
      usedCount: json['usedCount'] as int? ?? 0,
      totalUsageLimit: json['totalUsageLimit'] as int?,
      usageLimitPerCustomer: json['usageLimitPerCustomer'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'discountType': discountType,
      'discountValue': discountValue,
      'validFrom': validFrom.toIso8601String(),
      'validTo': validTo.toIso8601String(),
      'applicableServices': applicableServices.map((s) => s.toJson()).toList(),
      'active': active,
      'usedCount': usedCount,
      'totalUsageLimit': totalUsageLimit,
      'usageLimitPerCustomer': usageLimitPerCustomer,
    };
  }
}
