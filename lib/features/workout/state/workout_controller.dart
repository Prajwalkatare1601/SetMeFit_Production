import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/location_service.dart';
import '../domain/workout_point.dart';

final workoutProvider =
    StateNotifierProvider<WorkoutController, List<WorkoutPoint>>(
  (ref) => WorkoutController(),
);

class WorkoutController extends StateNotifier<List<WorkoutPoint>> {
  WorkoutController() : super([]);

  final _locationService = LocationService();
  double? _startLat;
  double? _startLng;

  void start() {
    state = [];

    _locationService.getPositionStream().listen((pos) {
      _startLat ??= pos.latitude;
      _startLng ??= pos.longitude;

      final dx = (pos.longitude - _startLng!) * 100000;
      final dy = (pos.latitude - _startLat!) * 100000;

      state = [
        ...state,
        WorkoutPoint(
          x: dx,
          y: dy,
          time: DateTime.now(),
        ),
      ];
    });
  }

  double get distance {
    double d = 0;
    for (int i = 1; i < state.length; i++) {
      d += sqrt(
        pow(state[i].x - state[i - 1].x, 2) +
        pow(state[i].y - state[i - 1].y, 2),
      );
    }
    return d / 1000;
  }
}
