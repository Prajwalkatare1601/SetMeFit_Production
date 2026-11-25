class FlashFitSubscription {
  final String userId;
  final String planName;
  final String tier; // 'ELITE', 'PRO', 'BASIC'
  final bool isActive;
  final int sessionsPerMonth;
  final int sessionsUsed;
  final DateTime validUntil;

  const FlashFitSubscription({
    required this.userId,
    this.planName = 'SetMeFit All-Access Pass',
    this.tier = 'ELITE',
    this.isActive = true,
    this.sessionsPerMonth = 30,
    this.sessionsUsed = 0,
    required this.validUntil,
  });

  bool get isExpired => DateTime.now().isAfter(validUntil);

  bool get isEligibleForBooking => isActive && !isExpired && (remainingSessions > 0);

  int get remainingSessions => (sessionsPerMonth - sessionsUsed).clamp(0, sessionsPerMonth);

  int get daysRemaining {
    final diff = validUntil.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  factory FlashFitSubscription.fromMap(Map<String, dynamic> map, String fallbackUserId) {
    DateTime parseDate(dynamic val) {
      if (val is String) {
        return DateTime.tryParse(val) ?? DateTime.now().add(const Duration(days: 30));
      }
      return DateTime.now().add(const Duration(days: 30));
    }

    return FlashFitSubscription(
      userId: map['user_id']?.toString() ?? fallbackUserId,
      planName: map['plan_name'] ?? 'SetMeFit All-Access Pass',
      tier: map['tier'] ?? 'ELITE',
      isActive: map['is_active'] ?? true,
      sessionsPerMonth: (map['sessions_per_month'] as num?)?.toInt() ?? 30,
      sessionsUsed: (map['sessions_used'] as num?)?.toInt() ?? 0,
      validUntil: parseDate(map['valid_until']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'plan_name': planName,
      'tier': tier,
      'is_active': isActive,
      'sessions_per_month': sessionsPerMonth,
      'sessions_used': sessionsUsed,
      'valid_until': validUntil.toIso8601String(),
    };
  }

  factory FlashFitSubscription.demoActive(String userId) {
    return FlashFitSubscription(
      userId: userId,
      planName: 'FlashFit Elite All-Access Pass',
      tier: 'ELITE',
      isActive: true,
      sessionsPerMonth: 30,
      sessionsUsed: 4,
      validUntil: DateTime.now().add(const Duration(days: 26)),
    );
  }
}
