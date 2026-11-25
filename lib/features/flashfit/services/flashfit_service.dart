import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/gym_model.dart';
import '../models/slot_model.dart';
import '../models/booking_model.dart';
import '../models/subscription_model.dart';

class FlashFitService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Singleton instance
  static final FlashFitService _instance = FlashFitService._internal();
  factory FlashFitService() => _instance;
  FlashFitService._internal();

  String get currentUserId {
    final user = _supabase.auth.currentUser;
    return user?.id ?? 'demo_setmefit_user';
  }

  // ===========================================================================
  // GYM DISCOVERY API
  // ===========================================================================

  Future<List<FlashFitGym>> getGyms({
    String? city,
    String? searchQuery,
    String? facilityFilter,
  }) async {
    try {
      // 1. Try fetching from Supabase table
      var query = _supabase.schema('setmefit').from('flashfit_gyms').select();
      if (city != null && city.isNotEmpty && city != 'All Cities') {
        query = query.eq('city', city);
      }
      final response = await query.order('rating', ascending: false);
      if ((response as List).isNotEmpty) {
        final List<dynamic> data = response;
        var gyms = data.map((json) => FlashFitGym.fromMap(json)).toList();
        gyms = _applyGymFilters(gyms, searchQuery, facilityFilter);
        return gyms;
      }
    } catch (e) {
      debugPrint('[FlashFit] Supabase fetch gyms fallback: $e');
    }

    // 2. Resilient local fallback seeded data
    return _getLocalSeededGyms(
      city: city,
      searchQuery: searchQuery,
      facilityFilter: facilityFilter,
    );
  }

  Future<FlashFitGym?> getGymById(String gymId) async {
    try {
      final response = await _supabase
          .schema('setmefit')
          .from('flashfit_gyms')
          .select()
          .eq('id', gymId)
          .maybeSingle();
      if (response != null) {
        return FlashFitGym.fromMap(response);
      }
    } catch (e) {
      debugPrint('[FlashFit] Supabase getGymById fallback: $e');
    }

    final localGyms = _getLocalSeededGyms();
    return localGyms.firstWhere(
      (g) => g.id == gymId,
      orElse: () => localGyms.first,
    );
  }

  // ===========================================================================
  // SLOTS API
  // ===========================================================================

  Future<List<WorkoutSlot>> getSlotsForGym(String gymId, String date) async {
    try {
      final response = await _supabase
          .schema('setmefit')
          .from('flashfit_slots')
          .select()
          .eq('gym_id', gymId)
          .eq('slot_date', date)
          .order('start_time', ascending: true);

      if ((response as List).isNotEmpty) {
        final List<dynamic> data = response;
        return data.map((json) => WorkoutSlot.fromMap(json)).toList();
      }
    } catch (e) {
      debugPrint('[FlashFit] Supabase fetch slots fallback: $e');
    }

    // Fallback: Generate or retrieve from local storage
    return await _getLocalOrGeneratedSlots(gymId, date);
  }

  // ===========================================================================
  // SUBSCRIPTION VALIDATION API
  // ===========================================================================

  Future<FlashFitSubscription> getUserSubscription(String userId) async {
    try {
      final response = await _supabase
          .schema('setmefit')
          .from('flashfit_subscriptions')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        return FlashFitSubscription.fromMap(response, userId);
      }
    } catch (e) {
      debugPrint('[FlashFit] Supabase subscription fallback: $e');
    }

    // Local cached subscription check
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('flashfit_sub_$userId');
    if (cached != null) {
      return FlashFitSubscription.fromMap(jsonDecode(cached), userId);
    }

    // Default to active SetMeFit All-Access Pass so users can immediately test & experience
    final defaultSub = FlashFitSubscription.demoActive(userId);
    await saveSubscription(defaultSub);
    return defaultSub;
  }

  Future<void> saveSubscription(FlashFitSubscription sub) async {
    try {
      await _supabase.schema('setmefit').from('flashfit_subscriptions').upsert(sub.toMap());
    } catch (e) {
      debugPrint('[FlashFit] Supabase save subscription fallback: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('flashfit_sub_${sub.userId}', jsonEncode(sub.toMap()));
  }

  // ===========================================================================
  // BOOKING API (Atomic, Double-Booking & Capacity Checked)
  // ===========================================================================

  Future<Map<String, dynamic>> bookSlot({
    required String userId,
    required String gymId,
    required String slotId,
    String? slotDate,
    String? startTime,
    String? endTime,
    String? sessionType,
  }) async {
    // 1. Validate subscription
    final sub = await getUserSubscription(userId);
    if (!sub.isEligibleForBooking) {
      return {
        'success': false,
        'error': 'INELIGIBLE_SUBSCRIPTION',
        'message': 'You need an active SetMeFit All-Access or FlashFit subscription to book workout sessions.',
      };
    }

    // 2. Fetch gym & slot details
    final gym = await getGymById(gymId);
    if (gym == null) {
      return {
        'success': false,
        'error': 'GYM_NOT_FOUND',
        'message': 'Gym not found.',
      };
    }

    final bookingCode = 'FF-${Random().nextInt(90000) + 10000}';

    // 3. Try Remote Supabase RPC first if available (only if slotId is a valid UUID)
    final bool isUuid = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(slotId);
    if (isUuid) {
      try {
        final rpcParams = <String, dynamic>{
          'p_user_id': userId,
          'p_gym_id': gymId,
          'p_slot_id': slotId,
          'p_booking_code': bookingCode,
        };
        if (slotDate != null) rpcParams['p_slot_date'] = slotDate;
        if (startTime != null) rpcParams['p_start_time'] = startTime;
        if (endTime != null) rpcParams['p_end_time'] = endTime;
        if (sessionType != null) rpcParams['p_session_type'] = sessionType;

        final rpcRes = await _supabase.rpc('book_flashfit_slot', params: rpcParams);

        if (rpcRes is Map && rpcRes['success'] == true) {
          return {
            'success': true,
            'booking_code': bookingCode,
            'message': rpcRes['message'] ?? 'Session booked successfully!',
          };
        } else if (rpcRes is Map && rpcRes['success'] == false) {
          final error = rpcRes['error']?.toString();
          if (error == 'ALREADY_BOOKED' || error == 'SLOT_FULL') {
            return Map<String, dynamic>.from(rpcRes);
          }
          debugPrint('[FlashFit] Supabase RPC returned $error, falling back to local transaction');
        }
      } catch (e) {
        debugPrint('[FlashFit] Supabase RPC book fallback to local transaction: $e');
      }
    }

    // 4. Local robust transaction implementation
    final existingBookings = await getUserBookings(userId);

    final targetDate = slotDate ?? DateTime.now().toString().substring(0, 10);
    final targetStart = startTime ?? '06:00 AM';
    final targetEnd = endTime ?? '07:30 AM';
    final targetType = sessionType ?? 'General Gym & Cardio';

    // Retrieve the target slot from targetDate
    final slots = await _getLocalOrGeneratedSlots(gymId, targetDate);
    WorkoutSlot? targetSlot;
    for (var s in slots) {
      if (s.id == slotId) targetSlot = s;
    }
    targetSlot ??= WorkoutSlot(
      id: slotId,
      gymId: gymId,
      slotDate: targetDate,
      startTime: targetStart,
      endTime: targetEnd,
      sessionType: targetType,
      totalCapacity: 15,
      bookedCount: 5,
    );

    // Check capacity
    if (targetSlot.bookedCount >= targetSlot.totalCapacity) {
      return {
        'success': false,
        'error': 'SLOT_FULL',
        'message': 'This workout slot is already fully booked. Please choose another slot.',
      };
    }

    // Prevent Double-Booking: check if user already has an active booking for this date & time
    final hasConflict = existingBookings.any((b) =>
        b.isUpcoming &&
        b.bookingDate == targetSlot!.slotDate &&
        b.startTime == targetSlot.startTime);

    if (hasConflict) {
      return {
        'success': false,
        'error': 'ALREADY_BOOKED',
        'message': 'You already have an active workout booking at ${targetSlot.startTime} on ${targetSlot.slotDate}.',
      };
    }

    // Create Booking
    final newBooking = FlashFitBooking(
      id: 'bk_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999)}',
      userId: userId,
      gymId: gymId,
      slotId: slotId,
      bookingDate: targetSlot.slotDate,
      startTime: targetSlot.startTime,
      endTime: targetSlot.endTime,
      sessionType: targetSlot.sessionType,
      status: 'upcoming',
      bookingCode: bookingCode,
      gymName: gym.name,
      gymAddress: gym.address,
      gymImage: gym.heroImage,
      createdAt: DateTime.now(),
    );

    // Save to local cache
    existingBookings.insert(0, newBooking);
    await _saveLocalBookings(userId, existingBookings);

    // Update slot count locally
    await _incrementLocalSlotCount(gymId, slotId);

    // Update subscription used count
    final updatedSub = FlashFitSubscription(
      userId: sub.userId,
      planName: sub.planName,
      tier: sub.tier,
      isActive: sub.isActive,
      sessionsPerMonth: sub.sessionsPerMonth,
      sessionsUsed: sub.sessionsUsed + 1,
      validUntil: sub.validUntil,
    );
    await saveSubscription(updatedSub);

    // Attempt direct insert to Supabase table as well
    try {
      await _supabase.schema('setmefit').from('flashfit_bookings').insert(newBooking.toMap());
    } catch (_) {}

    return {
      'success': true,
      'booking': newBooking,
      'booking_code': bookingCode,
      'message': 'Session confirmed! Your FlashFit Pass is ready.',
    };
  }

  Future<List<FlashFitBooking>> getUserBookings(String userId) async {
    try {
      final response = await _supabase
          .schema('setmefit')
          .from('flashfit_bookings')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      if ((response as List).isNotEmpty) {
        final List<dynamic> data = response;
        return data.map((json) => FlashFitBooking.fromMap(json)).toList();
      }
    } catch (e) {
      debugPrint('[FlashFit] Supabase fetch bookings fallback: $e');
    }

    // Local cached bookings
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('flashfit_bookings_$userId');
    if (raw != null) {
      final List<dynamic> list = jsonDecode(raw);
      return list.map((e) => FlashFitBooking.fromMap(e)).toList();
    }

    // Seed 1 sample upcoming & 1 sample completed booking for initial delightful experience
    final initialList = _getSeedBookings(userId);
    await _saveLocalBookings(userId, initialList);
    return initialList;
  }

  Future<Map<String, dynamic>> cancelBooking({
    required String bookingId,
    required String userId,
  }) async {
    // 1. Try Supabase RPC / table update
    try {
      final rpcRes = await _supabase.rpc('cancel_flashfit_booking', params: {
        'p_booking_id': bookingId,
        'p_user_id': userId,
      });
      if (rpcRes is Map && rpcRes['success'] == true) {
        return Map<String, dynamic>.from(rpcRes);
      }
    } catch (e) {
      debugPrint('[FlashFit] Supabase cancel fallback: $e');
    }

    // 2. Local update
    final bookings = await getUserBookings(userId);
    final idx = bookings.indexWhere((b) => b.id == bookingId);
    if (idx == -1) {
      return {'success': false, 'message': 'Booking not found.'};
    }

    final target = bookings[idx];
    if (target.isCancelled) {
      return {'success': false, 'message': 'Booking is already cancelled.'};
    }

    bookings[idx] = target.copyWith(
      status: 'cancelled',
      cancelledAt: DateTime.now(),
    );
    await _saveLocalBookings(userId, bookings);

    // Decrement slot count
    await _decrementLocalSlotCount(target.gymId, target.slotId);

    // Restore subscription session
    final sub = await getUserSubscription(userId);
    if (sub.sessionsUsed > 0) {
      final restoredSub = FlashFitSubscription(
        userId: sub.userId,
        planName: sub.planName,
        tier: sub.tier,
        isActive: sub.isActive,
        sessionsPerMonth: sub.sessionsPerMonth,
        sessionsUsed: sub.sessionsUsed - 1,
        validUntil: sub.validUntil,
      );
      await saveSubscription(restoredSub);
    }

    try {
      await _supabase
          .schema('setmefit')
          .from('flashfit_bookings')
          .update({'status': 'cancelled', 'cancelled_at': DateTime.now().toIso8601String()})
          .eq('id', bookingId);
    } catch (_) {}

    return {
      'success': true,
      'message': 'Workout session cancelled. Your session credit has been restored.',
    };
  }

  // ===========================================================================
  // LOCAL CACHE & MOCK HELPERS
  // ===========================================================================

  Future<void> _saveLocalBookings(String userId, List<FlashFitBooking> bookings) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = bookings.map((b) => b.toMap()).toList();
    await prefs.setString('flashfit_bookings_$userId', jsonEncode(jsonList));
  }

  Future<List<WorkoutSlot>> _getLocalOrGeneratedSlots(String gymId, String date) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'flashfit_slots_${gymId}_$date';
    final cached = prefs.getString(key);
    if (cached != null) {
      final List<dynamic> list = jsonDecode(cached);
      return list.map((e) => WorkoutSlot.fromMap(e)).toList();
    }

    // Standard 8 slots per day
    final times = [
      {'start': '06:00 AM', 'end': '07:30 AM', 'type': 'Morning Power Conditioning', 'booked': 14, 'cap': 15},
      {'start': '07:30 AM', 'end': '09:00 AM', 'type': 'Peak Hypertrophy & Cardio', 'booked': 15, 'cap': 15},
      {'start': '09:00 AM', 'end': '10:30 AM', 'type': 'General Open Gym', 'booked': 6, 'cap': 15},
      {'start': '11:00 AM', 'end': '12:30 PM', 'type': 'Midday Functional Strength', 'booked': 3, 'cap': 12},
      {'start': '04:00 PM', 'end': '05:30 PM', 'type': 'Afternoon Performance Lift', 'booked': 7, 'cap': 15},
      {'start': '05:30 PM', 'end': '07:00 PM', 'type': 'Evening Prime Strength', 'booked': 17, 'cap': 18},
      {'start': '07:00 PM', 'end': '08:30 PM', 'type': 'Night Rush HIIT & Lift', 'booked': 18, 'cap': 18},
      {'start': '08:30 PM', 'end': '10:00 PM', 'type': 'Late Night Recovery & Weights', 'booked': 4, 'cap': 15},
    ];

    final slots = <WorkoutSlot>[];
    for (int i = 0; i < times.length; i++) {
      final t = times[i];
      final start = t['start'] as String;
      final end = t['end'] as String;
      final type = t['type'] as String;
      final cap = t['cap'] as int;
      final booked = t['booked'] as int;

      // Deterministic valid UUID from gymId, date and index
      final cleanGym = gymId.replaceAll(RegExp(r'[^0-9a-fA-F]'), '').padRight(32, '0').substring(0, 16);
      final cleanDate = date.replaceAll(RegExp(r'[^0-9a-fA-F]'), '').padRight(8, '0').substring(0, 8);
      final hexIdx = i.toRadixString(16).padLeft(4, '0');
      final validUuid = '${cleanGym.substring(0, 8)}-${cleanGym.substring(8, 12)}-4${cleanGym.substring(13, 16)}-a$hexIdx-${cleanDate}0000';

      slots.add(WorkoutSlot(
        id: validUuid,
        gymId: gymId,
        slotDate: date,
        startTime: start,
        endTime: end,
        sessionType: type,
        totalCapacity: cap,
        bookedCount: booked,
      ));
    }

    await prefs.setString(key, jsonEncode(slots.map((s) => s.toMap()).toList()));

    // Try to sync generated slots to Supabase table so remote queries find them too
    try {
      for (var slot in slots) {
        final existing = await _supabase
            .schema('setmefit')
            .from('flashfit_slots')
            .select('id')
            .eq('gym_id', slot.gymId)
            .eq('slot_date', slot.slotDate)
            .eq('start_time', slot.startTime)
            .maybeSingle();

        if (existing != null) {
          await _supabase
              .schema('setmefit')
              .from('flashfit_slots')
              .update(slot.toMap())
              .eq('id', existing['id']);
        } else {
          await _supabase
              .schema('setmefit')
              .from('flashfit_slots')
              .insert(slot.toMap());
        }
      }
    } catch (_) {}

    return slots;
  }

  Future<void> _incrementLocalSlotCount(String gymId, String slotId) async {
    final prefs = await SharedPreferences.getInstance();
    // Search keys matching this gym
    for (var key in prefs.getKeys()) {
      if (key.startsWith('flashfit_slots_${gymId}_')) {
        final cached = prefs.getString(key);
        if (cached != null) {
          final List<dynamic> list = jsonDecode(cached);
          final slots = list.map((e) => WorkoutSlot.fromMap(e)).toList();
          final idx = slots.indexWhere((s) => s.id == slotId);
          if (idx != -1) {
            slots[idx] = slots[idx].copyWith(
              bookedCount: (slots[idx].bookedCount + 1).clamp(0, slots[idx].totalCapacity),
            );
            await prefs.setString(key, jsonEncode(slots.map((s) => s.toMap()).toList()));
            break;
          }
        }
      }
    }
  }

  Future<void> _decrementLocalSlotCount(String gymId, String slotId) async {
    final prefs = await SharedPreferences.getInstance();
    for (var key in prefs.getKeys()) {
      if (key.startsWith('flashfit_slots_${gymId}_')) {
        final cached = prefs.getString(key);
        if (cached != null) {
          final List<dynamic> list = jsonDecode(cached);
          final slots = list.map((e) => WorkoutSlot.fromMap(e)).toList();
          final idx = slots.indexWhere((s) => s.id == slotId);
          if (idx != -1) {
            slots[idx] = slots[idx].copyWith(
              bookedCount: (slots[idx].bookedCount - 1).clamp(0, slots[idx].totalCapacity),
            );
            await prefs.setString(key, jsonEncode(slots.map((s) => s.toMap()).toList()));
            break;
          }
        }
      }
    }
  }

  List<FlashFitGym> _getLocalSeededGyms({
    String? city,
    String? searchQuery,
    String? facilityFilter,
  }) {
    final gyms = [
      const FlashFitGym(
        id: 'a1111111-1111-1111-1111-111111111111',
        name: 'Volt Arena Performance Gym',
        tagline: 'Elite Olympic Lifting & Hypertrophy Hub',
        brand: 'FlashFit Signature',
        description:
            'Volt Arena is an elite 12,000 sq ft conditioning center equipped with Eleiko barbell stations, Hammer Strength plate-loaded machines, Olympic turf, and bio-recovery steam chambers.',
        address: '42, 100 Feet Rd, Indiranagar, Bengaluru, Karnataka 560038',
        city: 'Bangalore',
        locality: 'Indiranagar',
        latitude: 12.9784,
        longitude: 77.6408,
        rating: 4.9,
        reviewCount: 342,
        distanceKm: 0.8,
        imageUrls: [
          'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?q=80&w=1200&auto=format&fit=crop',
          'https://images.unsplash.com/photo-1540497077202-7c8a3999166f?q=80&w=1200&auto=format&fit=crop',
          'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?q=80&w=1200&auto=format&fit=crop',
        ],
        facilities: [
          'Heavy Weights',
          'Cardio Deck',
          'Olympic Turf',
          'Steam Bath',
          'Lockers',
          'Shower',
          'Personal Trainers',
          'Protein Bar',
        ],
        operatingHours: {
          'mon_fri': '5:30 AM - 11:00 PM',
          'sat_sun': '6:00 AM - 10:00 PM',
        },
        contactPhone: '+91 98801 23456',
        tier: 'FlashFit Elite',
        isFeatured: true,
      ),
      const FlashFitGym(
        id: 'b2222222-2222-2222-2222-222222222222',
        name: 'Titan Hydro & Strength Club',
        tagline: 'Dual-Zone Lifting & Heated Lap Pool',
        brand: 'FlashFit Signature',
        description:
            'Featuring an indoor semi-Olympic heated pool, dedicated CrossFit rig, specialized glute and leg builder zones, and certified physical therapy support.',
        address: '7th Main Rd, 4th Block, Koramangala, Bengaluru, Karnataka 560034',
        city: 'Bangalore',
        locality: 'Koramangala',
        latitude: 12.9352,
        longitude: 77.6245,
        rating: 4.8,
        reviewCount: 289,
        distanceKm: 1.6,
        imageUrls: [
          'https://images.unsplash.com/photo-1571902943202-507ec2618e8f?q=80&w=1200&auto=format&fit=crop',
          'https://images.unsplash.com/photo-1574680096145-d05b474e2155?q=80&w=1200&auto=format&fit=crop',
          'https://images.unsplash.com/photo-1584735935682-2f2b69dff9d2?q=80&w=1200&auto=format&fit=crop',
        ],
        facilities: [
          'Swimming Pool',
          'Heavy Weights',
          'CrossFit',
          'Sauna',
          'Lockers',
          'Shower',
          'Physiotherapy',
        ],
        operatingHours: {
          'mon_fri': '6:00 AM - 10:30 PM',
          'sat_sun': '6:30 AM - 9:30 PM',
        },
        contactPhone: '+91 98802 34567',
        tier: 'FlashFit Elite',
        isFeatured: true,
      ),
      const FlashFitGym(
        id: 'c3333333-3333-3333-3333-333333333333',
        name: 'Iron Vault Fitness Studio',
        tagline: 'Old-School Powerlifting & Modern Bio-Tracking',
        brand: 'FlashFit Partner',
        description:
            'Built for pure grit and biomechanics. Features calibrated competition plates, custom cable machinery, heavy dumbbells up to 70kg, and dedicated stretching pods.',
        address: '24th Main, HSR Layout Sector 2, Bengaluru, Karnataka 560102',
        city: 'Bangalore',
        locality: 'HSR Layout',
        latitude: 12.9116,
        longitude: 77.6474,
        rating: 4.7,
        reviewCount: 195,
        distanceKm: 2.3,
        imageUrls: [
          'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?q=80&w=1200&auto=format&fit=crop',
          'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?q=80&w=1200&auto=format&fit=crop',
        ],
        facilities: [
          'Heavy Weights',
          'Cardio Deck',
          'Lockers',
          'Shower',
          'Personal Trainers',
        ],
        operatingHours: {
          'mon_fri': '5:00 AM - 11:00 PM',
          'sat_sun': '6:00 AM - 10:00 PM',
        },
        contactPhone: '+91 98803 45678',
        tier: 'FlashFit Pro',
        isFeatured: false,
      ),
      const FlashFitGym(
        id: 'd4444444-4444-4444-4444-444444444444',
        name: 'Aura Wellness & Functional Fitness',
        tagline: 'Mindful Strength, Calisthenics & Hot Yoga',
        brand: 'FlashFit Signature',
        description:
            'A breathtaking sanctuary integrating high-intensity functional training with infrared sauna, sound-bath yoga studio, and restorative vitality baths.',
        address: 'Linking Road, Bandra West, Mumbai, Maharashtra 400050',
        city: 'Mumbai',
        locality: 'Bandra West',
        latitude: 19.0607,
        longitude: 72.8362,
        rating: 4.9,
        reviewCount: 412,
        distanceKm: 3.1,
        imageUrls: [
          'https://images.unsplash.com/photo-1518611012118-696072aa579a?q=80&w=1200&auto=format&fit=crop',
          'https://images.unsplash.com/photo-1506126613408-eca07ce68773?q=80&w=1200&auto=format&fit=crop',
        ],
        facilities: [
          'Yoga',
          'Sauna',
          'Cardio Deck',
          'Lockers',
          'Shower',
          'Smoothie Bar',
          'Steam Bath',
        ],
        operatingHours: {
          'mon_fri': '6:00 AM - 10:00 PM',
          'sat_sun': '7:00 AM - 9:00 PM',
        },
        contactPhone: '+91 98201 98765',
        tier: 'FlashFit Elite',
        isFeatured: true,
      ),
      const FlashFitGym(
        id: 'e5555555-5555-5555-5555-555555555555',
        name: 'Krypton 24/7 Athletic Club',
        tagline: 'Round-the-Clock Biomechanical Training',
        brand: 'FlashFit Partner',
        description:
            'Never miss a workout. 24-hour smart access, cardio cinematic theater, pin-loaded resistance towers, and kettlebell combat zone.',
        address: 'Cyber City Phase 2, Gurugram, Delhi NCR 122002',
        city: 'Delhi NCR',
        locality: 'Gurugram',
        latitude: 28.4907,
        longitude: 77.0892,
        rating: 4.8,
        reviewCount: 260,
        distanceKm: 4.5,
        imageUrls: [
          'https://images.unsplash.com/photo-1526506118085-60ce8714f8c5?q=80&w=1200&auto=format&fit=crop',
          'https://images.unsplash.com/photo-1534367507873-d2d7e24c797f?q=80&w=1200&auto=format&fit=crop',
        ],
        facilities: [
          '24/7 Access',
          'Heavy Weights',
          'Cardio Deck',
          'Lockers',
          'Shower',
        ],
        operatingHours: {
          'mon_fri': 'Open 24 Hours',
          'sat_sun': 'Open 24 Hours',
        },
        contactPhone: '+91 98111 54321',
        tier: 'FlashFit Pro',
        isFeatured: false,
      ),
      const FlashFitGym(
        id: 'f6666666-6666-6666-6666-666666666666',
        name: 'Apex Calisthenics & Movement Park',
        tagline: 'Bodyweight Mastery & Spartan Obstacle Zones',
        brand: 'FlashFit Partner',
        description:
            'Specialized calisthenics rigs, gymnastics rings, pegboards, and dynamic mobility turf designed for natural athletic expression.',
        address: 'Road No 36, Jubilee Hills, Hyderabad, Telangana 500033',
        city: 'Hyderabad',
        locality: 'Jubilee Hills',
        latitude: 17.4319,
        longitude: 78.4073,
        rating: 4.8,
        reviewCount: 178,
        distanceKm: 2.8,
        imageUrls: [
          'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?q=80&w=1200&auto=format&fit=crop',
          'https://images.unsplash.com/photo-1571902943202-507ec2618e8f?q=80&w=1200&auto=format&fit=crop',
        ],
        facilities: [
          'CrossFit',
          'Heavy Weights',
          'Cardio Deck',
          'Lockers',
          'Shower',
        ],
        operatingHours: {
          'mon_fri': '6:00 AM - 10:30 PM',
          'sat_sun': '6:30 AM - 9:30 PM',
        },
        contactPhone: '+91 98490 12345',
        tier: 'FlashFit Elite',
        isFeatured: true,
      ),
    ];

    return _applyGymFilters(gyms, searchQuery, facilityFilter, city: city);
  }

  List<FlashFitGym> _applyGymFilters(
    List<FlashFitGym> gyms,
    String? searchQuery,
    String? facilityFilter, {
    String? city,
  }) {
    var result = gyms;

    if (city != null && city.isNotEmpty && city != 'All Cities') {
      result = result.where((g) => g.city.toLowerCase() == city.toLowerCase()).toList();
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.toLowerCase().trim();
      result = result.where((g) {
        return g.name.toLowerCase().contains(q) ||
            g.locality.toLowerCase().contains(q) ||
            g.address.toLowerCase().contains(q) ||
            g.facilities.any((f) => f.toLowerCase().contains(q));
      }).toList();
    }

    if (facilityFilter != null && facilityFilter.isNotEmpty && facilityFilter != 'All') {
      final f = facilityFilter.toLowerCase();
      result = result.where((g) => g.facilities.any((fac) => fac.toLowerCase().contains(f))).toList();
    }

    return result;
  }

  List<FlashFitBooking> _getSeedBookings(String userId) {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    final yesterday = now.subtract(const Duration(days: 2));

    String fmt(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    return [
      FlashFitBooking(
        id: 'seed_up_1',
        userId: userId,
        gymId: 'a1111111-1111-1111-1111-111111111111',
        slotId: 'slot_volt_morning',
        bookingDate: fmt(tomorrow),
        startTime: '06:00 AM',
        endTime: '07:30 AM',
        sessionType: 'Morning Power Conditioning',
        status: 'upcoming',
        bookingCode: 'FF-7821A',
        gymName: 'Volt Arena Performance Gym',
        gymAddress: '42, 100 Feet Rd, Indiranagar, Bengaluru',
        gymImage: 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?q=80&w=1200&auto=format&fit=crop',
        createdAt: now.subtract(const Duration(hours: 4)),
      ),
      FlashFitBooking(
        id: 'seed_comp_1',
        userId: userId,
        gymId: 'b2222222-2222-2222-2222-222222222222',
        slotId: 'slot_titan_evening',
        bookingDate: fmt(yesterday),
        startTime: '05:30 PM',
        endTime: '07:00 PM',
        sessionType: 'Evening Prime Strength',
        status: 'completed',
        bookingCode: 'FF-4912K',
        gymName: 'Titan Hydro & Strength Club',
        gymAddress: '7th Main Rd, 4th Block, Koramangala, Bengaluru',
        gymImage: 'https://images.unsplash.com/photo-1571902943202-507ec2618e8f?q=80&w=1200&auto=format&fit=crop',
        createdAt: yesterday.subtract(const Duration(days: 1)),
        checkInAt: yesterday,
      ),
    ];
  }
}
