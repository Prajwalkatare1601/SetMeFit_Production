import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'calculator_logic.dart';


// ======================== PREMIUM SHARED WIDGETS ========================

Widget premiumField(TextEditingController controller, String label,
    {TextInputType keyboardType = TextInputType.number}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(fontSize: 18, color: Colors.white),
      onTap: () {
        // Clear the field when user taps on it
        if (controller.text.isNotEmpty) {
          controller.clear();
        }
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.6), width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      ),
    ),
  );
}

Widget premiumButton(String text, VoidCallback onPressed) {
  return Container(
    width: double.infinity,
    height: 60,
    margin: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(30),
      gradient: const LinearGradient(
        colors: [Color(0xFFFF9A9E), Color(0xFFFAD0C4), Color(0xFFFF9A9E)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.pinkAccent.withOpacity(0.5),
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ],
    ),
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          shadows: const [Shadow(color: Colors.black26, blurRadius: 4)],
        ),
      ),
    ),
  );
}

Widget premiumResult(String value, String remark) {
  return AnimatedSwitcher(
    duration: const Duration(milliseconds: 600),
    transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
    child: Container(
      key: ValueKey(value),
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.35),  // Brighter top
            Colors.white.withOpacity(0.1),   // Slightly darker bottom for depth
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.5),  // Stronger border for definition
          width: 1.5,
        ),
        boxShadow: [
          // Inner glow
          BoxShadow(
            color: Colors.white.withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 0),
          ),
          // Deep outer shadow for floating effect
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 40,
            spreadRadius: 5,
            offset: const Offset(0, 10),
          ),
          // Subtle bottom highlight
          BoxShadow(
            color: Colors.white.withOpacity(0.25),
            blurRadius: 30,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 42,
              fontWeight: FontWeight.w800,  // Bolder for impact
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.5),
                  offset: const Offset(0, 2),
                  blurRadius: 8,
                ),
                Shadow(
                  color: Colors.white.withOpacity(0.6),
                  offset: const Offset(0, -1),
                  blurRadius: 4,
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            remark,
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.95),  // Brighter, clearer
              height: 1.4,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.4),
                  offset: const Offset(0, 1),
                  blurRadius: 4,
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

// ======================== HOME PAGE ========================

class CalculatorHome extends StatefulWidget {
  const CalculatorHome({super.key});

  @override
  State<CalculatorHome> createState() => _CalculatorHomeState();
}

class _CalculatorHomeState extends State<CalculatorHome> with TickerProviderStateMixin {
  late AnimationController _glowController;
  int selectedTab = 0; // 0: Health & Fitness, 1: Everyday Magic

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Removed the Scaffold here — we use the one from MainPage
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6E48AA), Color(0xFF9D50BB), Color(0xFF667EEA), Color(0xFFF093FB)],
          stops: [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: Stack(
        children: [
          ...List.generate(12, (index) => _FloatingParticle(index: index)),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
                  child: Row(
                    children: [
                      AnimatedBuilder(
                        animation: _glowController,
                        builder: (context, child) {
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.pinkAccent.withOpacity(0.4 + 0.2 * _glowController.value),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.calculate, size: 32, color: Colors.white),
                          );
                        },
                      ),
                      const SizedBox(width: 16),
                      Text(
                        "Zealculators",
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: const [Shadow(color: Colors.black26, blurRadius: 8)],
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  "Pick your vibe & crunch numbers ✨",
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.white70),
                ),

                const SizedBox(height: 30),

                // Toggle Tabs
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => selectedTab = 0),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              decoration: BoxDecoration(
                                color: selectedTab == 0 ? Colors.white.withOpacity(0.3) : Colors.transparent,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Center(
                                child: Text(
                                  "🌿 Health & Fitness",
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => selectedTab = 1),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              decoration: BoxDecoration(
                                color: selectedTab == 1 ? Colors.white.withOpacity(0.3) : Colors.transparent,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Center(
                                child: Text(
                                  "🎉 Common ",
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
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

                const SizedBox(height: 30),

                // Content based on selected tab
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                    child: selectedTab == 0
                        ? ListView(
                      key: const ValueKey(0),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      // Added bottom padding to avoid overlap with BottomNavigationBar
                      children: [
                        ..._healthTiles,
                        const SizedBox(height: 100), // Extra space at bottom
                      ],
                    )
                        : ListView(
                      key: const ValueKey(1),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        ..._everydayTiles,
                        const SizedBox(height: 100), // Extra space at bottom
                      ],
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

  List<Widget> get _healthTiles => [
    _GlowyTile(title: "BMI Calculator", emoji: "⚖️", gradient: const LinearGradient(colors: [Color(0xFFFF9A9E), Color(0xFFFAD0C4)]), page: const BMICalc()),
    _GlowyTile(title: "Daily Calorie Needs", emoji: "🔥", gradient: const LinearGradient(colors: [Color(0xFFFFE259), Color(0xFFFFA751)]), page: const CalorieCalc()),
    _GlowyTile(title: "Body Fat %", emoji: "📏", gradient: const LinearGradient(colors: [Color(0xFFA18CD1), Color(0xFFFBC2EB)]), page: const BodyFatCalc()),
    _GlowyTile(title: "BMR Calculator", emoji: "⚡", gradient: const LinearGradient(colors: [Color(0xFF84FAB0), Color(0xFF8FD3F4)]), page: const BMRCalc()),
    _GlowyTile(title: "Target Weight ", emoji: "🎯", gradient: const LinearGradient(colors: [Color(0xFF89F7FE), Color(0xFF66A6FF)]), page: const IdealWeightCalc()),
    _GlowyTile(title: "Running Pace", emoji: "🏃", gradient: const LinearGradient(colors: [Color(0xFFFFECD2), Color(0xFFFCB69F)]), page: const PaceCalc()),
    _GlowyTile(title: "Pregnancy Due Date", emoji: "👶", gradient: const LinearGradient(colors: [Color(0xFFFFC3A0), Color(0xFFFFAFBD)]), page: const PregnancyCalc()),
    _GlowyTile(title: "Sleep Quality", emoji: "💤", gradient: const LinearGradient(colors: [Color(0xFF2E3192), Color(0xFF1BFFFF)]), page: const SleepCalc()),
    const SizedBox(height: 40),
  ];

  List<Widget> get _everydayTiles => [
    _GlowyTile(title: "GPA Calculator", emoji: "🎓", gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]), page: const GPACalc()),
    _GlowyTile(title: "Grade from %", emoji: "📊", gradient: const LinearGradient(colors: [Color(0xFFF093FB), Color(0xFFF5576C)]), page: const GradeCalc()),
    _GlowyTile(title: "Bra Size Finder", emoji: "👙", gradient: const LinearGradient(colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)]), page: const BraCalc()),
    _GlowyTile(title: "Shoe Size Converter", emoji: "👟", gradient: const LinearGradient(colors: [Color(0xFF43E97B), Color(0xFF38F9D7)]), page: const ShoeCalc()),
    _GlowyTile(title: "Tip Calculator", emoji: "💸", gradient: const LinearGradient(colors: [Color(0xFFFA709A), Color(0xFFFEE140)]), page: const TipCalc()),
    _GlowyTile(title: "Golf Handicap", emoji: "⛳", gradient: const LinearGradient(colors: [Color(0xFF56AB2F), Color(0xFFA8E063)]), page: const GolfCalc()),
    const SizedBox(height: 40),
  ];
}


class _GlowyTile extends StatefulWidget {
  final String title;
  final String emoji;
  final Gradient gradient;
  final Widget page;

  const _GlowyTile({
    required this.title,
    required this.emoji,
    required this.gradient,
    required this.page,
  });

  @override
  State<_GlowyTile> createState() => _GlowyTileState();
}

class _GlowyTileState extends State<_GlowyTile> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isTapped = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isTapped = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isTapped = false);
        _controller.reverse();
        Navigator.push(context, _createRoute(widget.page));
      },
      onTapCancel: () {
        setState(() => _isTapped = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 - 0.05 * _controller.value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              height: 90,
              decoration: BoxDecoration(
                gradient: widget.gradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: (_isTapped ? widget.gradient.colors.last : widget.gradient.colors.first).withOpacity(0.6),
                    blurRadius: 20 + 10 * _controller.value,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -30,
                    top: -30,
                    child: Opacity(
                      opacity: 0.3,
                      child: Text(widget.emoji, style: const TextStyle(fontSize: 120)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Text(widget.emoji, style: const TextStyle(fontSize: 40)),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Text(
                            widget.title,
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              shadows: const [Shadow(color: Colors.black26, blurRadius: 4)],
                            ),
                          ),
                        ),
                        Transform.translate(
                          offset: Offset(10 * _controller.value, 0),
                          child: const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 28),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

Route _createRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: ScaleTransition(scale: animation, child: child));
    },
    transitionDuration: const Duration(milliseconds: 600),
  );
}

class _FloatingParticle extends StatefulWidget {
  final int index;
  const _FloatingParticle({required this.index});

  @override
  State<_FloatingParticle> createState() => _FloatingParticleState();
}

class _FloatingParticleState extends State<_FloatingParticle> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Duration(seconds: 15 + widget.index * 2))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = 8.0 + (widget.index % 5) * 4;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: (widget.index * 37) % MediaQuery.of(context).size.width,
          top: _controller.value * MediaQuery.of(context).size.height,
          child: Opacity(
            opacity: 0.3,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.6),
                boxShadow: [
                  BoxShadow(color: Colors.white.withOpacity(0.4), blurRadius: 10),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ======================== ALL CALCULATOR PAGES  ========================

// BMI Calculator
class BMICalc extends StatefulWidget { const BMICalc({super.key}); @override State<BMICalc> createState() => _BMICalcState(); }
class _BMICalcState extends State<BMICalc> {
  final w = TextEditingController(), h = TextEditingController();
  String? res;

  @override
  Widget build(BuildContext context) => Scaffold(
    extendBodyBehindAppBar: true,
    appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, foregroundColor: Colors.white, title: const Text("BMI Calculator")),
    body: Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFF9A9E), Color(0xFFFAD0C4)]),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              Text("Body Mass Index ⚖️", style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 16),
              Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(16)), child: Text("Body Mass Index (BMI) is a simple calculation using a person's height and weight. It helps screen for weight categories that may lead to health problems.", style: GoogleFonts.poppins(fontSize: 16, color: Colors.white), textAlign: TextAlign.center)),
              const SizedBox(height: 40),
              premiumField(w, "Weight (kg)"),
              premiumField(h, "Height (cm)"),
              premiumButton("Calculate BMI", () { try { final bmiValue = bmi(double.parse(w.text), double.parse(h.text)); setState(() => res = bmiValue.toStringAsFixed(1)); } catch (e) {} }),
              if (res != null) premiumResult(res!, "Stay healthy & strong 🌱"),
              const SizedBox(height: 60),
            ]),
          ),
        ),
      ],
    ),
  );
}

// Calorie Calculator
class CalorieCalc extends StatefulWidget { const CalorieCalc({super.key}); @override State<CalorieCalc> createState() => _CalorieCalcState(); }
class _CalorieCalcState extends State<CalorieCalc> {
  final w = TextEditingController(), h = TextEditingController(), a = TextEditingController();
  bool male = true;
  String selectedActivity = activityMultipliers.keys.first;
  String? r;

  @override
  Widget build(BuildContext context) => Scaffold(
    extendBodyBehindAppBar: true,
    appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, foregroundColor: Colors.white),
    body: Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFE259), Color(0xFFFFA751)]),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              Text("Daily Calorie Needs 🔥", style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 16),
              Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(16)), child: Text("Calculate how many calories you need daily to maintain, lose, or gain weight based on your age, gender, activity level, and basal metabolism.", style: GoogleFonts.poppins(fontSize: 16, color: Colors.white), textAlign: TextAlign.center)),
              const SizedBox(height: 40),
              premiumField(w, "Weight (kg)"),
              premiumField(h, "Height (cm)"),
              premiumField(a, "Age"),
              SwitchListTile(title: Text("Male", style: GoogleFonts.poppins(color: Colors.white, fontSize: 18)), value: male, activeColor: Colors.pinkAccent, onChanged: (v) => setState(() => male = v)),
              Container(padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)), child: DropdownButton<String>(value: selectedActivity, isExpanded: true, underline: const SizedBox(), dropdownColor: Colors.orange.withOpacity(0.9), style: GoogleFonts.poppins(color: Colors.white, fontSize: 16), icon: const Icon(Icons.arrow_drop_down, color: Colors.white), items: activityMultipliers.keys.map((key) => DropdownMenuItem(value: key, child: Text(key))).toList(), onChanged: (v) => setState(() => selectedActivity = v!))),
              const SizedBox(height: 20),
              premiumButton("Calculate", () { try { final baseBMR = bmr(double.parse(w.text), double.parse(h.text), int.parse(a.text), male); final multiplier = activityMultipliers[selectedActivity]!; final daily = (baseBMR * multiplier).round(); setState(() => r = "$daily kcal/day"); } catch (e) {} }),
              if (r != null) premiumResult(r!, "Fuel your body smart 🔥"),
              const SizedBox(height: 60),
            ]),
          ),
        ),
      ],
    ),
  );
}

// Body Fat Calculator
class BodyFatCalc extends StatefulWidget { const BodyFatCalc({super.key}); @override State<BodyFatCalc> createState() => _BodyFatCalcState(); }
class _BodyFatCalcState extends State<BodyFatCalc> {
  final waist = TextEditingController(), neck = TextEditingController(), height = TextEditingController(), hip = TextEditingController();
  bool male = true;
  String? r;

  @override
  Widget build(BuildContext context) => Scaffold(
    extendBodyBehindAppBar: true,
    appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, foregroundColor: Colors.white),
    body: Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFA18CD1), Color(0xFFFBC2EB)]),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              Text("Body Fat Percentage 📏", style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 16),
              Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(16)), child: Text("Estimate body fat using the U.S. Navy method. Requires waist, neck, height, and hip measurements for females.", style: GoogleFonts.poppins(fontSize: 16, color: Colors.white), textAlign: TextAlign.center)),
              const SizedBox(height: 40),
              premiumField(waist, "Waist (cm)"),
              premiumField(neck, "Neck (cm)"),
              premiumField(height, "Height (cm)"),
              if (!male) premiumField(hip, "Hip (cm)"),
              SwitchListTile(title: Text("Male", style: GoogleFonts.poppins(color: Colors.white, fontSize: 18)), value: male, activeColor: Colors.pinkAccent, onChanged: (v) => setState(() => male = v)),
              premiumButton("Calculate", () { try { final bf = bodyFat(double.parse(waist.text), double.parse(neck.text), double.parse(height.text), male, male ? null : double.parse(hip.text)); setState(() => r = "${bf.toStringAsFixed(1)}%"); } catch (e) {} }),
              if (r != null) premiumResult(r!, "Every % tells a story 📊"),
              const SizedBox(height: 60),
            ]),
          ),
        ),
      ],
    ),
  );
}

// BMR Calculator
class BMRCalc extends StatefulWidget { const BMRCalc({super.key}); @override State<BMRCalc> createState() => _BMRCalcState(); }
class _BMRCalcState extends State<BMRCalc> {
  final w = TextEditingController(), h = TextEditingController(), a = TextEditingController();
  bool male = true;
  String? res;

  @override
  Widget build(BuildContext context) => Scaffold(
    extendBodyBehindAppBar: true,
    appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, foregroundColor: Colors.white),
    body: Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF84FAB0), Color(0xFF8FD3F4)]),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              Text("Basal Metabolic Rate ⚡", style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 16),
              Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(16)), child: Text("BMR is the number of calories your body burns at rest to maintain basic functions like breathing and circulation.", style: GoogleFonts.poppins(fontSize: 16, color: Colors.white), textAlign: TextAlign.center)),
              const SizedBox(height: 40),
              premiumField(w, "Weight (kg)"),
              premiumField(h, "Height (cm)"),
              premiumField(a, "Age"),
              SwitchListTile(title: Text("Male", style: GoogleFonts.poppins(color: Colors.white, fontSize: 18)), value: male, activeColor: Colors.pinkAccent, onChanged: (v) => setState(() => male = v)),
              premiumButton("Calculate BMR", () { try { final v = bmr(double.parse(w.text), double.parse(h.text), int.parse(a.text), male); setState(() => res = "${v.toStringAsFixed(0)} kcal/day"); } catch (e) {} }),
              if (res != null) premiumResult(res!, "Your body's silent engine 🔥"),
              const SizedBox(height: 60),
            ]),
          ),
        ),
      ],
    ),
  );
}

// Ideal Weight Calculator
class IdealWeightCalc extends StatefulWidget { const IdealWeightCalc({super.key}); @override State<IdealWeightCalc> createState() => _IdealWeightCalcState(); }
class _IdealWeightCalcState extends State<IdealWeightCalc> {
  final h = TextEditingController();
  bool male = true;
  String? res;

  @override
  Widget build(BuildContext context) => Scaffold(
    extendBodyBehindAppBar: true,
    appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, foregroundColor: Colors.white),
    body: Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF89F7FE), Color(0xFF66A6FF)]),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              Text("Target Weight Range 🎯", style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 16),
              Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(16)), child: Text("Estimate your ideal body weight using the Devine formula, a widely used method in medical settings.", style: GoogleFonts.poppins(fontSize: 16, color: Colors.white), textAlign: TextAlign.center)),
              const SizedBox(height: 40),
              premiumField(h, "Height (cm)"),
              SwitchListTile(title: Text("Male", style: GoogleFonts.poppins(color: Colors.white, fontSize: 18)), value: male, activeColor: Colors.pinkAccent, onChanged: (v) => setState(() => male = v)),
              premiumButton("Calculate", () { try { final v = idealWeight(double.parse(h.text), male); setState(() => res = "${v.toStringAsFixed(1)} kg"); } catch (e) {} }),
              if (res != null) premiumResult(res!, "Healthy looks different on everyone 🌱"),
              const SizedBox(height: 60),
            ]),
          ),
        ),
      ],
    ),
  );
}

// Running Pace Calculator
enum CalcMode { pace, time, distance }

class PaceCalc extends StatefulWidget {
  const PaceCalc({super.key});

  @override
  State<PaceCalc> createState() => _PaceCalcState();
}

class _PaceCalcState extends State<PaceCalc> {
  final TextEditingController field1 = TextEditingController();
  final TextEditingController field2 = TextEditingController();

  CalcMode mode = CalcMode.pace;
  String? result;

  // ==================== CALCULATION LOGIC (Separated clearly) ====================

  double calculatePace(double distanceKm, double timeMin) {
    if (distanceKm <= 0) throw Exception("Distance must be greater than 0");
    return timeMin / distanceKm;
  }

  double calculateTime(double distanceKm, double paceMinPerKm) {
    if (paceMinPerKm <= 0) throw Exception("Pace must be greater than 0");
    return paceMinPerKm * distanceKm;
  }

  double calculateDistance(double timeMin, double paceMinPerKm) {
    if (paceMinPerKm <= 0) throw Exception("Pace must be greater than 0");
    return timeMin / paceMinPerKm;
  }

  String getResultString(double value, CalcMode mode) {
    switch (mode) {
      case CalcMode.pace:
        return "${value.toStringAsFixed(2)} min/km";
      case CalcMode.time:
        return "${value.toStringAsFixed(1)} minutes";
      case CalcMode.distance:
        return "${value.toStringAsFixed(2)} km";
    }
  }

  void calculate() {
    if (field1.text.isEmpty || field2.text.isEmpty) {
      setState(() => result = "Please enter both values");
      return;
    }

    try {
      double val1 = double.parse(field1.text);
      double val2 = double.parse(field2.text);

      double calculatedValue;

      switch (mode) {
        case CalcMode.pace:
          calculatedValue = calculatePace(val1, val2); // distance, time
          break;
        case CalcMode.time:
          calculatedValue = calculateTime(val1, val2); // distance, pace
          break;
        case CalcMode.distance:
          calculatedValue = calculateDistance(val1, val2); // time, pace
          break;
      }

      setState(() {
        result = getResultString(calculatedValue, mode);
      });
    } catch (e) {
      setState(() {
        result = "Invalid input";
      });
    }
  }

  // ==================== UI HELPERS ====================

  String getTitle() {
    return switch (mode) {
      CalcMode.pace => "Running Pace 🏃",
      CalcMode.time => "Predicted Time ⏱️",
      CalcMode.distance => "Distance Covered 🛣️",
    };
  }

  String getDescription() {
    return switch (mode) {
      CalcMode.pace =>
      "Calculate your pace in minutes per kilometer based on distance and time.",
      CalcMode.time =>
      "Calculate how long it will take to run a distance at a given pace.",
      CalcMode.distance =>
      "Calculate how far you can run in a given time at your target pace.",
    };
  }

  String getLabel1() {
    return switch (mode) {
      CalcMode.pace => "Distance (km)",
      CalcMode.time => "Distance (km)",
      CalcMode.distance => "Time (minutes)",
    };
  }

  String getLabel2() {
    return switch (mode) {
      CalcMode.pace => "Time (minutes)",
      CalcMode.time => "Pace (min/km)",
      CalcMode.distance => "Pace (min/km)",
    };
  }

  String getMotivation() {
    return switch (mode) {
      CalcMode.pace => "Consistency beats speed 🏃",
      CalcMode.time => "Plan your race, own your pace ⏱️",
      CalcMode.distance => "Every kilometer counts 🛣️",
    };
  }

  IconData getIcon() {
    return switch (mode) {
      CalcMode.pace => Icons.speed,
      CalcMode.time => Icons.timer,
      CalcMode.distance => Icons.straighten,
    };
  }

  void switchMode(CalcMode? newMode) {
    if (newMode != null) {
      setState(() {
        mode = newMode;
        result = null;
        field1.clear();
        field2.clear();
      });
    }
  }

  // ==================== BUILD UI ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFECD2), Color(0xFFFCB69F)],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    getTitle(),
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      getDescription(),
                      style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Mode Selector (Radio Buttons)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        RadioListTile<CalcMode>(
                          title: Text("Calculate Pace", style: GoogleFonts.poppins(color: Colors.white)),
                          secondary: const Icon(Icons.speed, color: Colors.white70),
                          value: CalcMode.pace,
                          groupValue: mode,
                          onChanged: switchMode,
                          activeColor: Colors.white,
                        ),
                        RadioListTile<CalcMode>(
                          title: Text("Calculate Time", style: GoogleFonts.poppins(color: Colors.white)),
                          secondary: const Icon(Icons.timer, color: Colors.white70),
                          value: CalcMode.time,
                          groupValue: mode,
                          onChanged: switchMode,
                          activeColor: Colors.white,
                        ),
                        RadioListTile<CalcMode>(
                          title: Text("Calculate Distance", style: GoogleFonts.poppins(color: Colors.white)),
                          secondary: const Icon(Icons.straighten, color: Colors.white70),
                          value: CalcMode.distance,
                          groupValue: mode,
                          onChanged: switchMode,
                          activeColor: Colors.white,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Input Fields
                  TextField(
                    controller: field1,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 18),
                    decoration: InputDecoration(
                      labelText: getLabel1(),
                      labelStyle: GoogleFonts.poppins(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.15),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: field2,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 18),
                    decoration: InputDecoration(
                      labelText: getLabel2(),
                      labelStyle: GoogleFonts.poppins(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.15),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Calculate Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: calculate,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        backgroundColor: Colors.white.withOpacity(0.3),
                      ),
                      child: Text(
                        "Calculate",
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),

                  // Result Card
                  if (result != null) ...[
                    const SizedBox(height: 32),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Icon(getIcon(), size: 40, color: Colors.white),
                          const SizedBox(height: 12),
                          Text("Result", style: GoogleFonts.poppins(fontSize: 16, color: Colors.white70)),
                          const SizedBox(height: 8),
                          Text(
                            result!,
                            style: GoogleFonts.poppins(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            getMotivation(),
                            style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    field1.dispose();
    field2.dispose();
    super.dispose();
  }
}

// Pregnancy Due Date Calculator
class PregnancyCalc extends StatefulWidget { const PregnancyCalc({super.key}); @override State<PregnancyCalc> createState() => _PregnancyCalcState(); }
class _PregnancyCalcState extends State<PregnancyCalc> {
  int selectedMethod = 0;
  DateTime? selectedDate;
  int embryoDay = 5;
  final weeksController = TextEditingController();
  final daysController = TextEditingController();
  String? resultText;

  @override
  void initState() { super.initState(); weeksController.addListener(_updateFromGA); daysController.addListener(_updateFromGA); }

  @override
  void dispose() { weeksController.dispose(); daysController.dispose(); super.dispose(); }

  void _updateFromGA() { if (selectedMethod == 3 && selectedDate != null) updateResult(); }

  DateTime calculateDueDate() {
    if (selectedDate == null) return DateTime.now();
    switch (selectedMethod) {
      case 0: return dueDate(selectedDate!);
      case 1: return selectedDate!.add(const Duration(days: 266));
      case 2: return selectedDate!.add(Duration(days: embryoDay == 3 ? 263 : 261));
      case 3: final weeks = int.tryParse(weeksController.text) ?? 0; final days = int.tryParse(daysController.text) ?? 0; final currentDays = weeks * 7 + days; return selectedDate!.add(Duration(days: 280 - currentDays));
      default: return DateTime.now();
    }
  }

  DateTime estimateConception() {
    if (selectedMethod == 0 && selectedDate != null) return conception(selectedDate!);
    return calculateDueDate().subtract(const Duration(days: 266));
  }

  void updateResult() {
    if (selectedMethod != 3 && selectedDate == null) { setState(() => resultText = null); return; }
    if (selectedMethod == 3) { final weeks = int.tryParse(weeksController.text) ?? 0; final days = int.tryParse(daysController.text) ?? 0; if (weeks == 0 && days == 0) { setState(() => resultText = null); return; } }
    final due = calculateDueDate();
    final con = estimateConception();
    setState(() { resultText = "Estimated Due Date:\n${due.day}/${due.month}/${due.year}\n\nConception around:\n${con.day}/${con.month}/${con.year}"; });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    extendBodyBehindAppBar: true,
    appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, foregroundColor: Colors.white, title: const Text("Due Date Calculator")),
    body: Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFC3A0), Color(0xFFFFAFBD)]),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              Text("Pregnancy Due Date 👶", style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 16),
              Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(16)), child: Text("Accurately estimate your baby's due date using LMP, conception date, IVF transfer day, or ultrasound gestational age.", style: GoogleFonts.poppins(fontSize: 16, color: Colors.white), textAlign: TextAlign.center)),
              const SizedBox(height: 40),
              Container(padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)), child: DropdownButton<int>(value: selectedMethod, isExpanded: true, underline: const SizedBox(), dropdownColor: Colors.pinkAccent.withOpacity(0.9), style: GoogleFonts.poppins(color: Colors.white, fontSize: 18), icon: const Icon(Icons.arrow_drop_down, color: Colors.white), items: const [DropdownMenuItem(value: 0, child: Text("Last Menstrual Period (LMP)")), DropdownMenuItem(value: 1, child: Text("Conception Date")), DropdownMenuItem(value: 2, child: Text("IVF Embryo Transfer")), DropdownMenuItem(value: 3, child: Text("Ultrasound Scan Date"))], onChanged: (v) => setState(() { selectedMethod = v!; resultText = null; }))),
              const SizedBox(height: 30),
              if (selectedMethod == 2) Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text("Embryo Age: ", style: GoogleFonts.poppins(color: Colors.white, fontSize: 18)), ToggleButtons(isSelected: [embryoDay == 3, embryoDay == 5], onPressed: (i) => setState(() => embryoDay = i == 0 ? 3 : 5), color: Colors.white, selectedColor: Colors.white, fillColor: Colors.pinkAccent.withOpacity(0.6), borderRadius: BorderRadius.circular(20), children: const [Padding(padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12), child: Text("Day 3")), Padding(padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12), child: Text("Day 5"))])]),
              if (selectedMethod == 3) Row(children: [Expanded(child: premiumField(weeksController, "Weeks", keyboardType: TextInputType.number)), const SizedBox(width: 16), Expanded(child: premiumField(daysController, "Days (0-6)", keyboardType: TextInputType.number))]),
              const SizedBox(height: 30),
              premiumButton(selectedMethod == 3 ? "Select Ultrasound Scan Date" : "Select Date", () async { final d = await showDatePicker(context: context, initialDate: selectedDate ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 300))); if (d != null) { setState(() => selectedDate = d); updateResult(); } }),
              const SizedBox(height: 30),
              if (resultText != null) premiumResult(resultText!, "A beautiful journey begins ✨") else Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(24)), child: Text(selectedMethod == 3 ? "Enter gestational age and scan date" : "Select a method and date", style: GoogleFonts.poppins(fontSize: 16, color: Colors.white70), textAlign: TextAlign.center)),
              const SizedBox(height: 60),
            ]),
          ),
        ),
      ],
    ),
  );
}

// GPA Calculator

class GPACalc extends StatefulWidget {
  const GPACalc({super.key});

  @override
  State<GPACalc> createState() => _GPACalcState();
}

class _GPACalcState extends State<GPACalc> {
  final List<String?> grades = ['A', 'A', 'A'];
  final List<TextEditingController> credits = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];

  String? res;

  // Calculator.net standard grade scale
  static const Map<String, double> letterToPoint = {
    'A+': 4.3,'A': 4.0, 'A-': 3.7,
    'B+': 3.3, 'B': 3.0, 'B-': 2.7,
    'C+': 2.3, 'C': 2.0, 'C-': 1.7,
    'D+': 1.3, 'D': 1.0,
    'F': 0.0,
  };

  double calculateGPA() {
    double totalPoints = 0;
    double totalCredits = 0;

    for (int i = 0; i < grades.length; i++) {
      final letter = grades[i];
      if (letter == null || !letterToPoint.containsKey(letter)) continue;

      final gradePoint = letterToPoint[letter]!;

      final credit =
      credits[i].text.isEmpty ? 1.0 : double.tryParse(credits[i].text) ?? 1;

      totalPoints += gradePoint * credit;
      totalCredits += credit;
    }

    return totalCredits == 0 ? 0 : totalPoints / totalCredits;
  }

  @override
  void dispose() {
    for (final c in credits) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    extendBodyBehindAppBar: true,
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: Colors.white,
    ),
    body: Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            ),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  "GPA Calculator 🎓",
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    "Select letter grades and enter credits. GPA is calculated using the official weighted formula.",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 32),

                for (int i = 0; i < grades.length; i++)
                  _courseRow(i),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: premiumButton("Add Course", () {
                    setState(() {
                      grades.add('A');
                      credits.add(TextEditingController());
                    });
                  }),
                ),

                const SizedBox(height: 24),

                premiumButton("Calculate GPA", () {
                  final gpa = calculateGPA();
                  setState(() => res = gpa.toStringAsFixed(2));
                }),

                if (res != null)
                  premiumResult(
                    "$res GPA", "Brains + effort = results 🎓",
                  ),

                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _courseRow(int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              value: grades[index],
              items: letterToPoint.keys
                  .map(
                    (g) => DropdownMenuItem(
                  value: g,
                  child: Text(g),
                ),
              )
                  .toList(),
              onChanged: (v) => setState(() => grades[index] = v),
              decoration: InputDecoration(
                labelText: "Course ${index + 1} Grade",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: premiumField(
              credits[index],
              "Credits",
            ),
          ),
          const SizedBox(width: 8),
          if (grades.length > 1)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                setState(() {
                  grades.removeAt(index);
                  credits.removeAt(index);
                });
              },
            ),
        ],
      ),
    );
  }
}

// Grade from Percentage
class GradeCalc extends StatefulWidget { const GradeCalc({super.key}); @override State<GradeCalc> createState() => _GradeCalcState(); }
class _GradeCalcState extends State<GradeCalc> {
  final p = TextEditingController();
  String? res;

  @override
  Widget build(BuildContext context) => Scaffold(
    extendBodyBehindAppBar: true,
    appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, foregroundColor: Colors.white),
    body: Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF093FB), Color(0xFFF5576C)]),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              Text("Percentage to Grade 📊", style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 16),
              Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(16)), child: Text("Convert a percentage score to a letter grade (A–F scale).", style: GoogleFonts.poppins(fontSize: 16, color: Colors.white), textAlign: TextAlign.center)),
              const SizedBox(height: 40),
              premiumField(p, "Percentage"),
              premiumButton("Convert", () { try { setState(() => res = grade(double.parse(p.text))); } catch (e) {} }),
              if (res != null) premiumResult(res!, "Progress matters most 📘"),
              const SizedBox(height: 60),
            ]),
          ),
        ),
      ],
    ),
  );
}

// Bra Size Finder
class BraCalc extends StatefulWidget { const BraCalc({super.key}); @override State<BraCalc> createState() => _BraCalcState(); }
class _BraCalcState extends State<BraCalc> {
  final bust = TextEditingController(), band = TextEditingController();
  String? res;

  @override
  Widget build(BuildContext context) => Scaffold(
    extendBodyBehindAppBar: true,
    appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, foregroundColor: Colors.white),
    body: Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)]),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              Text("Bra Size Guide 👙", style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 16),
              Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(16)), child: Text("Find your bra size by measuring bust and underbust (band) in centimeters. Results in US/UK sizing.", style: GoogleFonts.poppins(fontSize: 16, color: Colors.white), textAlign: TextAlign.center)),
              const SizedBox(height: 40),
              premiumField(bust, "Bust (cm)"),
              premiumField(band, "Band (cm)"),
              premiumButton("Find Size", () { try { setState(() => res = braSize(double.parse(bust.text), double.parse(band.text))); } catch (e) {} }),
              if (res != null) premiumResult(res!, "Comfort is confidence 💖"),
              const SizedBox(height: 60),
            ]),
          ),
        ),
      ],
    ),
  );
}

// Shoe Size Converter
class ShoeCalc extends StatefulWidget {
  const ShoeCalc({super.key});

  @override
  State<ShoeCalc> createState() => _ShoeCalcState();
}

class _ShoeCalcState extends State<ShoeCalc> {
  final f = TextEditingController();
  String? res;
  String? error;

  @override
  Widget build(BuildContext context) => Scaffold(
    extendBodyBehindAppBar: true,
    appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white),
    body: Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF43E97B), Color(0xFF38F9D7)]),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              Text("Shoe Size Converter 👟",
                  style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 16),
              Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      Text(
                          "Convert foot length in centimeters to European (EU) shoe size.",
                          style: GoogleFonts.poppins(
                              fontSize: 16, color: Colors.white),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      Text(
                          "Tip: Measure your foot from heel to longest toe while standing. Add ~1 cm extra if you prefer looser fit.",
                          style: GoogleFonts.poppins(
                              fontSize: 14, color: Colors.white70),
                          textAlign: TextAlign.center),
                    ],
                  )),
              const SizedBox(height: 40),
              // Assuming premiumField is a custom TextField widget
              premiumField(f, "Foot Length (cm)"),
              const SizedBox(height: 16),
              premiumButton("Convert", () {
                setState(() {
                  error = null;
                  res = null;
                });
                try {
                  double cm = double.parse(f.text.trim());
                  if (cm <= 0) {
                    error = "Please enter a positive number";
                    return;
                  }
                  double size = shoeSize(cm);
                  setState(() {
                    // Round to nearest whole number (standard for most EU sizes)
                    res = size.round().toString();
                  });
                } catch (e) {
                  setState(() {
                    error = "Invalid input – enter a number (e.g. 25.5)";
                  });
                }
              }),
              const SizedBox(height: 20),
              if (error != null)
                Text(error!,
                    style: GoogleFonts.poppins(
                        color: Colors.redAccent, fontSize: 16)),
              if (res != null)
                premiumResult(res!, "Your EU Shoe Size👟"),
              const SizedBox(height: 60),
            ]),
          ),
        ),
      ],
    ),
  );
}

// Tip Calculator
class TipCalc extends StatefulWidget { const TipCalc({super.key}); @override State<TipCalc> createState() => _TipCalcState(); }
class _TipCalcState extends State<TipCalc> {
  final b = TextEditingController(), p = TextEditingController();
  String? res;

  @override
  Widget build(BuildContext context) => Scaffold(
    extendBodyBehindAppBar: true,
    appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, foregroundColor: Colors.white),
    body: Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFA709A), Color(0xFFFEE140)]),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              Text("Tip Calculator 💸", style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 16),
              Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(16)), child: Text("Calculate the tip amount based on bill total and desired tip percentage.", style: GoogleFonts.poppins(fontSize: 16, color: Colors.white), textAlign: TextAlign.center)),
              const SizedBox(height: 40),
              premiumField(b, "Bill Amount"),
              premiumField(p, "Tip %"),
              premiumButton("Calculate Tip", () { try { final tipAmt = tip(double.parse(b.text), double.parse(p.text)); setState(() => res = tipAmt.toStringAsFixed(2)); } catch (e) {} }),
              if (res != null) premiumResult("₹$res", "Kindness looks good on you ✨"),
              const SizedBox(height: 60),
            ]),
          ),
        ),
      ],
    ),
  );
}

// Golf Handicap Calculator
class GolfCalc extends StatefulWidget { const GolfCalc({super.key}); @override State<GolfCalc> createState() => _GolfCalcState(); }
class _GolfCalcState extends State<GolfCalc> {
  final s = TextEditingController(), r = TextEditingController();
  String? res;

  @override
  Widget build(BuildContext context) => Scaffold(
    extendBodyBehindAppBar: true,
    appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, foregroundColor: Colors.white),
    body: Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF56AB2F), Color(0xFFA8E063)]),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              Text("Golf Handicap ⛳", style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 16),
              Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(16)), child: Text("Calculate basic golf handicap differential using your score and the course rating.", style: GoogleFonts.poppins(fontSize: 16, color: Colors.white), textAlign: TextAlign.center)),
              const SizedBox(height: 40),
              premiumField(s, "Score"),
              premiumField(r, "Course Rating"),
              premiumButton("Calculate", () { try { final h = golfHandicap(double.parse(s.text), double.parse(r.text)); setState(() => res = h.toStringAsFixed(1)); } catch (e) {} }),
              if (res != null) premiumResult(res!, "Precision meets patience ⛳"),
              const SizedBox(height: 60),
            ]),
          ),
        ),
      ],
    ),
  );
}

// Sleep Quality Calculator

class SleepCalc extends StatefulWidget {
  const SleepCalc({super.key});

  @override
  State<SleepCalc> createState() => _SleepCalcState();
}

class _SleepCalcState extends State<SleepCalc> {
  TimeOfDay? bedTime;
  TimeOfDay? wakeTime;
  String? resultText; // Holds the raw string returned by sleepCalculator

  Future<void> _pickTime(bool isBedTime) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isBedTime
          ? (bedTime ?? const TimeOfDay(hour: 22, minute: 0))
          : (wakeTime ?? const TimeOfDay(hour: 6, minute: 0)),
    );

    if (picked != null) {
      setState(() {
        if (isBedTime) {
          bedTime = picked;
        } else {
          wakeTime = picked;
        }
      });
    }
  }

  DateTime _toDateTime(TimeOfDay t) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, t.hour, t.minute);
  }

  // Parses the string "X.X hours\nRemark" into hours and remark
  ({double hours, String remark}) _parseResult(String text) {
    final lines = text.split('\n');
    final hoursPart = lines[0].replaceAll(' hours', '').trim();
    final hours = double.parse(hoursPart);
    final remark = lines.length > 1 ? lines.sublist(1).join('\n').trim() : '';
    return (hours: hours, remark: remark);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    extendBodyBehindAppBar: true,
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: Colors.white,
    ),
    body: Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF2E3192), Color(0xFF1BFFFF)],
            ),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  "Sleep Quality 💤",
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    "Select your bedtime and wake-up time to analyze your sleep duration and quality.",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 40),

                // Bedtime picker - assuming premiumButton is already defined elsewhere
                premiumButton(
                  bedTime == null
                      ? "Select Bed Time"
                      : "Bed Time: ${bedTime!.format(context)}",
                      () => _pickTime(true),
                ),
                const SizedBox(height: 16),

                // Wake time picker
                premiumButton(
                  wakeTime == null
                      ? "Select Wake Time"
                      : "Wake Time: ${wakeTime!.format(context)}",
                      () => _pickTime(false),
                ),
                const SizedBox(height: 24),

                // Calculate button
                premiumButton("Check Sleep", () {
                  if (bedTime == null || wakeTime == null) return;

                  final bed = _toDateTime(bedTime!);
                  final wake = _toDateTime(wakeTime!);

                  setState(() {
                    resultText = sleepCalculator(
                      bedTime: bed,
                      wakeTime: wake,
                    );
                  });
                }),

                // Results - displayed separately
                if (resultText != null) ...[
                  const SizedBox(height: 40),

                  // Parse and display hours + remark separately
                      () {
                    final parsed = _parseResult(resultText!);
                    return Column(
                      children: [
                        // Big Hours Display
                        Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 24, horizontal: 32),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 2),
                          ),
                          child: Column(
                            children: [
                              Text(
                                parsed.hours.toStringAsFixed(1),
                                style: GoogleFonts.poppins(
                                  fontSize: 64,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                "Hours of Sleep",
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Remark Display
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            parsed.remark,
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        const SizedBox(height: 20),

                        Text(
                          "Sleep fuels everything 🌙",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.8),
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  }(),
                ],

                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}