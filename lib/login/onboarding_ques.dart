import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pillar_questions.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart'; // Add intl to your pubspec.yaml for date formatting

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  final supabase = Supabase.instance.client;

  // === ORIGINAL DATA STATE ===
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  double _height = 170;
  double _weight = 70;
  DateTime? _selectedDate;
  int _age = 0;
  String _gender = '';

  final List<String> _suggestedNicknames = [
    'Doremon', 'Sinchan', 'Lil champ', 'Ace', 'Luna', 'Nova', 'Champ'
  ];

  double get _bmi => _weight / ((_height / 100) * (_height / 100));

  // === NEW FUN & QUIRKY STATE ===
  int _currentPage = 0;
  String _currentQuip = "HO HO HO! Ready to become a legend, space cadet? ✨";

  late AnimationController _quipController;

  // === NEW VISUAL EFFECT STATE ===
  late AnimationController _bgAnimationController;
  late AnimationController _confettiController;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(_updatePage);
    _quipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();

    // Background floating stars animation
    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Confetti/Burst animation
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _firstNameController.addListener(_updateNameQuip);
    _lastNameController.addListener(_updateNameQuip);
    _nicknameController.addListener(_updateNameQuip);
  }

  void _triggerBurst() {
    _confettiController.reset();
    _confettiController.forward();
  }

  void _updatePage() {
    if (_pageController.page != null) {
      setState(() => _currentPage = _pageController.page!.round());
    }
  }

  void _setQuip(String quip) {
    if (quip != _currentQuip) {
      setState(() => _currentQuip = quip);
      _quipController.reset();
      _quipController.forward();
    }
  }

  void _updateNameQuip() {
    if (_currentPage == 0) {
      final name = _firstNameController.text.trim();
      if (name.isNotEmpty) {
        _setQuip("$name? That's a name that punches black holes! 💥");
      }
    }
  }

  // Calculate age from DOB
  void _calculateAge(DateTime birthDate) {
    DateTime today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    setState(() {
      _age = age;
      _selectedDate = birthDate;
      _dobController.text = DateFormat('yyyy-MM-dd').format(birthDate);
    });
    _setQuip(_getAgeQuip(age));
  }

  // === HILARIOUS QUIRKY COMMENT GENERATORS ===
  String _getHeightQuip(double h) {
    if (h < 150) return "POCKET ROCKET! Tiny but your vibes hit like a supernova 🔥";
    if (h > 190) return "YOU'RE A WALKING SKYSCRAPER! The stars are jealous 🌌";
    return "Goldilocks height — just right for epic hugs and dramatic entrances!";
  }

  String _getWeightQuip(double w) {
    if (w < 50) return "You're basically a feather with superpowers. Elegant chaos! 🪶";
    if (w > 100) return "THICC LEGEND! You make gravity nervous 😤";
    return "Built like a Greek god who discovered pizza. Perfect.";
  }

  String _getAgeQuip(int a) {
    if (a < 18) return "BABY LEGEND ALERT! The universe is still scared of what you'll do 💀";
    if (a > 50) return "ANCIENT COSMIC WISDOM + SWAG. We stan a timeless icon 👑";
    return "Prime main character energy! The plot is just getting good!";
  }

  String _getBmiQuip() {
    if (_bmi < 18.5) return "LIGHT AS A QUASAR! You're floating through life fabulously ✨";
    if (_bmi < 25) return "THIS BMI IS SEXY. The cosmos approves 👀";
    return "THICC & THICCER — you're a whole MOOD and a snack!";
  }

  String _getGenderQuip(String g) {
    return g == "Male"
        ? "Warrior of the stars chosen ⚔️"
        : "Goddess of the cosmos has arrived 👑";
  }

  @override
  void dispose() {
    _pageController.removeListener(_updatePage);
    _firstNameController.removeListener(_updateNameQuip);
    _lastNameController.removeListener(_updateNameQuip);
    _nicknameController.removeListener(_updateNameQuip);
    _dobController.dispose();
    _quipController.dispose();
    _bgAnimationController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  // === ORIGINAL PROCEED FUNCTION - MODIFIED FOR DATA TYPES ===
  void _proceedToQuestionnaire() {
    final onboardingData = {
      'first_name': _firstNameController.text,
      'last_name': _lastNameController.text,
      'nickname': _nicknameController.text,
      'height': _height.toInt(), // Integer
      'weight': _weight.toInt(), // Integer
      'bmi': double.parse(_bmi.toStringAsFixed(1)), // 1 decimal point
      'age': _age, // Integer
      'gender': _gender,
      'goal': 'Not Selected',
      'dob': _selectedDate?.toIso8601String(), // Store full date
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MovementPage(onboardingData: onboardingData),
      ),
    );
  }

  bool _validateNamePage() {
    if (_firstNameController.text.trim().isEmpty) {
      _showError("Please enter your First Name");
      return false;
    }
    if (_lastNameController.text.trim().isEmpty) {
      _showError("Please enter your Last Name");
      return false;
    }
    if (_nicknameController.text.trim().isEmpty) {
      _showError("Please choose or enter a Nickname");
      return false;
    }
    return true;
  }

  bool _validateAgePage() {
    if (_selectedDate == null) {
      _showError("When were you manifested? (Pick a Date)");
      return false;
    }
    // NEW GENDER VALIDATION
    if (_gender.isEmpty) {
      _showError("Please choose your Archetype (Gender)");
      return false;
    }
    return true;
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          _buildParticleSystem(),
          SafeArea(
            child: Column(
              children: [
                _buildProgressStars(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildNamePage(),
                      _buildBodyStatsPage(),
                      _buildAgeGenderPage(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildConfettiOverlay(),
        ],
      ),
    );
  }

  // ==================== VISUAL EFFECTS ====================
  Widget _buildParticleSystem() {
    return AnimatedBuilder(
      animation: _bgAnimationController,
      builder: (context, child) {
        return CustomPaint(
          painter: StarfieldPainter(_bgAnimationController.value),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildConfettiOverlay() {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _confettiController,
        builder: (context, child) {
          return CustomPaint(
            painter: BurstPainter(_confettiController.value),
            size: Size.infinite,
          );
        },
      ),
    );
  }

  Widget _buildProgressStars() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: _currentPage == i ? 30 : 12,
          height: 12,
          decoration: BoxDecoration(
            color: _currentPage == i ? const Color(0xFFFF6B6B) : Colors.white12,
            borderRadius: BorderRadius.circular(20),
            boxShadow: _currentPage == i
                ? [BoxShadow(color: const Color(0xFFFF6B6B).withOpacity(0.6), blurRadius: 10)]
                : [],
          ),
        )),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF050505), Color(0xFF0F0F1A), Color(0xFF1A0A1A)],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
    );
  }

  // ==================== NAME PAGE ====================
  Widget _buildNamePage() {
    return _buildPageWrapper(
      title: "LEGEND NAME?!",
      subtitle: "Make it unforgettable",
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _customTextField("First Name", _firstNameController, "Like 'Galactic'"),
          const SizedBox(height: 16),
          _customTextField("Last Name", _lastNameController, "Power move"),
          const SizedBox(height: 20),
          const Text("Pick a nickname:",
              style: TextStyle(color: Color(0xFFFF6B6B), fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestedNicknames.map((name) => _buildNicknameChip(name)).toList(),
          ),
          const SizedBox(height: 16),
          _customTextField("Or your own", _nicknameController, "Be creative!"),
        ],
      ),
      isLast: false,
      onNext: () {
        if (_validateNamePage()) {
          _triggerBurst();
          _setQuip("PERFECT! ${_nicknameController.text.toUpperCase()} has entered the chat 🔥");
          _pageController.nextPage(duration: const Duration(milliseconds: 600), curve: Curves.easeInOutCubic);
        }
      },
    );
  }

  Widget _buildNicknameChip(String name) {
    final isSelected = _nicknameController.text == name;
    return AnimatedScale(
      scale: isSelected ? 1.1 : 1.0,
      duration: const Duration(milliseconds: 220),
      child: ActionChip(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        label: Text(name, style: TextStyle(
          color: isSelected ? Colors.black : Colors.white,
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        )),
        backgroundColor: isSelected
            ? const Color(0xFFFFB347)
            : const Color(0xFF2A1A2A).withOpacity(0.6),
        side: isSelected
            ? const BorderSide(color: Color(0xFFFF6B6B), width: 2)
            : null,
        onPressed: () {
          _triggerBurst();
          setState(() => _nicknameController.text = name);
          _setQuip("$name?! HELL YES. That's main character energy! 🌟");
        },
      ),
    );
  }

  // ==================== BODY STATS PAGE ====================
  Widget _buildBodyStatsPage() {
    return _buildPageWrapper(
      title: "PHYSICAL VESSEL",
      subtitle: "How powerful are we talking?",
      content: Column(
        children: [
          _buildFunSlider("HEIGHT", "cm", 100, 250, _height, (val) {
            setState(() => _height = val);
            _setQuip(_getHeightQuip(val));
          }, Icons.height),
          const SizedBox(height: 24),
          _buildFunSlider("WEIGHT", "kg", 30, 200, _weight, (val) {
            setState(() => _weight = val);
            _setQuip(_getWeightQuip(val));
          }, Icons.fitness_center),
          const SizedBox(height: 24),
          AnimatedContainer(
            duration: const Duration(milliseconds: 700),
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _bmi < 25
                    ? [const Color(0xFFFFB347).withOpacity(0.8), const Color(0xFFFF8C00).withOpacity(0.8)]
                    : [const Color(0xFFFF6B6B).withOpacity(0.8), const Color(0xFFC2185B).withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: const Color(0xFFFF6B6B).withOpacity(0.3), blurRadius: 15, spreadRadius: 2)
              ],
            ),
            child: Column(
              children: [
                const Text("CELESTIAL BMI",
                    style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.bold)),
                Text(_bmi.toStringAsFixed(1),
                    style: GoogleFonts.poppins(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white)),
                Text(_getBmiQuip(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.2)),
              ],
            ),
          ),
        ],
      ),
      isLast: false,
      onNext: () {
        _triggerBurst();
        _pageController.nextPage(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOutCubic
        );
      },
    );
  }

  Widget _buildFunSlider(String label, String unit, double min, double max,
      double current, Function(double) onChanged, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFFFFB347), size: 20),
                const SizedBox(width: 8),
                Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
            Text("${current.toInt()} $unit",
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            activeTrackColor: const Color(0xFFFF6B6B),
            inactiveTrackColor: Colors.white12,
            thumbColor: const Color(0xFFFFB347),
          ),
          child: Slider(
            value: current,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  // ==================== AGE & GENDER PAGE (Final) ====================
  Widget _buildAgeGenderPage() {
    return _buildPageWrapper(
      title: "COSMIC VIBE",
      subtitle: "Define your archetype",
      content: Column(
        children: [
          // Date of Birth Field
          // === ENHANCED TEMPORAL SCAN (DOB) SECTION ===
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "WHEN DID YOUR JOURNEY BEGIN?",
                style: GoogleFonts.poppins(
                  color: const Color(0xFFFF6B6B),
                  fontSize: 13,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime(2000),
                    firstDate: DateTime(1920),
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: Color(0xFFFF6B6B),
                            onPrimary: Colors.white,
                            surface: Color(0xFF1A0A1A),
                            onSurface: Colors.white,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) _calculateAge(picked);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _selectedDate != null
                          ? const Color(0xFFFF6B6B).withOpacity(0.5)
                          : Colors.white10,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded, color: Color(0xFFFFB347)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedDate == null ? "Pick your birthday" : _dobController.text,
                              style: TextStyle(
                                color: _selectedDate == null ? Colors.white38 : Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Text(
                              "Select Date",
                              style: TextStyle(color: Color(0xFFFFB347), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      if (_selectedDate != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF6B6B), Color(0xFFC2185B)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF6B6B).withOpacity(0.3),
                                blurRadius: 8,
                              )
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                "$_age",
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              const Text(
                                "YEARS",
                                style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          const Text(
            "CHOOSE YOUR ARCHETYPE",
            style: TextStyle(
                color: Color(0xFFFF6B6B),
                fontSize: 13,
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _genderCard("Male", Icons.male, const Color(0xFFFFB347)),
              _genderCard("Female", Icons.female, const Color(0xFFFF6B6B)),
            ],
          ),
        ],
      ),
      isLast: true,
      onNext: () {
        if (_validateAgePage()) {
          _triggerBurst();
          _setQuip("You're perfect. Let's go make you UNSTOPPABLE! 🚀");
          Future.delayed(const Duration(milliseconds: 500), () => _proceedToQuestionnaire());
        }
      },
    );
  }

  // ==================== SHARED PAGE WRAPPER ====================
  Widget _buildPageWrapper({
    required String title,
    required String subtitle,
    required Widget content,
    required bool isLast,
    required VoidCallback onNext,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 20),
                onPressed: () {
                  if (_pageController.page == 0) {
                    Navigator.pop(context);
                  } else {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    );
                  }
                },
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
                  Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 13)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(30),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: content,
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 450),
            transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: ScaleTransition(scale: animation, child: child)),
            child: Container(
              key: ValueKey(_currentQuip),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFF6B6B).withOpacity(0.3)),
              ),
              child: Text(
                _currentQuip,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.white, fontStyle: FontStyle.italic),
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B6B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: onNext,
              child: Text(
                isLast ? "LAUNCH GREATNESS!" : "NEXT ADVENTURE →",
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _customTextField(String hint, TextEditingController controller, String helper) {
    return TextField(
      controller: controller,
      readOnly: controller == _dobController, // Make DOB field read-only to force picker
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        helperText: helper,
        helperStyle: const TextStyle(color: Color(0xFFFFB347), fontSize: 11),
        filled: true,
        fillColor: Colors.white.withOpacity(0.07),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _genderCard(String type, IconData icon, Color color) {
    bool isSelected = _gender == type;
    return GestureDetector(
      onTap: () {
        _triggerBurst();
        setState(() => _gender = type);
        _setQuip(_getGenderQuip(type));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 340),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isSelected ? color : Colors.transparent, width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, size: 48, color: isSelected ? color : Colors.white24),
            const SizedBox(height: 8),
            Text(type, style: TextStyle(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              color: isSelected ? Colors.white : Colors.white54,
            )),
          ],
        ),
      ),
    );
  }
}

// === CUSTOM PAINTERS ===
class StarfieldPainter extends CustomPainter {
  final double animationValue;
  StarfieldPainter(this.animationValue);
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);
    final paint = Paint()..color = Colors.white.withOpacity(0.3);
    for (int i = 0; i < 50; i++) {
      double x = random.nextDouble() * size.width;
      double y = (random.nextDouble() * size.height + (animationValue * 100)) % size.height;
      double radius = random.nextDouble() * 1.5;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }
  @override
  bool shouldRepaint(StarfieldPainter oldDelegate) => true;
}

class BurstPainter extends CustomPainter {
  final double progress;
  BurstPainter(this.progress);
  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0 || progress == 1) return;
    final center = Offset(size.width / 2, size.height * 0.8);
    final random = math.Random(123);
    final paint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 15; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final distance = progress * 150;
      final x = center.dx + math.cos(angle) * distance;
      final y = center.dy + math.sin(angle) * distance;
      paint.color = [const Color(0xFFFF6B6B), const Color(0xFFFFB347), Colors.white][random.nextInt(3)]
          .withOpacity(1 - progress);
      canvas.drawCircle(Offset(x, y), 4 * (1 - progress), paint);
    }
  }
  @override
  bool shouldRepaint(BurstPainter oldDelegate) => true;
}