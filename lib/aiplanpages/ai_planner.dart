import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import 'dart:ui';
import 'package:lottie/lottie.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:flutter_animate/flutter_animate.dart';
import '/services/gemini_service.dart';
import '/pages/health_activity_page.dart';

// --- GLOBAL PROVIDERS ---
final targetCaloriesProvider = StateProvider<double>((ref) => 0.0);
final targetSleepProvider = StateProvider<double>((ref) => 0.0);
final targetStepsProvider = StateProvider<double>((ref) => 0.0);
final targetGymProvider = StateProvider<double>((ref) => 0.0);
final targetYogaProvider = StateProvider<double>((ref) => 0.0);
final targetSportsProvider = StateProvider<double>((ref) => 0.0);

class AIPlanQuestionnaireScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> results;
  final String gender;
  final double weight;
  final double height;
  final double age;

  const AIPlanQuestionnaireScreen({
    super.key,
    required this.results,
    required this.gender,
    required this.weight,
    required this.height,
    required this.age,
  });

  @override
  ConsumerState<AIPlanQuestionnaireScreen> createState() => _AIPlanQuestionnaireScreenState();
}

class _AIPlanQuestionnaireScreenState extends ConsumerState<AIPlanQuestionnaireScreen>
    with TickerProviderStateMixin {

  bool _showPlan = false;


  // Internal State Variables
  double _currentBodyFat = 0.0;
  String _targetBodyFatMid = '';
  String _targetBodyFatStr = '';
  double _estimatedWeeks = 0.0;
  double _weeklyChangeRate = 0.0;
  double _startWeight = 0.0;
  double _targetWeight = 0.0;
  double _currentBMI = 0.0;
  double _targetBMI = 0.0;
  int _targetGymMinutes = 0;
  int _targetYogaMinutes = 0;
  int _targetSportsMinutes = 0;

  String _warning = '';
  String _exercises = '';
  String _diet = '';
  String _lifestyle = '';
  String _timelineDesc = '';
  String _supplements = '';
  String _motivationTips = '';
  String _progressTracking = '';
  String _genericInstruction = ''; // Add this line here

  int _targetCalories = 0;
  int _targetSleepHours = 0;
  int _targetSteps = 0;

  late AnimationController _celebrationController;
  late AnimationController _strideController;
  late AnimationController _exitController;
  bool _showCelebration = false;

  @override
  void initState() {
    super.initState();
    // Slow running cycle: ~3–5 seconds per full stride → very leisurely jog
    _strideController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),   // ← slower = longer duration
    )..repeat();   // loops forever until disposed

    // Exit animation (move + scale + fade)
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),   // much longer total scene time
    )..forward();   // start once when widget appears
    _celebrationController = AnimationController(duration: const Duration(seconds: 3), vsync: this);
    _autoGeneratePlan();
  }

  // ✅ CONNECTED TO GEMINI SERVICE
  // Inside _AIPlanQuestionnaireScreenState in ai_planner.dart

  final GeminiService _geminiService = GeminiService(); // Add this line at the top

  void _autoGeneratePlan() async {
    try {
      String mainGoal = widget.results['goal'] ?? 'Fitness';
      String activityLevel = widget.results['activity_level'] ?? 'Beginner';
      double targetWeight = widget.results['target_weight'];
      String userTargetBodyFat = widget.results['fat'];
      List<String> focusAreas = List<String>.from(widget.results['focus_areas'] ?? []);
      List<String> injuries = List<String>.from(widget.results['injuries'] ?? []);
      String location = widget.results['location'] ?? 'Gym and Home';

      final prompt = """
ACT AS A PROFESSIONAL FITNESS COACH. Return ONLY a JSON object.
Goal: $mainGoal, Focus: ${focusAreas.join(", ")}, Location: $location, Activity Level: $activityLevel
User: ${widget.gender}, ${widget.weight}kg, ${widget.height}cm, ${widget.age}yrs.
Injuries: ${injuries.join(", ")}.
Target_Weight: $targetWeight

CRITICAL INSTRUCTIONS:
1. Every numeric value MUST be greater than 0.
2. 'target_calories' must be a realistic TDEE calculation (e.g., 1500-3000).
3. 'target_steps' must be between 5000 and 15000.
4. 'target_sleep' must be between 6 and 9.
5. 'target_gym_mins', 'target_yoga_mins', and 'target_sports_mins' should reflect a balanced weekly split. Values should be for daily basis. MAX is 120 min. DO NOT GIVE VALUES BEYOND 120 for any of the three. 
6. Ensure 'target_weight' and 'estimated_weeks' are mathematically sound based on the goal.
7. Calculate 'estimated_weeks' based on reaching ${targetWeight}kg safely (0.5-1kg/week).
8. Return exactly ${targetWeight} for 'target_weight' and ${userTargetBodyFat} for 'target_body_fat'.
9. Formulate the training plan and target values prioritizing the goal and activity level. Justify each sections responses by mentioning user values and why you have designed the plan that way.
10. ALWAYS STRICTLY FOLLOW: give 3-4 rows for diet, 6-7 rows for exercise,3-4 rows for lifestyle,2-3 rows for supplements, 2-3 rows for motivation, 2-3 rows for tracking progress.

The JSON must contain these exact keys:
{
"diet": "Meal/Food | Macro/Qty | Justification based on $mainGoal\n",
"exercises": "Exercise | Sets/Reps | Justification for ${focusAreas.join(', ')}, $mainGoal and $activityLevel\n",
"lifestyle": "Habit | Frequency | Justification based on activity level\n",
"supplements": "Supplement | Dosage | Justification based on bio-data\n",
"target_calories": integer,
"target_steps": integer,
"target_sleep": integer,
"target_gym_mins": integer,
"target_yoga_mins": integer,
"target_sports_mins": integer,
"target_weight": double,
"current_body_fat": double,
"target_body_fat": "text",
"estimated_weeks": double,
"motivation": "Type | Metric | Description\n",
"tracking": "Type | Metric | Description\n"
}
""";

      final response = await _geminiService.sendText(prompt);

      String cleanJson = response.trim();
      int firstBracket = cleanJson.indexOf('{');
      int lastBracket = cleanJson.lastIndexOf('}');
      if (firstBracket != -1 && lastBracket != -1) {
        cleanJson = cleanJson.substring(firstBracket, lastBracket + 1);
      }

      final aiPlan = jsonDecode(cleanJson);

      // Update your helper to be even safer
      String formatAiField(dynamic field) {
        if (field == null) return "";
        if (field is List) return field.join("\n");
        // Ensure we don't have strange characters at the start/end
        return field.toString().trim();
      }

      setState(() {
        _startWeight = widget.weight;
        _currentBMI = widget.weight / math.pow(widget.height / 100, 2);
        _targetBMI = targetWeight / math.pow(widget.height / 100, 2);

        _targetWeight = targetWeight;
        _targetBodyFatMid = userTargetBodyFat;

        _currentBodyFat = (aiPlan['current_body_fat'] as num?)?.toDouble() ?? 0.0;
        _targetBodyFatStr = "${_targetBodyFatMid}";

// FIX: Use formatAiField to prevent the List vs String error
        _diet = formatAiField(aiPlan['diet']);
        _exercises = formatAiField(aiPlan['exercises']);
        _lifestyle = formatAiField(aiPlan['lifestyle']);
        _supplements = formatAiField(aiPlan['supplements']);
        _genericInstruction = aiPlan['generic_ins']?.toString() ?? "Tailoring protocol to your bio-data...";

        _motivationTips = aiPlan['motivation']?.toString() ?? '';
        _progressTracking = aiPlan['tracking']?.toString() ?? '';

        _targetCalories = (aiPlan['target_calories'] as num?)?.toInt() ?? 0;
        _targetSteps = (aiPlan['target_steps'] as num?)?.toInt() ?? 0;
        _targetSleepHours = (aiPlan['target_sleep'] as num?)?.toInt() ?? 0;
        _targetGymMinutes = (aiPlan['target_gym_mins'] as num?)?.toInt() ?? 0;
        _targetYogaMinutes = (aiPlan['target_yoga_mins'] as num?)?.toInt() ?? 0;
        _targetSportsMinutes = (aiPlan['target_sports_mins'] as num?)?.toInt() ?? 0;

        _estimatedWeeks = (aiPlan['estimated_weeks'] as num?)?.toDouble() ?? 0.0;
        _timelineDesc = "Estimated duration: ${_estimatedWeeks.toInt()} weeks to target.";

        _motivationTips = aiPlan['motivation']?.toString() ?? "Stay consistent and trust the process!";
        _progressTracking = aiPlan['tracking']?.toString() ?? "Monitor your weight and energy levels weekly.";

        List<String> warnings = [];
        for (var injury in injuries) {
          String lowerInjury = injury.toLowerCase();

          if (lowerInjury.contains('back')) {
            warnings.add("Back injury: Avoid heavy spinal loading and deep flexion.");
          }
          if (lowerInjury.contains('knee')) {
            warnings.add("Knee injury: Avoid high-impact jumps and deep lunges.");
          }
          if (lowerInjury.contains('shoulder')) {
            warnings.add("Shoulder injury: Avoid behind-the-neck presses and heavy overhead movements.");
          }
          if (lowerInjury.contains('waist')) {
            warnings.add("Waist/Core injury: Avoid heavy rotational movements and excessive trunk flexion.");
          }
          if (lowerInjury.contains('wrist')) {
            warnings.add("Wrist injury: Use wraps for heavy lifts; avoid high-pressure planks or pushups on palms.");
          }
        }
        _warning = warnings.join("\n");
        _showPlan = true;
        _showCelebration = true;
        _celebrationController.forward();
      });

      Future.microtask(() {
        if (!mounted) return;
        ref.read(targetCaloriesProvider.notifier).state = _targetCalories.toDouble();
        ref.read(targetStepsProvider.notifier).state = _targetSteps.toDouble();
        ref.read(targetSleepProvider.notifier).state = _targetSleepHours.toDouble();
        ref.read(targetGymProvider.notifier).state = _targetGymMinutes.toDouble();
        ref.read(targetYogaProvider.notifier).state = _targetYogaMinutes.toDouble();
        ref.read(targetSportsProvider.notifier).state = _targetSportsMinutes.toDouble();
        _syncToSupabase();
      });

    } catch (e) {
      debugPrint("AI Error: $e");
      setState(() { _showPlan = true; _diet = "Error generating AI plan: $e"; });
    }
  }
  Future<void> _syncToSupabase() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        await Supabase.instance.client.from('user_targets').upsert({
          'user_id': user.id,
          'target_calories': _targetCalories.toDouble(),
          'target_steps': _targetSteps.toDouble(),
          'target_gym_mins': _targetGymMinutes.toDouble(),
          'target_yoga_mins': _targetYogaMinutes.toDouble(),
          'target_sports_mins': _targetSportsMinutes.toDouble(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        debugPrint("Supabase Sync Error: $e");
      }
    }
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    _strideController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  // --- UI BUILDING (DESIGN UNCHANGED) ---

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        textTheme: GoogleFonts.zenDotsTextTheme(Theme.of(context).textTheme.apply()),
        scaffoldBackgroundColor: Colors.black,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          title: RichText(
            text: TextSpan(
              style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.bold),
              children: const [
                TextSpan(text: "AI ", style: TextStyle(color: Colors.white)),
                TextSpan(text: "PERFORMANCE PLAN", style: TextStyle(color: Colors.orange)),
              ],
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
              onPressed: _exportToPDF,
            )
          ],
        ),
        body: _showPlan
            ? _buildUltimateDashboard()
            : Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Options: center, start, end
            mainAxisSize: MainAxisSize.min,            children: [
              const CircularProgressIndicator(
                color: Colors.orange,
                strokeWidth: 3, // Optional: makes the line cleaner
              ),
              const SizedBox(height: 20), // Space between circle and text
              Text(
                "Hang on! We are analysing your data...",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.orange,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Crafting your personalized performance plan",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
        // GRADIENT FLOATING ACTION BUTTON
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: _showPlan ? Container(
          height: 60,
          width: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              colors: [Colors.orange, Colors.deepOrange, Colors.redAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: Text(
              "BACK TO HOME",
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ) : null,
      ),
    );
  }


  Widget _buildUltimateDashboard() {
    final features = [
      {
        'title': "Nutrition",
        'body': _diet,
        'icon': Icons.restaurant_menu,
        'color': Colors.orange,
        'image': 'assets/images/nutrition.png' // Updated to local path
      },
      {
        'title': "Training",
        'body': _exercises,
        'icon': Icons.fitness_center,
        'color': Colors.blueAccent,
        'image': 'assets/images/training.png'
      },
      {
        'title': "Lifestyle",
        'body': _lifestyle,
        'icon': Icons.self_improvement,
        'color': Colors.greenAccent,
        'image': 'assets/images/lifestyle.png'
      },
      {
        'title': "Supplements",
        'body': _supplements,
        'icon': Icons.medication_liquid,
        'color': Colors.purpleAccent,
        'image': 'assets/images/supplements.png'
      },
      {
        'title': "Motivation",
        'body': _motivationTips,
        'icon': Icons.tips_and_updates,
        'color': Colors.amber,
        'image': 'assets/images/motivation.png'
      },
      {
        'title': "Tracking",
        'body': _progressTracking,
        'icon': Icons.insights,
        'color': Colors.cyanAccent,
        'image': 'assets/images/tracking.png'
      },
    ];
    return Container(
      color: const Color(0xFF020202), // Ultra Black
      child: Stack(
        children: [
          // --- 1. THE NEURAL BACKGROUND (3D ORBS) ---
          Positioned(
            top: -100,
            right: -50,
            child: _buildBlurCircle(Colors.orange.withOpacity(0.12), 300),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(begin: 0, end: 60, duration: 5.seconds)
              .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2)),

          Positioned(
            bottom: 100,
            left: -50,
            child: _buildBlurCircle(Colors.cyan.withOpacity(0.08), 250),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
              .moveX(begin: 0, end: 50, duration: 7.seconds),

          // --- 2. THE SCAN LINE EFFECT (Maximum Engagement) ---
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.orange.withOpacity(0.05),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ).animate(onPlay: (c) => c.repeat())
                .moveY(begin: -800, end: 800, duration: 4.seconds),
          ),

          // --- 3. MAIN DASHBOARD CONTENT ---
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    "Your Fitness Plan is Ready!",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.orange
                    ),
                  ).animate().fade(duration: 800.ms).slideY(begin: -0.3),
                ),
                const SizedBox(height: 12),

                // Enhanced Glassmorphic AI Summary Box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Text(
                        "As per your goal for ${widget.results['goal']} and ${widget.results['fat']} body fat at the level of ${widget.results['activity_level']}, the AI plan is formulated. Focus given on ${List<String>.from(widget.results['focus_areas'] ?? []).join(', ')}, "
                            "You are a ${widget.gender} aged ${widget.age.toInt()}, weighing ${widget.weight}kg, "
                            "training at ${widget.results['location']}. "
                            "${widget.results['injuries'] != null && (widget.results['injuries'] as List).isNotEmpty
                            ? 'Taking care of your injury on ${List<String>.from(widget.results['injuries']).join(', ')}'
                            : 'with no reported injuries'}, "
                            "this is your AI-optimized plan:",
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.deepOrange,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.1),

                const SizedBox(height: 22),

                // Key Status Widgets
                _buildProfileStatusCard().animate().fadeIn(delay: 400.ms).scale(),
                const SizedBox(height: 20),
                _buildTargetOverviewCard().animate().fadeIn(delay: 500.ms).scale(),
                const SizedBox(height: 20),
                _buildTimelineCard().animate().fadeIn(delay: 600.ms),
                const SizedBox(height: 20),
                if (_warning.isNotEmpty)
                  _buildAlertCard().animate(onPlay: (c) => c.repeat())
                      .shimmer(duration: 2.seconds, color: Colors.red[900]),

                const SizedBox(height: 15),

                // FEATURE CARDS (STAGGERED 3D ENTRANCE)
                ...features.asMap().entries.map((entry) {
                  int index = entry.key;
                  var data = entry.value;
                  return Column(
                    children: [
                      _buildSectionHeaderWithImage(
                        imageUrl: data['image'] as String,
                        accentColor: data['color'] as Color,
                      ),
                      _buildMaxFeatureCard(
                        title: data['title'] as String,
                        body: data['body'] as String,
                        icon: data['icon'] as IconData,
                        accentColor: data['color'] as Color,
                        index: index,
                      ),
                    ],
                  );
                }).toList(),
                _buildCertifiedSeal(),
                _buildRacingTrackSection(),
              ],
            ),
          ),

          if (_showCelebration)
            CelebrationOverlay(controller: _celebrationController),
        ],
      ),
    );
  }

  Widget _buildRacingTrackSection() {
    const double horizonY = 100.0; // The fixed "end" of the road
    return Column(
      children: [
        Container(
          height: 280,
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 20),
          clipBehavior: Clip.none,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. THE 3D TRACK WITH COLOR-MORPHING RAILS
              _buildAnimatedTrack(horizonY),
              _buildStadiumLights(horizonY),
              // 2. THE FINISH LINE (Mapped to the end of the road)
              // 3. TINY FINISH LINE (At the end of the road)
              Positioned(
                top: horizonY - 8,
                child: Container()
                    .animate(onPlay: (c) => c.repeat())
                    .custom(
                  duration: 1200.ms,
                  builder: (context, value, child) => SizedBox(
                    width: 150,
                    height: 20,
                    child: CustomPaint(painter: WavingFlagPainter(animationValue: value)),
                  ),
                ),
              ),

              // 4. SPEED STREAKS
              ...List.generate(8, (index) => Positioned.fill(child: _buildSpeedStreak(index, horizonY))),

              // 5. THE REALISTIC RUNNER (Foreground to Horizon)
              // THE RUNNER (Moving away with realistic physics)
              Positioned(
                bottom: 0,
                left: MediaQuery.of(context).size.width / 2 - 75,
                child: SizedBox(
                  width: 150,
                  height: 200,
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_strideController, _exitController]),
                    builder: (context, child) {
                      return CustomPaint(
                        painter: HumanRunnerPainter(
                          animationValue: _strideController.value,   // 0.0 → 1.0 looping slowly
                        ),
                      );
                    },
                  ),
                )
                    .animate(onPlay: (c) => c.repeat())   // optional – but we control via controller now
                    .moveY(
                  begin: 100,
                  end: -180,               // a bit further up for more distance feeling
                  duration: 8500.ms,       // much longer movement
                  curve: Curves.linear,
                )
                    .scale(
                  begin: const Offset(2.0, 2.0),
                  end: const Offset(0.08, 0.08),
                  duration: 8500.ms,
                  curve: Curves.easeOutCubic,   // smoother slowdown at horizon
                )
                    .fadeOut(
                  delay: 5000.ms,          // start fading much later
                  duration: 3500.ms,       // very slow fade – lasts most of the second half
                  curve: Curves.easeOut,
                ),
              ),
              // 4. THE CINEMATIC REVEAL TEXT
              Positioned(
                bottom: 90,
                child: Column(
                  children: [
                    Text(
                      "START YOUR JOURNEY",
                      style: GoogleFonts.blackOpsOne(
                        fontSize: 28,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat())
                        .shimmer(duration: 2.seconds, color: Colors.orange)
                        .custom(
                      duration: 2.seconds,
                      builder: (context, value, child) {
                        return Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.6 * value),
                                blurRadius: 25 * value,
                                spreadRadius: 5 * value,
                              ),
                            ],
                          ),
                          child: child,
                        );
                      },
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () {
                        // Direct navigation logic within the widget
                        /*Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ActivityTrackingPage(), // Replace with your actual class name
                          ),
                              (route) => false, // This is the 'magic' line that prevents going back
                        );*/
                      },
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "LOG NOW!",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Colors.orangeAccent,
                                letterSpacing: 12,
                              ),
                            )
                                .animate()
                                .fadeIn(delay: 800.ms)
                                .moveY(begin: 15, end: 0)
                                .animate(onPlay: (c) => c.repeat())
                                .shimmer(delay: 2000.ms, duration: 1500.ms, color: Colors.white54),

                            // Animated underline indicator
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              width: 80,
                              height: 2,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.transparent, Colors.orangeAccent, Colors.transparent],
                                ),
                              ),
                            ).animate().scaleX(delay: 1000.ms, duration: 600.ms),
                          ],
                        ),
                      ),
                    )                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
// --- FIXED STADIUM LIGHTS HELPER ---
  Widget _buildStadiumLights(double horizonY) {
    return Positioned(
      top: horizonY - 40,
      width: 400,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(2, (index) =>
            Container(
              width: 60,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                boxShadow: [
                  BoxShadow(
                    color: index == 0 ? Colors.white.withOpacity(0.7) : Colors.white.withOpacity(0.7),
                    blurRadius: 30,
                    spreadRadius: 2,
                  )
                ],
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
            // Fix: Ensure duration and delay are explicitly defined
                .fadeOut(
                duration: Duration(milliseconds: 500),
                delay: Duration(milliseconds: index * 200)
            )
        ),
      ),
    );
  }
  Widget _buildAnimatedTrack(double horizonY) {
    return Container()
        .animate(onPlay: (c) => c.repeat())
        .custom(
      duration: 3000.ms,
      builder: (context, value, child) => CustomPaint(
        size: const Size(double.infinity, 320),
        painter: UltimateRacingTrackPainter(progress: value, horizonY: horizonY),
      ),
    );
  }


// SPEED STREAK COMPONENTS
  Widget _buildSpeedStreak(int index, double horizonY) {
    final random = math.Random();
    return Container()
        .animate(onPlay: (c) => c.repeat())
        .custom(
      duration: Duration(milliseconds: 800 + random.nextInt(600)),
      builder: (context, value, child) => CustomPaint(
        painter: StreakPainter(progress: value, seed: index, horizonY: horizonY),
      ),
    );
  }
// Support Widget: Blur Circle Background
  Widget _buildBlurCircle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
        child: Container(color: Colors.transparent),
      ),
    );
  }

// Support Widget: Section Header with Circular Image
  Widget _buildSectionHeaderWithImage({ required String imageUrl, required Color accentColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Row(
        children: [
          Container(
            width: 470,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accentColor.withOpacity(0.4), width: 1.5),
              boxShadow: [BoxShadow(color: accentColor.withOpacity(0.2), blurRadius: 10)],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(imageUrl, fit: BoxFit.cover),
            ),
          ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
        ],
      ),
    );
  }

// Support Widget: Maximum Enhanced Feature Card
  Widget _buildMaxFeatureCard({
    required String title,
    required String body,
    required IconData icon,
    required Color accentColor,
    required int index,
  }) {
    // Parse rows (Expecting: Item | Metric | Justification)
    List<String> lines = body.trim().split('\n').where((l) => l.contains('|')).toList();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: accentColor.withOpacity(0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.05),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- SECTION 1: HEADER & STATUS ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _buildAnimatedHeaderIcon(icon, accentColor),
                        const SizedBox(width: 15),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title.toUpperCase(),
                              style: GoogleFonts.orbitron(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 1.5,
                              ),
                            ),
                            Text(
                              "Optimized for you",
                              style: GoogleFonts.poppins(
                                fontSize: 8,
                                color: accentColor.withOpacity(0.6),
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    _buildPulseDot(accentColor),
                  ],
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(color: Colors.white10),
                ),

                // --- SECTION 3: 3-COLUMN TABLE GRID ---
                _buildTableHeaderLabels(),
                const SizedBox(height: 12),

                ...lines.map((line) {
                  final parts = line.split('|');
                  return _buildDataRow(parts, accentColor, title);
                }).toList(),
                // --- 4. THE RESTORED HINT LEGEND ---
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: Colors.yellowAccent.withOpacity(0.8), size: 16),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "LEGEND: Neon ${accentColor == const Color(0xFFFF6B00) ? 'Orange' : 'Pills'} indicate critical targets. The Bio-Strategy column is unique to your age, weight, and goals.",
                          style: GoogleFonts.poppins(
                              fontSize: 9,
                              color: Colors.white38,
                              height: 1.4,
                              fontStyle: FontStyle.italic
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    ).animate()
        .fadeIn(duration: 600.ms, delay: (index * 150).ms)
        .slideY(begin: 0.1, end: 0);
  }

// --- DATA ROW BUILDER ---
  Widget _buildDataRow(List<String> parts, Color accentColor, String title) {
    final item = parts.isNotEmpty ? parts[0].trim() : "";
    final metric = parts.length > 1 ? parts[1].trim() : "-";
    final strategy = parts.length > 2 ? parts[2].trim() : "";

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.01),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Col 1: Item + Dynamic Emoji
          Expanded(
            flex: 3,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_getSectionEmoji(title), style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          // Col 2: Metric Pill
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accentColor.withOpacity(0.2)),
              ),
              child: Text(
                metric,
                textAlign: TextAlign.center,
                style: GoogleFonts.orbitron(fontSize: 9, fontWeight: FontWeight.bold, color: accentColor),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Col 3: Strategy
          Expanded(
            flex: 4,
            child: Text(
              strategy,
              style: GoogleFonts.poppins(fontSize: 10, color: Colors.white54, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertifiedSeal() {
    const Color coachOrange = Color(0xFFFF6B00);
    const Color coachYellow = Color(0xFFFFD600);
    return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
      child: Row(
        children: [
          // Left Side: The Official Stamp
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [coachOrange, coachYellow, coachOrange],
                  ),                ),
              ).animate(onPlay: (c) => c.repeat()).rotate(duration: 8.seconds),
              const Icon(Icons.verified, color: Colors.deepPurple, size: 38)
                  .animate(onPlay: (c) => c.repeat())
                  .shimmer(duration: 3.seconds),
            ],
          ),
          const SizedBox(width: 15),

          // Middle: Signature & Verification
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  "PLAN CERTIFIED",
                  style: GoogleFonts.orbitron(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                    letterSpacing: 1.2,
                  )
              ),
              Text(
                "Coach Signature:",
                style: GoogleFonts.poppins(fontSize: 8, color: Colors.white38),
              ),
              Text(
                "SetMeFit AI Coach",
                style: GoogleFonts.caveat(
                    fontSize: 20,
                    color: coachYellow,
                    fontWeight: FontWeight.bold
                ),
              ),
            ],
          ),

          // Spacer to push the message to the far right
          const Spacer(),

          // Right Side: The Friendly Coach Message
          Container(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "Let's crush this Champ! I'm right here in your pocket if you need me. You've got the spark—now let's build the fire!🔥\n -Zain <3",
                  textAlign: TextAlign.right,
                  style: GoogleFonts.caveat(
                    fontSize: 16,
                    height: 1.1,
                    color: Colors.white.withOpacity(0.8),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 1200.ms).slideX(begin: 0.2, end: 0),
        ],
      ),
    );
  }
// --- HELPER WIDGETS ---

  Widget _buildTableHeaderLabels() {
    return Row(
      children: [
        Expanded(flex: 3, child: _smallLabel("PROTOCOL")),
        Expanded(flex: 2, child: _smallLabel("TARGET")),
        Expanded(flex: 4, child: _smallLabel("BIO-STRATEGY")),
      ],
    );
  }
  Widget _smallLabel(String text) {
    return Text(text, style: GoogleFonts.orbitron(fontSize: 8, color: Colors.white24, letterSpacing: 1.2));
  }

  Widget _buildAnimatedHeaderIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
      child: Icon(icon, color: color, size: 20),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 3.seconds);
  }

  Widget _buildPulseDot(Color color) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 8, spreadRadius: 2)],
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1, 1), end: const Offset(1.4, 1.4)).fadeOut();
  }

  String _getSectionEmoji(String title) {
    final t = title.toLowerCase();

    // Diet & Nutrition
    if (t.contains("diet") || t.contains("meal") || t.contains("nutrition")) {
      return "🥗";
    }
    // Training & Exercises
    if (t.contains("exercise") || t.contains("workout") || t.contains("training") || t.contains("gym")) {
      return "🏋️"; // Using lightning for energy/effort
    }
    // Lifestyle & Habits
    if (t.contains("lifestyle") || t.contains("habit") || t.contains("sleep")) {
      return "🧘";
    }
    // Supplements
    if (t.contains("supplement") || t.contains("vitamin")) {
      return "💊";
    }
    // Tracking & Motivation
    if (t.contains("motivation") || t.contains("goal")) {
      return "🔥";
    }

    return "🎯"; // Default "Target" emoji
  }



  Widget _buildTargetOverviewCard() {
    return Stack(
      children: [
        // Futuristic Background Glow (Mesh effect)
        Positioned(
          top: -20,
          right: -20,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green.withOpacity(0.05),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1, 1), end: const Offset(1.5, 1.5), duration: 4.seconds),
        ),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            // Deep Obsidian Glassmorphism
            color: const Color(0xFF0A0A0A).withOpacity(0.9),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: Colors.white.withOpacity(0.05),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
              BoxShadow(
                color: Colors.green.withOpacity(0.02),
                blurRadius: 20,
                spreadRadius: -5,
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        // High-Tech Neo-Brutalism Icon Container
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.green.withOpacity(0.2), Colors.green.withOpacity(0.02)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.green.withOpacity(0.2)),
                          ),
                          child: const Icon(Icons.gps_fixed_outlined, color: Colors.green, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Daily AI Targets",
                              style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.8
                              ),
                            ),
                            Text(
                              "OPTIMIZED BY NEURAL ENGINE",
                              style: GoogleFonts.poppins(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withOpacity(0.3),
                                  letterSpacing: 1.2
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Refined "Live" Status Indicator
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.05),
                            border: Border.all(color: Colors.green.withOpacity(0.3)),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                    boxShadow: [BoxShadow(color: Colors.green, blurRadius: 4)]
                                ),
                              ).animate(onPlay: (c) => c.repeat()).fade(duration: 1.seconds),
                              const SizedBox(width: 8),
                              Text("LIVE", style: GoogleFonts.poppins(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold, letterSpacing: 1)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),

                // Metric Grid with dynamic spacing
                LayoutBuilder(
                    builder: (context, constraints) {
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: _buildEnhancedMetric(Icons.local_fire_department, "$_targetCalories", "Kcal", Colors.orange)),
                              const SizedBox(width: 16),
                              Expanded(child: _buildEnhancedMetric(Icons.hotel, "${_targetSleepHours}h", "Sleep", Colors.indigoAccent)),
                              const SizedBox(width: 16),
                              Expanded(child: _buildEnhancedMetric(Icons.directions_walk, "$_targetSteps", "Steps", Colors.yellow)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: _buildEnhancedMetric(Icons.fitness_center, "$_targetGymMinutes", "Gym (min)", Colors.deepOrange)),
                              const SizedBox(width: 16),
                              Expanded(child: _buildEnhancedMetric(Icons.self_improvement, "$_targetYogaMinutes", "Yoga (min)", Colors.tealAccent)),
                              const SizedBox(width: 16),
                              Expanded(child: _buildEnhancedMetric(Icons.sports_soccer, "$_targetSportsMinutes", "Sports (min)", Colors.amber[800]!)),
                            ],
                          ),
                        ],
                      );
                    }
                ),
              ],
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildEnhancedMetric(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        // Subtle glass effect for each tile
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Glowing Icon Container
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.15),
                  blurRadius: 12,
                  spreadRadius: 1,
                )
              ],
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),

          // Primary Value
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 2),

          // Sub-label
          Text(
            label.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.4),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    ).animate().scale(delay: 200.ms, duration: 400.ms, curve: Curves.easeOutBack);
  }

  Widget _buildProfileStatusCard() {
    return Container(
      padding: const EdgeInsets.all(24), // Increased slightly for breathing room
      decoration: BoxDecoration(
        // True obsidian black with a hint of depth
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 30,
            offset: const Offset(0, 15),
          )
        ],
        // Subtle "Glass" border instead of solid grey
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Profile Status",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w800, // Heavier weight for premium feel
                  fontSize: 17,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              // Decorative element to fill the "Advanced" look
              Icon(Icons.analytics_outlined, color: Colors.orange.shade400, size: 20),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricCol(
                  "WEIGHT",
                  "${_startWeight.toStringAsFixed(1)}Kg",
                  "${_targetWeight.toStringAsFixed(1)}Kg"
              ),
              // Vertical Divider for visual structure
              Container(width: 1, height: 40, color: Colors.white.withOpacity(0.05)),
              _buildMetricCol(
                  "BMI",
                  _currentBMI.toStringAsFixed(1),
                  _targetBMI.toStringAsFixed(1)
              ),
              // Vertical Divider
              Container(width: 1, height: 40, color: Colors.white.withOpacity(0.05)),
              _buildMetricCol(
                  "BODY FAT",
                  "${_currentBodyFat.toStringAsFixed(1)}%",
                  _targetBodyFatStr
              ),
            ],
          )
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.05, end: 0);
  }

  Widget _buildMetricCol(String label, String current, String target) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.poppins(
            fontSize: 9,
            color: Colors.white.withOpacity(0.3),
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              current,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1,
              ),
            ),
            const SizedBox(width: 8),
            // Subtle Animated Sparkline
            _buildMiniSparkline(label == "Weight" ? Colors.orange : Colors.green),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.keyboard_double_arrow_right_rounded, size: 12, color: Colors.orange.shade400),
              const SizedBox(width: 4),
              Text(
                target,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.orange.shade400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

// Helper widget for the "Trend" look
  Widget _buildMiniSparkline(Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(4, (index) {
        // Logic-less heights for pure aesthetic "data" feel
        final heights = [6.0, 10.0, 8.0, 14.0];
        return Container(
          margin: const EdgeInsets.only(right: 2),
          width: 2,
          height: heights[index],
          decoration: BoxDecoration(
            color: color.withOpacity(0.4 + (index * 0.2)),
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }).animate(interval: 100.ms).scaleY(begin: 0, end: 1, duration: 400.ms, curve: Curves.easeOut),
    );
  }

  Widget _buildTimelineCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF070707),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
            color: Colors.white.withOpacity(0.08),
            width: 1.5
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.03),
            blurRadius: 40,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Estimated Timeline",
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: Colors.orange,
                    letterSpacing: 0.5
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.auto_graph_rounded, color: Colors.deepOrangeAccent, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "From current weight to target, based on your weekly change.",
            style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.white.withOpacity(0.4),
                height: 1.4
            ),
          ),
          const SizedBox(height: 24),

          // The Graph Theater with Custom Grid Background
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.01),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.03)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  // Layer 1: The Technical Grid
                  Positioned.fill(
                    child: CustomPaint(
                      painter: TechnicalGridPainter(),
                    ),
                  ),
                  // Layer 2: Radial Depth Glow
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [Colors.orange.withOpacity(0.05), Colors.transparent],
                          center: Alignment.center,
                          radius: 1.2,
                        ),
                      ),
                    ),
                  ),
                  // Layer 3: Your Existing Logic (Trajectory)
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: TrajectoryPainter(
                        start: _startWeight,
                        target: _targetWeight,
                        weeks: _estimatedWeeks,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Footer Description Pod
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time_filled, color: Colors.deepOrange, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _timelineDesc,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Colors.orangeAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 1.seconds).slideY(begin: 0.2, end: 0);
  }


  Widget _buildAlertCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: Colors.red[900], borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          const Icon(Icons.warning, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(child: Text(_warning, style: const TextStyle(color: Colors.white, fontSize: 12))),
        ],
      ),
    );
  }

  Future<void> _exportToPDF() async {
    final pdf = pw.Document();

    // Standard styling for the PDF
    final headerStyle = pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.orange);
    final subHeaderStyle = pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.black);
    final bodyStyle = pw.TextStyle(fontSize: 11);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("AI PERFORMANCE PLAN", style: headerStyle),
                  pw.Text(DateTime.now().toString().split(' ')[0], style: bodyStyle),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Profile Section
            pw.Text("User Profile Summary", style: subHeaderStyle),
            pw.Divider(color: PdfColors.grey),
            pw.Bullet(text: "Age: ${widget.age} | Gender: ${widget.gender}"),
            pw.Bullet(text: "Start Weight: ${widget.weight} kg | Target Weight: $_targetWeight kg"),
            pw.Bullet(text: "Current BMI: ${_currentBMI.toStringAsFixed(1)}"),
            pw.SizedBox(height: 20),

            // Targets Section
            pw.Text("Daily AI Targets", style: subHeaderStyle),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.orange, width: 1)),
              child: pw.Column(
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("Calories: $_targetCalories kcal", style: bodyStyle),
                      pw.Text("Sleep: $_targetSleepHours hrs", style: bodyStyle),
                      pw.Text("Steps: $_targetSteps", style: bodyStyle),
                    ],
                  ),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("Gym: $_targetGymMinutes min", style: bodyStyle),
                      pw.Text("Yoga: $_targetYogaMinutes min", style: bodyStyle),
                      pw.Text("Sports: $_targetSportsMinutes min", style: bodyStyle),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Plan Details
            _buildPdfSection("Nutrition Plan", _diet, subHeaderStyle, bodyStyle),
            _buildPdfSection("Workout Routine", _exercises, subHeaderStyle, bodyStyle),
            _buildPdfSection("Lifestyle", "$_lifestyle\n$_supplements", subHeaderStyle, bodyStyle),
            _buildPdfSection("Supplements", _supplements, subHeaderStyle, bodyStyle), // Added
            _buildPdfSection("Motivation", _motivationTips, subHeaderStyle, bodyStyle),
            if (_warning.isNotEmpty) ...[
              pw.SizedBox(height: 10),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(color: PdfColors.red100),
                child: pw.Text("INJURY ADVISORY: $_warning", style: pw.TextStyle(fontSize: 10, color: PdfColors.red900, fontWeight: pw.FontWeight.bold)),
              ),
            ],
          ];
        },
      ),
    );

    // Save and print/preview the PDF
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  // Helper for PDF layout
  pw.Widget _buildPdfSection(String title, String content, pw.TextStyle titleStyle, pw.TextStyle contentStyle) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 15),
        pw.Text(title, style: titleStyle),
        pw.Padding(
          padding: const pw.EdgeInsets.only(left: 10, top: 5),
          child: pw.Text(content, style: contentStyle),
        ),
      ],
    );
  }
}


// Custom Painter for the Timeline Graph with axes & labels
class TrajectoryPainter extends CustomPainter {
  final double start;
  final double target;
  final double weeks;

  TrajectoryPainter({
    required this.start,
    required this.target,
    required this.weeks,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Transparent Background (The Card handles the BG color now for a cleaner look)
    // Removed bgPaint to allow the container's technical grid to show through.

    final axisPaint = Paint()
      ..color = Colors.white.withOpacity(0.15) // Subtler, more technical
      ..strokeWidth = 1.0;

    // The Main Trajectory Line - Neon Glow Effect
    final linePaint = Paint()
      ..color = Colors.orange
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2); // Makes the line "glow"

    const double marginLeft = 40;
    const double marginBottom = 30;
    const double marginTop = 18;
    const double marginRight = 12;

    final double chartWidth = size.width - marginLeft - marginRight;
    final double chartHeight = size.height - marginTop - marginBottom;
    final double originX = marginLeft;
    final double originY = size.height - marginBottom;

    // Draw Axes (Refined)
    canvas.drawLine(Offset(originX, originY), Offset(originX + chartWidth, originY), axisPaint);
    canvas.drawLine(Offset(originX, originY), Offset(originX, originY - chartHeight), axisPaint);

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 1,
    );

    // Labels: Weeks
    textPainter.text = TextSpan(
      text: "Weeks",
      style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.w600),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(originX + chartWidth / 2 - textPainter.width / 2, originY + 12));

    // Labels: Weight
    textPainter.text = TextSpan(
      text: "Weight (kg)",
      style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.w600),
    );
    textPainter.layout();
    canvas.save();
    canvas.translate(originX - 32, originY - chartHeight / 2);
    canvas.rotate(-math.pi / 2);
    textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
    canvas.restore();

    final double minWeight = math.min(start, target) - 2;
    final double maxWeight = math.max(start, target) + 2;
    final double weightRange = (maxWeight - minWeight).abs() < 1 ? 1 : (maxWeight - minWeight);

    double weightToY(double w) => originY - ((w - minWeight) / weightRange) * chartHeight;
    double weekToX(double w) => originX + (w / (weeks <= 0 ? 12 : weeks)) * chartWidth;

    // --- GRADIENT AREA UNDER CURVE ---
    final fillPath = Path();
    fillPath.moveTo(weekToX(0), originY);
    fillPath.lineTo(weekToX(0), weightToY(start));
    fillPath.quadraticBezierTo(weekToX(weeks / 2), weightToY((start + target) / 2), weekToX(weeks), weightToY(target));
    fillPath.lineTo(weekToX(weeks), originY);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.orange.withOpacity(0.2), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    // --- MAIN CURVE PATH ---
    final path = Path();
    path.moveTo(weekToX(0), weightToY(start));
    path.quadraticBezierTo(weekToX(weeks / 2), weightToY((start + target) / 2), weekToX(weeks), weightToY(target));
    canvas.drawPath(path, linePaint);

    // --- DATA POINTS (Glow & Shadow) ---
    final startOffset = Offset(weekToX(0), weightToY(start));
    final targetOffset = Offset(weekToX(weeks), weightToY(target));

    void drawPulsingPoint(Canvas canvas, Offset offset, Color color) {
      canvas.drawCircle(offset, 8, Paint()..color = color.withOpacity(0.2)); // Outer Glow
      canvas.drawCircle(offset, 4.5, Paint()..color = Colors.white); // Core
      canvas.drawCircle(offset, 3, Paint()..color = color); // Inner Color
    }

    drawPulsingPoint(canvas, startOffset, Colors.orange);
    drawPulsingPoint(canvas, targetOffset, Colors.green);

    // --- LABELS (START/TARGET) ---
    textPainter.text = TextSpan(
      text: "Start\n${start.toStringAsFixed(1)} kg",
      style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.8), fontSize: 9, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(startOffset.dx - textPainter.width - 8, startOffset.dy - textPainter.height - 4));

    textPainter.text = TextSpan(
      text: "Target\n${target.toStringAsFixed(1)} kg",
      style: GoogleFonts.poppins(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.w800),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(targetOffset.dx + 8, targetOffset.dy - textPainter.height - 4));

    // --- AXIS TICKS & VALUES ---
    final double safeWeeks = weeks <= 0 ? 12 : weeks;
    final List<double> weekMarks = [0, safeWeeks / 2, safeWeeks];
    for (final w in weekMarks) {
      final dx = weekToX(w);
      canvas.drawLine(Offset(dx, originY), Offset(dx, originY + 6), axisPaint);
      textPainter.text = TextSpan(
        text: w.toStringAsFixed(0),
        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 9, fontWeight: FontWeight.bold),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(dx - textPainter.width / 2, originY + 10));
    }

    final List<double> weightMarks = [minWeight, (minWeight + maxWeight) / 2, maxWeight];
    for (final w in weightMarks) {
      final dy = weightToY(w);
      canvas.drawLine(Offset(originX - 6, dy), Offset(originX, dy), axisPaint);
      textPainter.text = TextSpan(
        text: w.toStringAsFixed(0),
        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 9, fontWeight: FontWeight.bold),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(originX - textPainter.width - 10, dy - textPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

class CelebrationOverlay extends StatefulWidget {
  final AnimationController controller;

  const CelebrationOverlay({super.key, required this.controller});

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay> {
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTick);
  }

  @override
  void didUpdateWidget(CelebrationOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTick);
      widget.controller.addListener(_onTick);
    }
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTick);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.controller.isAnimating) {
      return const SizedBox.shrink();
    }

    final size = MediaQuery.of(context).size;
    final progress = widget.controller.value;

    final particles = List<Widget>.generate(80, (i) {
      final t = (i / 80.0 + progress) % 1.0;
      final x = _random.nextDouble() * size.width;
      final y = size.height * (1.0 - t);
      final colors = [
        Colors.red,
        Colors.orange,
        Colors.yellow,
        Colors.green,
        Colors.blue,
        Colors.purple,
        Colors.pink,
        Colors.cyan,
      ];
      final color = colors[_random.nextInt(colors.length)];

      return Positioned(
        left: x,
        top: y,
        child: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
      );
    });

    return IgnorePointer(
      ignoring: true,
      child: SizedBox.expand(
        child: Stack(children: particles),
      ),
    );
  }
}

class TechnicalGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1.0;

    const double step = 25.0; // Spacing between lines

    // Draw Vertical Lines
    for (double i = 0; i <= size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    // Draw Horizontal Lines
    for (double i = 0; i <= size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class UltimateRacingTrackPainter extends CustomPainter {
  final double progress;
  final double horizonY;
  UltimateRacingTrackPainter({required this.progress, required this.horizonY});

  @override
  void paint(Canvas canvas, Size size) {
    final Rect trackRect = Offset.zero & size;

    // 1. RESTORED: Metallic Asphalt with Depth Gradient
    final Paint asphaltPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFF2A2A2A), Colors.black, const Color(0xFF0F0F0F)],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(trackRect);

    final Path trackPath = Path()
      ..moveTo(size.width * 0.49, horizonY)
      ..lineTo(size.width * 0.51, horizonY)
      ..lineTo(size.width * 2.5, size.height)
      ..lineTo(size.width * -1.5, size.height)
      ..close();
    canvas.drawPath(trackPath, asphaltPaint);

    // 2. RESTORED: Speed-Flicker Center Lines
    final Paint dashPaint = Paint()..color = Colors.white.withOpacity(0.5);
    for (int i = 0; i < 15; i++) {
      // Calculate perspective-based positioning
      double t = math.pow(i / 15, 3.0).toDouble();
      double y = horizonY + (size.height - horizonY) * t;

      // The speed effect: move the dashes based on the progress value
      double speedOffset = (progress * 50) % 50;
      double finalY = y + speedOffset;

      if (finalY < size.height) {
        double currentWidth = 1 + (t * 20);
        canvas.drawRect(
            Rect.fromCenter(center: Offset(size.width / 2, finalY), width: currentWidth, height: 10 * (t + 0.2)),
            dashPaint
        );
      }
    }

    // 3. RESTORED: High-Glow Neon Side Rails
    Color railColor = Color.lerp(Colors.cyanAccent, Colors.orangeAccent, progress)!;
    final Paint railPaint = Paint()
      ..strokeWidth = 10
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

    railPaint.color = railColor;
    canvas.drawLine(Offset(size.width * 0.49, horizonY), Offset(size.width * -1.5, size.height), railPaint);
    canvas.drawLine(Offset(size.width * 0.51, horizonY), Offset(size.width * 2.5, size.height), railPaint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class StreakPainter extends CustomPainter {
  final double progress;
  final int seed;
  final double horizonY;
  StreakPainter({required this.progress, required this.seed, required this.horizonY});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.2 * (1 - progress))..strokeWidth = 1.5;
    final random = math.Random(seed);
    double angle = (random.nextDouble() * math.pi) + (random.nextBool() ? 0 : math.pi);
    double centerX = size.width / 2;
    double centerY = horizonY;
    double endX = centerX + math.cos(angle) * (size.width * progress);
    double endY = centerY + math.sin(angle) * (size.height * progress);
    canvas.drawLine(Offset(centerX, centerY), Offset(endX, endY), paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


class HumanRunnerPainter extends CustomPainter {
  final double animationValue;   // 0.0 → 1.0 looping slowly

  HumanRunnerPainter({required this.animationValue});
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final skin = Paint()..color = const Color(0xFFC68642);
    final darkSkin = Paint()..color = const Color(0xFF8D5524);
    final vest = Paint()..color = Colors.orange.shade900;
    final clothes = Paint()..color = Colors.black87;

    // ───────────────────────────────────────────────
    // NEW: Gradient & shadow paints for realism
    // ───────────────────────────────────────────────
    final skinGradient = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFFD49A6A), const Color(0xFFC68642), const Color(0xFFAF6F38)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final deepShadow = Paint()
      ..color = Colors.black.withOpacity(0.40)
      ..style = PaintingStyle.fill;

    final midShadow = Paint()
      ..color = Colors.black.withOpacity(0.22)
      ..style = PaintingStyle.fill;

    final softHighlight = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..style = PaintingStyle.fill;

    final hairBase = Paint()
      ..color = const Color(0xFF0F0A05) // very dark realistic hair
      ..style = PaintingStyle.fill;

    final hairHighlight = Paint()
      ..color = const Color(0xFF2A1A0F).withOpacity(0.7)
      ..style = PaintingStyle.fill;

    // ───────────────────────────────────────────────
    // HYPER ENHANCED: Additional paints for ultimate realism (sweat, veins, specular)
    // ───────────────────────────────────────────────
    final specularHighlight = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..style = PaintingStyle.fill;

    final veinPaint = Paint()
      ..color = const Color(0xFF7A4A2A).withOpacity(0.45)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final sweatPaint = Paint()
      ..color = Colors.white.withOpacity(0.55)
      ..style = PaintingStyle.fill;

    final muscleFiber = Paint()
      ..color = Colors.black.withOpacity(0.08)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    // Legs (Alternate Stride for realism) ── original kept
    final legPaint = Paint()
      ..color = const Color(0xFFC68642)
      ..strokeWidth = w * 0.1
      ..strokeCap = StrokeCap.round;

    // Left Leg (Pushing back) ── original
    canvas.drawLine(Offset(w * 0.42, h * 0.6), Offset(w * 0.35, h * 0.85), legPaint);

    // Right Leg (Stepping forward) ── original
    canvas.drawLine(Offset(w * 0.58, h * 0.6), Offset(w * 0.65, h * 0.75), legPaint);

    // ───────────────────────────────────────────────
    // ADDED: Filled muscular legs + calf/hamstring definition (rear view)
    // ───────────────────────────────────────────────
    final leftCalf = Path()
      ..moveTo(w * 0.38, h * 0.72)
      ..quadraticBezierTo(w * 0.34, h * 0.81, w * 0.36, h * 0.86)
      ..lineTo(w * 0.40, h * 0.86)
      ..quadraticBezierTo(w * 0.39, h * 0.80, w * 0.41, h * 0.72)
      ..close();
    canvas.drawPath(leftCalf, midShadow); // inner shadow
    canvas.drawPath(leftCalf, skinGradient);

    final rightCalf = Path()
      ..moveTo(w * 0.62, h * 0.65)
      ..quadraticBezierTo(w * 0.66, h * 0.72, w * 0.67, h * 0.76)
      ..lineTo(w * 0.70, h * 0.77)
      ..quadraticBezierTo(w * 0.68, h * 0.73, w * 0.64, h * 0.66)
      ..close();
    canvas.drawPath(rightCalf, midShadow);
    canvas.drawPath(rightCalf, skinGradient);

    // ───────────────────────────────────────────────
    // HYPER ENHANCED: Thighs, glutes, finer muscle details, veins, sweat
    // ───────────────────────────────────────────────
    // Left thigh (hamstring + quad hint from back)
    final leftThigh = Path()
      ..moveTo(w * 0.40, h * 0.60)
      ..cubicTo(w * 0.36, h * 0.65, w * 0.35, h * 0.72, w * 0.38, h * 0.78)
      ..lineTo(w * 0.42, h * 0.78)
      ..cubicTo(w * 0.41, h * 0.72, w * 0.42, h * 0.65, w * 0.44, h * 0.60)
      ..close();
    canvas.drawPath(leftThigh, deepShadow);
    canvas.drawPath(leftThigh, skinGradient);

    // Right thigh
    final rightThigh = Path()
      ..moveTo(w * 0.60, h * 0.60)
      ..cubicTo(w * 0.64, h * 0.65, w * 0.65, h * 0.68, w * 0.62, h * 0.72)
      ..lineTo(w * 0.66, h * 0.72)
      ..cubicTo(w * 0.65, h * 0.68, w * 0.64, h * 0.65, w * 0.56, h * 0.60)
      ..close();
    canvas.drawPath(rightThigh, deepShadow);
    canvas.drawPath(rightThigh, skinGradient);

    // Glutes (subtle from back view)
    final glutes = Path()
      ..moveTo(w * 0.42, h * 0.58)
      ..quadraticBezierTo(w * 0.50, h * 0.55, w * 0.58, h * 0.58)
      ..quadraticBezierTo(w * 0.56, h * 0.62, w * 0.50, h * 0.64)
      ..quadraticBezierTo(w * 0.44, h * 0.62, w * 0.42, h * 0.58)
      ..close();
    canvas.drawPath(glutes, midShadow);
    canvas.drawPath(glutes, skinGradient);

    // Veins on left leg
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.38, h * 0.74)
        ..quadraticBezierTo(w * 0.37, h * 0.78, w * 0.39, h * 0.82),
      veinPaint,
    );

    // Muscle fibers on right calf
    canvas.drawLine(Offset(w * 0.64, h * 0.68), Offset(w * 0.66, h * 0.72), muscleFiber);
    canvas.drawLine(Offset(w * 0.65, h * 0.67), Offset(w * 0.67, h * 0.71), muscleFiber);

    // Sweat drops
    canvas.drawCircle(Offset(w * 0.41, h * 0.76), 1.2, sweatPaint);
    canvas.drawCircle(Offset(w * 0.63, h * 0.69), 1.0, sweatPaint);

    // Torso (V-Shape Back) ── original kept
    final Path back = Path()
      ..moveTo(w * 0.3, h * 0.2)
      ..lineTo(w * 0.7, h * 0.2)
      ..lineTo(w * 0.6, h * 0.6)
      ..lineTo(w * 0.4, h * 0.6)
      ..close();
    canvas.drawPath(back, vest);

    // Muscle Detail ── original kept
    canvas.drawLine(Offset(w * 0.5, h * 0.25), Offset(w * 0.5, h * 0.55), Paint()..color = Colors.black26..strokeWidth = 2);

    // ───────────────────────────────────────────────
    // ADDED: Realistic back musculature (traps, lats, spine, shoulder blades)
    // ───────────────────────────────────────────────
    final traps = Path()
      ..moveTo(w * 0.44, h * 0.18)
      ..quadraticBezierTo(w * 0.50, h * 0.14, w * 0.56, h * 0.18)
      ..lineTo(w * 0.54, h * 0.26)
      ..lineTo(w * 0.46, h * 0.26)
      ..close();
    canvas.drawPath(traps, skinGradient);

    final latsLeft = Path()
      ..moveTo(w * 0.38, h * 0.28)
      ..quadraticBezierTo(w * 0.42, h * 0.42, w * 0.40, h * 0.55)
      ..lineTo(w * 0.35, h * 0.56)
      ..quadraticBezierTo(w * 0.36, h * 0.43, w * 0.34, h * 0.30)
      ..close();
    canvas.drawPath(latsLeft, deepShadow);

    final latsRight = Path()
      ..moveTo(w * 0.62, h * 0.28)
      ..quadraticBezierTo(w * 0.58, h * 0.42, w * 0.60, h * 0.55)
      ..lineTo(w * 0.65, h * 0.56)
      ..quadraticBezierTo(w * 0.64, h * 0.43, w * 0.66, h * 0.30)
      ..close();
    canvas.drawPath(latsRight, deepShadow);

    // subtle spine groove
    canvas.drawLine(
      Offset(w * 0.50, h * 0.22),
      Offset(w * 0.50, h * 0.58),
      Paint()..color = Colors.black.withOpacity(0.35)..strokeWidth = 1.8..style = PaintingStyle.stroke,
    );

    // ───────────────────────────────────────────────
    // HYPER ENHANCED: Finer back details (rhomboids, lower back dimples, specular highlights, sweat)
    // ───────────────────────────────────────────────
    // Rhomboids (between shoulder blades)
    final rhomboids = Path()
      ..moveTo(w * 0.46, h * 0.30)
      ..quadraticBezierTo(w * 0.50, h * 0.28, w * 0.54, h * 0.30)
      ..quadraticBezierTo(w * 0.52, h * 0.38, w * 0.50, h * 0.40)
      ..quadraticBezierTo(w * 0.48, h * 0.38, w * 0.46, h * 0.30)
      ..close();
    canvas.drawPath(rhomboids, midShadow);
    canvas.drawPath(rhomboids, skinGradient);

    // Lower back dimples
    canvas.drawCircle(Offset(w * 0.45, h * 0.52), 3, deepShadow..maskFilter = MaskFilter.blur(BlurStyle.normal, 1.5));
    canvas.drawCircle(Offset(w * 0.55, h * 0.52), 3, deepShadow..maskFilter = MaskFilter.blur(BlurStyle.normal, 1.5));

    // Specular highlights on shoulders
    canvas.drawOval(Rect.fromLTWH(w * 0.32, h * 0.22, w * 0.05, h * 0.03), specularHighlight);
    canvas.drawOval(Rect.fromLTWH(w * 0.63, h * 0.22, w * 0.05, h * 0.03), specularHighlight);

    // Muscle fibers on lats
    canvas.drawLine(Offset(w * 0.38, h * 0.35), Offset(w * 0.40, h * 0.45), muscleFiber);
    canvas.drawLine(Offset(w * 0.62, h * 0.35), Offset(w * 0.60, h * 0.45), muscleFiber);

    // Sweat on back
    canvas.drawCircle(Offset(w * 0.48, h * 0.35), 1.5, sweatPaint);
    canvas.drawOval(Rect.fromLTWH(w * 0.52, h * 0.45, 2, 3), sweatPaint); // dripping effect

    // Arms (High speed pump) ── original kept
    final armP = Paint()
      ..color = const Color(0xFFC68642)
      ..strokeWidth = w * 0.08
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.3, h * 0.25), Offset(w * 0.15, h * 0.45), armP); // Left arm forward
    canvas.drawLine(Offset(w * 0.7, h * 0.25), Offset(w * 0.85, h * 0.2), armP); // Right arm back

    // ───────────────────────────────────────────────
    // ADDED: Arm volume & triceps/shoulder definition
    // ───────────────────────────────────────────────
    final leftArmPath = Path()
      ..moveTo(w * 0.28, h * 0.24)
      ..lineTo(w * 0.16, h * 0.44)
      ..lineTo(w * 0.20, h * 0.46)
      ..lineTo(w * 0.32, h * 0.26)
      ..close();
    canvas.drawPath(leftArmPath, skinGradient);

    final rightArmPath = Path()
      ..moveTo(w * 0.72, h * 0.24)
      ..lineTo(w * 0.84, h * 0.19)
      ..lineTo(w * 0.88, h * 0.22)
      ..lineTo(w * 0.76, h * 0.27)
      ..close();
    canvas.drawPath(rightArmPath, skinGradient);

    // ───────────────────────────────────────────────
    // HYPER ENHANCED: Biceps/triceps details, forearms, hands, veins, sweat
    // ───────────────────────────────────────────────
    // Left arm triceps (visible from back)
    final leftTriceps = Path()
      ..moveTo(w * 0.26, h * 0.30)
      ..quadraticBezierTo(w * 0.22, h * 0.35, w * 0.20, h * 0.40)
      ..lineTo(w * 0.24, h * 0.42)
      ..quadraticBezierTo(w * 0.26, h * 0.37, w * 0.28, h * 0.32)
      ..close();
    canvas.drawPath(leftTriceps, midShadow);
    canvas.drawPath(leftTriceps, skinGradient);

    // Right arm biceps hint
    final rightBiceps = Path()
      ..moveTo(w * 0.74, h * 0.28)
      ..quadraticBezierTo(w * 0.78, h * 0.25, w * 0.80, h * 0.22)
      ..lineTo(w * 0.84, h * 0.24)
      ..quadraticBezierTo(w * 0.82, h * 0.27, w * 0.78, h * 0.30)
      ..close();
    canvas.drawPath(rightBiceps, midShadow);
    canvas.drawPath(rightBiceps, skinGradient);

    // Hands (simple clenched fists for running)
    // Left hand
    canvas.drawOval(Rect.fromLTWH(w * 0.13, h * 0.44, w * 0.06, h * 0.05), skinGradient);
    // Right hand
    canvas.drawOval(Rect.fromLTWH(w * 0.83, h * 0.18, w * 0.06, h * 0.05), skinGradient);

    // Veins on arms
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.24, h * 0.32)
        ..quadraticBezierTo(w * 0.20, h * 0.36, w * 0.18, h * 0.40),
      veinPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.76, h * 0.24)
        ..quadraticBezierTo(w * 0.80, h * 0.22, w * 0.82, h * 0.20),
      veinPaint,
    );

    // Sweat on arms
    canvas.drawCircle(Offset(w * 0.22, h * 0.38), 1.0, sweatPaint);
    canvas.drawCircle(Offset(w * 0.78, h * 0.25), 1.2, sweatPaint);

    // Head ── original kept
    canvas.drawCircle(Offset(w * 0.5, h * 0.1), 12, skin);
    canvas.drawArc(Rect.fromLTWH(w * 0.38, h * 0.02, w * 0.24, 15), 3.14, 3.14, true, Paint()..color = Colors.black);

    // ───────────────────────────────────────────────
    // ADDED: Much more realistic head/hair from behind
    // ───────────────────────────────────────────────
    // Skull shape (slightly oval, not perfect circle)
    final headOval = Path()
      ..addOval(Rect.fromCenter(center: Offset(w * 0.5, h * 0.105), width: w * 0.22, height: h * 0.18));
    canvas.drawPath(headOval, skinGradient);

    // Hair – realistic swept-back short/mid length (wind from running)
    final hair = Path()
      ..moveTo(w * 0.39, h * 0.03)
      ..cubicTo(w * 0.45, h * -0.02, w * 0.55, h * -0.01, w * 0.61, h * 0.04)
      ..quadraticBezierTo(w * 0.66, h * 0.09, w * 0.64, h * 0.14)
      ..quadraticBezierTo(w * 0.55, h * 0.19, w * 0.45, h * 0.19)
      ..quadraticBezierTo(w * 0.36, h * 0.19, w * 0.36, h * 0.14)
      ..close();
    canvas.drawPath(hair, hairBase);

    // Hair strands / highlights
    canvas.drawLine(
      Offset(w * 0.48, h * 0.02),
      Offset(w * 0.52, h * 0.12),
      hairHighlight..strokeWidth = 2.5..style = PaintingStyle.stroke,
    );

    // Ear (more detailed)
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.63, h * 0.115), width: w * 0.07, height: h * 0.055),
      Paint()..color = const Color(0xFF9C6640),
    );
    canvas.drawArc(
      Rect.fromCenter(center: Offset(w * 0.635, h * 0.125), width: w * 0.04, height: h * 0.03),
      0,
      3.14 * 1.6,
      false,
      Paint()..color = const Color(0xFF7A4A2A)..style = PaintingStyle.stroke..strokeWidth = 1.5,
    );

    // Neck & trap connection
    final neck = Path()
      ..moveTo(w * 0.44, h * 0.16)
      ..lineTo(w * 0.56, h * 0.16)
      ..lineTo(w * 0.58, h * 0.24)
      ..lineTo(w * 0.42, h * 0.24)
      ..close();
    canvas.drawPath(neck, skinGradient);

    // ───────────────────────────────────────────────
    // HYPER ENHANCED: Finer head details (hair strands, neck veins, sweat, jawline shadow)
    // ───────────────────────────────────────────────
    // More hair strands
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.42, h * 0.05)
        ..cubicTo(w * 0.46, h * 0.02, w * 0.48, h * 0.04, w * 0.50, h * 0.08),
      hairHighlight..strokeWidth = 1.8..style = PaintingStyle.stroke,
    );
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.58, h * 0.05)
        ..cubicTo(w * 0.54, h * 0.02, w * 0.52, h * 0.04, w * 0.50, h * 0.08),
      hairHighlight..strokeWidth = 1.8..style = PaintingStyle.stroke,
    );

    // Neck veins
    canvas.drawLine(Offset(w * 0.47, h * 0.18), Offset(w * 0.45, h * 0.22), veinPaint);
    canvas.drawLine(Offset(w * 0.53, h * 0.18), Offset(w * 0.55, h * 0.22), veinPaint);

    // Jawline shadow
    canvas.drawArc(
      Rect.fromLTWH(w * 0.43, h * 0.14, w * 0.14, h * 0.08),
      3.14 / 2,
      3.14,
      false,
      deepShadow..strokeWidth = 1.2..style = PaintingStyle.stroke,
    );

    // Sweat on neck/head
    canvas.drawCircle(Offset(w * 0.49, h * 0.15), 1.3, sweatPaint);
    canvas.drawOval(Rect.fromLTWH(w * 0.51, h * 0.12, 1.5, 2.5), sweatPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
class WavingFlagPainter extends CustomPainter {
  final double animationValue;
  WavingFlagPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final white = Paint()..color = Colors.white;
    final black = Paint()..color = Colors.black;

    // Checkerboard cells with wave
    double cols = 10;
    double rows = 3;
    double cellW = w / cols;
    double cellH = h / rows;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        double wave = math.sin((c * 0.6) + (animationValue * math.pi * 2)) * 4;
        canvas.drawRect(
          Rect.fromLTWH(c * cellW, (r * cellH) + wave, cellW, cellH),
          (r + c) % 2 == 0 ? white : black,
        );
      }
    }

    // "FINISH" Text
    TextPainter(
      text: TextSpan(
        text: 'FINISH',
        style: GoogleFonts.blackOpsOne(fontSize: 12, color: Colors.red[900], fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout()..paint(canvas, Offset(w / 2 - 20, h / 2 - 6));
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}