class AvailableSlot {
  final DateTime startTime;
  final String displayTime;
  final String? discountMessage;
  final double? discountPercentage;
  final bool busy;

  AvailableSlot({
    required this.startTime,
    required this.displayTime,
    this.discountMessage,
    this.discountPercentage,
    this.busy = false,
  });

  factory AvailableSlot.fromJson(Map<String, dynamic> json) {
    return AvailableSlot(
      startTime: DateTime.parse(json['startTime']).toLocal(),
      displayTime: json['displayTime'],
      discountMessage: json['discountMessage'],
      discountPercentage: (json['discountPercentage'] as num?)?.toDouble(),
      busy: json['busy'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime.toIso8601String(),
      'displayTime': displayTime,
      'discountMessage': discountMessage,
      'discountPercentage': discountPercentage,
      'busy': busy,
    };
  }
}
