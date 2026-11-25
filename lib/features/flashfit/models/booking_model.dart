class FlashFitBooking {
  final String id;
  final String userId;
  final String gymId;
  final String slotId;
  final String bookingDate; // yyyy-MM-dd
  final String startTime;
  final String endTime;
  final String sessionType;
  final String status; // 'upcoming', 'completed', 'cancelled'
  final String bookingCode;
  final String gymName;
  final String gymAddress;
  final String? gymImage;
  final DateTime createdAt;
  final DateTime? cancelledAt;
  final DateTime? checkInAt;

  const FlashFitBooking({
    required this.id,
    required this.userId,
    required this.gymId,
    required this.slotId,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    required this.sessionType,
    required this.status,
    required this.bookingCode,
    required this.gymName,
    required this.gymAddress,
    this.gymImage,
    required this.createdAt,
    this.cancelledAt,
    this.checkInAt,
  });

  bool get isUpcoming => status.toLowerCase() == 'upcoming';
  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isCancelled => status.toLowerCase() == 'cancelled';

  factory FlashFitBooking.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val is String) {
        return DateTime.tryParse(val) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return FlashFitBooking(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      gymId: map['gym_id']?.toString() ?? '',
      slotId: map['slot_id']?.toString() ?? '',
      bookingDate: map['booking_date']?.toString() ?? '',
      startTime: map['start_time'] ?? '',
      endTime: map['end_time'] ?? '',
      sessionType: map['session_type'] ?? 'General Gym & Cardio',
      status: map['status'] ?? 'upcoming',
      bookingCode: map['booking_code'] ?? 'FF-00000',
      gymName: map['gym_name'] ?? 'Partner Gym',
      gymAddress: map['gym_address'] ?? '',
      gymImage: map['gym_image'],
      createdAt: parseDate(map['created_at']),
      cancelledAt: map['cancelled_at'] != null ? parseDate(map['cancelled_at']) : null,
      checkInAt: map['check_in_at'] != null ? parseDate(map['check_in_at']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'gym_id': gymId,
      'slot_id': slotId,
      'booking_date': bookingDate,
      'start_time': startTime,
      'end_time': endTime,
      'session_type': sessionType,
      'status': status,
      'booking_code': bookingCode,
      'gym_name': gymName,
      'gym_address': gymAddress,
      'gym_image': gymImage,
      'created_at': createdAt.toIso8601String(),
      'cancelled_at': cancelledAt?.toIso8601String(),
      'check_in_at': checkInAt?.toIso8601String(),
    };
  }

  FlashFitBooking copyWith({
    String? status,
    DateTime? cancelledAt,
    DateTime? checkInAt,
  }) {
    return FlashFitBooking(
      id: id,
      userId: userId,
      gymId: gymId,
      slotId: slotId,
      bookingDate: bookingDate,
      startTime: startTime,
      endTime: endTime,
      sessionType: sessionType,
      status: status ?? this.status,
      bookingCode: bookingCode,
      gymName: gymName,
      gymAddress: gymAddress,
      gymImage: gymImage,
      createdAt: createdAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      checkInAt: checkInAt ?? this.checkInAt,
    );
  }
}
