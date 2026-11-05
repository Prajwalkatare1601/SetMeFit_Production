import 'dart:math';

/* ---------- HEALTH ---------- */

// BMI: Standard formula (kg / m²)
double bmi(double w, double hCm) {
  final h = hCm / 100;
  return w / (h * h);
}

// BMR: Mifflin-St Jeor (most accurate and default on calculator.net)
double bmr(double w, double h, int age, bool male) {
  return male
      ? 10 * w + 6.25 * h - 5 * age + 5
      : 10 * w + 6.25 * h - 5 * age - 161;
}

// Daily calorie needs multipliers (exact match to calculator.net Calorie Calculator)
const Map<String, double> activityMultipliers = {
  "Sedentary (little or no exercise)": 1.2,
  "Lightly active (light exercise/sports 1-3 days/week)": 1.375,
  "Moderately active (moderate exercise/sports 3-5 days/week)": 1.55,
  "Very active (hard exercise/sports 6-7 days a week)": 1.725,
  "Extra active (very hard exercise/sports & physical job)": 1.9,
};

// Body Fat %: U.S. Navy method (metric version - most accurate and used on site)
double bodyFat(double waist, double neck, double height, bool male, [double? hip]) {
  final log10 = log;
  if (male) {
    return 495 / (1.0324 - 0.19077 * log10(waist - neck) + 0.15456 * log10(height)) - 450;
  } else {
    if (hip == null) throw ArgumentError("Hip measurement required for female");
    return 495 / (1.29579 - 0.35004 * log10(waist + hip - neck) + 0.22100 * log10(height)) - 450;
  }
}

// Ideal Weight: Devine formula (widely used and common on calculator.net)
double idealWeight(double heightCm, bool male) {
  final inches = heightCm / 2.54;
  final base = male ? 50.0 : 45.5;
  final extra = (inches - 60) * 2.3;
  return base + (extra > 0 ? extra : 0);
}

// Pace: minutes per km (exact match)
// pace_calculator.dart
class PaceCalculator {
  // Pace = time (min) / distance (km) → min per km
  static double calculatePace(double distanceKm, double timeMin) {
    if (distanceKm <= 0) throw Exception("Distance must be > 0");
    return timeMin / distanceKm;
  }

  // Time = pace (min/km) × distance (km) → minutes
  static double calculateTime(double distanceKm, double paceMinPerKm) {
    if (paceMinPerKm <= 0) throw Exception("Pace must be > 0");
    return paceMinPerKm * distanceKm;
  }

  // Distance = time (min) / pace (min/km) → km
  static double calculateDistance(double timeMin, double paceMinPerKm) {
    if (paceMinPerKm <= 0) throw Exception("Pace must be > 0");
    return timeMin / paceMinPerKm;
  }

  // Get result string with unit
  static String getResult(double value, CalcMode mode) {
    String unit;
    switch (mode) {
      case CalcMode.pace:
        unit = "min/km";
        break;
      case CalcMode.time:
        unit = "minutes";
        break;
      case CalcMode.distance:
        unit = "km";
        break;
    }
    return "${value.toStringAsFixed(2)} $unit";
  }
}

enum CalcMode { pace, time, distance }

// Pregnancy: Keep advanced multi-method (better than basic on calculator.net)
// But provide simple helpers for LMP-based (most common)
DateTime dueDate(DateTime lmp) => lmp.add(const Duration(days: 280));
DateTime conception(DateTime lmp) => lmp.add(const Duration(days: 14));

/* ---------- EVERYDAY ---------- */

// GPA: Simple average (for 3 grades as in your app)
double calculateGPAFromLetters({
  required List<String?> grades,   // ['A', 'B+', 'C']
  required List<double?> credits,  // [4, 3, 2]
}) {
  // Calculator.net standard scale
  const Map<String, double> letterToPoint = {
    'A': 4.0,
    'A-': 3.7,
    'B+': 3.3,
    'B': 3.0,
    'B-': 2.7,
    'C+': 2.3,
    'C': 2.0,
    'C-': 1.7,
    'D+': 1.3,
    'D': 1.0,
    'F': 0.0,
  };

  double totalPoints = 0;
  double totalCredits = 0;

  for (int i = 0; i < grades.length; i++) {
    final letter = grades[i];

    // Skip invalid rows (calculator.net behavior)
    if (letter == null || !letterToPoint.containsKey(letter)) continue;

    final gradePoint = letterToPoint[letter]!;

    // Default credit = 1 if missing/invalid
    final credit =
    (i < credits.length && credits[i] != null && credits[i]! > 0)
        ? credits[i]!
        : 1.0;

    totalPoints += gradePoint * credit;
    totalCredits += credit;
  }

  return totalCredits == 0 ? 0 : totalPoints / totalCredits;
}

// Grade from percentage: Simple letter grade
String grade(double p) {
  if (p >= 90) return "A";
  if (p >= 80) return "B";
  if (p >= 70) return "C";
  if (p >= 60) return "D";
  return "F";
}

// Bra Size: Approximate US/UK from cm difference
String braSize(double bustCm, double underbustCm) {
  // Convert cm → inches
  double bustInches = bustCm / 2.54;
  double underbustInches = underbustCm / 2.54;

  // Round underbust to nearest whole inch
  int roundedUnderbust = underbustInches.round();

  // US/CA band size rule: odd → round up to next even
  int bandSize = roundedUnderbust;
  if (bandSize % 2 != 0) {
    bandSize += 1;
  }

  // Cup difference (in inches)
  int diff = (bustInches - bandSize).round();

  String cup;
  if (diff <= 0) {
    cup = "AA";
  } else if (diff == 1) {
    cup = "A";
  } else if (diff == 2) {
    cup = "B";
  } else if (diff == 3) {
    cup = "C";
  } else if (diff == 4) {
    cup = "D";
  } else if (diff == 5) {
    cup = "DD";
  } else if (diff == 6) {
    cup = "DDD";
  } else if (diff == 7) {
    cup = "G";
  } else if (diff == 8) {
    cup = "H";
  } else if (diff == 9) {
    cup = "I";
  } else if (diff == 10) {
    cup = "J";
  } else {
    cup = "J+";
  }

  return "$bandSize$cup";
}


// Shoe Size: Approximate EU from foot length cm (common formula)
double shoeSize(double footCm) {
  // Standard formula: (footCm * 1.5) + 2
  // Equivalent to (footCm + 1.5) / (2/3)
  return (footCm * 1.5) + 2;
}

// Tip: Standard
double tip(double bill, double percent) => bill * percent / 100;

// Golf Handicap: Basic differential (most common simple version)
double golfHandicap(double score, double rating) =>
    (score - rating) * 0.96;

String sleepCalculator({
  required DateTime bedTime,
  required DateTime wakeTime,
}) {
  // Handle cases where wakeTime is on the next day (e.g., slept past midnight)
  DateTime effectiveWakeTime = wakeTime;
  if (wakeTime.isBefore(bedTime)) {
    effectiveWakeTime = wakeTime.add(const Duration(days: 1));
  }

  // Calculate total sleep duration
  Duration sleepDuration = effectiveWakeTime.difference(bedTime);
  double hours = sleepDuration.inMinutes / 60.0;

  // Get the remark based on hours
  String remark = sleepRemark(hours);

  // Format nicely: total hours with 1 decimal + remark
  String hoursText = hours.toStringAsFixed(1);

  return "$hoursText hours\n$remark";
}

String sleepRemark(double hrs) {
  if (hrs < 5) return "Zombie mode activated 🧟‍♂️ Seriously, recharge!";
  if (hrs < 6) return "Running on fumes 😴 You need more rest!";
  if (hrs < 7) return "Okay, but could be better 💤 Aim higher!";
  if (hrs < 8) return "Solid sleep 🧠 Well done!";
  if (hrs < 9) return "Sleep champion 👑 Great job!";
  return "Sleep master 🛌 You're living the dream!";
}