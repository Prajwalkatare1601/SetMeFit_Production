import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:async/async.dart';

// ✅ 1. Initial Provider: Fetches the pre-calculated health_score from your profile table
final initialHealthScoreProvider = FutureProvider<double?>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return null;

  try {
    final data = await Supabase.instance.client
        .from('user_health_profiles')
        .select('health_score')
        .eq('id', user.id)
        .maybeSingle();

    if (data == null || data['health_score'] == null) return null;
    return (data['health_score'] as num).toDouble();
  } catch (e) {
    return null;
  }
});

// ✅ 2. Real-time Stream: Listens to the log tables
final healthDataStreamProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final client = Supabase.instance.client;
  final userId = client.auth.currentUser?.id;
  if (userId == null) return Stream.value({});

  // Added 'filterCol' parameter to specify which column to match the userId against
  Stream<Map<String, dynamic>> tableStream(String table, String orderCol, {String filterCol = 'user_id'}) {
    return client
        .from(table)
        .stream(primaryKey: ['id'])
        .eq(filterCol, userId) // Uses the specified column (defaults to user_id)
        .order(orderCol, ascending: false)
        .limit(1)
        .map((data) => data.isNotEmpty ? data.first : <String, dynamic>{});
  }

  return StreamZip([
    tableStream('activity_logs', 'date'),
    tableStream('wellbeing_logs', 'log_date'),
    tableStream('diet_logs', 'log_date'),
    tableStream('medical_vitals', 'updated_at'),
    tableStream('tongue_records', 'timestamp'),
  ]).map((results) => {
    'activity': results[0],
    'wellbeing': results[1],
    'diet': results[2],
    'vitals': results[3],
    'tongue': results[4],
  });
});

// ✅ 3. Detailed Calculation Engine: Preserves all granular logic
final pillarScoresProvider = Provider.family<Map<String, double>, Map<String, dynamic>>((ref, data) {
  double toDouble(dynamic val) => val == null ? 0.0 : (val is num ? val.toDouble() : double.tryParse(val.toString()) ?? 0.0);

  // --- 1. ACTIVITY PILLAR (Max 150) ---
  final act = data['activity'] ?? {};
  double activityScore = 0.0;

// Helper function to extract minutes from "MM:SS" string in JSON
  double getMinutesFromData(dynamic activityData) {
    if (activityData == null || activityData['time'] == null) return 0.0;
    try {
      String timeStr = activityData['time'].toString(); // "MM:SS"
      List<String> parts = timeStr.split(':');
      if (parts.length == 2) {
        int minutes = int.parse(parts[0]);
        int seconds = int.parse(parts[1]);
        return minutes + (seconds / 60.0);
      }
      return double.tryParse(timeStr) ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

// --- 1a. Steps Component (Max 60) ---
// 10,000 steps = 100% of this component
  activityScore += (toDouble(act['steps']) / 10000 * 60.0).clamp(0.0, 60.0);

// --- 1b. Exercise Component (Max 90) ---
// Intensity Weighting:
// High: Run (2.5x), Jog (2.0x)
// Moderate-High: Gym (1.5x), Sports (1.5x)
// Moderate: Yoga (1.0x), Walk (1.0x)

  double runMins = getMinutesFromData(act['run_data']);
  double jogMins = getMinutesFromData(act['jog_data']);
  double walkMins = getMinutesFromData(act['walk_data']);

  double exerciseWeight = (runMins * 2.5) +
      (jogMins * 2.0) +
      (toDouble(act['gym_min']) * 1.5) +
      (toDouble(act['sports_min']) * 1.5) +
      (toDouble(act['yoga_min']) * 1.0) +
      (walkMins * 1.0);

// Benchmark: Reaching a weighted value of 90 (e.g., 36 mins of pure running or 60 mins of gym)
// This fills the remaining 90 points of the 150 total.
  activityScore += (exerciseWeight / 90.0 * 90.0).clamp(0.0, 90.0);

// Total Activity Score is now activityScore (Max 150)

  // --- 2. WELLBEING (Max 112.5) ---
  final wb = data['wellbeing'] ?? {};
  double wbScore = 0.0;

  // Sleep (Max 30)
  double sleep = toDouble(wb['sleep_hours']);
  if (sleep >= 7 && sleep <= 9) wbScore += 30;
  else if (sleep > 9 || (sleep >= 6 && sleep < 7)) wbScore += 15;

  // Meditation (Max 25): 20 mins benchmark
  wbScore += (toDouble(wb['meditation_min']) / 20.0 * 25.0).clamp(0.0, 25.0);

  // Happiness Index (Max 25)
  final mood = wb['happiness_mood']?.toString().toLowerCase();
  wbScore += {
    'delighted': 25.0,
    'happy': 20.0,
    'normal': 15.0,
    'sad': 5.0,
    'heartbroken': 0.0
  }[mood] ?? 0.0;

  // Music (Max 12.5)
  wbScore += (toDouble(wb['music_min']) >= 15 ? 12.5 : 5.0);

  // Hobby Level (Max 20)
  final hobby = wb['hobby_level']?.toString().toLowerCase();
  wbScore += {
    'expert': 20.0,
    'talented': 15.0,
    'developing': 10.0,
    'exploring': 5.0
  }[hobby] ?? 0.0;

  // --- 3. DIET (Max 150) ---
  final dt = data['diet'] ?? {};
  double dietScore = 0.0;

  // 1. Calories (Max 60): Optimal benchmark ~2000 kcal
  double totalCal = toDouble(dt['total_calories']);
  if (totalCal > 0) {
    double calRatio = totalCal / 2000.0;
    // Score peaks at 1.0 ratio, degrades if significantly over or under
    if (calRatio <= 1.1 && calRatio >= 0.8) dietScore += 60.0;
    else if (calRatio > 1.1) dietScore += (60.0 * (1.5 - calRatio)).clamp(0.0, 60.0);
    else dietScore += (60.0 * calRatio).clamp(0.0, 60.0);
  }

  // 2. Protein (Max 30): Benchmark 50g
  dietScore += (toDouble(dt['total_protein']) / 50.0 * 30.0).clamp(0.0, 30.0);

  // 3. Carbs (Max 30): Benchmark 250g
  dietScore += (toDouble(dt['total_carbs']) / 250.0 * 30.0).clamp(0.0, 30.0);

  // 4. Fat (Max 30): Benchmark 70g
  dietScore += (toDouble(dt['total_fat']) / 70.0 * 30.0).clamp(0.0, 30.0);

  // --- 4. VITALS (Max 225) ---
  final vt = data['vitals'] ?? {};
  double vtScore = 0.0;

  // A. Blood Pressure (Max 60)
  // Scrutinizing both Systolic and Diastolic
  double sys = toDouble(vt['systolic']);
  double dia = toDouble(vt['diastolic']);
  if (sys > 0 && dia > 0) {
    if (sys <= 120 && dia <= 80) vtScore += 60; // Optimal
    else if (sys <= 130 && dia <= 85) vtScore += 40; // Normal
    else if (sys <= 140 && dia <= 90) vtScore += 20; // Pre-hypertension
  }

  // B. Blood Sugar & Long-term Glucose (Max 60)
  // Prioritizes HbA1c as it's a 3-month average
  double hba1c = toDouble(vt['hba1c']);
  double sugar = toDouble(vt['sugar']);
  if (hba1c > 0) {
    if (hba1c < 5.7) vtScore += 60;
    else if (hba1c < 6.5) vtScore += 30;
  } else if (sugar > 0) {
    // Fallback to fasting/random sugar if HbA1c is missing
    if (sugar < 100) vtScore += 50;
    else if (sugar < 125) vtScore += 25;
  }

  // C. Lipid Profile - Heart Health (Max 45)
  double ldl = toDouble(vt['ldl']);
  double hdl = toDouble(vt['hdl']);
  double tri = toDouble(vt['triglycerides']);
  if (ldl > 0 && ldl < 100) vtScore += 15;
  if (hdl > 40) vtScore += 15;
  if (tri > 0 && tri < 150) vtScore += 15;

  // D. Systemic Markers - Thyroid & Blood (Max 30)
  double hb = toDouble(vt['hb']);
  double tsh = toDouble(vt['thyroid_tsh']);
  if (hb >= 13.0) vtScore += 15; // Normal Hemoglobin
  else if (hb >= 11.0) vtScore += 7;

  if (tsh >= 0.4 && tsh <= 4.0 && tsh > 0) vtScore += 15; // Normal TSH

  // E. Digestion & Pulse (Max 30)
  final gastric = vt['gastric_severity']?.toString().toLowerCase();
  double pulse = toDouble(vt['pulse']);

  if (gastric == 'none') vtScore += 15;
  else if (gastric == 'mild') vtScore += 7;

  if (pulse >= 60 && pulse <= 100) vtScore += 15;

  // --- 5. TONGUE (Max 112.5) ---
  final tg = data['tongue'] ?? {};
  double tgScore = 0.0;

  // Color (Max 25)
  final color = tg['color']?.toString().toLowerCase();
  tgScore += {'pink': 25.0, 'pale': 15.0, 'red': 10.0, 'deep red': 5.0, 'purple': 2.0, 'blue': 0.0}[color] ?? 0.0;

  // Coating (Max 25)
  final coat = tg['coating']?.toString().toLowerCase();
  tgScore += {'none': 25.0, 'thin white': 25.0, 'thick white': 15.0, 'yellow': 10.0, 'greasy': 5.0, 'peeled': 0.0}[coat] ?? 0.0;

  // Cracks (Max 20)
  final cracks = tg['cracks']?.toString().toLowerCase();
  tgScore += {'none': 20.0, 'mild': 15.0, 'moderate': 10.0, 'deep': 5.0, 'horizontal': 5.0, 'vertical': 5.0}[cracks] ?? 0.0;

  // Moisture (Max 20)
  final moist = tg['moisture']?.toString().toLowerCase();
  tgScore += {'normal': 20.0, 'moist': 20.0, 'slightly dry': 10.0, 'dry': 5.0, 'excessively wet': 5.0}[moist] ?? 0.0;

  // Shape (Max 22.5)
  final shape = tg['shape']?.toString().toLowerCase();
  tgScore += {'normal': 22.5, 'thin': 15.0, 'swollen': 10.0, 'scalloped': 10.0, 'stiff': 5.0, 'flabby': 5.0}[shape] ?? 0.0;

  return {
    'Activity': activityScore.clamp(0.0, 150.0),
    'Wellbeing': wbScore.clamp(0.0, 112.5),
    'Diet': dietScore.clamp(0.0, 150.0),
    'Vitals': vtScore.clamp(0.0, 225.0),
    'Tongue': tgScore.clamp(0.0, 112.5),
  };
});

// ✅ 4. The Unified Final Score Provider
final finalScoreProvider = Provider<AsyncValue<double?>>((ref) {
  final streamAsync = ref.watch(healthDataStreamProvider);
  final initialAsync = ref.watch(initialHealthScoreProvider);

  return streamAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
    data: (logData) {
      // Check if ANY daily logs exist in log tables
      bool hasLogs = logData.values.any((m) => m.isNotEmpty);

      if (hasLogs) {
        final pillars = ref.read(pillarScoresProvider(logData));
        double score = (250.0 + pillars.values.fold(0.0, (sum, score) => sum + score)).clamp(250.0, 1000.0);
        return AsyncValue.data(score);
      } else {
        // Fallback to initial health_score from the profile table
        return initialAsync.when(
          loading: () => const AsyncValue.loading(),
          error: (err, stack) => const AsyncValue.data(null),
          data: (score) => AsyncValue.data(score),
        );
      }
    },
  );
});