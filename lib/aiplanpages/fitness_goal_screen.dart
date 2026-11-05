import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'dart:math';
import 'ai_planner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserFitnessData {
  // Supabase values
  final String gender;
  final double weight;
  final double height;
  final double age;

  // Flow values
  //Map<String, dynamic>? results;
  String? fitnessGoal;
  double? currentWeight;
  double? targetWeight;
  int? weeksToTarget;
  String? bodyFat;
  Set<int> focusAreas = {};
  String? activityIndex;
  int? workoutPlace;
  Set<int> selectedInjuries = {};

  UserFitnessData({

    required this.gender,
    required this.weight,
    required this.height,
    required this.age,
  });
}


class FitnessGoalScreen extends StatefulWidget {
  // ✅ ADD THESE FIELDS
  //final Map<String, dynamic> results;
  final String gender;
  final double weight;
  final double height;
  final double age;

  const FitnessGoalScreen({
    super.key,
    //required this.results,
    required this.gender,
    required this.weight,
    required this.height,
    required this.age,
  });


  @override
  State<FitnessGoalScreen> createState() => _FitnessGoalScreenState();
}

class _FitnessGoalScreenState extends State<FitnessGoalScreen> {
  late UserFitnessData userData;
  int selectedIndex = 1;


  @override
  void initState() {
    super.initState();
    // Initialize the shared data object with Supabase values
    userData = UserFitnessData(
      gender: widget.gender,
      weight: widget.weight,
      height: widget.height,
      age: widget.age,
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF343434),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),

            // ===== HEADER =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, size: 18, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.orange.shade400,
                              Colors.orange.shade800,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Set me fit",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Progress Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        width: index == 0 ? 26 : 18,
                        height: 4,
                        decoration: BoxDecoration(
                          gradient: index == 0
                              ? LinearGradient(
                            colors: [
                              Colors.orange.shade400,
                              Colors.orange.shade800,
                            ],
                          )
                              : null,
                          color: index == 0 ? null : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ===== TITLE =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) {
                      return LinearGradient(
                        colors: [
                          Colors.orange.shade400,
                          Colors.orange.shade800,
                        ],
                      ).createShader(bounds);
                    },
                    child: Text(
                      "What’s your fitness goal?",
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Your goal is our roadmap, let's make it happen!",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 36),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: GoalCard(
                          title: "Weight Loss",
                          imagePath: widget.gender == "Male"
                              ? "assets/weight_loss_boy.png"
                              : "assets/weight_lossgirls.png",
                          selected: selectedIndex == 0,
                          onTap: () {
                            setState(() => selectedIndex = 0);
                            // Store the answer
                            userData.fitnessGoal = "Weight Loss";
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TargetWeightScreen(userData: userData),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GoalCard(
                          title: "Muscle Build",
                          imagePath: widget.gender == "Male"
                              ? "assets/muscle_buildboys.png"
                              : "assets/muscle_buildgirls.png",
                          selected: selectedIndex == 1,
                          onTap: () {
                            setState(() => selectedIndex = 1);
                            // Store the answer
                            userData.fitnessGoal = "Muscle Build";
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TargetWeightScreen(userData: userData),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.55,
                    child: GoalCard(
                      title: "Keep Fit",
                      imagePath: widget.gender == "Male"
                          ? "assets/keep_fitboys.png"
                          : "assets/keep_fitgirls.png",
                      selected: selectedIndex == 2,
                      onTap: () {
                        setState(() => selectedIndex = 2);
                        // Store the answer
                        userData.fitnessGoal = "Keep Fit";
                        userData.currentWeight = userData.weight;
                        userData.targetWeight = userData.weight;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FocusAreaScreen(userData: userData),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GoalCard extends StatelessWidget {
  final String title;
  final String imagePath;
  final bool selected;
  final VoidCallback onTap;

  const GoalCard({
    super.key,
    required this.title,
    required this.imagePath,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 260,
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.orange.shade400,
              Colors.orange.shade800,
            ],
          )
              : null,
          // Color remains Color(0xFFFAF3E1) when not selected as per your design
          color: selected ? null : const Color(0xFFFAF3E1),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? Colors.orange.shade800.withOpacity(0.45)
                  : Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10), // Added slight padding for the image
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  // Text turns white when selected for better contrast against orange
                  color: selected ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}
enum GoalType { loss, gain, keepFit }


class TargetWeightScreen extends StatefulWidget {
  final UserFitnessData userData;

  const TargetWeightScreen({
    super.key,
    required this.userData,
  });

  @override
  State<TargetWeightScreen> createState() => _TargetWeightScreenState();
}

class _TargetWeightScreenState extends State<TargetWeightScreen> {
  final Color orangeLight = Colors.orange.shade400;
  final Color orangeDark = Colors.orange.shade800;

  final double minWeight = 20;
  final double maxWeight = 120;
  final double tickWidth = 22;

  late double currentWeight;
  late double targetWeight;

  // Use height from the userData object (passed from Supabase)
  late double heightCm;

  double get currentBmi {
    final h = heightCm / 100;
    return currentWeight / (h * h);
  }

  double get targetBmi {
    final h = heightCm / 100;
    return targetWeight / (h * h);
  }

  String bmiLabel(double bmi) {
    if (bmi < 18.5) return "Underweight";
    if (bmi < 25) return "Normal";
    if (bmi < 30) return "Overweight";
    return "Obese";
  }

  Color bmiColor(double bmi) {
    if (bmi < 18.5) return Colors.orange;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.redAccent;
    return Colors.red;
  }

  final ScrollController _currentController = ScrollController();
  final ScrollController _targetController = ScrollController();

  @override
  void initState() {
    super.initState();

    // Initialize weights from the userData/Supabase profile
    currentWeight = widget.userData.weight;
    targetWeight = widget.userData.weight;
    heightCm = widget.userData.height;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_currentController.hasClients) {
        _currentController.jumpTo((currentWeight - minWeight) * tickWidth);
      }
      if (_targetController.hasClients) {
        _targetController.jumpTo((targetWeight - minWeight) * tickWidth);
      }
    });

    // CURRENT WEIGHT LISTENER
    _currentController.addListener(() {
      final index = (_currentController.offset / tickWidth).round();
      final value = minWeight + index;

      if (value >= minWeight && value <= maxWeight) {
        setState(() {
          currentWeight = value;
          targetWeight = value;
        });
        _targetController.jumpTo((targetWeight - minWeight) * tickWidth);
      }
    });

    // TARGET WEIGHT LISTENER
    _targetController.addListener(() {
      final index = (_targetController.offset / tickWidth).round();
      final value = minWeight + index;

      if (value >= minWeight && value <= maxWeight) {
        // Corrected check: using widget.userData.fitnessGoal
        if (widget.userData.fitnessGoal == "Weight Loss" && value > currentWeight) return;
        if (widget.userData.fitnessGoal == "Muscle Build" && value < currentWeight) return;

        setState(() {
          targetWeight = value;
        });
      }
    });
  }

  // INSIGHT LOGIC
  double get weightDiff => targetWeight - currentWeight;
  bool get isWeightLoss => weightDiff < 0;
  bool get isWeightGain => weightDiff > 0;

  String get insightTitle {
    if (weightDiff == 0) return "Maintaining your weight";
    if (isWeightLoss) return "Healthy weight loss goal";
    return "Lean muscle gain goal";
  }

  String get insightMessage {
    if (weightDiff == 0) return "Good! Staying at this weight helps improve fitness.";
    if (isWeightLoss) return "You are aiming to lose ${weightDiff.abs().round()} kg safely.";
    return "You are aiming to gain ${weightDiff.round()} kg gradually.";
  }

  Widget buildScale(ScrollController controller, double selectedValue) {
    return SizedBox(
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ListView.builder(
            controller: controller,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: (maxWeight - minWeight + 1).toInt(),
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width / 2,
            ),
            itemBuilder: (context, index) {
              final value = minWeight + index;
              final isSelected = value.round() == selectedValue.round();

              return SizedBox(
                width: tickWidth,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (value % 10 == 0)
                      Text(
                        value.toInt().toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: isSelected ? orangeLight : Colors.grey.shade400,
                        ),
                      ),
                    const SizedBox(height: 6),
                    Container(
                      height: value % 10 == 0 ? 34 : 18,
                      width: isSelected ? 3.5 : 2,
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(colors: [orangeLight, orangeDark])
                            : null,
                        color: isSelected ? null : Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Positioned(
            bottom: 0,
            child: Container(
              height: 65,
              width: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [orangeLight, orangeDark]),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Fallback background
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.4,
              child: Image.asset("assets/target.png", fit: BoxFit.cover),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 1),
                // HEADER
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios, size: 18, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Set Me FiT",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      // Progress Bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (i) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            width: i == 1 ? 26 : 18,
                            height: 4,
                            decoration: BoxDecoration(
                              gradient: i <= 1 ? LinearGradient(colors: [orangeLight, orangeDark]) : null,
                              color: i <= 1 ? null : Colors.grey.shade600,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  widget.userData.fitnessGoal == "Weight Loss"
                      ? "Set your weight loss goal"
                      : "Set your muscle gain goal",
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: orangeLight,
                  ),
                ),

                const SizedBox(height: 4),
                Text("Current weight", style: TextStyle(color: Colors.white70)),
                Text("${currentWeight.round()} kg", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                buildScale(_currentController, currentWeight),

                const SizedBox(height: 5),
                Text("Target weight", style: TextStyle(color: Colors.white70)),
                Text("${targetWeight.round()} kg", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                buildScale(_targetController, targetWeight),

                const SizedBox(height: 6),

                // Insight Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF3E1),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(insightTitle, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      Text(insightMessage),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            children: [
                              Text("Current BMI", style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(currentBmi.toStringAsFixed(1), style: TextStyle(color: bmiColor(currentBmi))),
                            ],
                          ),
                          Column(
                            children: [
                              Text("Target BMI", style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(targetBmi.toStringAsFixed(1), style: TextStyle(color: bmiColor(targetBmi))),
                            ],
                          ),
                        ],
                      )
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    height: 56,
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () async {
                        try {
                          // 1. Local Data Update
                          widget.userData.currentWeight = currentWeight;
                          widget.userData.targetWeight = targetWeight;

                          // 3. Update Supabase
                          final supabase = Supabase.instance.client;
                          final userId = supabase.auth.currentUser?.id;

                          if (userId != null) {
                            await supabase
                                .from('profiles')
                                .update({
                              'weight': currentWeight,
                              'bmi': currentBmi.toStringAsFixed(1),
                            })
                                .eq('id', userId);
                          }

                          // 4. Navigate to Prediction Screen
                          if (context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WeightPredictionScreen(
                                  userData: widget.userData,
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          debugPrint("Supabase Update Error: $e");
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Cloud sync failed, but proceeding with your plan..."),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            // Still navigate even if sync fails so user experience isn't blocked
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WeightPredictionScreen(userData: widget.userData),
                              ),
                            );
                          }
                        }
                      },
                      child: Text("CONTINUE", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

///---------2---------------
class FocusAreaScreen extends StatefulWidget {
  final UserFitnessData userData;
  const FocusAreaScreen({super.key, required this.userData});

  @override
  State<FocusAreaScreen> createState() => _FocusAreaScreenState();
}

class _FocusAreaScreenState extends State<FocusAreaScreen> {
  // Use the gender passed from the previous screens/Supabase
  late String gender;

  final Color orangeLight = Colors.orange.shade400;
  final Color orangeDark = Colors.orange.shade800;
  final Color grey = Colors.grey.shade400;

  Set<int> selectedFocusIndexes = {};

  final List<String> focusAreas = [
    "Arms",
    "Abs",
    "Butt",
    "Legs",
    "Full Body",
  ];

  @override
  void initState() {
    super.initState();
    // Initialize gender from the userData object
    gender = widget.userData.gender.toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2F2F2F),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, size: 18, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [orangeLight, orangeDark],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "SetMe FiT",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Progress bar (Index 2 for Focus Area)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        width: i == 2 ? 26 : 18, // Updated index to 2
                        height: 4,
                        decoration: BoxDecoration(
                          gradient: i <= 2
                              ? LinearGradient(colors: [orangeLight, orangeDark])
                              : null,
                          color: i <= 2 ? null : Colors.grey.shade600,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [orangeLight, orangeDark],
              ).createShader(bounds),
              child: Text(
                "Which areas do you want to\nfocus on?",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Get a plan that best suits your focus area",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade300,
              ),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // LEFT: OPTIONS
                    Expanded(
                      flex: 6,
                      child: ListView.builder(
                        itemCount: focusAreas.length,
                        itemBuilder: (context, index) {
                          final bool selected = selectedFocusIndexes.contains(index);
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (index == 4) {
                                  if (selectedFocusIndexes.contains(0) &&
                                      selectedFocusIndexes.contains(1) &&
                                      selectedFocusIndexes.contains(2) &&
                                      selectedFocusIndexes.contains(3)) {
                                    selectedFocusIndexes.clear();
                                  } else {
                                    selectedFocusIndexes = {0, 1, 2, 3, 4};
                                  }
                                } else {
                                  if (selectedFocusIndexes.contains(index)) {
                                    selectedFocusIndexes.remove(index);
                                    selectedFocusIndexes.remove(4); // Uncheck "Full Body" if any part is removed
                                  } else {
                                    selectedFocusIndexes.add(index);
                                    if (selectedFocusIndexes.contains(0) &&
                                        selectedFocusIndexes.contains(1) &&
                                        selectedFocusIndexes.contains(2) &&
                                        selectedFocusIndexes.contains(3)) {
                                      selectedFocusIndexes.add(4); // Auto-check "Full Body"
                                    }
                                  }
                                }
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: selected ? LinearGradient(colors: [orangeLight, orangeDark]) : null,
                                color: selected ? null : const Color(0xFFFAF3E1),
                                borderRadius: BorderRadius.circular(28),
                              ),
                              child: Text(
                                focusAreas[index],
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: selected ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    // RIGHT: MODEL IMAGE
                    Expanded(
                      flex: 5,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.asset(
                            gender == "male" ? "assets/model1boys.png" : "assets/model1girls.png",
                            fit: BoxFit.contain,
                          ),
                          if (selectedFocusIndexes.contains(0))
                            Image.asset(gender == "Male" ? "assets/armsboys.png" : "assets/armsgirls.png", fit: BoxFit.contain),
                          if (selectedFocusIndexes.contains(1))
                            Image.asset(gender == "Male" ? "assets/bellyboys.png" : "assets/bellygirls.png", fit: BoxFit.contain),
                          if (selectedFocusIndexes.contains(2))
                            Image.asset(gender == "Male" ? "assets/buttboys.png" : "assets/buttgirls.png", fit: BoxFit.contain),
                          if (selectedFocusIndexes.contains(3))
                            Image.asset(gender == "Male" ? "assets/legsboys.png" : "assets/legsgirls.png", fit: BoxFit.contain),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
            // CONTINUE BUTTON
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                height: 56,
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: selectedFocusIndexes.isEmpty ? null : () {
                    // ✅ STORE DATA IN TEMPORARY OBJECT
                    widget.userData.focusAreas = selectedFocusIndexes;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TargetBodyTypeWidget(
                          userData: widget.userData,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    "CONTINUE",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TargetBodyTypeWidget extends StatefulWidget {
  // ✅ Change this to accept the full data object
  final UserFitnessData userData;

  const TargetBodyTypeWidget({
    super.key,
    required this.userData,
  });

  @override
  State<TargetBodyTypeWidget> createState() => _TargetBodyTypeWidgetState();
}

class _TargetBodyTypeWidgetState extends State<TargetBodyTypeWidget> {
  // ✅ Sync gender with the data provided earlier in the app
  late String gender = widget.userData.gender.toLowerCase();

  int bodyIndex = 2; // default middle

  String get bodyTypeTitle {
    switch (bodyIndex) {
      case 0: return "Athletic & Lean";
      case 1: return "Fit & Toned";
      case 2: return "Balanced Body";
      case 3: return "Fat Loss Focus";
      case 4: return "Long-Term Wellness";
      default: return "";
    }
  }

  String get bodyTypeDesc {
    switch (bodyIndex) {
      case 0: return "You already have very low body fat. Focus on muscle tone, strength, and performance.";
      case 1: return "A healthy and fit range. Maintain consistency and improve muscle definition.";
      case 2: return "A balanced body type. A mix of cardio and strength training works best here.";
      case 3: return "Focus on fat reduction with structured workouts and mindful nutrition.";
      case 4: return "Start slow, build daily habits, and focus on sustainable long-term health.";
      default: return "";
    }
  }

  final List<String> bodyFatLabels = [
    "10–13%",
    "14–17%",
    "18–22%",
    "26–30%",
    "30–35%",
  ];

  List<String> get bodyImages => [
    gender == "male" ? "assets/body_10_13_boys.png" : "assets/body_10_13_girls.png",
    gender == "male" ? "assets/body_14_17_boys.png" : "assets/body_14_17_girls.png",
    gender == "male" ? "assets/body_18_22_boys.png" : "assets/body_18_22_girls.png",
    gender == "male" ? "assets/body_26_30_boys.png" : "assets/body_26_30_girls.png",
    gender == "male" ? "assets/body_30_35_boys.png" : "assets/body_30_35_girls.png",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF343434),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // ===== BACK ICON =====
                    Row(
                      children: const [
                        Icon(Icons.arrow_back_ios, size: 18, color: Colors.white),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // ===== LOGO =====
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.orange.shade400,
                                Colors.orange.shade800,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Set Me FiT",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // ===== PROGRESS BAR (STEP 3) =====
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          width: i == 2 ? 26 : 18,
                          height: 4,
                          decoration: BoxDecoration(
                            gradient: i <= 2
                                ? LinearGradient(
                              colors: [
                                Colors.orange.shade400,
                                Colors.orange.shade800,
                              ],
                            )
                                : null,
                            color: i <= 2 ? null : Colors.grey.shade600,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),



              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ShaderMask(
                  shaderCallback: (bounds) {
                    return LinearGradient(
                      colors: [
                        Colors.orange.shade400,
                        Colors.orange.shade800,
                      ],
                    ).createShader(bounds);
                  },
                  child: Text(
                    "Your target body type",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),


              const SizedBox(height: 6),

              Text(
                "Select the body fat % you want to achieve",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),

              const SizedBox(height: 28),
              // ... (Your existing Header, Progress Bar, and Title code stays here)

              // ===== IMAGE CARD =====
              Container(
                height: 240,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF3E1),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.orange.withOpacity(0.6)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Image.asset(
                    bodyImages[bodyIndex],
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ===== SLIDER =====
              Text(
                bodyFatLabels[bodyIndex],
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade300,
                ),
              ),

              Slider(
                value: bodyIndex.toDouble(),
                min: 0,
                max: 4,
                divisions: 4, // 🔥 THIS IS THE KEY (5 steps)
                activeColor: Colors.orange,
                inactiveColor: Colors.grey.shade700,
                onChanged: (value) {
                  setState(() {
                    bodyIndex = value.round();
                  });
                },
              ),


              const SizedBox(height: 24),

              // ===== INSIGHT CARD =====
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bodyTypeTitle,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      bodyTypeDesc,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade300,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  height: 56,
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () {
                      // ✅ SAVE THE GOAL DATA
                      widget.userData.bodyFat = bodyFatLabels[bodyIndex];
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlanSetupScreen(
                            userData: widget.userData,
                          ),
                        ),
                      );
                    },
                    child: ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [Colors.orange.shade400, Colors.orange.shade800],
                      ).createShader(bounds),
                      child: Text(
                        "CONTINUE",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
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
}
class ActivityLevelScreen extends StatefulWidget {
  final UserFitnessData userData;
  const ActivityLevelScreen({super.key, required this.userData});

  @override
  State<ActivityLevelScreen> createState() => _ActivityLevelScreenState();
}

class _ActivityLevelScreenState extends State<ActivityLevelScreen> {
  // Use the gender from our data object to pick the right background
  late String gender;
  int activityIndex = 1;

  final List<String> activityLevels = [
    "Beginner",
    "Lightly Active",
    "Moderately Active",
    "Very Active",
  ];

  final List<String> activityDesc = [
    "rarely exercise or just starting out",
    "work out 1–2 days a week",
    "work out 3–4 days a week",
    "work out 5+ days a week",
  ];

  @override
  void initState() {
    super.initState();
    // Initialize gender from the userData object (originally from Supabase)
    gender = widget.userData.gender.toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final orangeLight = Colors.orange.shade400;
    final orangeDark = Colors.orange.shade800;

    return Scaffold(
      backgroundColor: const Color(0xFF343434),
      body: Stack(
        children: [
          // 🔹 DYNAMIC BACKGROUND IMAGE (Boys or Girls)
          Positioned.fill(
            child: Image.asset(
              "assets/bg_activitygirls.png",
              fit: BoxFit.cover,
            ),
          ),

          // 🔹 DARK OVERLAY
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.55),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 12),

                // ===== HEADER + PROGRESS =====
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios, size: 18, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [orangeLight, orangeDark]),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "SetMe FiT",
                            style: GoogleFonts.poppins(
                              fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Progress bar (STEP 4)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (i) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            width: i == 3 ? 26 : 18,
                            height: 4,
                            decoration: BoxDecoration(
                              gradient: i <= 3 ? LinearGradient(colors: [orangeLight, orangeDark]) : null,
                              color: i <= 3 ? null : Colors.grey.shade600,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ===== TITLE =====
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [orangeLight, orangeDark],
                  ).createShader(bounds),
                  child: Text(
                    "How active do you want to be?",
                    style: GoogleFonts.poppins(
                      fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 6),
                Text(
                  "This helps us personalize your workout intensity",
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
                ),

                const SizedBox(height: 32),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ListView.builder(
                      itemCount: activityLevels.length,
                      itemBuilder: (context, index) {
                        final bool selected = activityIndex == index;
                        return GestureDetector(
                          onTap: () => setState(() => activityIndex = index),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                            decoration: BoxDecoration(
                              gradient: selected ? LinearGradient(colors: [orangeLight, orangeDark]) : null,
                              color: selected ? null : const Color(0xFFFAF3E1),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: selected ? orangeDark.withOpacity(0.45) : Colors.black.withOpacity(0.08),
                                  blurRadius: 16, offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  activityLevels[index],
                                  style: GoogleFonts.poppins(
                                    fontSize: 18, fontWeight: FontWeight.w600,
                                    color: selected ? Colors.white : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  activityDesc[index],
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: selected ? Colors.white.withOpacity(0.8) : Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // ===== CONTINUE =====
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    height: 56,
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        // ✅ STORE SELECTION IN TEMPORARY OBJECT
                        widget.userData.activityIndex = activityDesc[activityIndex];

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => WorkoutPlaceScreen(userData: widget.userData),
                          ),
                        );
                      },
                      child: ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [orangeLight, orangeDark],
                        ).createShader(bounds),
                        child: Text(
                          "CONTINUE",
                          style: GoogleFonts.poppins(
                            fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WorkoutPlaceScreen extends StatefulWidget {
  final UserFitnessData userData;

  const WorkoutPlaceScreen({
    super.key,
    required this.userData,
  });

  @override
  State<WorkoutPlaceScreen> createState() => _WorkoutPlaceScreenState();
}

class _WorkoutPlaceScreenState extends State<WorkoutPlaceScreen> {
  int selectedPlace = -1; // 0 = Home, 1 = Gym, 2 = Both
  late String gender;

  @override
  void initState() {
    super.initState();
    // Initialize gender from the carry-over data object (default to female if null)
    gender = widget.userData.gender.toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final orangeLight = Colors.orange.shade400;
    final orangeDark = Colors.orange.shade800;

    return Scaffold(
      body: Stack(
        children: [
          // ===== DYNAMIC BACKGROUND IMAGE BASED ON GENDER =====
          Positioned.fill(
            child: Image.asset(
              "assets/bg_workout_placegirls.png",
              fit: BoxFit.cover,
            ),
          ),

          // ===== DARK OVERLAY =====
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.55),
            ),
          ),

          // ===== MAIN UI =====
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 12),

                // ===== HEADER + PROGRESS (STEP 5) =====
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios, size: 18, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [orangeLight, orangeDark]),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "SetMe FiT",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Progress bar (Final Step highlight)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (i) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            width: i == 4 ? 26 : 18,
                            height: 4,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [orangeLight, orangeDark]),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ===== TITLE =====
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [orangeLight, orangeDark],
                  ).createShader(bounds),
                  child: Text(
                    "Where do you work out?",
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 8),
                Text(
                  "Choose your primary workout place",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),

                const SizedBox(height: 40),

                // ===== OPTIONS =====
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _placeCard(
                              title: "Home",
                              icon: Icons.home_rounded,
                              isSelected: selectedPlace == 0,
                              onTap: () => setState(() => selectedPlace = 0),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _placeCard(
                              title: "Gym",
                              icon: Icons.fitness_center_rounded,
                              isSelected: selectedPlace == 1,
                              onTap: () => setState(() => selectedPlace = 1),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.45,
                        child: _placeCard(
                          title: "Both",
                          icon: Icons.all_inclusive_rounded,
                          isSelected: selectedPlace == 2,
                          onTap: () => setState(() => selectedPlace = 2),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // ===== CONTINUE =====
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    height: 56,
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: selectedPlace == -1
                          ? null
                          : () {
                        // ✅ Save selection to the shared object
                        widget.userData.workoutPlace = selectedPlace;

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => InjuryScreen(userData: widget.userData),
                          ),
                        );
                      },
                      child: ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [orangeLight, orangeDark],
                        ).createShader(bounds),
                        child: Text(
                          "CONTINUE",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===== HELPER CARD WIDGET (Fixed: Now inside the State class) =====
  Widget _placeCard({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: isSelected ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          height: 160, // Adjusted height for better fit
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(colors: [Colors.orange.shade400, Colors.orange.shade800])
                : null,
            color: isSelected ? null : const Color(0xFFFAF3E1),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: isSelected ? Colors.orange.shade800.withOpacity(0.4) : Colors.black.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 42,
                color: isSelected ? Colors.white : Colors.black,
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//------6-----

class InjuryScreen extends StatefulWidget {
  final UserFitnessData userData;

  const InjuryScreen({
    super.key,
    required this.userData,
  }); // Added missing parenthesis and semicolon

  @override
  State<InjuryScreen> createState() => _InjuryScreenState();
}

class _InjuryScreenState extends State<InjuryScreen> {
  late String gender; // Use dynamic gender from model
  Set<int> selectedInjuries = {};

  @override
  void initState() {
    super.initState();
    // Fetch gender from the carry-over data object
    gender = widget.userData.gender.toLowerCase();
  }

  final Color orangeLight = Colors.orange.shade400;
  final Color orangeDark = Colors.orange.shade800;

  List<Map<String, String>> get injuries {
    String suffix = gender == "male" ? "boys" : "girls";

    return [
      {"title": "No Injuries", "image": "assets/injury_none_$suffix.png"},
      {"title": "Shoulder", "image": "assets/injury_shoulder_$suffix.png"},
      {"title": "Back", "image": "assets/injury_back_$suffix.png"},
      {"title": "Waist", "image": "assets/injury_waist_$suffix.png"},
      {"title": "Wrist", "image": "assets/injury_wrist_$suffix.png"},
      {"title": "Knee", "image": "assets/injury_knee_$suffix.png"},
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF343434),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),

            // ===== HEADER + PROGRESS (STEP 6) =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, size: 18, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [orangeLight, orangeDark]),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "SetMe FiT",
                        style: GoogleFonts.poppins(
                          fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Progress bar (Finalizing Step 6)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (i) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        width: i == 5 ? 26 : 18,
                        height: 4,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [orangeLight, orangeDark]),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ===== TITLE =====
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [orangeLight, orangeDark],
              ).createShader(bounds),
              child: Text(
                "Have you suffered any\ninjuries recently?",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 23, fontWeight: FontWeight.w700, color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 8),
            Text(
              "Select all that apply",
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
            ),

            const SizedBox(height: 32),

            // ===== 3x2 GRID =====
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GridView.builder(
                  itemCount: injuries.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.1,
                  ),
                  itemBuilder: (context, index) {
                    final bool selected = selectedInjuries.contains(index);

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (index == 0) {
                            selectedInjuries = {0}; // Selecting "None" clears others
                          } else {
                            selectedInjuries.remove(0); // Selecting an injury clears "None"
                            if (selected) {
                              selectedInjuries.remove(index);
                            } else {
                              selectedInjuries.add(index);
                            }
                          }
                          // If everything is deselected, default back to nothing
                        });
                      },
                      child: AnimatedScale(
                        scale: selected ? 1.05 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: selected
                                ? LinearGradient(colors: [orangeLight, orangeDark])
                                : null,
                            color: selected ? null : const Color(0xFFFAF3E1),
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: [
                              BoxShadow(
                                color: selected ? orangeDark.withOpacity(0.4) : Colors.black12,
                                blurRadius: 15, offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // TITLE
                              Positioned(
                                top: 16, left: 16, right: 10,
                                child: Text(
                                  injuries[index]["title"]!,
                                  style: GoogleFonts.poppins(
                                    fontSize: 15, fontWeight: FontWeight.w600,
                                    color: selected ? Colors.white : Colors.black,
                                  ),
                                ),
                              ),
                              // IMAGE
                              Positioned(
                                bottom: -10, right: -5,
                                child: SizedBox(
                                  height: 130,
                                  child: Image.asset(
                                    injuries[index]["image"]!,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // ===== CONTINUE =====
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                height: 56,
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: selectedInjuries.isEmpty ? null : () {
                    // ✅ 1. Store the final answers
                    widget.userData.selectedInjuries = selectedInjuries;

                    // ✅ 2. Navigate to the results/planning screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PlanFinalizationScreen(
                          userData: widget.userData,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    "CONTINUE",
                    style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WeightPredictionScreen extends StatefulWidget {
  final UserFitnessData userData; // Changed to accept our data object

  const WeightPredictionScreen({
    super.key,
    required this.userData,
  });

  @override
  State<WeightPredictionScreen> createState() =>
      _WeightPredictionScreenState();
}

class _WeightPredictionScreenState extends State<WeightPredictionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Calculate target date based on weeks entered in weight screen
  String get targetDateText {
    final weeks = widget.userData.weeksToTarget ?? 12;
    final date = DateTime.now().add(
      Duration(days: weeks * 7),
    );
    return "${_month(date.month)} ${date.day}";
  }

  String _month(int m) {
    const months = [
      "Jan","Feb","Mar","Apr","May","Jun",
      "Jul","Aug","Sep","Oct","Nov","Dec"
    ];
    return months[m - 1];
  }

  // Using height from userData
  double get heightCm => widget.userData.height ?? 170.0;

  double get currentBmi {
    final h = heightCm / 100;
    return (widget.userData.currentWeight ?? 70.0) / (h * h);
  }

  double get targetBmi {
    final h = heightCm / 100;
    return (widget.userData.targetWeight ?? 65.0) / (h * h);
  }

  @override
  Widget build(BuildContext context) {
    final orangeLight = Colors.orange.shade400;
    final orangeDark = Colors.orange.shade800;

    return Scaffold(
      backgroundColor: const Color(0xFF343434),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),

            // ===== HEADER =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, size: 18, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [orangeLight, orangeDark]),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Set Me FiT",
                        style: GoogleFonts.poppins(
                          fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Progress bar (Step 2/5)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        width: i == 1 ? 26 : 18,
                        height: 4,
                        decoration: BoxDecoration(
                          gradient: i <= 1 ? LinearGradient(colors: [orangeLight, orangeDark]) : null,
                          color: i <= 1 ? null : Colors.grey.shade600,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text(
              "We predict that you'll be",
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.white70),
            ),

            const SizedBox(height: 6),

            RichText(
              text: TextSpan(
                style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w700),
                children: [
                  TextSpan(
                    text: "${widget.userData.targetWeight?.round() ?? 0}kg ",
                    style: TextStyle(color: orangeLight),
                  ),
                  TextSpan(
                    text: "on $targetDateText",
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // ===== ANIMATED GRAPH =====
            LayoutBuilder(
              builder: (context, constraints) {
                return SizedBox(
                  height: 200,
                  width: constraints.maxWidth,
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      return CustomPaint(
                        size: Size(constraints.maxWidth, 200),
                        painter: AnimatedWeightCurvePainter(
                          progress: _controller.value,
                          lightColor: orangeLight,
                          darkColor: orangeDark,
                          targetDateText: targetDateText,
                        ),
                      );
                    },
                  ),
                );
              },
            ),

            const SizedBox(height: 30),

            // BMI Result Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _bmiValue(title: "Current BMI", value: currentBmi, color: Colors.white),
                  _bmiValue(title: "Target BMI", value: targetBmi, color: orangeLight),
                ],
              ),
            ),

            const SizedBox(height: 30),

            Text(
              "Excellent!",
              style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white),
            ),

            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "We’ve got a clear understanding of you and your body",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
              ),
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                height: 56,
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    // Navigate to the next screen (FocusAreaScreen) and pass data
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FocusAreaScreen(userData: widget.userData),
                      ),
                    );
                  },
                  child: ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [orangeLight, orangeDark],
                    ).createShader(bounds),
                    child: Text(
                      "CONTINUE",
                      style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bmiValue({
    required String title,
    required double value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(title, style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70)),
        const SizedBox(height: 4),
        Text(
          value.toStringAsFixed(1),
          style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: color),
        ),
      ],
    );
  }
}

// Keep your existing AnimatedWeightCurvePainter class exactly as it is below...
class AnimatedWeightCurvePainter extends CustomPainter {
  final double progress;
  final Color lightColor;
  final Color darkColor;
  final String targetDateText;

  AnimatedWeightCurvePainter({
    required this.progress,
    required this.lightColor,
    required this.darkColor,
    required this.targetDateText,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final startX = 0.0;
    final endX = size.width;

    final startY = size.height * 0.75;
    final endY = size.height * 0.35;

    // ===== CURVE =====
    final path = Path();
    path.moveTo(startX, startY);
    path.cubicTo(
      size.width * 0.3,
      startY,
      size.width * 0.6,
      endY,
      endX,
      endY,
    );

    final metric = path.computeMetrics().first;
    final drawPath =
    metric.extractPath(0, metric.length * progress);

    // ===== LINE =====
    final linePaint = Paint()
      ..shader = LinearGradient(
        colors: [lightColor, darkColor],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      )
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(drawPath, linePaint);

    // ===== FILL =====
    final fillPath = Path.from(drawPath)
      ..lineTo(endX, size.height)
      ..lineTo(startX, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          lightColor.withOpacity(0.25),
          darkColor.withOpacity(0.05),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );

    canvas.drawPath(fillPath, fillPaint);

    // ===== START DOT =====
    final startDotPaint = Paint()..color = lightColor;
    canvas.drawCircle(
      Offset(startX, startY),
      5,
      startDotPaint,
    );

    // ===== TODAY TEXT =====
    _drawText(
      canvas,
      "Today",
      Offset(startX + 2, startY + 14),
      lightColor,
    );

    // ===== END POINT =====
    if (progress > 0.95) {
      final endPoint =
          metric.getTangentForOffset(metric.length)!.position;

      // Dotted vertical line
      final dashPaint = Paint()
        ..color = darkColor.withOpacity(0.6)
        ..strokeWidth = 1;

      double y = endPoint.dy + 8;
      while (y < size.height) {
        canvas.drawLine(
          Offset(endPoint.dx, y),
          Offset(endPoint.dx, y + 6),
          dashPaint,
        );
        y += 12;
      }

      // Trophy
      final trophyPainter = TextPainter(
        text: const TextSpan(
          text: "🏆",
          style: TextStyle(fontSize: 26),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      trophyPainter.paint(
        canvas,
        endPoint.translate(-12, -36),
      );

      // Target date text
      _drawText(
        canvas,
        targetDateText,
        Offset(endPoint.dx - 20, endPoint.dy + 14),
        darkColor,
      );
    }
  }

  void _drawText(
      Canvas canvas,
      String text,
      Offset position,
      Color color,
      ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    painter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class PlanSetupScreen extends StatefulWidget {
  final UserFitnessData userData; // Changed to accept the full data object

  const PlanSetupScreen({
    super.key,
    required this.userData,
  });

  @override
  State<PlanSetupScreen> createState() => _PlanSetupScreenState();
}

class _PlanSetupScreenState extends State<PlanSetupScreen>
    with SingleTickerProviderStateMixin {
  int currentStep = 0;
  late AnimationController _cardController;

  late Animation<Offset> card1Slide;
  late Animation<Offset> card2Slide;
  late Animation<Offset> card3Slide;

  late Animation<double> glow1;
  late Animation<double> glow2;
  late Animation<double> glow3;

  @override
  void initState() {
    super.initState();
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..forward();

    card1Slide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    ));

    card2Slide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
    ));

    card3Slide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
    ));

    glow1 = Tween<double>(begin: 0, end: 18).animate(
      CurvedAnimation(parent: _cardController, curve: const Interval(0.0, 0.4)),
    );

    glow2 = Tween<double>(begin: 0, end: 18).animate(
      CurvedAnimation(parent: _cardController, curve: const Interval(0.3, 0.7)),
    );

    glow3 = Tween<double>(begin: 0, end: 18).animate(
      CurvedAnimation(parent: _cardController, curve: const Interval(0.6, 1.0)),
    );

    // Simulated step progression
    _startStepProgression();
  }

  void _startStepProgression() async {
    for (int i = 1; i <= 4; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) setState(() => currentStep = i);
    }
  }

  @override
  void dispose() {
    _cardController.dispose();
    super.dispose();
  }

  // Helper methods to display user choices in the UI
  String get focusText {
    final areas = widget.userData.focusAreas;
    if (areas == null || areas.isEmpty) return "Full Body";
    if (areas.contains(4)) return "Full Body";

    final hasUpper = areas.contains(0) || areas.contains(1);
    final hasLower = areas.contains(2) || areas.contains(3);

    if (hasUpper && hasLower) return "Full Body";
    if (hasUpper) return "Upper Body";
    if (hasLower) return "Lower Body";

    return "Full Body";
  }

  @override
  Widget build(BuildContext context) {
    final orangeLight = Colors.orange.shade400;
    final orangeDark = Colors.orange.shade800;

    return Scaffold(
      backgroundColor: const Color(0xFF343434),
      body: SafeArea(
        child: Stack(
          children: [
            // 🔥 BACKGROUND ANIMATION
            Positioned.fill(
              child: Opacity(
                opacity: 0.2, // Slightly lowered for better text readability
                child: Lottie.asset(
                  "assets/fitness_glow.json",
                  fit: BoxFit.cover,
                ),
              ),
            ),

            Column(
              children: [
                const SizedBox(height: 12),

                // ===== HEADER =====
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios, size: 18, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [orangeLight, orangeDark]),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "SetMe FiT",
                            style: GoogleFonts.poppins(
                              fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Progress bar (Step 3/5)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (i) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            width: i == 2 ? 26 : 18,
                            height: 4,
                            decoration: BoxDecoration(
                              gradient: i <= 2 ? LinearGradient(colors: [orangeLight, orangeDark]) : null,
                              color: i <= 2 ? null : Colors.grey.shade600,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // ===== TITLE =====
                Text(
                  "Setting up your fitness plan",
                  style: GoogleFonts.poppins(
                    fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white,
                  ),
                ),

                const SizedBox(height: 30),

                // ===== ANIMATED CARDS =====
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      buildAnimatedCard(
                        slide: card1Slide,
                        glow: glow1,
                        icon: Icons.psychology,
                        text: "Identifying your body type",
                      ),
                      buildAnimatedCard(
                        slide: card2Slide,
                        glow: glow2,
                        icon: Icons.flag,
                        text: "Connecting to your goals",
                      ),
                      buildAnimatedCard(
                        slide: card3Slide,
                        glow: glow3,
                        icon: Icons.auto_awesome,
                        text: "Tailoring a personalized plan",
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Progress Indicator Text
                if (currentStep >= 1 && currentStep < 4)
                  Text(
                    "Processing data...",
                    style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
                  ),

                if (currentStep >= 4)
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 500),
                    builder: (context, value, child) => Opacity(
                      opacity: value,
                      child: Text(
                        "Plan Ready for $focusText",
                        style: GoogleFonts.poppins(
                          fontSize: 18, fontWeight: FontWeight.w600, color: orangeLight,
                        ),
                      ),
                    ),
                  ),

                const Spacer(),

                // ===== CONTINUE BUTTON =====
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    height: 56, width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: currentStep >= 4
                          ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ActivityLevelScreen(userData: widget.userData),
                          ),
                        );
                      }
                          : null,
                      child: ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [orangeLight, orangeDark],
                        ).createShader(bounds),
                        child: Text(
                          "CONTINUE",
                          style: GoogleFonts.poppins(
                            fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildAnimatedCard({
    required Animation<Offset> slide,
    required Animation<double> glow,
    required IconData icon,
    required String text,
  }) {
    final orangeLight = Colors.orange.shade400;

    return SlideTransition(
      position: slide,
      child: AnimatedBuilder(
        animation: glow,
        builder: (_, __) {
          return Container(
            margin: const EdgeInsets.only(bottom: 18),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.black54,
              border: Border.all(color: orangeLight.withOpacity(0.3)),
              boxShadow: [
                if (glow.value > 0)
                  BoxShadow(
                    color: orangeLight.withOpacity(0.3),
                    blurRadius: glow.value,
                    spreadRadius: glow.value / 4,
                  )
              ],
            ),
            child: Row(
              children: [
                Icon(icon, color: orangeLight, size: 26),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    text,
                    style: GoogleFonts.poppins(
                      color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class PlanFinalizationScreen extends StatefulWidget {
  final UserFitnessData userData;

  const PlanFinalizationScreen({super.key, required this.userData});

  @override
  State<PlanFinalizationScreen> createState() => _PlanFinalizationScreenState();
}

class _PlanFinalizationScreenState extends State<PlanFinalizationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int currentStep = 0;

  void _onViewPlanPressed() {
    final focusAreaNames = ["Arms", "Abs", "Butt", "Legs", "Full Body"];
    final injuryNames = ["None", "Shoulder", "Back", "waist", "Wrist","knee"];

    final selectedAreas = widget.userData.focusAreas
        .map((index) => focusAreaNames[index])
        .toList();

    final selectedInjuries = widget.userData.selectedInjuries
        .map((index) => index < injuryNames.length ? injuryNames[index] : "Other")
        .toList();

    final Map<String, dynamic> resultsMap = {
      'goal': widget.userData.fitnessGoal ?? "General Fitness",
      'fat': widget.userData.bodyFat,
      //'current_weight': widget.userData.currentWeight ?? widget.userData.weight,
      'target_weight': widget.userData.targetWeight,
      'focus_areas': selectedAreas,
      'activity_level': widget.userData.activityIndex,
      'location': widget.userData.workoutPlace == 0 ? "Home" : "Gym",
      'injuries': selectedInjuries.isEmpty ? ["None"] : selectedInjuries,
    };

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => AIPlanQuestionnaireScreen(
          results: resultsMap,
          gender: widget.userData.gender,
          weight: widget.userData.currentWeight ?? widget.userData.weight,
          height: widget.userData.height,
          age: widget.userData.age,
        ),
      ),
    );
  }
  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..forward();

    // Sequence the loading steps
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => currentStep = 1);
    });
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => currentStep = 2);
    });
    Future.delayed(const Duration(milliseconds: 2100), () {
      if (mounted) setState(() => currentStep = 3);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ✅ FIXED: Accessing data through widget.userData
  String get intensityInsight {
    final activity = widget.userData.activityIndex ?? 1;
    switch (activity) {
      case 0:
        return "⚡ Training intensity set to Low\nGentle workouts to help you build consistency.";
      case 1:
        return "⚡ Training intensity set to Moderate\nBalanced workouts tailored to your routine.";
      case 2:
        return "⚡ Training intensity set to Active\nChallenging sessions to boost strength and stamina.";
      case 3:
        return "⚡ Training intensity set to High\nHigh-energy workouts for maximum performance.";
      default:
        return "⚡ Training intensity optimized for you.";
    }
  }

  String get environmentInsight {
    final place = widget.userData.workoutPlace ?? 0;
    switch (place) {
      case 0:
        return "🏠 Workout environment: Home\nBodyweight and space-friendly workouts included.";
      case 1:
        return "🏋️ Workout environment: Gym\nEquipment-based workouts unlocked.";
      case 2:
        return "🏠🏋️ Flexible workout environment\nTrain seamlessly at home or in the gym.";
      default:
        return "🏠 Workout environment optimized for you.";
    }
  }

  String get safetyInsight {
    final injuries = widget.userData.selectedInjuries ?? {};
    if (injuries.isEmpty || injuries.contains(0)) {
      return "🛡️ No injury restrictions\nFull exercise range enabled for faster progress.";
    }
    if (injuries.length == 1) {
      return "🛡️ Safety adjustments applied\nExercises modified to protect selected areas.";
    }
    return "🛡️ Advanced safety adjustments applied\nYour plan avoids strain on sensitive areas.";
  }

  Widget buildStep(String text, int step) {
    return AnimatedOpacity(
      opacity: currentStep >= step ? 1 : 0,
      duration: const Duration(milliseconds: 400),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentStep > step ? "✅" : "⏳",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orangeLight = Colors.orange.shade400;
    final orangeDark = Colors.orange.shade800;

    return Scaffold(
      backgroundColor: const Color(0xFF343434),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 12),
                // ===== HEADER =====
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios, size: 18, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        "SetMe FiT",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Progress bar (Final Step)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (i) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            width: i == 4 ? 26 : 18,
                            height: 4,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [orangeLight, orangeDark]),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                Text(
                  "Finalizing your training plan",
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 40),

                // ===== CIRCULAR VISUAL =====
                SizedBox(
                  height: 180,
                  width: 180,
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (_, __) {
                      return CustomPaint(
                        painter: _RingPainter(_controller.value),
                        child: Center(
                          child: Text(
                            "${(_controller.value * 100).toInt()}%",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 40),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      buildStep(intensityInsight, 1),
                      buildStep(environmentInsight, 2),
                      buildStep(safetyInsight, 3),
                    ],
                  ),
                ),

                const Spacer(),

                // ===== VIEW PLAN BUTTON =====
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    height: 56,
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: currentStep >= 3 ? _onViewPlanPressed : null,
                      child: ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [orangeLight, orangeDark],
                        ).createShader(bounds),
                        child: Text(
                          "VIEW PLAN",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;

  _RingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = 68.0;
    final stroke = 14.0;

    final baseAngle = -1.57; // top
    final gap = 0.22;

    final segments = [
      _RingSegment(
        color: Colors.greenAccent,
        icon: "⚡",
        label: "Intensity",
        start: baseAngle,
      ),
      _RingSegment(
        color: Colors.orangeAccent,
        icon: "🏠",
        label: "Environment",
        start: baseAngle + 1.8 + gap,
      ),
      _RingSegment(
        color: Colors.lightBlueAccent,
        icon: "🛡️",
        label: "Safety",
        start: baseAngle + 3.6 + gap * 2,
      ),
    ];

    for (int i = 0; i < segments.length; i++) {
      final isVisible = progress >= (i + 1) / segments.length;
      if (!isVisible) continue;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(
          colors: [
            segments[i].color.withOpacity(0.6),
            segments[i].color,
          ],
        ).createShader(
          Rect.fromCircle(center: center, radius: radius),
        );

      // Glow
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        segments[i].start,
        1.4,
        false,
        paint..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );

      // Main arc
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        segments[i].start,
        1.4,
        false,
        paint..maskFilter = null,
      );

      // Label
      _drawLabel(
        canvas,
        center,
        radius + 26,
        segments[i],
      );
    }

    // Center check
    if (progress > 0.95) {
      final tp = TextPainter(
        text: const TextSpan(
          text: "✔",
          style: TextStyle(
            fontSize: 42,
            color: Colors.orangeAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(
        canvas,
        Offset(
          center.dx - tp.width / 2,
          center.dy - tp.height / 2,
        ),
      );
    }
  }

  void _drawLabel(
      Canvas canvas,
      Offset center,
      double distance,
      _RingSegment segment,
      ) {
    final angle = segment.start + 0.7;
    final position = Offset(
      center.dx + distance * cos(angle),
      center.dy + distance * sin(angle),
    );

    final painter = TextPainter(
      text: TextSpan(
        text: "${segment.icon} ${segment.label}",
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white70,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    painter.paint(
      canvas,
      position.translate(-painter.width / 2, -painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _RingSegment {
  final Color color;
  final String icon;
  final String label;
  final double start;

  _RingSegment({
    required this.color,
    required this.icon,
    required this.label,
    required this.start,
  });
}
class CelebrationPopups extends StatefulWidget {
  const CelebrationPopups({super.key});

  @override
  State<CelebrationPopups> createState() => _CelebrationPopupsState();
}

class _CelebrationPopupsState extends State<CelebrationPopups>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late double centerX; // ✅ stored safely

  final emojis = ["🎉", "💪", "🔥", "🏆"];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ✅ SAFE place to read MediaQuery
    centerX = MediaQuery.of(context).size.width / 2;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          return Stack(
            children: List.generate(emojis.length, (i) {
              final progress = _controller.value;
              final offsetX = (i - 1.5) * 40;
              final offsetY = -progress * 120;

              return Positioned(
                left: centerX + offsetX,
                bottom: 160 + offsetY,
                child: Opacity(
                  opacity: 1 - progress,
                  child: Transform.scale(
                    scale: 0.6 + progress,
                    child: Text(
                      emojis[i],
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
