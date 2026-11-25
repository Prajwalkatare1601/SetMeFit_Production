import 'package:flutter/material.dart';

class FlashFitGym {
  final String id;
  final String name;
  final String tagline;
  final String brand;
  final String description;
  final String address;
  final String city;
  final String locality;
  final double latitude;
  final double longitude;
  final double rating;
  final int reviewCount;
  final List<String> imageUrls;
  final List<String> facilities;
  final Map<String, String> operatingHours;
  final String contactPhone;
  final String tier;
  final bool isFeatured;
  final double distanceKm;

  const FlashFitGym({
    required this.id,
    required this.name,
    required this.tagline,
    this.brand = 'FlashFit Partner',
    required this.description,
    required this.address,
    required this.city,
    required this.locality,
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.rating = 4.8,
    this.reviewCount = 120,
    this.imageUrls = const [],
    this.facilities = const [],
    this.operatingHours = const {
      'mon_fri': '5:30 AM - 11:00 PM',
      'sat_sun': '6:00 AM - 10:00 PM',
    },
    this.contactPhone = '+91 98800 00000',
    this.tier = 'FlashFit Elite',
    this.isFeatured = false,
    this.distanceKm = 1.4,
  });

  String get heroImage => imageUrls.isNotEmpty
      ? imageUrls.first
      : 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?q=80&w=1200&auto=format&fit=crop';

  factory FlashFitGym.fromMap(Map<String, dynamic> map, {double? fallbackDistance}) {
    List<String> parseStringList(dynamic value) {
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      return [];
    }

    Map<String, String> parseHours(dynamic value) {
      if (value is Map) {
        return value.map((k, v) => MapEntry(k.toString(), v.toString()));
      }
      return {
        'mon_fri': '5:30 AM - 11:00 PM',
        'sat_sun': '6:00 AM - 10:00 PM',
      };
    }

    return FlashFitGym(
      id: map['id']?.toString() ?? '',
      name: map['name'] ?? 'Premier Fitness Studio',
      tagline: map['tagline'] ?? 'State-of-the-art strength & recovery zone',
      brand: map['brand'] ?? 'FlashFit Partner',
      description: map['description'] ?? '',
      address: map['address'] ?? '',
      city: map['city'] ?? 'Bangalore',
      locality: map['locality'] ?? 'City Center',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      rating: (map['rating'] as num?)?.toDouble() ?? 4.8,
      reviewCount: (map['review_count'] as num?)?.toInt() ?? 120,
      imageUrls: parseStringList(map['image_urls']),
      facilities: parseStringList(map['facilities']),
      operatingHours: parseHours(map['operating_hours']),
      contactPhone: map['contact_phone'] ?? '+91 98800 00000',
      tier: map['tier'] ?? 'FlashFit Elite',
      isFeatured: map['is_featured'] ?? false,
      distanceKm: fallbackDistance ?? ((map['distance_km'] as num?)?.toDouble() ?? 1.4),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'tagline': tagline,
      'brand': brand,
      'description': description,
      'address': address,
      'city': city,
      'locality': locality,
      'latitude': latitude,
      'longitude': longitude,
      'rating': rating,
      'review_count': reviewCount,
      'image_urls': imageUrls,
      'facilities': facilities,
      'operating_hours': operatingHours,
      'contact_phone': contactPhone,
      'tier': tier,
      'is_featured': isFeatured,
    };
  }

  static IconData getFacilityIcon(String facility) {
    final lower = facility.toLowerCase();
    if (lower.contains('weight') || lower.contains('strength')) {
      return Icons.fitness_center_rounded;
    } else if (lower.contains('cardio')) {
      return Icons.directions_run_rounded;
    } else if (lower.contains('pool') || lower.contains('swim')) {
      return Icons.pool_rounded;
    } else if (lower.contains('sauna') || lower.contains('steam')) {
      return Icons.hot_tub_rounded;
    } else if (lower.contains('crossfit') || lower.contains('turf')) {
      return Icons.sports_gymnastics_rounded;
    } else if (lower.contains('yoga')) {
      return Icons.self_improvement_rounded;
    } else if (lower.contains('locker')) {
      return Icons.lock_outline_rounded;
    } else if (lower.contains('shower')) {
      return Icons.shower_rounded;
    } else if (lower.contains('trainer')) {
      return Icons.person_search_rounded;
    } else if (lower.contains('bar') || lower.contains('smoothie')) {
      return Icons.local_drink_rounded;
    } else if (lower.contains('24/7') || lower.contains('hour')) {
      return Icons.all_inclusive_rounded;
    }
    return Icons.check_circle_outline_rounded;
  }
}
