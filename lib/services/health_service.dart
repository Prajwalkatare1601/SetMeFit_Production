import 'package:supabase_flutter/supabase_flutter.dart';

class HealthService {
  final _supabase = Supabase.instance.client;

  /// Syncs all data collected locally to Supabase after the user has signed up.
  /// [userId] is the new Auth UID.
  /// [data] contains 'profile' (onboarding info) and 'health' (questionnaire info).
  Future<void> syncHealthData(String userId, Map<String, dynamic> data) async {
    try {
      // 1. Insert Profile FIRST
      // This is required because health tables reference 'profiles.id'
      final profile = data['profile'];

      await _supabase.from('profiles').insert({
        'id': userId,
        'first_name': profile['first_name'],
        'last_name': profile['last_name'],
        'nickname': profile['nickname'],
        'height': profile['height'],
        'weight': profile['weight'],
        'bmi': profile['bmi'],
        'age': profile['age'],
        'gender': profile['gender'],
        'goal': profile['goal'],
        'dob': profile['dob'],
        'email': _supabase.auth.currentUser?.email,
        'phone': _supabase.auth.currentUser?.phone, // Added to capture phone during OTP
        'updated_at': DateTime.now().toIso8601String(),
      });

      // 2. Insert Health Data into the consolidated table
      final health = data['health'];

      await _supabase.from('user_health_profiles').insert({
        'id': userId, // Primary key linked to Auth UID

        // Movement
        'walking_steps': health['walking_steps'],
        'jogging_mins': health['jogging_mins'],
        'running_mins': health['running_mins'],

        // Workout
        'gym_mins': health['gym_mins'],
        'yoga_mins': health['yoga_mins'],

        // Sports
        'cricket_mins': health['cricket_mins'],
        'football_mins': health['football_mins'],
        'badminton_mins': health['badminton_mins'],
        'basketball_mins': health['basketball_mins'],
        'swimming_mins': health['swimming_mins'],
        'tennis_mins': health['tennis_mins'],
        'throwball_mins': health['throwball_mins'],
        'volleyball_mins': health['volleyball_mins'],
        'total_sports_mins': health['total_sports_mins'],

        // Sugar Levels
        'sugar_fasting': health['sugar_fasting'],
        'sugar_pp1': health['sugar_pp1'],
        'sugar_pp2': health['sugar_pp2'],
        'sugar_pp3': health['sugar_pp3'],

        // Vitals
        'systolic': health['systolic'],
        'diastolic': health['diastolic'],
        'heart_rate': health['heart_rate'],
        'hemoglobin': health['hemoglobin'],

        // Conditions
        'thyroid_status': health['thyroid_status'],
        'cholesterol_status': health['cholesterol_status'],
        'gastric_status': health['gastric_status'],
        'pcod_status': health['pcod_status'],

        // Diet
        'food_quality': health['food_quality'],
        'eating_schedule': health['eating_schedule'],
        'fasting_habit': health['fasting_habit'],
        'alcohol_habit': health['alcohol_habit'],
        'smoking_habit': health['smoking_habit'],

        // Wellbeing
        'energy_level': health['energy_level'],
        'stress_level_percent': health['stress_level_percent'],
        'sleep_hours': health['sleep_hours'],
        'mood_level': health['mood_level'],
        'hobby_frequency': health['hobby_frequency'],

        // Tongue
        'tongue_color': health['tongue_color'],
        'tongue_coating': health['tongue_coating'],
        'tongue_moisture': health['tongue_moisture'],
        'tongue_cracks': health['tongue_cracks'],
        'tongue_shape': health['tongue_shape'],

        //Health
        'health_score': health['health_score']
      });

      print("SUCCESS: Profile and Health data synced to user_health_profiles for $userId");
    } catch (e) {
      print("CRITICAL SYNC ERROR: $e");
      rethrow;
    }
  }
}