import 'package:supabase_flutter/supabase_flutter.dart';

class TargetService {
  final _supabase = Supabase.instance.client;

  Future<void> upsertTargets({
    required double calories,
    required double sleep,
    required double steps,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase.from('user_targets').upsert({
      'user_id': user.id,
      'target_calories': calories,
      'target_sleep': sleep,
      'target_steps': steps,
      'updated_at': DateTime.now().toIso8601String(), // Supabase handles IST if configured
    });
  }

  // Stream to listen to real-time changes
  Stream<Map<String, dynamic>> watchTargets() {
    final user = _supabase.auth.currentUser;
    return _supabase
        .from('user_targets')
        .stream(primaryKey: ['user_id'])
        .eq('user_id', user?.id ?? '')
        .map((data) => data.isNotEmpty ? data.first : {});
  }
}