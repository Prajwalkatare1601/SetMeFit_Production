// diet_page.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'add_food_page.dart';
import 'package:intl/intl.dart';
import 'package:food_log/providers/home_provider.dart';
import 'package:food_log/providers/history_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ────────────────────────────────────────────────
//  BLACK + ORANGE / YELLOW / RED THEME
//  Water page → shades of blue only
// ────────────────────────────────────────────────

const Color kBg          = Color(0xFF0B0B0F);
const Color kSurface     = Color(0xFF16161E);
const Color kCard        = Color(0xFF1F1F2A);
const Color kAccent      = Color(0xFFFF6200);     // main orange
const Color kAccentLight = Color(0xFFFFA726);     // lighter orange
const Color kYellow      = Color(0xFFFFD54F);     // yellow highlight
const Color kRedAccent   = Color(0xFFFF3D00);     // red fire
const Color kGlow        = Color(0xFFFF9500);
const Color kTextLight   = Color(0xFFEEEEEE);
const Color kTextMuted   = Color(0xFFAAAAAA);

// Water theme (blue only)
const Color kWaterBg     = Color(0xFF021526);
const Color kWaterSurf   = Color(0xFF0A2A44);
const Color kWaterPrim   = Color(0xFF00A8E8);
const Color kWaterLight  = Color(0xFF4FC3F7);
const Color kWaterGlow   = Color(0xFF81D4FA);

class DietAppDemo extends StatelessWidget {
  const DietAppDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kAccentLight),
          onPressed: () => Navigator.pop(context),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [kYellow, kAccent, kRedAccent],
          ).createShader(bounds),
          child: const Text(
            'FOOD FUEL🔥⚡',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.5,
              color: Colors.white,
            ),
          ),
        ),
      ),
      body: const HomePage(),
    );
  }
}

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});
  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with TickerProviderStateMixin {
  static const int fallbackCalorieGoal = 2000; // default if no record
  int userCalorieGoal = fallbackCalorieGoal;
  final supabase = Supabase.instance.client;
  late AnimationController _logPulse;

  @override
  void initState() {
    super.initState();
    _logPulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    _fetchUserCalorieGoal();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listenManual(combinedLogsProvider, (prev, next) {
        _syncTotalsToSupabase(next);
        if ((next?.length ?? 0) > (prev?.length ?? 0)) {
          _logPulse.forward(from: 0.0);
        }
      }, fireImmediately: true);
    });
  }

  Future<void> _fetchUserCalorieGoal() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final response = await supabase
          .from('user_targets')
          .select('target_calories')
          .eq('user_id', user.id)
          .maybeSingle();

      if (mounted && response != null) {
        final target = response['target_calories'] as double?;
        if (target != null && target > 0) {
          setState(() {
            userCalorieGoal = target.round(); // or keep as double if you prefer
          });
        }
      }
    } catch (e) {
      debugPrint("Failed to fetch user calorie goal: $e");
      // fallback already set to 2000
    }
  }

  Future<void> _syncTotalsToSupabase(List<Map<String, dynamic>> logs) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    double cal = 0, prot = 0, carb = 0, fat = 0;
    for (var log in logs) {
      cal  += (log['total_calories'] ?? 0).toDouble();
      prot += (log['total_protein'] ?? 0).toDouble();
      carb += (log['total_carbs']   ?? 0).toDouble();
      fat  += (log['total_fat']     ?? 0).toDouble();
    }

    try {
      await supabase.from('diet_logs').upsert({
        'user_id': user.id,
        'log_date': today,
        'total_calories': cal.round(),
        'total_protein': prot.round(),
        'total_carbs': carb.round(),
        'total_fat': fat.round(),
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,log_date');
    } catch (e) {
      debugPrint("Sync error: $e");
    }
  }

  @override
  void dispose() {
    _logPulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final historyAsync = ref.watch(historyProvider(todayDate));

    return historyAsync.when(
      loading: () => const Scaffold(
        backgroundColor: kBg,
        body: Center(child: CircularProgressIndicator(color: kAccent)),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: kBg,
        body: Center(child: Text("Error: $err", style: const TextStyle(color: kTextLight))),
      ),
      data: (_) {
        final logs = ref.watch(combinedLogsProvider);

        double totalCal = 0, totalProt = 0, totalCarb = 0, totalFat = 0;
        for (final log in logs) {
          totalCal  += (log['total_calories'] ?? 0).toDouble();
          totalProt += (log['total_protein'] ?? 0).toDouble();
          totalCarb += (log['total_carbs']   ?? 0).toDouble();
          totalFat  += (log['total_fat']     ?? 0).toDouble();
        }

        final caloriesConsumed = totalCal.round();
        final remaining = (userCalorieGoal - caloriesConsumed).clamp(0, 99999);
        final progress = (caloriesConsumed / userCalorieGoal).clamp(0.0, 1.0);

        final grouped = groupLogsByMeal(logs);

        return Scaffold(
          backgroundColor: kBg,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tabs
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: const [
                      _Tab("TODAY", true),
                      SizedBox(width: 12),
                      _Tab("WEEK", false),
                      SizedBox(width: 12),
                      _Tab("MONTH", false),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [kSurface, kBg],
                      ),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Compact Energy Core
                          _EnergyCore(
                            calorieGoal: userCalorieGoal,
                            consumed: caloriesConsumed,
                            remaining: remaining,
                            progress: progress,
                            protein: totalProt.round(),
                            carbs: totalCarb.round(),
                            fat: totalFat.round(),
                            pulseCtrl: _logPulse,
                          ),

                          const SizedBox(height: 28),

                          Row(
                            children: [
                              Expanded(
                                child: _ActionBtn(
                                  icon: Icons.local_drink,
                                  label: "HYDRATE",
                                  isHydrate: true,           // ← blue style
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const WaterPage()),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _ActionBtn(
                                  icon: Icons.ramen_dining,
                                  label: "LOG MEAL",
                                  isHydrate: false,          // ← orange style
                                  onTap: () async {
                                    final added = await Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const AddFoodPage()),
                                    );
                                    if (added != null && mounted) {
                                      ref.invalidate(historyProvider(todayDate));
                                      ref.invalidate(combinedLogsProvider);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text("+$added added 🔥"),
                                          backgroundColor: kAccent,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          const Padding(
                            padding: EdgeInsets.only(left: 8, bottom: 6),
                            child: Text(
                              "TODAY'S LOGS",
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kAccentLight),
                            ),
                          ),

                          if (logs.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 60),
                                child: Text(
                                  "No entries yet\nStart fueling! 🚀",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: kTextMuted, fontSize: 16),
                                ),
                              ),
                            )
                          else
                            ...grouped.entries
                                .where((e) => e.value.isNotEmpty)
                                .map((entry) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
                                  child: Text(
                                    "${entry.key} 🍽️",
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: kAccentLight,
                                    ),
                                  ),
                                ),
                                ...entry.value.map((log) => _LogCard(log, todayDate)),
                              ],
                            ))
                                .toList(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Map<String, List<Map<String, dynamic>>> groupLogsByMeal(List<Map<String, dynamic>> logs) {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final log in logs) {
      final dt = DateTime.parse(log['consumed_at'] ?? DateTime.now().toIso8601String());
      final h = dt.hour;
      final label = h < 11 ? "Breakfast" : h < 15 ? "Lunch" : h < 19 ? "Snacks" : "Dinner";
      map.putIfAbsent(label, () => []).add(log);
    }
    map.forEach((k, v) => v.sort((a, b) => DateTime.parse(a['consumed_at'] ?? '').compareTo(DateTime.parse(b['consumed_at'] ?? ''))));
    return map;
  }

  Widget _LogCard(Map<String, dynamic> log, DateTime today) {
    final isMeal = log['type'] == "meal";
    final id = isMeal ? log['meal_log_id'] ?? log['id'] : log['id'];
    final name = log['name'] ?? "Unknown";
    final emoji = log['emoji'] ?? (isMeal ? "🍲" : "🍎");

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) => Transform.scale(
        scale: 0.96 + 0.04 * t,
        child: Opacity(
          opacity: t,
          child: GestureDetector(
            // subtle press feedback on whole card
            onTapDown: (_) => setState(() {}), // optional: can be used later for more
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: kCard.withOpacity(0.92),
                borderRadius: BorderRadius.circular(22),
                border: Border(
                  left: BorderSide(
                    color: kAccent,
                    width: 6,
                  ),
                ),
                boxShadow: [
                  // main glow
                  BoxShadow(
                    color: kGlow.withOpacity(0.45),
                    blurRadius: 16,
                    spreadRadius: 1,
                    offset: const Offset(0, 6),
                  ),
                  // subtle inner glow on left side
                  BoxShadow(
                    color: kAccent.withOpacity(0.25),
                    blurRadius: 20,
                    spreadRadius: -8,
                    offset: const Offset(-10, 0),
                  ),
                ],
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    kCard,
                    kCard.withOpacity(0.85),
                    Color.lerp(kCard, kAccent, 0.08)!,
                  ],
                  stops: const [0.0, 0.7, 1.0],
                ),
              ),
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: kAccent.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: kAccent.withOpacity(0.5),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                    border: Border.all(
                      color: kAccent.withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                ),
                title: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    color: kTextLight,
                    letterSpacing: 0.2,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    "${DateFormat('HH:mm').format(DateTime.parse(log['consumed_at'] ?? DateTime.now().toString()))}  •  ${log['total_calories'] ?? 0} kcal",
                    style: TextStyle(
                      fontSize: 13.5,
                      color: kTextMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                trailing: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: kRedAccent,
                    size: 28,
                  ),
                  splashRadius: 24,
                  tooltip: "Delete entry",
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: kSurface,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: const Text(
                          "Delete entry?",
                          style: TextStyle(color: kTextLight),
                        ),
                        content: Text(
                          "Remove ${isMeal ? "meal" : "food"}?",
                          style: TextStyle(color: kTextMuted),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text(
                              "Delete",
                              style: TextStyle(color: kRedAccent),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true && mounted) {
                      final success = await ref.read(homeProvider.notifier).deleteLog(
                        logType: isMeal ? "meal" : "food",
                        id: id,
                      );
                      if (success) {
                        ref.refresh(historyProvider(today));
                      }
                    }
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────
//  COMPACT ENERGY CORE
// ────────────────────────────────────────────────

class _EnergyCore extends StatelessWidget {
  final int calorieGoal;
  final int consumed;
  final int remaining;
  final double progress;
  final int protein;
  final int carbs;
  final int fat;
  final AnimationController pulseCtrl;

  const _EnergyCore({
    required this.calorieGoal,
    required this.consumed,
    required this.remaining,
    required this.progress,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.pulseCtrl,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kCard, Color(0xFF1A0F00)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: kAccent.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(color: kGlow.withOpacity(0.45), blurRadius: 28, spreadRadius: 3),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text("ENERGY", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kYellow)),
              SizedBox(width: 8),
              Text("CORE", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kAccent)),
              SizedBox(width: 8),
              Text("🔥", style: TextStyle(fontSize: 20)),
            ],
          ),
          const SizedBox(height: 12),

          SizedBox(
            height: 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: pulseCtrl,
                  builder: (_, __) => CustomPaint(
                    size: const Size(170, 170),
                    painter: _FireRingPainter(
                      progress: progress,
                      pulse: pulseCtrl.value,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TweenAnimationBuilder<int>(
                      tween: IntTween(begin: 0, end: consumed),
                      duration: const Duration(milliseconds: 1000),
                      builder: (_, v, __) => Text(
                        "$v",
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          foreground: Paint()..shader = const LinearGradient(colors: [kTextLight, kTextMuted]).createShader(const Rect.fromLTWH(0,0,120,50)),
                        ),
                      ),
                    ),
                    Text("Kcal", style: TextStyle(fontSize: 16, color: kAccentLight)),
                    const SizedBox(height: 4),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      "Remaining: $remaining Kcal",
                      style: TextStyle(fontSize: 13, color: kRedAccent, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 150),
                    Text(
                      "Goal: $calorieGoal Kcal",
                      style: TextStyle(fontSize: 16, color: Colors.green),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _MacroMini("💪Protein", "$protein g", kAccent),
              _MacroMini("🍚Carbs", "$carbs g", kYellow),
              _MacroMini("🧈Fat", "$fat g", kRedAccent),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            _getInsight(consumed, protein, carbs, fat),
            style: TextStyle(fontSize: 13.5, color: kYellow.withOpacity(0.9), fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getInsight(int cal, int p, int c, int f) {
    final bool highProtein = p > 100;
    final bool goodProtein = p >= 70 && p <= 100;
    final bool lowProtein = p < 50;

    final bool highCarbs = c > 200;
    final bool moderateCarbs = c >= 120 && c <= 200;
    final bool lowCarbs = c < 80;

    final bool highFat = f > 80;
    final bool balancedFat = f >= 40 && f <= 80;
    final bool lowFat = f < 30;

    final double progress = cal / calorieGoal;
    final bool almostFull = progress > 0.85;
    final bool overGoal = progress > 1.0;
    final bool lowIntake = progress < 0.5;
    final bool decentIntake = progress >= 0.5 && progress <= 0.85;

    // ────────────────────────────────────────────────
    // Priority: over/under eating → macro imbalances → strong positives
    // ────────────────────────────────────────────────

    if (overGoal) {
      return "Whoa – energy overload detected! 🌋 $cal kcal today • Time to ease off or go burn it 🔥";
    }

    if (lowIntake) {
      if (lowProtein) {
        return "Fuel tank almost empty... and low on protein 😴 Add some power food soon! 💪";
      }
      return "Quiet day in the reactor... only $cal kcal • Time to refuel captain 🚀";
    }

    if (almostFull) {
      if (highProtein) {
        return "You're almost at max – and protein is crushing it! 💪🟢 Smart work today";
      }
      if (highCarbs) {
        return "Close to full tank – carb dominant day 🍚⚡ Use the energy wisely!";
      }
      return "Approaching core capacity ($cal / $calorieGoal) • Choose your last fuel drop carefully ⚠️";
    }

    // ────────────────────────────────────────────────
    // Macro-dominant personalities
    // ────────────────────────────────────────────────

    if (highProtein && goodProtein && !highCarbs && !highFat) {
      return "Protein beast mode – muscles are loving this day! 🏋️‍♂️💪 Keep ruling!";
    }

    if (highProtein && highCarbs) {
      return "Anabolic rocket launch detected! 💥 High protein + high carbs = growth mode activated";
    }

    if (highCarbs && lowFat && lowProtein) {
      return "Pure carb rocket fuel day 🍙✨ Energy is high, but maybe sneak in some protein next time?";
    }

    if (highFat && lowCarbs) {
      return "Fat-adapted warrior status • 🧈🔥 Steady ketones, low drama";
    }

    if (highFat && highProtein && moderateCarbs) {
      return "Keto-ish legend loading... high fat + high protein • You're basically a fat-burning machine";
    }

    // ────────────────────────────────────────────────
    // Balanced & positive vibes
    // ────────────────────────────────────────────────

    if (balancedFat && goodProtein && moderateCarbs && decentIntake) {
      return "Textbook balanced macro day – you're operating like a high-performance engine 🟢⚙️";
    }

    if (goodProtein && moderateCarbs && balancedFat) {
      return "Solid all-rounder intake • Protein strong, carbs useful, fats happy • Peak human vibes";
    }

    if (progress > 0.7 && goodProtein) {
      return "Strong progress + solid protein • You're building something great today 💪🚀";
    }

    // ────────────────────────────────────────────────
    // Gentle nudges / light humor
    // ────────────────────────────────────────────────

    if (lowProtein && decentIntake) {
      return "Calories look good... but where is the protein army? 👀 Time to recruit some";
    }

    if (lowFat && highCarbs) {
      return "Carb king/queen energy 🍚👑 Maybe invite some healthy fats to the party next time?";
    }

    if (cal > 0 && cal < 300) {
      return "Early morning fuel check? Still warming up the engines... ☕→🍳";
    }

    // Default / fallback messages – rotate a few fun ones
    final List<String> defaults = [
      "Steady burn – keep fueling the reactor! ⚡🔥",
      "Energy signature detected – looking strong today 🚀",
      "Core is humming nicely • Maintain course! 🌌",
      "Fuel log updated • You're writing a good story 💪",
      "Another page in the legend of your gains 📈",
    ];

    return defaults[DateTime.now().millisecond % defaults.length];
  }
}

class _FireRingPainter extends CustomPainter {
  final double progress;
  final double pulse;

  _FireRingPainter({required this.progress, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.38;

    // Glow layers
    for (int i = 0; i < 4; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r + i * 5),
        -math.pi / 2,
        math.pi * 2 * progress,
        false,
        Paint()
          ..color = kGlow.withOpacity((0.4 - i * 0.1) * (1 + pulse * 0.3))
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 14 + i * 4),
      );
    }

    // Main ring
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      Paint()
        ..shader = const LinearGradient(colors: [kYellow, kAccent, kRedAccent]).createShader(Rect.fromCircle(center: c, radius: r + 15))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 13
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _FireRingPainter old) => true;
}

Widget _MacroMini(String emoji, String value, Color color) {
  return Column(
    children: [
      Text(emoji, style: TextStyle(fontSize: 24,color: color)),
      Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
    ],
  );
}

Widget _ActionBtn({
  required IconData icon,
  required String label,
  required VoidCallback onTap,
  required bool isHydrate,   // ← new required parameter to distinguish the button
}) {
  final isBlue = isHydrate;

  final gradientColors = isBlue
      ? const [Color(0xFF00B4FF), Color(0xFF4FC3F7)]
      : const [Color(0xFFFF6200), Color(0xFFFFA726)];

  final glowColor = isBlue
      ? const Color(0xFF81D4FA)
      : const Color(0xFFFF9500);

  return GestureDetector(
    onTapDown: (_) {
      // Optional: you can add feedback here if you want
    },
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: glowColor.withOpacity(0.55),
            blurRadius: 18,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 26,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    ),
  );
}

class _Tab extends StatelessWidget {
  final String label;
  final bool active;

  const _Tab(this.label, this.active);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: active ? kAccent : Colors.transparent,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: kAccent, width: active ? 0 : 1.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? Colors.black : kAccentLight,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────
// WATER PAGE – shades of blue only
// ────────────────────────────────────────────────

class WaterPage extends StatefulWidget {
  const WaterPage({super.key});

  @override
  State<WaterPage> createState() => _WaterPageState();
}

class _WaterPageState extends State<WaterPage> with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  int currentMl = 0;
  final int goal = 3000;
  List<Map<String, dynamic>> todayLogs = []; // in-memory only: {amount_ml, added_at}

  late AnimationController _waveCtrl;

  String get todayDate => DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();

    _loadTodayWater();
  }

  Future<void> _loadTodayWater() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    // Load current total from Supabase
    final res = await supabase
        .from('water_logs')
        .select('amount')
        .eq('user_id', user.id)
        .eq('log_date', todayDate)
        .maybeSingle();

    if (mounted) {
      setState(() {
        currentMl = res?['amount'] as int? ?? 0;
      });
    }

    // Clean old in-memory logs (>24h)
    final now = DateTime.now();
    setState(() {
      todayLogs.removeWhere((log) {
        final added = log['added_at'] as DateTime;
        return now.difference(added).inHours >= 24;
      });
    });
  }

  Future<void> _addWater(int ml) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final newTotal = currentMl + ml;
    final now = DateTime.now();

    // Update/insert daily total
    await supabase.from('water_logs').upsert({
      'user_id': user.id,
      'log_date': todayDate,
      'amount': newTotal,
      'logged_at': now.toIso8601String(),
    }, onConflict: 'user_id,log_date');

    if (mounted) {
      setState(() {
        currentMl = newTotal;
        todayLogs.add({
          'amount_ml': ml,
          'added_at': now,
        });
      });
    }
  }

  Future<void> _deleteLog(int index) async {
    final entry = todayLogs[index];
    final mlToRemove = entry['amount_ml'] as int;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kWaterSurf,
        title: const Text("Remove entry?", style: TextStyle(color: Colors.white)),
        content: Text("Delete +$mlToRemove ml?", style: TextStyle(color: kWaterLight)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final user = supabase.auth.currentUser;
    if (user == null) return;

    final newTotal = currentMl - mlToRemove;

    await supabase.from('water_logs').update({
      'amount': newTotal,
      'logged_at': DateTime.now().toIso8601String(),
    }).eq('user_id', user.id).eq('log_date', todayDate);

    setState(() {
      currentMl = newTotal;
      todayLogs.removeAt(index);
    });
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (currentMl / goal).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: kWaterBg,
      appBar: AppBar(
        backgroundColor: kWaterSurf,
        title: const Text(
          "HYDRO FLOW",
          style: TextStyle(color: kWaterLight, fontWeight: FontWeight.w800, letterSpacing: 1.5),
        ),
        iconTheme: const IconThemeData(color: kWaterLight),
      ),
      body: Column(
        children: [
          const SizedBox(height: 30),

          // Smaller sphere – 200×200
          Center(
            child: SizedBox(
              width: 200,
              height: 200,
              child: AnimatedBuilder(
                animation: _waveCtrl,
                builder: (_, __) => CustomPaint(
                  painter: _WaterSpherePainter(progress: progress, phase: _waveCtrl.value),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          Text(
            "$currentMl ml 🥤",
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),

          Text(
            "of $goal ml goal",
            style: TextStyle(fontSize: 16, color: kWaterLight.withOpacity(0.9)),
          ),

          const SizedBox(height: 8),

          Text(
            "${(progress * 100).toStringAsFixed(0)}% hydrated ${progress > 0.75 ? '💧🔥' : '💧'}",
            style: TextStyle(fontSize: 17, color: kWaterLight, fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 100),
          // Quick add buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [100, 250, 500].map((ml) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: ElevatedButton(
                      onPressed: () => _addWater(ml),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kWaterPrim,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 10,
                        shadowColor: kWaterGlow.withOpacity(0.6),
                      ),
                      child: Text(
                        "+$ml ml",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────
// Restored original sphere painter (visible wave + rim)
// ────────────────────────────────────────────────

class _WaterSpherePainter extends CustomPainter {
  final double progress;
  final double phase;

  _WaterSpherePainter({required this.progress, required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Outer glow (visible even at low progress)
    canvas.drawCircle(
      center,
      radius + 14,
      Paint()
        ..color = kWaterGlow.withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
    );

    // Wave path – starts higher so it's always visible
    final path = Path();
    final baseY = size.height * (1 - progress) - 25; // raised position
    path.moveTo(0, size.height);
    for (double x = 0; x <= size.width; x += 2) {
      final wave = math.sin(x / size.width * math.pi * 4 + phase * 5) * 20;
      path.lineTo(x, baseY + wave);
    }
    path.lineTo(size.width, size.height);
    path.close();

    // Clip to circle
    canvas.clipPath(Path()..addOval(rect));

    // Dark background inside circle
    canvas.drawOval(rect, Paint()..color = const Color(0xFF001F3F));

    // Wave fill with gradient
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          colors: [kWaterPrim, kWaterLight, kWaterPrim],
          stops: [0.0, 0.5, 1.0],
        ).createShader(rect),
    );

    // Bright rim highlight
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = kWaterLight.withOpacity(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12,
    );
  }

  @override
  bool shouldRepaint(covariant _WaterSpherePainter old) => old.progress != progress || old.phase != phase;
}