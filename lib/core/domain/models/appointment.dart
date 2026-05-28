import 'package:intl/intl.dart';

class Appointment {
  final int id;
  final int? customerId;
  final int? staffId;
  final DateTime appointmentAt;
  final String staffName;
  final List<String> serviceNames;
  final String status;
  final double totalPrice;
  final double finalAmount;
  final bool homeService;
  final String? address;

  Appointment({
    required this.id,
    this.customerId,
    this.staffId,
    required this.appointmentAt,
    required this.staffName,
    required this.serviceNames,
    required this.status,
    required this.totalPrice,
    required this.finalAmount,
    required this.homeService,
    this.address,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'],
      customerId: json['customerId'],
      staffId: json['staffId'],
      appointmentAt: DateTime.parse(json['appointmentAt']).toLocal(),
      staffName: json['staffName'] ?? '',
      serviceNames: List<String>.from(json['serviceNames'] ?? []),
      status: json['status'] ?? '',
      totalPrice: (json['totalPrice'] as num).toDouble(),
      finalAmount: (json['finalAmount'] as num).toDouble(),
      homeService: json['homeService'] ?? false,
      address: json['address'],
    );
  }

  String get formattedDateTime {
    return DateFormat('dd-MM-yyyy  HH:mm').format(appointmentAt);
  }

  String get displayMessage {
    switch (status.toLowerCase()) {
      case 'booked':
        return "Your Upcoming appointment is on the way";
      case 'missed':
        return "Your appointment was missed";
      case 'completed':
        return "Your appointment has been completed";
      case 'cancelled':
        return "Your appointment was cancelled";
      default:
        return "You have an appointment update";
    }
  }
}
