import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

final combinedLogsProvider =
StateProvider<List<Map<String, dynamic>>>((ref) => []);

final weeklyCaloriesProvider =
StateProvider<List<Map<String, dynamic>>>((ref) => []);

/// Load history & weekly calories
final historyProvider = FutureProvider.family<void, DateTime>((ref, date) async {
  final supabase = ref.read(supabaseProvider);

  try {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception("User not logged in");
    }

    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // --- Fetch food logs ---
    final foodResponse = await supabase
        .from('food_logs')
        .select(
        'id, quantity, consumed_at, foods(name, calories, carbs, protein, fat, fiber, emoji)')
        .eq('user_id', userId)
        .gte('consumed_at', startOfDay.toIso8601String())
        .lt('consumed_at', endOfDay.toIso8601String())
        .order('consumed_at', ascending: true);

    final foodLogs = List<Map<String, dynamic>>.from(foodResponse ?? []);

    // --- Fetch meal logs ---
    final mealResponse = await supabase
        .from('meal_logs_view')
        .select('*')
        .eq('user_id', userId)
        .gte('consumed_at', startOfDay.toIso8601String())
        .lt('consumed_at', endOfDay.toIso8601String())
        .order('consumed_at', ascending: true);

    final mealLogs = List<Map<String, dynamic>>.from(mealResponse ?? []);

    // --- Combine logs ---
    final merged = [
      ...foodLogs.map((f) => {
        "type": "food",
        "id": f['id'], // <- keep food log ID here
        "name": f['foods']?['name'] ?? "Unnamed",
        "emoji": f['foods']?['emoji'] ?? "🍽️",
        "quantity": f['quantity'] ?? 1,
        "consumed_at": f['consumed_at'],
        "total_calories":
        (f['foods']?['calories'] ?? 0) * (f['quantity'] ?? 1),
        "total_protein":
        (f['foods']?['protein'] ?? 0) * (f['quantity'] ?? 1),
        "total_carbs": (f['foods']?['carbs'] ?? 0) * (f['quantity'] ?? 1),
        "total_fat": (f['foods']?['fat'] ?? 0) * (f['quantity'] ?? 1),
        "total_fiber":
        (f['foods']?['fiber'] ?? 0) * (f['quantity'] ?? 1),
      }),
      ...mealLogs.map((m) => {
        "type": "meal",
        "meal_log_id": m['meal_log_id'] ?? m['id'], // <- include the meal log ID
        "name": m['meal_name'] ?? "Unnamed Meal",
        "emoji": m['meal_emoji'] ?? "🍲",
        "quantity": m['quantity'] ?? 1,
        "consumed_at": m['consumed_at'],
        "total_calories": m['total_calories'] ?? 0,
        "total_protein": m['total_protein'] ?? 0,
        "total_carbs": m['total_carbs'] ?? 0,
        "total_fat": m['total_fat'] ?? 0,
        "total_fiber": m['total_fiber'] ?? 0,
      }),
    ];

    merged.sort((a, b) {
      try {
        return DateTime.parse(a['consumed_at'])
            .compareTo(DateTime.parse(b['consumed_at']));
      } catch (_) {
        return 0;
      }
    });

    // --- Weekly calories ---
    final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    final weeklyFoodResponse = await supabase
        .from('food_logs')
        .select('quantity, consumed_at, foods(calories)')
        .eq('user_id', userId)
        .gte('consumed_at', startOfWeek.toIso8601String())
        .lt('consumed_at', endOfWeek.toIso8601String());

    final weeklyMealResponse = await supabase
        .from('meal_logs_view')
        .select('consumed_at, total_calories')
        .eq('user_id', userId)
        .gte('consumed_at', startOfWeek.toIso8601String())
        .lt('consumed_at', endOfWeek.toIso8601String());

    Map<String, double> dailyCaloriesMap = {};

    for (var log in weeklyFoodResponse ?? []) {
      try {
        final consumedAt = DateTime.parse(log['consumed_at']).toLocal();
        final key = DateFormat('yyyy-MM-dd').format(consumedAt);
        final cal = ((log['foods']?['calories'] ?? 0) * (log['quantity'] ?? 1))
            .toDouble();
        dailyCaloriesMap[key] = (dailyCaloriesMap[key] ?? 0) + cal;
      } catch (_) {}
    }

    for (var log in weeklyMealResponse ?? []) {
      try {
        final consumedAt = DateTime.parse(log['consumed_at']).toLocal();
        final key = DateFormat('yyyy-MM-dd').format(consumedAt);
        final cal = (log['total_calories'] ?? 0).toDouble();
        dailyCaloriesMap[key] = (dailyCaloriesMap[key] ?? 0) + cal;
      } catch (_) {}
    }

    List<Map<String, dynamic>> weeklyData = [];
    for (int i = 0; i < 7; i++) {
      final day = startOfWeek.add(Duration(days: i));
      final key = DateFormat('yyyy-MM-dd').format(day);
      weeklyData.add({"day": day, "calories": dailyCaloriesMap[key] ?? 0.0});
    }

    // Update providers
    ref.read(selectedDateProvider.notifier).state = date;
    ref.read(combinedLogsProvider.notifier).state = merged;
    ref.read(weeklyCaloriesProvider.notifier).state = weeklyData;
  } catch (e) {
    print("Error loading history: $e");
    throw e; // propagate to UI
  }
});

/// Group logs by meal type
Map<String, List<Map<String, dynamic>>> groupLogsByMeal(
    List<Map<String, dynamic>> logs) {
  Map<String, List<Map<String, dynamic>>> meals = {
    "Breakfast": [],
    "Lunch": [],
    "Snacks": [],
    "Dinner": [],
  };

  for (var log in logs) {
    final consumedAtStr = log['consumed_at'];
    if (consumedAtStr == null) continue;

    try {
      final dt = DateTime.parse(consumedAtStr).toLocal();
      final hour = dt.hour;
      String mealType;

      if (hour >= 3 && hour < 12) {
        mealType = "Breakfast";
      } else if (hour >= 12 && hour < 16) {
        mealType = "Lunch";
      } else if (hour >= 16 && hour < 19) {
        mealType = "Snacks";
      } else {
        mealType = "Dinner";
      }

      meals[mealType]!.add(log);
    } catch (_) {}
  }

  return meals;
}
