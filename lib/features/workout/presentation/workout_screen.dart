import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../state/workout_controller.dart';
import 'route_canvas.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const WorkoutScreen(activityType: 'walk_data'),
    );
  }
}

class WorkoutScreen extends ConsumerStatefulWidget {
  final String activityType; // walk_data / run_data / jog_data

  const WorkoutScreen({
    super.key,
    required this.activityType,
  });

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  bool _isRunning = false;

  /// ---------------- START / STOP TIMER ----------------
  void _startTimer() {
    _timer?.cancel();
    _elapsed = Duration.zero;
    _isRunning = true;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _elapsed += const Duration(seconds: 1);
      });
    });
  }

  Future<void> _stopTimerAndSave(double distanceKm) async {
    _timer?.cancel();
    _isRunning = false;

    final pace = _formatPace(_elapsed, distanceKm);

    await _saveWorkoutToSupabase(
      distanceKm,
      _elapsed,
      pace,
    );
  }

  /// ---------------- SUPABASE WRITE ----------------
  Future<void> _saveWorkoutToSupabase(
      double distanceKm,
      Duration time,
      String pace,
      ) async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final today = DateTime.now().toIso8601String().split('T')[0];

      await supabase.from('activity_logs').upsert(
        {
          'user_id': user.id,
          'date': today,
          widget.activityType: {
            'distance_km': distanceKm.toStringAsFixed(2),
            'time': _formatDuration(time),
            'pace': pace,
            'recorded_at': DateTime.now().toIso8601String(),
          },
        },
        onConflict: 'user_id,date',
      );
    } catch (e) {
      debugPrint('Supabase error: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final points = ref.watch(workoutProvider);
    final controller = ref.read(workoutProvider.notifier);

    final distanceKm = controller.distance;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.activityType.replaceAll('_data', '').toUpperCase()),
        centerTitle: true,
      ),
      body: Column(
        children: [
          /// -------- ROUTE CANVAS (UNCHANGED) --------
          Expanded(
            child: CustomPaint(
              painter: RouteCanvas(points),
              child: Container(),
            ),
          ),

          /// -------- STATS --------
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Time: ${_formatDuration(_elapsed)}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'Distance: ${distanceKm.toStringAsFixed(2)} km',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pace: ${_formatPace(_elapsed, distanceKm)}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),

                /// -------- ACTION BUTTON --------
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: !_isRunning
                        ? () {
                      controller.start();   // EXISTING METHOD
                      _startTimer();        // UI timer
                    }
                        : () async {
                      await _stopTimerAndSave(distanceKm); // UI stop + save
                    },
                    child: Text(_isRunning ? 'STOP' : 'START'),
                  ),
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ---------------- FORMATTERS ----------------
  String _formatDuration(Duration d) =>
      "${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:"
          "${d.inSeconds.remainder(60).toString().padLeft(2, '0')}";

  String _formatPace(Duration time, double km) {
    if (km <= 0) return '--';
    final secPerKm = time.inSeconds / km;
    return "${(secPerKm ~/ 60).toString().padLeft(2, '0')}:"
        "${(secPerKm % 60).toStringAsFixed(0).padLeft(2, '0')} /km";
  }
}
