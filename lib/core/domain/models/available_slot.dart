class AvailableSlot {
  final DateTime startTime;
  final String displayTime;

  AvailableSlot({
    required this.startTime,
    required this.displayTime,
  });

  factory AvailableSlot.fromJson(Map<String, dynamic> json) {
    return AvailableSlot(
      startTime: DateTime.parse(json['startTime']).toLocal(),
      displayTime: json['displayTime'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime.toIso8601String(),
      'displayTime': displayTime,
    };
  }
}
