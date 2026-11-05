import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math' as math;
import 'wheel.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'health_activity_page.dart';
import 'diet_page.dart';
import 'medical_vitals_page.dart';
import 'wellbeing_ui.dart';
import 'tongue.dart';
import 'chat_page.dart';
import 'healthscore_report.dart';
import '/providers/health_score_engine.dart';
import '/features/workout/presentation/workout_screen.dart';

class HomePage extends ConsumerStatefulWidget {
  final bool useGradientBackground;
  const HomePage({super.key, this.useGradientBackground = true});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with SingleTickerProviderStateMixin {
  int selectedIndex = 2;
  final double delta = 5;
  String firstName = "AGENT";
  late AnimationController _controller;

  final labels = ['Activities', 'Well-Being', 'Diet', 'Medical', 'Tongue'];
  final icons = [
    Icons.directions_run_rounded,
    Icons.self_improvement_rounded,
    Icons.restaurant_rounded,
    Icons.monitor_heart_rounded,
    Icons.spa_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _getFirstName();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15), // Slower for premium feel
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _getFirstName() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('first_name')
          .eq('id', user.id)
          .single();

      if (mounted) {
        setState(() {
          firstName = data['first_name'] ?? "USER";
        });
      }
    } catch (e) {
      debugPrint("Error fetching name: $e");
    }
  }

  void _onSliceTap(int idx) {
    setState(() => selectedIndex = idx);
    final List<Widget> pages = [
      ActivityTrackingPage(),
      const WellbeingPage(),
      const DietAppDemo(),
      const VitalsPage(),
      const TongueDashboardPage(),
    ];
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => pages[idx]),
    ).then((_) => ref.invalidate(healthDataStreamProvider));
  }

  final healthScoreProvider = FutureProvider<double>((ref) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) return 0.0;

    try {
      // We use maybeSingle() to avoid exceptions if the row is still being written
      final data = await supabase
          .from('user_health_profiles')
          .select('health_score')
          .eq('id', user.id)
          .maybeSingle();

      if (data == null || data['health_score'] == null) {
        return 0.0;
      }

      // Cast precisely: Convert int from DB to double for Flutter
      return (data['health_score'] as int).toDouble();
    } catch (e) {
      debugPrint('Error reading health_score: $e');
      return 0.0;
    }
  });

  Future<void> _updateHealthScore(double score) async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId != null) {
        await supabase
            .from('profiles')
            .update({
          // Ensure it is stored as a rounded 3-digit integer
          'health_score': score.round().clamp(0, 999),
        })
            .eq('id', userId);
      }
    } catch (e) {
      debugPrint("Failed to update health score: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Watch the master score (handles fallback logic)
    final scoreAsync = ref.watch(finalScoreProvider);
    // 2. Watch raw data for roadmap cards
    final dataAsync = ref.watch(healthDataStreamProvider);

    // Extract values safely
    final double result = scoreAsync.maybeWhen(
      data: (score) {
        final finalScore = score ?? 0.0;

        // Trigger the Supabase update asynchronously
        // We use Future.microtask or simply call it without await if we
        // don't want to block the UI rendering.
        if (finalScore > 0) {
          _updateHealthScore(finalScore);
        }

        return finalScore;
      },
      orElse: () => 0.0,
    );



    final healthData = dataAsync.value ?? {};
    final String stepCount = (healthData['activity']?['steps'] ?? 0).toString();
    final String sleepHours = (healthData['wellbeing']?['sleep_hours'] ?? 0.0).toStringAsFixed(1);
    final String calConsumed = (healthData['diet']?['calories'] ?? 0).toString();
    final String bpValue = healthData['vitals']?['systolic'] != null
        ? "${healthData['vitals']?['systolic']}/${healthData['vitals']?['diastolic']}"
        : "--/--";
    final String tongueColor = (healthData['tongue']?['color'] ?? "Not Checked").toString();

    final width = MediaQuery.of(context).size.width;
    final wheelSize = (width * 0.65).clamp(200.0, 260.0);

    return Scaffold(
      backgroundColor: const Color(0xFF050505), // Deeper Black
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false, // Ensures text stays on the left
        title: RichText(
          text: TextSpan(
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: Colors.white,
              fontFamily: 'Inter',
            ),
            children: [
              const TextSpan(text: 'Hello, '),
              TextSpan(
                text: firstName.isNotEmpty ? firstName : "AGENT",
                style: const TextStyle(color: Colors.cyanAccent),
              ),
              const TextSpan(text: ' ! 😊👋'),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ScoreCalculator()))
                    .then((_) => ref.invalidate(healthDataStreamProvider));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: const Color(0xFF37CD58).withOpacity(0.4), blurRadius: 12)],
                    gradient: const LinearGradient(colors: [Color(0xFF7DF57A), Color(0xFF37CD58)])),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${result.toInt()} Score',
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_ios, size: 10, color: Colors.black54),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ULTIMATE NEON BACKGROUND
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: UltimateNeonPainter(_controller.value),
                );
              },
            ),
          ),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: () async => ref.refresh(healthDataStreamProvider.future),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    SizedBox(
                      height: wheelSize,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: WheelWithCenter(
                          diameter: wheelSize,
                          labels: labels,
                          icons: icons,
                          visibleScore: result,
                          delta: delta,
                          minScore: 250,
                          maxScore: 1000,
                          selectedIndex: selectedIndex,
                          onSliceTap: _onSliceTap,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _healthStatsGraph(stepCount, sleepHours, calConsumed, bpValue, tongueColor, width),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'chat_page_fab',
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatPage())),
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 10,
        shape: CircleBorder(side: BorderSide(color: Colors.blueAccent.withOpacity(0.4), width: 1.5)),
        child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
      ),
    );
  }
  final galacticHealthProvider = FutureProvider<Map<String, dynamic>>((ref) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return {};

    final results = await Future.wait([
      supabase.from('activity_logs').select().eq('user_id', user.id).order('date', ascending: false).limit(1).maybeSingle(),
      supabase.from('wellbeing_logs').select().eq('user_id', user.id).order('log_date', ascending: false).limit(1).maybeSingle(),
      supabase.from('medical_vitals').select().eq('user_id', user.id).maybeSingle(),
      supabase.from('tongue_records').select().eq('user_id', user.id).order('timestamp', ascending: false).limit(1).maybeSingle(),
    ]);

    return {
      'activity': results[0] ?? {},
      'wellbeing': results[1] ?? {},
      'vitals': results[2] ?? {},
      'tongue': results[3] ?? {},
    };
  });

  Widget _healthStatsGraph(String steps, String sleep, String kcal, String bp, String tongue, double screenWidth) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final ValueNotifier<int> activeIndex = ValueNotifier<int>(0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 40, offset: const Offset(0, 20))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF4F46E5)]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.4), blurRadius: 25)],
                ),
                child: const Icon(Icons.route_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 18),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PERFORMANCE TRACKER', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)),
                    Text('Current Report Card • Live Updates', style: TextStyle(fontSize: 12, color: Colors.white60, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // TAB SELECTOR
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: ValueListenableBuilder<int>(
              valueListenable: activeIndex,
              builder: (context, current, _) {
                final cats = ['Activity', 'Wellbeing', 'Diet', 'Vitals', 'Tongue'];
                final ics = [Icons.directions_run, Icons.nights_stay, Icons.restaurant, Icons.monitor_heart, Icons.lens_blur];
                final cols = [const Color(0xFF6366F1), const Color(0xFF8B5CF6), const Color(0xFF0EA5E9), const Color(0xFFEC4899), const Color(0xFF84CC16)];

                return Row(
                  children: List.generate(5, (i) {
                    bool isSelected = current == i;
                    return GestureDetector(
                      onTap: () => activeIndex.value = i,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? cols[i] : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isSelected ? cols[i] : Colors.white.withOpacity(0.1), width: 1),
                        ),
                        child: Row(
                          children: [
                            Icon(ics[i], color: isSelected ? Colors.white : Colors.white38, size: 16),
                            if (isSelected) const SizedBox(width: 8),
                            if (isSelected) Text(cats[i], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
          const SizedBox(height: 22),

          // NESTED STREAMS FOR DATA
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: Supabase.instance.client.from('user_targets').stream(primaryKey: ['user_id']).eq('user_id', userId ?? ''),
            builder: (context, targetSnapshot) {
              final targetData = targetSnapshot.data?.firstOrNull ?? {};
              final double tCal = (targetData['target_calories'] ?? 2000).toDouble();
              final double tSleep = (targetData['target_sleep'] ?? 8).toDouble();
              final double tSteps = (targetData['target_steps'] ?? 10000).toDouble();

              return StreamBuilder<List<Map<String, dynamic>>>(
                stream: Supabase.instance.client.from('activity_logs').stream(primaryKey: ['id']).order('date', ascending: false).limit(1),
                builder: (context, activitySnapshot) {
                  final activityData = activitySnapshot.data?.firstOrNull ?? {};

                  return StreamBuilder<List<Map<String, dynamic>>>(
                    stream: Supabase.instance.client.from('wellbeing_logs').stream(primaryKey: ['id']).order('log_date', ascending: false).limit(1),
                    builder: (context, wellbeingSnapshot) {
                      final wellbeingData = wellbeingSnapshot.data?.firstOrNull ?? {};

                      return StreamBuilder<List<Map<String, dynamic>>>(
                        stream: Supabase.instance.client.from('medical_vitals').stream(primaryKey: ['user_id']).order('log_date', ascending: false).limit(1),
                        builder: (context, vitalsSnapshot) {
                          final vitalsData = vitalsSnapshot.data?.firstOrNull ?? {};

                          return StreamBuilder<List<Map<String, dynamic>>>(
                            stream: Supabase.instance.client.from('tongue_records').stream(primaryKey: ['id']).order('timestamp', ascending: false).limit(1),
                            builder: (context, tongueSnapshot) {
                              final tongueData = tongueSnapshot.data?.firstOrNull ?? {};

                              // DIET LOGS STREAM
                              return StreamBuilder<List<Map<String, dynamic>>>(
                                stream: Supabase.instance.client.from('diet_logs').stream(primaryKey: ['id']).eq('user_id', userId ?? '').order('log_date', ascending: false).limit(1),
                                builder: (context, dietSnapshot) {
                                  final dietRaw = dietSnapshot.data?.firstOrNull ?? {};
                                  // Validate it's for today
                                  final dietData = (dietRaw['log_date'] == today) ? dietRaw : {};

                                  final combinedData = {
                                    'activity': activityData,
                                    'wellbeing': wellbeingData,
                                    'vitals': vitalsData,
                                    'tongue': tongueData,
                                    'diet': dietData,
                                  };

                                  return ValueListenableBuilder<int>(
                                    valueListenable: activeIndex,
                                    builder: (context, selectedIdx, _) {
                                      return _buildPitstopRoadmapJourney(
                                        dbData: combinedData,
                                        targetCal: tCal,
                                        targetSleep: tSleep,
                                        targetSteps: tSteps,
                                        kcalFallback: kcal,
                                        selectedIndex: selectedIdx,
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
  Widget _buildPitstopRoadmapJourney({
    required Map<String, dynamic> dbData,
    required double targetCal, required double targetSleep, required double targetSteps,
    required String kcalFallback,
    required int selectedIndex,
  }) {
    final categories = ['Activity', 'Wellbeing', 'Diet', 'Vitals', 'Tongue'];
    final icons = [Icons.directions_run, Icons.nights_stay, Icons.restaurant, Icons.monitor_heart, Icons.lens_blur];
    final pages = [ActivityTrackingPage(), const WellbeingPage(), const DietAppDemo(), const VitalsPage(), const TongueDashboardPage()];
    final pitstopColors = [const Color(0xFF6366F1), const Color(0xFF8B5CF6), const Color(0xFF0EA5E9), const Color(0xFFEC4899), const Color(0xFF84CC16)];

    return Column(
      children: [
        Container(
          height: 6,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF374151), Color(0xFF1F2937), Color(0xFF111827)]),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(height: 20),

        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildSingleRoadmapCard(
            key: ValueKey<int>(selectedIndex),
            index: selectedIndex,
            categories: categories,
            icons: icons,
            pages: pages,
            pitstopColors: pitstopColors,
            dbData: dbData,
            targetSteps: targetSteps,
            targetSleep: targetSleep,
            targetCal: targetCal,
            kcalFallback: kcalFallback,
          ),
        ),
      ],
    );
  }

  Widget _buildSingleRoadmapCard({
    required Key key,
    required int index,
    required List<String> categories,
    required List<IconData> icons,
    required List<Widget> pages,
    required List<Color> pitstopColors,
    required Map<String, dynamic> dbData,
    required double targetSteps, required double targetSleep, required double targetCal,
    required String kcalFallback,
  }) {
    String actual = ""; String target = ""; double percent = 0.0;
    Map<String, String> dataStrip = {};

    if (index == 0) {
      final steps = dbData['activity']?['steps'] ?? 0;
      actual = "$steps Steps"; target = "${targetSteps.toInt()}";
      percent = steps / (targetSteps > 0 ? targetSteps : 1);
      dataStrip = {
        "Gym": "${dbData['activity']?['gym_min'] ?? 0}m",
        "Yoga": "${dbData['activity']?['yoga_min'] ?? 0}m",
        "Running": "${dbData['activity']?['run_data']?['time'] ?? '0'}m",
        "Sports": "${dbData['activity']?['sports_min'] ?? 0}m"
      };
    } else if (index == 1) {
      final hrs = (dbData['wellbeing']?['sleep_hours'] ?? 0.0).toDouble();
      actual = "$hrs H"; target = "${targetSleep.toInt()} H";
      percent = hrs / (targetSleep > 0 ? targetSleep : 1);
      dataStrip = {"Meditation": "${dbData['wellbeing']?['meditation_min'] ?? 0}m", "Mood": "${dbData['wellbeing']?['happiness_mood'] ?? 'N/A'}", "Music": "${dbData['wellbeing']?['music_min'] ?? 0}m", "Hobby": "${dbData['wellbeing']?['hobby_level'] ?? 'N/A'}"};
    } else if (index == 2) {
      // --- LOGIC FOR DIET PILLAR ---
      final cal = (dbData['diet']?['total_calories'] ?? 0).toInt();
      actual = "$cal Kcal";
      target = "${targetCal.toInt()}";
      percent = cal / (targetCal > 0 ? targetCal : 1);
      dataStrip = {
        "Protein Consumed": "${dbData['diet']?['total_protein'] ?? 0}g",
        "Carbs Taken": "${dbData['diet']?['total_carbs'] ?? 0}g",
        "Fats Added": "${dbData['diet']?['total_fat'] ?? 0}g",
      };
    } else if (index == 3) {
      final sys = dbData['vitals']?['systolic'] ?? 0;
      final dia = dbData['vitals']?['diastolic'] ?? 0;
      actual = sys > 0 ? "$sys/$dia" : "Pending"; target = "120/80";
      percent = (sys <= 0 || dia <= 0) ? 0.0 : (sys < 120 && dia < 80) ? 1.0 : (sys >= 120 && sys < 130 && dia <= 80) ? 0.85 : ((sys >= 130 && sys < 140) || (dia >= 80 && dia < 90)) ? 0.65 : ((sys >= 140 && sys < 180) || (dia >= 90 && dia < 120)) ? 0.40 : 0.20;
      dataStrip = {"Sugar": "${dbData['vitals']?['sugar'] ?? '0'} mg", "Pulse": "${dbData['vitals']?['pulse'] ?? '0'} bpm", "HB": "${dbData['vitals']?['hb'] ?? '0'} g/dL", "Gastric": "${dbData['vitals']?['gastric_severity'] ?? 'None'}"};
    } else {
      final score = dbData['tongue']?['score'] ?? 0;
      final tongueColor = (dbData['tongue']?['color'] ?? 'N/A').toString();
      actual = tongueColor; target = "Normal Pink";
      String colorLower = tongueColor.toLowerCase();
      if (colorLower.contains("pink")) {percent = 1.0;} else if (colorLower.contains("white") || colorLower.contains("pale")) {percent = 0.75;} else if (colorLower.contains("yellow") || colorLower.contains("red") || colorLower.contains("purple")) {percent = 0.40;} else {percent = 0.50;}
      dataStrip = {"Tongue Score": "$score/100", "Coating": "${dbData['tongue']?['coating'] ?? 'N/A'}", "Cracks": "${dbData['tongue']?['cracks'] ?? 'None'}", "Moisture": "${dbData['tongue']?['moisture'] ?? 'N/A'}"};
    }

    percent = percent.clamp(0.0, 1.0);
    String verdict; Color statusColor;
    if (percent >= 0.9) { verdict = "EXCELLENT"; statusColor = const Color(0xFF059669); }
    else if (percent >= 0.8) { verdict = "VERY GOOD"; statusColor = const Color(0xFFD97706); }
    else if (percent >= 0.7) { verdict = "GOOD"; statusColor = const Color(0xFFFDE047); }
    else { verdict = "POOR"; statusColor = const Color(0xFFB91C1C); }

    return Builder(
      key: key,
      builder: (context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => pages[index])).then((_) => ref.invalidate(healthDataStreamProvider)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(width: 4, height: 90, decoration: BoxDecoration(color: pitstopColors[index].withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
                  Transform.rotate(
                    angle: 0.2,
                    child: Container(
                      width: 36, height: 28,
                      decoration: BoxDecoration(color: pitstopColors[index], borderRadius: BorderRadius.circular(6), boxShadow: [BoxShadow(color: pitstopColors[index].withOpacity(0.5), blurRadius: 15)]),
                      child: Icon(icons[index], color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: pitstopColors[index].withOpacity(0.15), width: 1.5),
                    boxShadow: [BoxShadow(color: statusColor.withOpacity(0.1), blurRadius: 16, offset: const Offset(0, 8))],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(categories[index].toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: pitstopColors[index], letterSpacing: 1.2)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                    child: Text("${(percent * 100).toInt()}% - $verdict", style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w900)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('YOURS', style: TextStyle(fontSize: 10, color: Colors.white38, fontWeight: FontWeight.bold)),
                                        Text(actual, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text('TARGET', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                                      Text(target, style: TextStyle(color: pitstopColors[index], fontSize: 15, fontWeight: FontWeight.w900)),
                                    ],
                                  ),
                                ],
                              ),
                              if (dataStrip.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 14),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(),
                                    child: Row(
                                      children: dataStrip.entries.map((e) {
                                        bool isActivityCard = index == 0;

                                        return GestureDetector(
                                          onTap: isActivityCard ? () {
                                            if (e.key == "Running") {
                                              _showWorkoutSelectionDialog(context);
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text("${e.key} tracking coming soon!"))
                                              );
                                            }
                                          } : null,
                                          child: Container(
                                            margin: const EdgeInsets.only(right: 8),
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: isActivityCard
                                                  ? Colors.blueAccent.withOpacity(0.15)
                                                  : Colors.white.withOpacity(0.04),
                                              borderRadius: BorderRadius.circular(10),
                                              border: isActivityCard
                                                  ? Border.all(color: Colors.blueAccent.withOpacity(0.4))
                                                  : null,
                                            ),
                                            child: Row(
                                              children: [
                                                if (isActivityCard)
                                                  const Padding(
                                                    padding: EdgeInsets.only(right: 4),
                                                    child: Icon(Icons.play_circle_outline, color: Colors.cyanAccent, size: 12),
                                                  ),
                                                Text("${e.key}: ${e.value}",
                                                    style: TextStyle(
                                                        color: isActivityCard ? Colors.white : Colors.white70,
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.bold
                                                    )
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          height: 4, width: double.infinity,
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05)),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: percent,
                            child: Container(decoration: BoxDecoration(color: statusColor, boxShadow: [BoxShadow(color: statusColor.withOpacity(0.4), blurRadius: 6)])),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- POPUP DIALOG FOR WORKOUT SELECTION ---
  void _showWorkoutSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Track Activity", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogOption(context, "Track Run", Icons.directions_run, Colors.orange, "run_data"),
              const SizedBox(height: 10),
              _dialogOption(context, "Track Jog", Icons.directions_walk, Colors.purple, "jog_data"),
            ],
          ),
        );
      },
    );
  }

  Widget _dialogOption(BuildContext context, String title, IconData icon, Color color, String activityType) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: const TextStyle(color: Colors.white70)),
      tileColor: Colors.white.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => WorkoutScreen(activityType: activityType)),
        ).then((_) => ref.invalidate(healthDataStreamProvider));
      },
    );
  }
}

class UltimateNeonPainter extends CustomPainter {
  final double progress;
  UltimateNeonPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42); // Fixed seed for consistent star placement

    // 1. Draw Deep Space Background
    final paint = Paint()..style = PaintingStyle.fill;
    final bgRect = Rect.fromLTWH(0, 0, size.width, size.height);
    paint.shader = RadialGradient(
      center: const Alignment(0, -0.5),
      colors: [const Color(0xFF0F172A), const Color(0xFF020617), Colors.black],
      radius: 1.2,
    ).createShader(bgRect);
    canvas.drawRect(bgRect, paint);

    // 2. Draw Pulsing Stars (Micro-effects)
    for (int i = 0; i < 40; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final starAlpha = (math.sin(progress * 2 * math.pi + random.nextDouble() * 10) + 1) / 2;
      canvas.drawCircle(Offset(x, y), 0.8, Paint()..color = Colors.white.withOpacity(starAlpha * 0.4));
    }

    // 3. Draw Neon Comets (Streaks)
    final cometColors = [const Color(0xFF3B82F6), const Color(0xFF10B981), const Color(0xFFEF4444)];
    for (int i = 0; i < 3; i++) {
      final cometPaint = Paint()
        ..strokeWidth = 2
        ..shader = LinearGradient(
          colors: [cometColors[i].withOpacity(0), cometColors[i].withOpacity(0.5), cometColors[i].withOpacity(0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      double cometX = (progress * size.width * 1.5 + (i * 200)) % (size.width + 300) - 150;
      double cometY = size.height * (0.2 + (i * 0.25));
      canvas.drawLine(Offset(cometX, cometY), Offset(cometX + 100, cometY - 40), cometPaint);
    }

    // 4. Draw Premium Electric Waves
    final waveColors = [
      const Color(0xFF1E3A8A), // Navy Blue
      const Color(0xFF064E3B), // Dark Emerald
      const Color(0xFF7F1D1D), // Dark Red
    ];

    for (int i = 0; i < 3; i++) {
      final path = Path();
      final wavePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = waveColors[i].withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8); // Neon Glow

      double yOffset = size.height * (0.4 + (i * 0.15));
      path.moveTo(0, yOffset);

      for (double x = 0; x <= size.width; x += 5) {
        double angle = (x / size.width * 1.5 * math.pi) + (progress * 2 * math.pi) + (i * math.pi / 3);
        double y = yOffset + math.sin(angle) * 35;
        path.lineTo(x, y);
      }
      canvas.drawPath(path, wavePaint);

      // Core bright line of the wave
      canvas.drawPath(path, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = waveColors[i].withOpacity(0.6));
    }
  }

  @override
  bool shouldRepaint(UltimateNeonPainter oldDelegate) => true;
}