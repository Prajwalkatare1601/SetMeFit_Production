import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Model for macros + logs
class HomeState {
  final bool isLoading;
  final double carbs, protein, fat, fiber, calories;
  final List<Map<String, dynamic>> logs;
  final int waterMl; // 👈 new


  const HomeState({
    this.isLoading = true,
    this.carbs = 0,
    this.protein = 0,
    this.fat = 0,
    this.fiber = 0,
    this.calories = 0,
    this.waterMl = 0, // 👈 new
    this.logs = const [],
  });

  HomeState copyWith({
    bool? isLoading,
    double? carbs,
    double? protein,
    double? fat,
    double? fiber,
    double? calories,
    int? waterMl, // 👈 new
    List<Map<String, dynamic>>? logs,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      carbs: carbs ?? this.carbs,
      protein: protein ?? this.protein,
      fat: fat ?? this.fat,
      fiber: fiber ?? this.fiber,
      calories: calories ?? this.calories,
      waterMl: waterMl ?? this.waterMl, // 👈 new
      logs: logs ?? this.logs,
    );
  }
}

class HomeNotifier extends StateNotifier<HomeState> {
  HomeNotifier() : super(const HomeState()) {
    loadData();
  }

  final supabase = Supabase.instance.client;

  // Add water to DB
  Future<void> addWater(int amount) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    // Insert new water log
    await supabase.from('water_logs').insert({
      'user_id': userId,
      'amount_ml': amount,
    });

    // Update local state (optional: refetch total from DB for accuracy)
    await loadWater();
  }

// Reset today's water intake
  Future<void> resetWater() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    // Delete today's water logs
    final today = DateTime.now();
    final todayStart =
    DateTime(today.year, today.month, today.day).toIso8601String();

    await supabase
        .from('water_logs')
        .delete()
        .eq('user_id', userId)
        .gte('consumed_at', todayStart);

    await loadWater();
  }

// Load today's water total
  Future<void> loadWater() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    final today = DateTime.now();
    final todayStart =
    DateTime(today.year, today.month, today.day).toIso8601String();

    final result = await supabase
        .from('water_logs')
        .select('amount_ml')
        .eq('user_id', userId)
        .gte('consumed_at', todayStart);

    int total = 0;
    if (result != null) {
      for (var entry in result) {
        total += entry['amount_ml'] as int;
      }
    }

    state = state.copyWith(waterMl: total);
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true);
    try {
      final userId = supabase.auth.currentUser!.id;
      final today = DateTime.now();
      final todayStart =
      DateTime(today.year, today.month, today.day).toIso8601String();

      final response = await supabase
          .from('food_logs')
          .select(
          'id, quantity, consumed_at, foods(name, carbs, protein, fat, fiber, calories)')
          .eq('user_id', userId)
          .gte('consumed_at', todayStart)
          .order('consumed_at', ascending: false);

      double c = 0, p = 0, f = 0, fi = 0, cal = 0;
      List<Map<String, dynamic>> newLogs = [];

      for (var row in response) {
        final qty = row['quantity'] as num;
        final food = row['foods'] ?? {};

        c += ((food['carbs'] ?? 0) as num) * qty;
        p += ((food['protein'] ?? 0) as num) * qty;
        f += ((food['fat'] ?? 0) as num) * qty;
        fi += ((food['fiber'] ?? 0) as num) * qty;
        cal += ((food['calories'] ?? 0) as num) * qty;

        newLogs.add({
          'id': row['id'],
          'name': food['name'] ?? 'Unknown',
          'quantity': qty,
          'consumed_at': row['consumed_at'],
        });
      }

      state = state.copyWith(
        carbs: c.toDouble(),
        protein: p.toDouble(),
        fat: f.toDouble(),
        fiber: fi.toDouble(),
        calories: cal.toDouble(),
        logs: newLogs,
        isLoading: false,
      );
    } catch (e, st) {
      // keep UI responsive; log for debugging
      print('homeProvider.loadData error: $e\n$st');

      await loadWater();
      state = state.copyWith(isLoading: false);
    }
  }

  /// Delete a log by type and id.
  /// logType: "food" or "meal"
  /// id: food_log id or meal_log id
  /// Returns true if deletion succeeded, false otherwise
  Future<bool> deleteLog({
    required String logType,
    required dynamic id,
  }) async {
    final supabase = Supabase.instance.client;
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return false;

      if (logType == "food") {
        // Delete food log
        await supabase.from('food_logs').delete().eq('id', id).eq('user_id', userId);
      } else if (logType == "meal") {
        // Delete meal log
        await supabase.from('meal_logs').delete().eq('id', id).eq('user_id', userId);
      } else {
        throw Exception("Unknown log type: $logType");
      }

      // Refresh local state
      await loadData(); // recomputes macros & logs
      return true;
    } catch (e, st) {
      print('deleteLog error: $e\n$st');
      return false;
    }
  }

}

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  return HomeNotifier();
});
