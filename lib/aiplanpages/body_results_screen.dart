import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'fitness_goal_screen.dart';

class BodyResultsScreen extends StatefulWidget {
  const BodyResultsScreen({super.key});

  @override
  State<BodyResultsScreen> createState() => _BodyResultsScreenState();
}

class _BodyResultsScreenState extends State<BodyResultsScreen>
    with TickerProviderStateMixin {
  // Logic variables
  Map<String, dynamic> _results = {};
  bool _showResults = false;
  bool _isLoading = true;

  // Storing fetched values for navigation to questionnaire
  double? _fetchedWeight;
  double? _fetchedHeight;
  double? _fetchedAge;
  String _fetchedGender = 'Male';

  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  // Intro screen control
  bool _showIntro = true;
  late AnimationController _introController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    // Intro animation setup
    _introController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _introController, curve: const Interval(0.0, 0.4, curve: Curves.easeOut)),
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _introController, curve: const Interval(0.0, 0.6, curve: Curves.elasticOut)),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _introController, curve: const Interval(0.3, 1.0, curve: Curves.easeInOut)),
    );

    _introController.forward();

    // Auto-hide intro and start fetching
    Future.delayed(const Duration(milliseconds: 5000), () {
      if (mounted) {
        setState(() {
          _showIntro = false;
        });
      }
    });

    _controllers = [];
    _animations = [];

    // Trigger automatic data fetch
    _fetchProfileAndCalculate();
  }

  @override
  void dispose() {
    _introController.dispose();
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchProfileAndCalculate() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('weight, height, age, gender')
          .eq('id', user.id)
          .single();

      _fetchedWeight = (data['weight'] as num?)?.toDouble() ?? 0.0;
      _fetchedHeight = (data['height'] as num?)?.toDouble() ?? 0.0;
      _fetchedAge = (data['age'] as num?)?.toDouble() ?? 0.0;
      _fetchedGender = data['gender'] ?? 'Male';

      _calculate(_fetchedWeight!, _fetchedHeight!, _fetchedAge!, _fetchedGender);
    } catch (e) {
      debugPrint("Fetch Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching profile: $e", style: GoogleFonts.zenDots())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _calculate(double weight, double height, double age, String gender) {
    final int genderValue = gender == 'Male' ? 1 : 0;

    // Logic kept identical to your provided code
    double bmi = weight / math.pow(height / 100, 2);
    double bmiSq = bmi * bmi;
    double bodyFat = -44.988 + (0.503 * age) + (10.689 * genderValue) + (3.172 * bmi) - (0.026 * bmiSq) + (0.181 * bmi * genderValue) - (0.02 * bmi * age) - (0.005 * bmiSq * genderValue) + (0.00021 * bmiSq * age);
    bodyFat = bodyFat.clamp(3, 50);

    double leanMass = genderValue == 1
        ? (0.407 * weight) + (0.267 * height) - 19.2
        : (0.252 * weight) + (0.473 * height) - 48.3;

    double asm = (0.244 * weight) + (7.8 * (height / 100)) - (0.098 * age) + (6.6 * genderValue) - 3.3;
    double muscleMass = asm / 0.75;

    double tbw = genderValue == 1
        ? 2.447 - (0.09156 * age) + (0.1074 * height) + (0.3362 * weight)
        : -2.097 + (0.1069 * height) + (0.2466 * weight);
    double bodyMoisture = (tbw / weight) * 100;

    double boneMass = leanMass * 0.07;
    double protein = leanMass - tbw - boneMass;
    if (protein < 0) protein = leanMass * 0.17;

    double bmr = (10 * weight) + (6.25 * height) - (5 * age) + (genderValue == 1 ? 5 : -161);

    double visceralThreshold = (bmi * 0.35) + (age * 0.05) - (genderValue == 1 ? 5 : 8);
    String visceralFat = visceralThreshold < 10 ? 'Normal' : visceralThreshold < 15 ? 'High' : 'Very High';

    double subFat = bodyFat * 0.88;
    String obesityLevel = bmi < 18.5 ? 'Underweight' : bmi < 25 ? 'Normal' : bmi < 30 ? 'Overweight' : 'Obese';

    double athleteThreshold = genderValue == 1 ? 13 : 20;
    double fitThreshold = genderValue == 1 ? 17 : 24;
    double averageThreshold = genderValue == 1 ? 24 : 31;
    String bodyType = bodyFat <= athleteThreshold ? 'Athlete' : bodyFat <= fitThreshold ? 'Fit' : bodyFat <= averageThreshold ? 'Average' : 'Obese';

    double heightInches = height / 2.54;
    double inchOverFiveFeet = math.max(0, heightInches - 60);
    double standardWeight = genderValue == 1 ? 52 + (1.9 * inchOverFiveFeet) : 49 + (1.7 * inchOverFiveFeet);

    setState(() {
      _results = {
        'BMI': bmi.toStringAsFixed(1),
        'Body Fat Rate (%)': bodyFat.toStringAsFixed(2),
        'Muscle Mass (kg)': muscleMass.toStringAsFixed(2),
        'Body Moisture Rate (%)': bodyMoisture.toStringAsFixed(2),
        'Visceral Fat': visceralFat,
        'Bone Mass (kg)': boneMass.toStringAsFixed(2),
        'BMR (kcal/day)': bmr.toStringAsFixed(0),
        'Protein (kg)': protein.toStringAsFixed(2),
        'Obesity Levels': obesityLevel,
        'Subcutaneous Fat %': subFat.toStringAsFixed(2),
        'Lean Mass (kg)': leanMass.toStringAsFixed(2),
        'Body Type': bodyType,
        'Standard Weight (kg)': standardWeight.toStringAsFixed(2),
      };
      _showResults = true;
    });

    _controllers.clear();
    _animations.clear();
    for (int i = 0; i < _results.length; i++) {
      final controller = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
      final animation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutExpo));
      _controllers.add(controller);
      _animations.add(animation);
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) controller.forward();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (!_showIntro)
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(center: Alignment.center, radius: 1.5, colors: [Colors.grey.shade900, Colors.black]),
              ),
              child: SafeArea(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.orange))
                    : SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          "Zain from SetMeFit",
                          style: GoogleFonts.zenDots(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade500,
                            shadows: [
                              BoxShadow(color: Colors.orange.shade800, blurRadius: 20, spreadRadius: 2),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Text(
                          "Bio-Metric Scan Complete. Reviewing your stats:",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.zenDots(
                            fontSize: 18,
                            fontStyle: FontStyle.italic,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                      if (_showResults) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 20, bottom: 20),
                          child: Text(
                            'YOUR BODY INSIGHTS',
                            style: GoogleFonts.zenDots(
                              fontSize: 24,
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              shadows: [const BoxShadow(color: Colors.yellow, blurRadius: 15)],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _results.length,
                            itemBuilder: (context, index) {
                              final key = _results.keys.elementAt(index);
                              final value = _results[key];
                              if (index >= _animations.length) return _buildElectrifyingGauge(key, value);
                              return FadeTransition(opacity: _animations[index], child: _buildElectrifyingGauge(key, value));
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FitnessGoalScreen(
                                    //results: _results,
                                    gender: _fetchedGender,
                                    weight: _fetchedWeight!,
                                    height: _fetchedHeight!,
                                    age: _fetchedAge!,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              shadowColor: Colors.orange.shade800,
                              elevation: 10,
                            ),
                            child: Text(
                              'GET STARTED WITH AI PLAN',
                              style: GoogleFonts.zenDots(fontSize: 18, color: Colors.orange.shade500, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          if (_showIntro) _buildIntroOverlay(),
        ],
      ),
    );
  }

  Widget _buildIntroOverlay() {
    return AnimatedBuilder(
      animation: _introController,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.8,
              colors: [Colors.orange.shade900.withOpacity(0.6), Colors.black.withOpacity(0.9)],
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.orange.withOpacity(0.1 * _glowAnimation.value),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.6 * _glowAnimation.value),
                        blurRadius: 100 * _glowAnimation.value,
                        spreadRadius: 50 * _glowAnimation.value,
                      ),
                    ],
                  ),
                ),
              ),
              Center(
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Heya! Welcome to Set Me Fit',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.zenDots(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade300,
                            shadows: [
                              BoxShadow(color: Colors.orange.shade800, blurRadius: 30, spreadRadius: 5),
                              BoxShadow(color: Colors.yellow.shade600, blurRadius: 15),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "I am Zain\nYour AI Planner",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.zenDots(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.2,
                            shadows: [
                              BoxShadow(color: Colors.orange.shade700, blurRadius: 40, spreadRadius: 8),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildElectrifyingGauge(String title, dynamic value) {
    bool isPercentage = title.contains('%') || title == 'Body Fat Rate (%)' || title == 'Body Moisture Rate (%)' || title == 'Subcutaneous Fat %';
    double progress = isPercentage ? (double.tryParse(value.toString()) ?? 0.0) / 100 : 0.5;
    progress = progress.clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(120, 120),
                painter: ElectrifyingGaugePainter(progress: progress),
              ),
              Text(
                isPercentage ? '${(progress * 100).toStringAsFixed(0)}%' : value.toString(),
                style: GoogleFonts.zenDots(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [BoxShadow(color: Colors.orange.shade600, blurRadius: 8)],
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),
          Text(
            title,
            style: GoogleFonts.zenDots(
              fontSize: 18,
              color: Colors.orange.shade400,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class ElectrifyingGaugePainter extends CustomPainter {
  final double progress;

  ElectrifyingGaugePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // Background arc
    final bgPaint = Paint()
      ..color = Colors.grey.shade800
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, math.pi * 2, false, bgPaint);

    // Glow effect
    final glowPaint = Paint()
      ..color = Colors.orange.shade600
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, math.pi * 2 * progress, false, glowPaint);

    // Progress arc
    final progressPaint = Paint()
      ..shader = LinearGradient(colors: [Colors.orange.shade400, Colors.orange.shade800]).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 10;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, math.pi * 2 * progress, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}