import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/history_provider.dart';

/// Supabase client provider
final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Current user provider
final currentUserProvider = Provider<User?>((ref) {
  return Supabase.instance.client.auth.currentUser;
});

/// Fetch all foods
final foodsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = ref.watch(supabaseProvider);
  final response = await supabase.from('foods').select();
  return List<Map<String, dynamic>>.from(response);
});

/// Fetch user favorites
final favoritesProvider = FutureProvider<List<String>>((ref) async {
  final supabase = ref.watch(supabaseProvider);
  final user = supabase.auth.currentUser;
  if (user == null) return [];

  final response = await supabase
      .from('user_favorites')
      .select('food_id')
      .eq('user_id', user.id);

  return List<String>.from(response.map((f) => f['food_id']));
});

/// Combine foods + favorites: Favorites always on top
final sortedFoodsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final foods = await ref.watch(foodsProvider.future);
  final favorites = await ref.watch(favoritesProvider.future);

  foods.sort((a, b) {
    final isFavA = favorites.contains(a['id']);
    final isFavB = favorites.contains(b['id']);
    if (isFavA && !isFavB) return -1;
    if (!isFavA && isFavB) return 1;
    return (a['name'] as String).compareTo(b['name'] as String);
  });

  return foods;
});

/// Action: Toggle favorite
final favoriteActionsProvider = Provider((ref) {
  final supabase = ref.watch(supabaseProvider);
  final user = supabase.auth.currentUser;

  return (String foodId, bool isFav) async {
    if (user == null) return;
    if (isFav) {
      // Remove from favorites
      await supabase
          .from('user_favorites')
          .delete()
          .eq('user_id', user.id)
          .eq('food_id', foodId);
    } else {
      // Add to favorites
      await supabase.from('user_favorites').insert({
        'user_id': user.id,
        'food_id': foodId,
      });
    }

    // Refresh favorites and sorted foods
    ref.invalidate(favoritesProvider);
    ref.invalidate(sortedFoodsProvider);
  };
});

/// Fetch user custom meals
final userMealsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = ref.watch(supabaseProvider);
  final user = supabase.auth.currentUser;
  if (user == null) return [];

  final response = await supabase
      .from('user_meals')
      .select('id, name, emoji, user_meal_items(food_id, quantity)')
      .eq('user_id', user.id);

  return List<Map<String, dynamic>>.from(response);
});

/// Save a custom meal
final saveCustomMealProvider = Provider((ref) {
  final supabase = ref.watch(supabaseProvider);
  final user = supabase.auth.currentUser;

  return (String name, String? emoji, List<Map<String, dynamic>> items) async {
    if (user == null) return;

    // Insert into user_meals
    final mealResponse = await supabase.from('user_meals').insert({
      'user_id': user.id,
      'name': name,
      'emoji': emoji,
    }).select().single();

    final mealId = mealResponse['id'];

    // Insert meal items
    final mealItems = items.map((item) {
      return {
        'meal_id': mealId,
        'food_id': item['id'],
        'quantity': item['quantity'],
      };
    }).toList();

    await supabase.from('user_meal_items').insert(mealItems);

    // Refresh user meals provider
    ref.invalidate(historyProvider(ref.read(selectedDateProvider)));
  };
});

final deleteCustomMealProvider = Provider((ref) {
  final supabase = ref.watch(supabaseProvider);

  return (String mealId) async {
    // 1. Delete meal items
    await supabase.from('user_meal_items').delete().eq('meal_id', mealId);

    // 2. Delete meal
    await supabase.from('user_meals').delete().eq('id', mealId);

    // 3. Refresh userMealsProvider
    ref.invalidate(userMealsProvider);
  };
});
