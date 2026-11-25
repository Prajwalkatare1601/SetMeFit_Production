import 'package:flutter/material.dart';

enum SlotAvailabilityStatus {
  available,
  almostFull,
  fullyBooked,
}

class WorkoutSlot {
  final String id;
  final String gymId;
  final String slotDate; // yyyy-MM-dd
  final String startTime;
  final String endTime;
  final String sessionType;
  final int totalCapacity;
  final int bookedCount;
  final bool isActive;

  const WorkoutSlot({
    required this.id,
    required this.gymId,
    required this.slotDate,
    required this.startTime,
    required this.endTime,
    this.sessionType = 'General Gym & Cardio',
    this.totalCapacity = 15,
    this.bookedCount = 0,
    this.isActive = true,
  });

  int get availableSpots => (totalCapacity - bookedCount).clamp(0, totalCapacity);

  bool get isFullyBooked => availableSpots <= 0;

  bool get isAlmostFull => !isFullyBooked && availableSpots <= 3;

  SlotAvailabilityStatus get availabilityStatus {
    if (isFullyBooked) return SlotAvailabilityStatus.fullyBooked;
    if (isAlmostFull) return SlotAvailabilityStatus.almostFull;
    return SlotAvailabilityStatus.available;
  }

  String get statusLabel {
    if (isFullyBooked) return 'Fully Booked';
    if (isAlmostFull) return 'Almost Full ($availableSpots spots left)';
    return 'Available ($availableSpots spots left)';
  }

  Color get statusColor {
    if (isFullyBooked) return const Color(0xFF6B7280); // Grey
    if (isAlmostFull) return const Color(0xFFF59E0B); // Amber
    return const Color(0xFF10B981); // Emerald Green
  }

  factory WorkoutSlot.fromMap(Map<String, dynamic> map) {
    return WorkoutSlot(
      id: map['id']?.toString() ?? '',
      gymId: map['gym_id']?.toString() ?? '',
      slotDate: map['slot_date']?.toString() ?? '',
      startTime: map['start_time'] ?? '06:00 AM',
      endTime: map['end_time'] ?? '07:30 AM',
      sessionType: map['session_type'] ?? 'General Gym & Cardio',
      totalCapacity: (map['total_capacity'] as num?)?.toInt() ?? 15,
      bookedCount: (map['booked_count'] as num?)?.toInt() ?? 0,
      isActive: map['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'gym_id': gymId,
      'slot_date': slotDate,
      'start_time': startTime,
      'end_time': endTime,
      'session_type': sessionType,
      'total_capacity': totalCapacity,
      'booked_count': bookedCount,
      'is_active': isActive,
    };
  }

  WorkoutSlot copyWith({
    int? bookedCount,
    bool? isActive,
  }) {
    return WorkoutSlot(
      id: id,
      gymId: gymId,
      slotDate: slotDate,
      startTime: startTime,
      endTime: endTime,
      sessionType: sessionType,
      totalCapacity: totalCapacity,
      bookedCount: bookedCount ?? this.bookedCount,
      isActive: isActive ?? this.isActive,
    );
  }
}
