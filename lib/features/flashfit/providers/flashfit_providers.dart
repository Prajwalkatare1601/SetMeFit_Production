import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/gym_model.dart';
import '../models/slot_model.dart';
import '../models/booking_model.dart';
import '../models/subscription_model.dart';
import '../services/flashfit_service.dart';

// City Filter Provider
final flashFitCityProvider = StateProvider<String>((ref) => 'Bangalore');

// Search Query Provider
final flashFitSearchQueryProvider = StateProvider<String>((ref) => '');

// Facility Category Filter Provider
final flashFitFacilityFilterProvider = StateProvider<String>((ref) => 'All');

// Selected Booking Tab Provider: 'upcoming', 'completed', 'cancelled'
final flashFitBookingsTabProvider = StateProvider<String>((ref) => 'upcoming');

// Gyms List Provider
final flashFitGymsProvider = FutureProvider<List<FlashFitGym>>((ref) async {
  final city = ref.watch(flashFitCityProvider);
  final search = ref.watch(flashFitSearchQueryProvider);
  final facility = ref.watch(flashFitFacilityFilterProvider);

  return await FlashFitService().getGyms(
    city: city,
    searchQuery: search,
    facilityFilter: facility,
  );
});

// Single Gym Provider
final flashFitGymDetailsProvider =
    FutureProvider.family<FlashFitGym?, String>((ref, gymId) async {
  return await FlashFitService().getGymById(gymId);
});

// Slot Query Parameters Class
class SlotQueryParams {
  final String gymId;
  final String date;

  const SlotQueryParams({required this.gymId, required this.date});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SlotQueryParams &&
          runtimeType == other.runtimeType &&
          gymId == other.gymId &&
          date == other.date;

  @override
  int get hashCode => gymId.hashCode ^ date.hashCode;
}

// Slots For Gym on Date Provider
final flashFitSlotsProvider =
    FutureProvider.family<List<WorkoutSlot>, SlotQueryParams>((ref, params) async {
  return await FlashFitService().getSlotsForGym(params.gymId, params.date);
});

// User Subscription Provider
final flashFitSubscriptionProvider =
    FutureProvider<FlashFitSubscription>((ref) async {
  final userId = FlashFitService().currentUserId;
  return await FlashFitService().getUserSubscription(userId);
});

// User Bookings Provider
final flashFitBookingsProvider =
    FutureProvider<List<FlashFitBooking>>((ref) async {
  final userId = FlashFitService().currentUserId;
  return await FlashFitService().getUserBookings(userId);
});
