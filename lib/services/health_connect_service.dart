import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

class HealthConnectPermissionsStatus {
  final bool hasActivityRecognition;
  final bool isActivityRecognitionPermanentlyDenied;
  final bool hasReadSteps;
  final bool hasWriteSteps;

  const HealthConnectPermissionsStatus({
    required this.hasActivityRecognition,
    this.isActivityRecognitionPermanentlyDenied = false,
    required this.hasReadSteps,
    required this.hasWriteSteps,
  });

  bool get hasAll => hasActivityRecognition && hasReadSteps && hasWriteSteps;
  bool get canRead => hasActivityRecognition && hasReadSteps;
  bool get canWrite => hasWriteSteps;
}

class HealthConnectService {
  HealthConnectService._internal();
  static final HealthConnectService instance = HealthConnectService._internal();

  final Health _health = Health();
  bool _isConfigured = false;

  /// Ensures Health plugin is configured
  Future<void> _ensureConfigured() async {
    if (!_isConfigured) {
      await _health.configure();
      _isConfigured = true;
    }
  }

  /// Checks Health Connect SDK status on Android
  Future<HealthConnectSdkStatus?> checkAvailability() async {
    if (!Platform.isAndroid) {
      return HealthConnectSdkStatus.sdkUnavailable;
    }
    try {
      return await _health.getHealthConnectSdkStatus();
    } catch (e) {
      debugPrint('Error checking Health Connect availability: $e');
      return HealthConnectSdkStatus.sdkUnavailable;
    }
  }

  /// Directs user to install / update Google Health Connect from Play Store (Android 9-13)
  Future<void> installHealthConnect() async {
    try {
      await _health.installHealthConnect();
    } catch (e) {
      debugPrint('Error launching Health Connect installation: $e');
    }
  }

  /// Checks current permissions status individually
  Future<HealthConnectPermissionsStatus> checkPermissions() async {
    if (!Platform.isAndroid) {
      return const HealthConnectPermissionsStatus(
        hasActivityRecognition: false,
        hasReadSteps: false,
        hasWriteSteps: false,
      );
    }

    try {
      await _ensureConfigured();

      final activityRecognitionStatus = await Permission.activityRecognition.status;
      final hasActivity = activityRecognitionStatus.isGranted;
      final isActivityPermanentlyDenied = activityRecognitionStatus.isPermanentlyDenied;

      final hasRead = await _health.hasPermissions(
            [HealthDataType.STEPS],
            permissions: [HealthDataAccess.READ],
          ) ??
          false;

      final hasWrite = await _health.hasPermissions(
            [HealthDataType.STEPS],
            permissions: [HealthDataAccess.WRITE],
          ) ??
          false;

      return HealthConnectPermissionsStatus(
        hasActivityRecognition: hasActivity,
        isActivityRecognitionPermanentlyDenied: isActivityPermanentlyDenied,
        hasReadSteps: hasRead,
        hasWriteSteps: hasWrite,
      );
    } catch (e) {
      debugPrint('Error checking Health Connect permissions: $e');
      return const HealthConnectPermissionsStatus(
        hasActivityRecognition: false,
        hasReadSteps: false,
        hasWriteSteps: false,
      );
    }
  }

  /// Requests Activity Recognition and Health Connect read/write permissions
  Future<HealthConnectPermissionsStatus> requestPermissions() async {
    if (!Platform.isAndroid) {
      return const HealthConnectPermissionsStatus(
        hasActivityRecognition: false,
        hasReadSteps: false,
        hasWriteSteps: false,
      );
    }

    try {
      // 1. Request Activity Recognition runtime permission
      var activityStatus = await Permission.activityRecognition.status;
      if (!activityStatus.isGranted) {
        activityStatus = await Permission.activityRecognition.request();
      }

      // 2. Configure Health plugin
      await _ensureConfigured();

      // 3. Request Health Connect authorization for STEPS
      final types = [HealthDataType.STEPS];
      final permissions = [HealthDataAccess.READ_WRITE];

      // Note: On Android, requestAuthorization can return true if at least one permission is granted.
      await _health.requestAuthorization(types, permissions: permissions);

      // 4. Verify individual permissions explicitly
      return await checkPermissions();
    } catch (e) {
      debugPrint('Error requesting Health Connect permissions: $e');
      return await checkPermissions();
    }
  }

  /// Reads today's total step count from Health Connect (from midnight to now)
  /// Checks read permission and activity recognition before reading.
  Future<int?> getTodaySteps() async {
    if (!Platform.isAndroid) return null;

    try {
      await _ensureConfigured();

      final permissions = await checkPermissions();
      if (!permissions.canRead) {
        debugPrint('Cannot read steps: Read permission or Activity Recognition not granted.');
        return null;
      }

      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);

      final totalSteps = await _health.getTotalStepsInInterval(midnight, now);
      return totalSteps;
    } catch (e) {
      debugPrint('Error reading today steps from Health Connect: $e');
      return null;
    }
  }

  /// Writes manual steps to Health Connect
  /// Strictly requires a positive step count (> 0) and checks write permission before writing.
  /// Uses RecordingMethod.manual and a 1-minute interval ending at current time.
  Future<bool> writeManualSteps(int stepCount) async {
    if (!Platform.isAndroid) return false;
    if (stepCount <= 0) {
      throw ArgumentError('Step count must be a strictly positive integer.');
    }

    try {
      await _ensureConfigured();

      final hasWrite = await _health.hasPermissions(
            [HealthDataType.STEPS],
            permissions: [HealthDataAccess.WRITE],
          ) ??
          false;

      if (!hasWrite) {
        debugPrint('Cannot write steps: Health Connect Write permission not granted.');
        return false;
      }

      final now = DateTime.now();
      // Ensure start time is strictly before end time
      final startTime = now.subtract(const Duration(minutes: 1));

      final success = await _health.writeHealthData(
        value: stepCount.toDouble(),
        type: HealthDataType.STEPS,
        startTime: startTime,
        endTime: now,
        recordingMethod: RecordingMethod.manual,
      );

      return success;
    } catch (e) {
      debugPrint('Error writing manual steps to Health Connect: $e');
      return false;
    }
  }
}
