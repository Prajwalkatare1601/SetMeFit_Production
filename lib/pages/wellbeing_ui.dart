import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'dart:math';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart'; // Audio player import

class WellbeingPage extends StatefulWidget {
  const WellbeingPage({super.key});
  @override
  State<WellbeingPage> createState() => _WellbeingPageState();
}

class _WellbeingPageState extends State<WellbeingPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _sleepController = TextEditingController();
  final _meditationController = TextEditingController();
  final _musicController = TextEditingController();

  // Date Management Variables
  int _activeDayIndex = DateTime.now().day - 1;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  final DateTime _maxDate = DateTime(DateTime.now().year, DateTime.now().month);
  final DateTime _minDate = DateTime(DateTime.now().year - 1, DateTime.now().month);

  final ScrollController _timelineScrollController = ScrollController();

  String _selectedMood = 'Normal';
  String _selectedHobby = 'Exploring';
  final List<String> _moods = ['Delighted', 'Happy', 'Normal', 'Sad', 'Heartbroken'];
  final List<String> _hobbyLevels = ['Exploring', 'Developing', 'Talented', 'Expert'];
  double _targetSleep = 10.0;
  String _activeMetric = 'SLEEP'; // Default tab

// Add this to your _WellbeingPageState class
  late AnimationController _pulseController;
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = false;

  late AnimationController _rotationController;
  late AnimationController _ringRotationController;
  late AnimationController _starController;

  final Color kVoid = const Color(0xFF020202);
  final Color kSolar = const Color(0xFFFF6200);
  final Color kBlood = const Color(0xFFFF003C);
  final Color kCyber = const Color(0xFF00F2FF);
  final Color kGold = const Color(0xFFFFD700);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _fetchLogs();
    _rotationController = AnimationController(vsync: this, duration: const Duration(seconds: 15))..repeat();
    _ringRotationController = AnimationController(vsync: this, duration: const Duration(seconds: 25))..repeat();
    _starController = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    _fetchUserTargets();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _ringRotationController.dispose();
    _starController.dispose();
    _sleepController.dispose();
    _meditationController.dispose();
    _musicController.dispose();
    super.dispose();
  }

  // 1. Unified engine to get data for the day selected in the timeline
  dynamic _getSelectedDayRawValue(String key) {
    if (_logs.isEmpty) return null;
    final String selectedDateStr = DateFormat('yyyy-MM-dd').format(
        DateTime(_selectedYear, _selectedMonth, _activeDayIndex + 1)
    );
    try {
      final dayLog = _logs.firstWhere((l) => l['log_date'] == selectedDateStr);
      return dayLog[key];
    } catch (e) {
      return null;
    }
  }

  // 2. Updated val helper used by Orbit Rings and Header
  String val(String key, [String unit = ""]) {
    final raw = _getSelectedDayRawValue(key);
    if (raw == null) return "--";
    return unit.isEmpty ? "$raw" : "$raw $unit";
  }

  // 3. 7-Day Window for the Graph (ends at selected day)
  List<Map<String, dynamic>> _getGraphData() {
    List<Map<String, dynamic>> window = [];
    final DateTime selectedDate = DateTime(_selectedYear, _selectedMonth, _activeDayIndex + 1);

    for (int i = 6; i >= 0; i--) {
      DateTime targetDate = selectedDate.subtract(Duration(days: i));
      String targetStr = DateFormat('yyyy-MM-dd').format(targetDate);

      var log = _logs.firstWhere((l) => l['log_date'] == targetStr, orElse: () => {});

      if (log.isNotEmpty) {
        window.add(log);
      } else {
        // Keeps graph line continuous even if data is missing
        window.add({'log_date': targetStr, 'is_placeholder': true});
      }
    }
    return window;
  }

  bool _isEditable() {
    final DateTime selectedDate = DateTime(_selectedYear, _selectedMonth, _activeDayIndex + 1);

    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime yesterday = today.subtract(const Duration(days: 1));

    return selectedDate.isAtSameMomentAs(today) || selectedDate.isAtSameMomentAs(yesterday);
  }

  Future<void> _fetchUserTargets() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user != null) {
        final data = await client.from('user_targets').select('target_sleep').eq('user_id', user.id).maybeSingle();
        if (data != null && data['target_sleep'] != null) {
          if (mounted) {
            setState(() { _targetSleep = (data['target_sleep'] as num).toDouble(); });
          }
        }
      }
    } catch (e) {
      debugPrint("Neural Error: Failed to fetch targets: $e");
      setState(() => _targetSleep = 8.0);
    }
  }

  Future<void> _fetchLogs() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Calculate the range for the selected month
      final daysInMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
      final firstDay = DateTime(_selectedYear, _selectedMonth, 1);
      final lastDay = DateTime(_selectedYear, _selectedMonth, daysInMonth);

      final response = await Supabase.instance.client
          .from('wellbeing_logs')
          .select()
          .eq('user_id', user.id)
          .gte('log_date', DateFormat('yyyy-MM-dd').format(firstDay))
          .lte('log_date', DateFormat('yyyy-MM-dd').format(lastDay))
          .order('log_date', ascending: true);

      setState(() {
        _logs = List<Map<String, dynamic>>.from(response);
      });

      _scrollToActiveDay(); // Auto-scroll the timeline to the selected day
    } catch (e) {
      debugPrint("Sync Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

// Helper to scroll timeline horizontally
  void _scrollToActiveDay() {
    if (_timelineScrollController.hasClients) {
      double screenWidth = MediaQuery.of(context).size.width;
      double targetScroll = (_activeDayIndex * 60.0) - (screenWidth / 2) + 30;
      _timelineScrollController.animateTo(
        targetScroll.clamp(0.0, _timelineScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 500), curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submitForm({String? targetDate}) async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Determine the date: use the passed targetDate OR fallback to today
      final finalDateStr = targetDate ?? DateFormat('yyyy-MM-dd').format(DateTime.now());

      // 1. Check if a record exists for the specific selected date
      final existingLog = await Supabase.instance.client
          .from('wellbeing_logs')
          .select()
          .eq('user_id', user.id)
          .eq('log_date', finalDateStr)
          .maybeSingle();

      final Map<String, dynamic> data = {
        'user_id': user.id,
        'log_date': finalDateStr,
      };

      if (existingLog == null) {
        // NEW ENTRY LOGIC: Initialize defaults to avoid nulls
        data['sleep_hours'] = double.tryParse(_sleepController.text) ?? 0.0;
        data['meditation_min'] = int.tryParse(_meditationController.text) ?? 0;
        data['music_min'] = int.tryParse(_musicController.text) ?? 0;
        data['happiness_mood'] = _selectedMood.isEmpty ? "NA" : _selectedMood;
        data['hobby_level'] = _selectedHobby.isEmpty ? "NA" : _selectedHobby;
      } else {
        // UPDATE LOGIC: Only target the specific metric being edited
        if (_sleepController.text.isNotEmpty) data['sleep_hours'] = double.tryParse(_sleepController.text);
        if (_meditationController.text.isNotEmpty) data['meditation_min'] = int.tryParse(_meditationController.text);
        if (_musicController.text.isNotEmpty) data['music_min'] = int.tryParse(_musicController.text);
        data['happiness_mood'] = _selectedMood;
        data['hobby_level'] = _selectedHobby;
      }

      // Upsert targets the unique (user_id, log_date) constraint in your schema
      await Supabase.instance.client
          .from('wellbeing_logs')
          .upsert(data, onConflict: 'user_id,log_date');

      // Clean up
      _sleepController.clear();
      _meditationController.clear();
      _musicController.clear();

      // Refresh the UI with the latest data from Supabase
      await _fetchLogs();

    } catch (e) {
      debugPrint("Submit Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showEditLogDialog(String selectedDateStr) {
    final Map<String, dynamic> config = {
      'SLEEP': {'label': 'Sleep Hours', 'controller': _sleepController, 'isDrop': false},
      'ZEN': {'label': 'Meditation Minutes', 'controller': _meditationController, 'isDrop': false},
      'SONIC': {'label': 'Music Minutes', 'controller': _musicController, 'isDrop': false},
      'MOOD': {'label': 'Current Vibe', 'items': _moods, 'isDrop': true},
      'HOBBY': {'label': 'Hobby Rank', 'items': _hobbyLevels, 'isDrop': true},
    }[_activeMetric]!;

    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF222222).withOpacity(0.95),
                  const Color(0xFF000000).withOpacity(0.98),
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: kSolar.withOpacity(0.4), width: 1.5),
              boxShadow: [
                BoxShadow(color: kSolar.withOpacity(0.12), blurRadius: 40, spreadRadius: 2)
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: kSolar.withOpacity(0.1), shape: BoxShape.circle),
                      child: Icon(Icons.auto_awesome, color: kSolar, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "UPDATE $_activeMetric",
                      style: TextStyle(color: kSolar, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "LOGGING FOR: $selectedDateStr",
                    style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: config['isDrop']
                      ? _miniDrop(
                      Icons.auto_fix_high,
                      config['label'],
                      _activeMetric == 'MOOD' ? _selectedMood : _selectedHobby,
                      config['items'],
                      kGold,
                          (v) => setState(() => _activeMetric == 'MOOD' ? _selectedMood = v! : _selectedHobby = v!)
                  )
                      : _miniQ(
                      Icons.edit,
                      config['controller'],
                      "Value for ${config['label']}?",
                      kCyber
                  ),
                ),
                const SizedBox(height: 35),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("CANCEL", style: TextStyle(color: Colors.white24, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kSolar,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      onPressed: () {
                        // Pass the date captured from the card to the submit function
                        _submitForm(targetDate: selectedDateStr);
                        Navigator.pop(context);
                      },
                      child: const Text("SYNC", style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _updateMeditationLog(int newMinutes) async {
    if (newMinutes <= 0) return;
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Get today's date in YYYY-MM-DD format
      final todayStr = DateTime.now().toIso8601String().split('T')[0];

      // 1. Fetch existing meditation minutes for today
      final existing = await Supabase.instance.client
          .from('wellbeing_logs')
          .select('meditation_min')
          .eq('user_id', user.id)
          .eq('log_date', todayStr)
          .maybeSingle();

      int totalMins = newMinutes;
      if (existing != null && existing['meditation_min'] != null) {
        totalMins += (existing['meditation_min'] as int);
      }

      // 2. Perform the Upsert with the onConflict constraint
      // This specifically targets the unique constraint causing your error
      await Supabase.instance.client.from('wellbeing_logs').upsert(
        {
          'user_id': user.id,
          'log_date': todayStr,
          'meditation_min': totalMins,
        },
        onConflict: 'user_id,log_date', // Matches your DB unique constraint
      );

      // 3. Refresh the UI orbital rings
      _fetchLogs();
    } catch (e) {
      debugPrint("Auto-Log Sync Error: $e");
    }
  }

  Widget _getMetricInsight(Map<String, dynamic> dayLog) {
    // 1. Scenario: No log exists for the selected date
    if (dayLog.isEmpty || dayLog['is_placeholder'] == true) {
      return _insightNote("GHOSTED", "No data? Are we even friends? Log something!", Colors.white24);
    }

    switch (_activeMetric) {
      case 'SLEEP':
        double s = (dayLog['sleep_hours'] ?? 0.0).toDouble();
        if (s == 0) return _insightNote("VAMPIRE", "Zero sleep? How are you even awake?", Colors.red);
        return s < 5
            ? _insightNote("ROAST", "Sleeping $s hr? You're a literal raccoon. Nap now.", Colors.deepOrangeAccent)
            : _insightNote("YAY", "$s hrs! Look at you being a functional adult.", Colors.lightGreenAccent);

      case 'ZEN':
        int z = (dayLog['meditation_min'] ?? 0).toInt();
        if (z == 0) return _insightNote("CHAOS", "Your brain is a screaming group chat right now.", Colors.red);
        return z < 10
            ? _insightNote("FOCUS", "$z min? Almost there, don't let the thoughts win.", Colors.amber)
            : _insightNote("CHILL", "$z min. You're basically a monk now. Teach me.", Colors.lightGreenAccent);

      case 'SONIC':
        int m = (dayLog['music_min'] ?? 0).toInt();
        if (m == 0) return _insightNote("MUTE", "The vibes are at zero. Play something quickly!", Colors.white24);
        return m < 20
            ? _insightNote("LOW", "Vibes are dangerously low. Increase the volume.", Colors.red)
            : _insightNote("VIBE", "Main character energy detected. I'm here for it.", Colors.lightGreenAccent);

      case 'MOOD':
        String mood = (dayLog['happiness_mood'] ?? 'Normal').toString().toLowerCase();
        if (mood.contains('delighted') || mood.contains('happy')) {
          return _insightNote("GLOW", "Your energy is elite today. Keep shining!", Colors.lightGreenAccent);
        } else if (mood.contains('sad') || mood.contains('heartbroken')) {
          return _insightNote("HUG", "Virtual pizza sent. Tomorrow will be better.", Colors.orangeAccent);
        } else {
          return _insightNote("STEADY", "Balanced and chill. A solid day for a solid human.", Colors.yellow);
        }

      case 'HOBBY':
        String lvl = (dayLog['hobby_level'] ?? 'novice').toString().toLowerCase();
        if (lvl.contains('expert') || lvl.contains('talented')) {
          return _insightNote("PRO", "Look at you becoming a master! Proud of you.", Colors.lightGreenAccent);
        } else if (lvl.contains('developing') || lvl.contains('exploring')) {
          return _insightNote("GROW", "Progress is progress. You're getting there, bestie.", Colors.amber);
        } else {
          return _insightNote("START", "Everyone starts at zero. Just don't stop now!", Colors.yellow);
        }

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _insightNote(String tag, String msg, Color color) {
    return AnimatedBuilder(
      animation: _starController,
      builder: (context, child) {
        // High-speed blinking pulse
        double blinkValue = (sin(_starController.value * 8 * pi) + 1) / 2;

        return CustomPaint(
          painter: ThinkingCloudPainter(color: color, pulse: blinkValue),
          child: Container(
            // Wide horizontal padding for the stretch effect
            padding: const EdgeInsets.fromLTRB(30, 20, 25, 32),
            constraints: const BoxConstraints(
              maxWidth: 220, // STRETCHED WIDTH
              minHeight: 70,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  tag.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  msg,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    height: 1.2,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  Widget _buildMonthSelector() {
    String monthStr = DateFormat('MMMM yyyy').format(DateTime(_selectedYear, _selectedMonth)).toUpperCase();
    bool canGoBack = DateTime(_selectedYear, _selectedMonth - 1).isAfter(_minDate) || DateTime(_selectedYear, _selectedMonth - 1).isAtSameMomentAs(_minDate);
    bool canGoForward = DateTime(_selectedYear, _selectedMonth + 1).isBefore(_maxDate) || DateTime(_selectedYear, _selectedMonth + 1).isAtSameMomentAs(_maxDate);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios, color: canGoBack ? kSolar : Colors.white30, size: 20),
            onPressed: canGoBack ? () {
              DateTime target = DateTime(_selectedYear, _selectedMonth - 1);
              setState(() { _selectedMonth = target.month; _selectedYear = target.year; _activeDayIndex = 0; });
              _fetchLogs();
            } : null,
          ),
          Text(monthStr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 2)),
          IconButton(
            icon: Icon(Icons.arrow_forward_ios, color: canGoForward ? kSolar : Colors.white30, size: 20),
            onPressed: canGoForward ? () {
              DateTime target = DateTime(_selectedYear, _selectedMonth + 1);
              setState(() { _selectedMonth = target.month; _selectedYear = target.year; _activeDayIndex = 0; });
              _fetchLogs();
            } : null,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    final daysInMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
    return SizedBox(
      height: 50,
      child: ListView.builder(
        controller: _timelineScrollController,
        scrollDirection: Axis.horizontal,
        itemCount: daysInMonth,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemBuilder: (context, index) {
          bool isSelected = _activeDayIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                _activeDayIndex = index;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 50,
              margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
              decoration: BoxDecoration(
                // DESIGN REMAINS INTACT
                color: isSelected ? kSolar : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(15),
                border: isSelected ? Border.all(color: Colors.white24) : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${index + 1}",
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    DateFormat('E').format(DateTime(_selectedYear, _selectedMonth, index + 1)).toUpperCase(),
                    style: TextStyle(
                      color: isSelected ? Colors.black54 : Colors.white24,
                      fontSize: 8,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kVoid,
      body: Stack(
        children: [
          _buildSolarStarfall(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildMonthSelector(),
                _buildTimeline(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        _sectionTitle("WELLNESS ORBIT"),
                        _build5RingOrbitalCore(),
                        _sectionTitle("7-DAY BIOMETRIC TREND"),
                        _buildAmplifyTrendCard(),
                        _sectionTitle("LIVE TRACK"),
                        _buildUnifiedTrackButton(),
                        const SizedBox(height: 40),
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

  Widget _buildUnifiedTrackButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => _showTrackingSelection(context),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [kSolar.withOpacity(0.2), Colors.black],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kSolar.withOpacity(0.4), width: 1.5),
            boxShadow: [BoxShadow(color: kSolar.withOpacity(0.1), blurRadius: 15, spreadRadius: 2)],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.radar, color: kSolar, size: 22),
              const SizedBox(width: 12),
              const Text("TRACK ACTIVITY", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2)),
            ],
          ),
        ),
      ),
    );
  }

  void _showTrackingSelection(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(icon: const Icon(Icons.close, color: Colors.white38), onPressed: () => Navigator.pop(context)),
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("SELECT MODE", style: TextStyle(color: Colors.white24, letterSpacing: 6, fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 60),
                  _buildTrackerChoice(
                    context,
                    label: "MEDITATE",
                    icon: Icons.self_improvement,
                    color: Colors.orangeAccent,
                    onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MeditationTimerPage(onSessionComplete: _updateMeditationLog))),
                  ),
                  const SizedBox(height: 30),
                  _buildTrackerChoice(
                    context,
                    label: "BREATHE",
                    icon: Icons.air,
                    color: kCyber,
                    onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => BreathingExercisePage(onSessionComplete: _updateMeditationLog))),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrackerChoice(BuildContext context, {required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 25),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(height: 15),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2)),
          ],
        ),
      ),
    );
  }

  Widget _buildSolarStarfall() {
    return AnimatedBuilder(
      animation: _starController,
      builder: (context, child) => CustomPaint(
        size: Size.infinite,
        painter: _SolarStarPainter(_starController.value, [kSolar, kGold, Colors.orangeAccent]),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: Icon(Icons.arrow_back_ios, color: kSolar, size: 18), onPressed: () {Navigator.of(context).pop();}),
          Text("MENTAL WELL BEING ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 4, fontSize: 16)),
          Row(children: [
            _topBtn("SCRIBBLE", kSolar, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScribblePage()))),
            const SizedBox(width: 8),
            _topBtn("ARCADE", kGold, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GameArcadePage()))),
          ])
        ],
      ),
    );
  }

  Widget _topBtn(String t, Color c, VoidCallback a) => GestureDetector(
    onTap: a,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(border: Border.all(color: c), borderRadius: BorderRadius.circular(4)),
      child: Text(t, style: TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.bold)),
    ),
  );

  Widget _sectionTitle(String t) => Container(
    width: double.infinity,
    padding: const EdgeInsets.only(left: 20, top: 10, bottom: 5),
    child: Text(t, style: TextStyle(color: kSolar.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 3)),
  );

  Widget _build5RingOrbitalCore() {
    if (_isLoading) return const SizedBox(height: 320, child: Center(child: CircularProgressIndicator()));

    final String selectedDateStr = DateFormat('yyyy-MM-dd').format(
        DateTime(_selectedYear, _selectedMonth, _activeDayIndex + 1)
    );
    final dayLog = _logs.firstWhere((l) => l['log_date'] == selectedDateStr, orElse: () => {});

    String getVal(String key, [String unit = ""]) {
      if (dayLog.isEmpty || dayLog[key] == null) return "--";
      return unit.isEmpty ? "${dayLog[key]}" : "${dayLog[key]} $unit";
    }

    const double tilt = 0.3;

    // REDUCED WIDTH: Radius increments adjusted to stay within 360-380dp screens
    final List<Map<String, dynamic>> planetConfigs = [
      {'rx': 60.0,  'c': kSolar, 'i': Icons.bed, 'l': "SLEEP", 'v': getVal('sleep_hours', 'HR'), 'off': 0.0},
      {'rx': 95.0,  'c': Colors.orange, 'i': Icons.self_improvement, 'l': "ZEN", 'v': getVal('meditation_min', 'MIN'), 'off': 1.5},
      {'rx': 130.0, 'c': kCyber, 'i': Icons.music_note, 'l': "SONIC", 'v': getVal('music_min', 'MIN'), 'off': 3.0},
      {'rx': 165.0, 'c': kGold, 'i': Icons.mood, 'l': "MOOD", 'v': getVal('happiness_mood'), 'off': 4.5},
      {'rx': 195.0, 'c': Colors.orangeAccent, 'i': Icons.military_tech, 'l': "HOBBY", 'v': getVal('hobby_level'), 'off': 6.0},
    ];

    return SizedBox(
      height: 150,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _rotationController,
        builder: (context, child) {
          List<Widget> backElements = [];
          List<Widget> frontElements = [];

          for (var p in planetConfigs) {
            double angle = _rotationController.value * 2 * math.pi + p['off'];
            double x = math.cos(angle) * p['rx'];
            double y = math.sin(angle) * p['rx'] * tilt;
            double depth = math.sin(angle);

            Widget planetWidget = Transform.translate(
              offset: Offset(x, y),
              child: _buildPlanetWidget(p['c'], p['i'], p['l'], p['v'], depth),
            );

            if (depth < 0) backElements.add(planetWidget);
            else frontElements.add(planetWidget);
          }

          return Stack(
            alignment: Alignment.center,
            children: [
              for (var p in planetConfigs)
                _buildRingPath(p['rx'], p['rx'] * tilt, p['c']),

              ...backElements,
              _buildSunWidget(), // Now uses Orange/Yellow/Red
              ...frontElements,
            ],
          );
        },
      ),
    );
  }

  Widget _buildRingPath(double rx, double ry, Color c) {
    return Container(
      width: rx * 2,
      height: ry * 2,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.elliptical(rx, ry)),
        border: Border.all(color: c.withOpacity(0.12), width: 1.0),
      ),
    );
  }

  Widget _buildSunWidget() {
    return AnimatedBuilder(
      animation: _starController,
      builder: (context, child) => Container(
        width: 60, height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [
              Colors.yellowAccent, // Yellow Core
              Colors.orange,       // Orange Middle
              Colors.redAccent,    // Red Outer
            ],
            stops: [0.0, 0.5, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.5 * _starController.value),
              blurRadius: 35,
              spreadRadius: 8 * _starController.value,
            ),
            BoxShadow(
              color: Colors.orange.withOpacity(0.4),
              blurRadius: 15,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanetWidget(Color c, IconData icon, String label, String value, double depth) {
    double scale = 0.8 + (depth + 1) / 2 * 0.5; // Scale from 0.8x to 1.3x
    double opacity = 0.4 + (depth + 1) / 2 * 0.6; // Fade to 40% when at back

    return Center( // Ensures the translate anchor is the icon center
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: opacity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: TextStyle(color: c, fontSize: 7, fontWeight: FontWeight.w900, letterSpacing: 1)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                  border: Border.all(color: c, width: 2),
                  boxShadow: [BoxShadow(color: c.withOpacity(0.3), blurRadius: 10 * scale)],
                ),
                child: Icon(icon, color: c, size: 12),
              ),
              const SizedBox(height: 4),
              Text(value.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmplifyTrendCard() {


    final String selectedDateStr = DateFormat('yyyy-MM-dd').format(
        DateTime(_selectedYear, _selectedMonth, _activeDayIndex + 1)
    );

    final dayLog = _logs.firstWhere(
          (l) => l['log_date'] == selectedDateStr,
      orElse: () => {},
    );

    final Map<String, dynamic> config = {
      'SLEEP': {'key': 'sleep_hours', 'target': _targetSleep, 'unit': 'HR', 'icon': Icons.bed, 'color': kSolar},
      'ZEN': {'key': 'meditation_min', 'target': 20.0, 'unit': 'MIN', 'color': Colors.orangeAccent, 'icon': Icons.self_improvement},
      'SONIC': {'key': 'music_min', 'target': 30.0, 'unit': 'MIN', 'color': kCyber, 'icon': Icons.music_note},
      'MOOD': {'key': 'happiness_mood', 'target': 'Happy', 'unit': '', 'color': kGold, 'icon': Icons.mood},
      'HOBBY': {'key': 'hobby_level', 'target': 'Talented', 'unit': '', 'color': Colors.orange, 'icon': Icons.military_tech},
    }[_activeMetric]!;

    final Color accentColor = config['color'] as Color;
    final bool isMissingData = dayLog.isEmpty || dayLog[config['key']] == null;

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFB33F10),
            Color(0xFF000000),
            Color(0xFF000000),
            Color(0xFFE68A00),
          ],
          stops: [0.0, 0.25, 0.75, 1.0],
        ),
        border: Border.all(color: const Color(0xFFFFB347).withOpacity(0.25), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              top: -40, left: -40,
              child: Container(
                width: 150, height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [const Color(0xFFB33F10).withOpacity(0.15), Colors.transparent]),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. Metric Selection Row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['SLEEP', 'ZEN', 'SONIC', 'MOOD', 'HOBBY'].map((m) {
                        bool isSel = _activeMetric == m;
                        Color btnCol = (m == 'SLEEP' ? kSolar : m == 'ZEN' ? Colors.orangeAccent : m == 'SONIC' ? kCyber : m == 'MOOD' ? kGold : Colors.orange);
                        return GestureDetector(
                          onTap: () => setState(() => _activeMetric = m),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8, bottom: 16),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSel ? btnCol.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                              border: Border.all(color: isSel ? btnCol : Colors.white10),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(m, style: TextStyle(color: isSel ? btnCol : Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // 2. Split Section: Data Left / Thinking Cloud Right
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // LEFT COLUMN: Metric Info & Value
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(config['icon'] as IconData, color: accentColor, size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  _activeMetric,
                                  style: TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                                ),
                                const SizedBox(width: 4),
                                Text("| Enter Log ", style: TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.w900)),
                                AnimatedBuilder(
                                  animation: _starController,
                                  builder: (context, child) {
                                    double fastPulse = (sin(_starController.value * 8 * pi) + 1) / 2;
                                    bool shouldPulse = isMissingData && _isEditable();
                                    return GestureDetector(
                                        onTap: _isEditable() ? () => _showEditLogDialog(selectedDateStr) : null,                                    child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: accentColor.withOpacity(shouldPulse ? 0.1 + (fastPulse * 0.4) : 0.1),
                                          border: Border.all(color: shouldPulse ? accentColor.withOpacity(fastPulse) : accentColor.withOpacity(0.2)),
                                          boxShadow: [
                                            if (shouldPulse) BoxShadow(color: accentColor.withOpacity(0.6 * fastPulse), blurRadius: 10 * fastPulse)
                                          ],
                                        ),
                                        child: const Icon(Icons.edit_square, size: 12, color: Colors.white),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  val(config['key'] as String, config['unit'] as String).toUpperCase(),
                                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(width: 4),
                                if (!isMissingData) ...[
                                  const Icon(Icons.check_circle, color: Colors.green, size: 17),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "GOAL: ${config['target']} ${config['unit']}",
                              style: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),

                      // RIGHT COLUMN: The Thinking Cloud Insight
                      Expanded(
                        flex: 5,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: _getMetricInsight(dayLog),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // 5. GRAPH AREA
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(16)),
                    child: SizedBox(
                      height: 150,
                      child: CustomPaint(
                        size: Size(MediaQuery.of(context).size.width - 60, 120),
                        painter: MetricLinePainter(
                          data: _getGraphData(),
                          metricKey: config['key'] as String,
                          target: config['target'],
                          lineColor: accentColor,
                        ),
                      ),
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

  Widget _miniQ(IconData icon, TextEditingController c, String q, Color col) => Container(
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.03),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: col.withOpacity(0.15)),
    ),
    child: TextFormField(
      controller: c,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
        prefixIcon: Icon(icon, color: col, size: 18),
        labelText: q,
        labelStyle: TextStyle(color: col.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.bold),
        border: InputBorder.none, // Removes the default line
        focusedBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
      ),
    ),
  );

  Widget _miniDrop(IconData icon, String q, String v, List<String> i, Color col, ValueChanged<String?> onCh) => Container(
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.03),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: col.withOpacity(0.15)),
    ),
    child: DropdownButtonFormField<String>(
      value: v,
      dropdownColor: const Color(0xFF1A1A1A), // Deep obsidian dropdown menu
      iconEnabledColor: col,
      items: i.map((e) => DropdownMenuItem(
          value: e,
          child: Text(e.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))
      )).toList(),
      onChanged: onCh,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        prefixIcon: Icon(icon, color: col, size: 16),
        labelText: q,
        labelStyle: TextStyle(color: col.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
        border: InputBorder.none,
        focusedBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
      ),
    ),
  );
}

// --- ENHANCED SERENE MEDITATION PAGE ---

class MeditationTimerPage extends StatefulWidget {
  final Function(int) onSessionComplete;
  const MeditationTimerPage({super.key, required this.onSessionComplete});

  @override
  State<MeditationTimerPage> createState() => _MeditationTimerPageState();
}

class _MeditationTimerPageState extends State<MeditationTimerPage> with TickerProviderStateMixin {
  Timer? _timer;
  int _seconds = 0;
  bool _isActive = false;
  late AnimationController _glowController;
  late AudioPlayer _bgMusicPlayer;

  @override
  void initState() {
    super.initState();
    _bgMusicPlayer = AudioPlayer();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  void _manageMusic(bool play) async {
    try {
      if (play) {
        await _bgMusicPlayer.setReleaseMode(ReleaseMode.loop);
        await _bgMusicPlayer.setVolume(0.4);
        await _bgMusicPlayer.play(AssetSource('audio/calm_zen_bg.mp3'));
      } else {
        await _bgMusicPlayer.stop();
      }
    } catch (e) {
      debugPrint("Audio Error: $e");
    }
  }

  void _toggleTimer() {
    if (_isActive) {
      _timer?.cancel();
      _manageMusic(false);
      int finalMins = (_seconds / 60).ceil();
      widget.onSessionComplete(finalMins);
      _showCompletionDialog();
    } else {
      _manageMusic(true);
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        setState(() => _seconds++);
      });
    }
    setState(() => _isActive = !_isActive);
  }

  void _showCompletionDialog() {
    int mins = _seconds ~/ 60;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: Colors.black.withOpacity(0.9),
          shape: RoundedRectangleBorder(
              side: const BorderSide(color: Colors.blueAccent, width: 0.5),
              borderRadius: BorderRadius.circular(20)),
          title: const Text("ZENITH REACHED",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.blueAccent, letterSpacing: 3, fontSize: 16)),
          content: Text(
            "Session complete.\n$mins mins logged to your profile.",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            Center(
              child: TextButton(
                onPressed: () {
                  setState(() => _seconds = 0);
                  Navigator.pop(context);
                },
                child: const Text("CLOSE", style: TextStyle(color: Colors.blueAccent)),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _glowController.dispose();
    _bgMusicPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: AnimatedBuilder(
              animation: _glowController,
              builder: (context, child) => Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.blueAccent.withOpacity(0.12 * _glowController.value),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text("NAMASTE",
                    style: TextStyle(color: Colors.blueAccent, fontSize: 22, letterSpacing: 8, fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                const Text("STILLNESS AWAITS",
                    style: TextStyle(color: Colors.white38, fontSize: 18, letterSpacing: 2)),
                const SizedBox(height: 15),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    "Meditation is the journey from sound to silence, from movement to stillness. Close your eyes, breathe naturally, and find your center.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.6, fontStyle: FontStyle.italic),
                  ),
                ),
                const SizedBox(height: 60),

                // TIMER DISPLAY WITH BACKGROUND IMAGE
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 250,
                      width: 250,
                      child: CircularProgressIndicator(
                        value: _isActive ? null : 1.0,
                        strokeWidth: 1,
                        color: Colors.blueAccent.withOpacity(0.3),
                      ),
                    ),

                    // --- THE SOOTHING IMAGE CONTAINER ---
                    Container(
                      height: 200,
                      width: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: const AssetImage('assets/images/zen_bg.png'), // Path to your image
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            Colors.black.withOpacity(0.6), // Darkens image so text stays readable
                            BlendMode.darken,
                          ),
                        ),
                        border: Border.all(color: Colors.blueAccent.withOpacity(0.1), width: 0.5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "${(_seconds ~/ 60).toString().padLeft(2, '0')}:${(_seconds % 60).toString().padLeft(2, '0')}",
                        style: const TextStyle(color: Colors.white, fontSize: 60, fontWeight: FontWeight.w100),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 80),
                GestureDetector(
                  onTap: _toggleTimer,
                  child: Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _isActive ? Colors.red : Colors.blueAccent),
                      boxShadow: [
                        BoxShadow(
                          color: (_isActive ? Colors.red : Colors.blueAccent).withOpacity(0.2),
                          blurRadius: 20,
                        )
                      ],
                    ),
                    child: Icon(
                      _isActive ? Icons.stop_rounded : Icons.play_arrow_rounded,
                      color: _isActive ? Colors.red : Colors.blueAccent,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("BACK", style: TextStyle(color: Colors.white24, letterSpacing: 2)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BreathingExercisePage extends StatefulWidget {
  // 1. Defined the callback parameter to sync with wellbeing database
  final Function(int)? onSessionComplete;

  // 2. Constructor updated to receive the callback
  const BreathingExercisePage({super.key, this.onSessionComplete});

  @override
  State<BreathingExercisePage> createState() => _BreathingExercisePageState();
}

class _BreathingExercisePageState extends State<BreathingExercisePage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  Timer? _timer;
  int _seconds = 0;
  int _breathCount = 0;
  bool _isActive = false;

  @override
  void initState() {
    super.initState();
    // 5 seconds for Inhale, 5 seconds for Exhale as per your 365 method
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 5));
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reverse();
      } else if (status == AnimationStatus.dismissed && _isActive) {
        setState(() => _breathCount++);
        _controller.forward();
      }
    });
  }

  void _start() {
    setState(() {
      _isActive = true;
      _breathCount = 0;
      _seconds = 0;
      _controller.forward();
      _timer = Timer.periodic(const Duration(seconds: 1), (t) => setState(() => _seconds++));
    });
  }

  void _stop() {
    _timer?.cancel();
    _controller.stop();
    _controller.animateTo(0.5, duration: const Duration(milliseconds: 500));

    // --- DATABASE SYNC LOGIC ADDED HERE ---
    // If the session lasted more than 0 seconds, send minutes to meditation_min column
    if (_seconds > 0) {
      int minutesLogged = (_seconds / 60).ceil();
      if (widget.onSessionComplete != null) {
        widget.onSessionComplete!(minutesLogged);
      }
    }

    _showCongrats();
    setState(() {
      _isActive = false;
    });
  }

  void _showCongrats() {
    String timeStr = "${(_seconds ~/ 60).toString().padLeft(2, '0')}:${(_seconds % 60).toString().padLeft(2, '0')}";
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: Colors.black.withOpacity(0.8),
          shape: RoundedRectangleBorder(
              side: const BorderSide(color: Colors.tealAccent, width: 0.5),
              borderRadius: BorderRadius.circular(20)),
          title: const Text("SESSION COMPLETE",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.tealAccent, letterSpacing: 2, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Time: $timeStr", style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 8),
              Text("Breaths: $_breathCount", style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 16),
              const Text("Your soul feels calm and peaceful.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70)),
            ],
          ),
          actions: [
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("PEACE OUT", style: TextStyle(color: Colors.tealAccent)),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isInhaling = _controller.status == AnimationStatus.forward || _controller.value == 1.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "NAMASTE!",
                  style: TextStyle(color: Colors.tealAccent, fontSize: 27, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Welcome to Pranayama designed for Daily Stress Reduction.\n\n It Uses 365 method (Inhale: 5 sec, Exhale: 5 sec, Total: 6 breathes/min) Often Recommended by Therapists for Calm State of Mind.\n\nDo This at least 3 times a Day for 5 minutes.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.timer_outlined, color: Colors.tealAccent.withOpacity(0.5), size: 16),
                    const SizedBox(width: 5),
                    Text(
                      "Timer ${(_seconds ~/ 60).toString().padLeft(2, '0')}:${(_seconds % 60).toString().padLeft(2, '0')}",
                      style: const TextStyle(color: Colors.tealAccent, fontSize: 24, fontFamily: 'monospace'),
                    ),
                    const SizedBox(width: 20),
                    Icon(Icons.air, color: Colors.tealAccent.withOpacity(0.5), size: 16),
                    const SizedBox(width: 5),
                    Text(
                      "Breath: $_breathCount",
                      style: const TextStyle(color: Colors.tealAccent, fontSize: 24, fontFamily: 'monospace'),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Container(
                      width: 220 * _animation.value,
                      height: 220 * _animation.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.tealAccent.withOpacity(0.2 * _animation.value),
                            blurRadius: 40,
                            spreadRadius: 10,
                          )
                        ],
                        gradient: RadialGradient(
                          colors: [
                            Colors.tealAccent.withOpacity(0.4 * _animation.value),
                            Colors.tealAccent.withOpacity(0.0),
                          ],
                        ),
                        border: Border.all(color: Colors.tealAccent.withOpacity(0.3), width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          _isActive ? (isInhaling ? "INHALE" : "EXHALE") : "READY",
                          style: const TextStyle(color: Colors.white, letterSpacing: 4, fontWeight: FontWeight.w300),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 60),

                GestureDetector(
                  onTap: _isActive ? _stop : _start,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isActive ? Colors.red.withOpacity(0.1) : Colors.tealAccent.withOpacity(0.1),
                      border: Border.all(color: _isActive ? Colors.red : Colors.tealAccent, width: 2),
                    ),
                    child: Icon(
                      _isActive ? Icons.stop_rounded : Icons.play_arrow_rounded,
                      color: _isActive ? Colors.red : Colors.tealAccent,
                      size: 40,
                    ),
                  ),
                ),

                const SizedBox(height: 30),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("EXIT SESSION", style: TextStyle(color: Colors.white24, letterSpacing: 2, fontSize: 12)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SolarStarPainter extends CustomPainter {
  final double progress; final List<Color> colors;
  _SolarStarPainter(this.progress, this.colors);
  @override
  void paint(Canvas canvas, Size size) {
    final r = math.Random(42);
    for (int i = 0; i < 60; i++) {
      final p = Paint()..color = colors[r.nextInt(colors.length)].withOpacity(r.nextDouble());
      double x = r.nextDouble() * size.width;
      double y = ((r.nextDouble() * size.height) + (progress * size.height)) % size.height;
      canvas.drawCircle(Offset(x, y), r.nextDouble() * 2, p);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

// --- SCRIBBLE PAGE ---
class ScribblePage extends StatefulWidget {
  const ScribblePage({super.key});
  @override
  State<ScribblePage> createState() => _ScribblePageState();
}

class _ScribblePageState extends State<ScribblePage> {
  List<Offset?> _points = [];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.transparent, title: const Text("Scribble: Stress Buster", style: TextStyle(color: Colors.orange))),
      body: GestureDetector(
        onPanUpdate: (d) => setState(() => _points.add(d.localPosition)),
        onPanEnd: (d) => setState(() => _points.add(null)),
        child: CustomPaint(painter: _ScribblePainter(_points), size: Size.infinite),
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => setState(() => _points = []), backgroundColor: Colors.yellow, child: const Icon(Icons.restart_alt)),
    );
  }
}

class _ScribblePainter extends CustomPainter {
  final List<Offset?> points;
  _ScribblePainter(this.points);
  @override
  void paint(Canvas canvas, Size size) {
    Paint p = Paint()..color = Colors.orange..strokeWidth = 3.0..strokeCap = StrokeCap.round;
    for (int i = 0; i < points.length - 1; i++) { if (points[i] != null && points[i+1] != null) canvas.drawLine(points[i]!, points[i+1]!, p); }
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

// --- ARCADE PAGE ---
class GameArcadePage extends StatelessWidget {
  const GameArcadePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.transparent, title: const Text("AURA ARCADE", style: TextStyle(color: Colors.amber))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          ArcadeTile(title: "METEOR DODGER", game: MeteorGame(), color: Colors.red),
          ArcadeTile(title: "FOCUS TAPPER", game: TapperGame(), color: Colors.orange),

        ],
      ),
    );
  }
}

class ArcadeTile extends StatelessWidget {
  final String title; final Widget game; final Color color;
  const ArcadeTile({super.key, required this.title, required this.game, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 30),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(border: Border.all(color: color.withOpacity(0.5)), borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, letterSpacing: 2)),
        const SizedBox(height: 20),
        SizedBox(height: 200, child: game),
      ]),
    );
  }
}

// --- 1. METEOR DODGER ---
class MeteorGame extends StatefulWidget {
  const MeteorGame({super.key});
  @override
  State<MeteorGame> createState() => _MeteorGameState();
}

class _MeteorGameState extends State<MeteorGame> {
  double playerX = 0;
  double meteorY = -1;
  double meteorX = 0;
  int score = 0;
  bool isGameOver = false;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  void _startGame() {
    isGameOver = false;
    score = 0;
    meteorY = -1;
    timer = Timer.periodic(const Duration(milliseconds: 50), (t) {
      setState(() {
        if (!isGameOver) {
          meteorY += 0.08;
          if (meteorY > 1.2) {
            meteorY = -1;
            meteorX = (math.Random().nextDouble() * 2) - 1;
            score++;
          }
          if (meteorY > 0.8 && (meteorX - playerX).abs() < 0.3) {
            isGameOver = true;
            timer?.cancel();
          }
        }
      });
    });
  }

  @override
  void dispose() { timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (d) { if (!isGameOver) setState(() => playerX = (playerX + d.delta.dx / 100).clamp(-1, 1)); },
      child: Container(
        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.red.withOpacity(0.3))),
        child: Stack(
          children: [
            Positioned(top: 10, left: 10, child: Text("SCORE: $score", style: const TextStyle(color: Colors.white, fontSize: 10))),
            Align(alignment: Alignment(meteorX, meteorY), child: const Icon(Icons.thunderstorm, color: Colors.orange, size: 30)),
            Align(alignment: Alignment(playerX, 0.9), child: Icon(Icons.rocket_launch, color: isGameOver ? Colors.grey : Colors.red, size: 35)),
            if (isGameOver)
              Container(
                color: Colors.black87,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("CRITICAL FAILURE", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, letterSpacing: 2)),
                      const SizedBox(height: 10),
                      Text("SCORE: $score", style: const TextStyle(color: Colors.white)),
                      const SizedBox(height: 20),
                      TextButton(onPressed: _startGame, style: TextButton.styleFrom(backgroundColor: Colors.red), child: const Text("RESTART DODGE", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// --- 2. FOCUS TAPPER ---
class TapperGame extends StatefulWidget {
  const TapperGame({super.key});
  @override
  State<TapperGame> createState() => _TapperGameState();
}

class _TapperGameState extends State<TapperGame> with SingleTickerProviderStateMixin {
  Offset pos = const Offset(0, 0);
  int score = 0;
  late AnimationController _burstController;

  @override
  void initState() {
    super.initState();
    _burstController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
  }

  void _handleTap() {
    setState(() {
      score++;
      pos = Offset((math.Random().nextDouble() * 2) - 1, (math.Random().nextDouble() * 2) - 1);
    });
    _burstController.reset();
    _burstController.forward();
  }

  @override
  void dispose() { _burstController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(top: 0, child: Text("FOCUS TAPS: $score", style: const TextStyle(color: Colors.orange, fontSize: 10))),
        AnimatedBuilder(
          animation: _burstController,
          builder: (context, child) => CustomPaint(painter: BurstPainter(_burstController.value, pos, Colors.orangeAccent), size: Size.infinite),
        ),
        Align(
          alignment: Alignment(pos.dx, pos.dy),
          child: GestureDetector(
            onTap: _handleTap,
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.orange, boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.6), blurRadius: 15)]),
              child: const Icon(Icons.gps_fixed, color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
    );
  }
}

class BurstPainter extends CustomPainter {
  final double progress; final Offset alignmentPos; final Color color;
  BurstPainter(this.progress, this.alignmentPos, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0 || progress == 1) return;
    final center = Offset((alignmentPos.dx + 1) * size.width / 2, (alignmentPos.dy + 1) * size.height / 2);
    final paint = Paint()..color = color.withOpacity(1 - progress)..strokeWidth = 2;
    for (int i = 0; i < 8; i++) {
      double angle = (i * 45) * math.pi / 180;
      double distStart = progress * 20;
      double distEnd = progress * 50;
      canvas.drawLine(Offset(center.dx + math.cos(angle) * distStart, center.dy + math.sin(angle) * distStart), Offset(center.dx + math.cos(angle) * distEnd, center.dy + math.sin(angle) * distEnd), paint);
    }
  }
  @override
  bool shouldRepaint(BurstPainter old) => true;
}

class HexClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(size.width * 0.1, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width * 0.9, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class NeuralMeshPainter extends CustomPainter {
  final Color color;
  NeuralMeshPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()..color = color..strokeWidth = 1.0;
    double step = 30;
    for (double i = 0; i < size.width; i += step) {
      for (double j = 0; j < size.height; j += step) {
        canvas.drawCircle(Offset(i, j), 1, paint);
        if (i % 60 == 0 && j % 60 == 0) canvas.drawLine(Offset(i, j), Offset(i + 20, j + 20), paint);
      }
    }
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class CyberFrameClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    double cut = 35.0;
    Path path = Path()..moveTo(cut, 0)..lineTo(size.width, 0)..lineTo(size.width, size.height - cut)..lineTo(size.width - cut, size.height)..lineTo(0, size.height)..lineTo(0, cut)..close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class MetricLinePainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final String metricKey;
  final dynamic target;
  final Color lineColor;

  MetricLinePainter({
    required this.data,
    required this.metricKey,
    required this.target,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    // Use total width divided by 6 segments (for 7 points)
    final double widthStep = size.width / 6;
    const double vPadding = 30;
    double chartHeight = size.height - (vPadding * 2);

    // Scaling Logic
    double targetVal = _normalize(target);
    double maxVal = targetVal;
    for (var d in data) {
      double v = _normalize(d[metricKey]);
      if (v > maxVal) maxVal = v;
    }
    if (maxVal == 0) maxVal = 1;

    final axisPaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // --- 1. DRAW AXES ---
    canvas.drawLine(Offset(0, vPadding / 2), Offset(0, size.height - vPadding + 5), axisPaint);
    canvas.drawLine(Offset(-5, size.height - vPadding + 5), Offset(size.width, size.height - vPadding + 5), axisPaint);

    // --- 2. DRAW Y-AXIS UNIT INTERVALS (NEW) ---
    int intervals = 5;
    for (int i = 0; i <= intervals; i++) {
      double pct = i / intervals;
      double y = size.height - vPadding - (pct * chartHeight);

      // Draw small tick mark
      canvas.drawLine(Offset(-3, y), Offset(0, y), axisPaint);

      // Draw Interval Label
      String intervalText = _getIntervalLabel(pct * maxVal);
      _drawText(canvas, Offset(-15, y - 5), intervalText, Colors.white38, 7);
    }

    // --- ADDED: DRAW DOTTED TARGET LINE ---
    final double targetY = size.height - vPadding - (targetVal / maxVal * chartHeight);
    final Paint targetPaint = Paint()
      ..color = Colors.green.withOpacity(0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    double dashWidth = 5;
    double dashSpace = 5;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, targetY),
        Offset(startX + dashWidth, targetY),
        targetPaint,
      );
      startX += dashWidth + dashSpace;
    }
    // Optional label for the target line
    _drawText(canvas, Offset(25, targetY - 10), "TARGET", Colors.green, 8);

    List<Offset> points = [];
    for (int i = 0; i < data.length; i++) {
      double val = _normalize(data[i][metricKey]);
      double x = i * widthStep;
      double y = size.height - vPadding - (val / maxVal * chartHeight);
      points.add(Offset(x, y));
    }

    // 1. Draw the Trend Line
    final path = Path();
    for (int i = 0; i < points.length; i++) {
      if (i == 0) path.moveTo(points[i].dx, points[i].dy);
      else path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(
        path,
        Paint()
          ..color = lineColor
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke
    );

    // 2. Draw Data Points and the Corrected Labels
    for (int i = 0; i < data.length; i++) {
      bool isPlaceholder = data[i]['is_placeholder'] == true;
      double valRaw = _normalize(data[i][metricKey]);

      // Color coding based on target
      Color dotColor = isPlaceholder
          ? Colors.white10
          : (valRaw >= targetVal ? Colors.green : Colors.red);

      canvas.drawCircle(points[i], 4, Paint()..color = dotColor);

      // Top Label (Value)
      String valLabel = (isPlaceholder || data[i][metricKey] == null)
          ? "--"
          : data[i][metricKey].toString().toUpperCase();
      _drawText(canvas, points[i] + const Offset(0, -18), valLabel, dotColor, 10);

      // --- RESTORED BOTTOM LABEL (DATE + 3 LETTER MONTH) ---
      DateTime date = DateTime.parse(data[i]['log_date']);
      // Format: "12 MON" (Day + Short Month)
      String dateLabel = DateFormat('dd MMM').format(date);

      _drawText(
          canvas,
          Offset(points[i].dx, size.height - 10),
          dateLabel,
          Colors.white24,
          10
      );
    }
  }

  // Helper to convert numeric scale back to readable short labels
  String _getIntervalLabel(double value) {
    if (metricKey == 'happiness_mood') {
      if (value >= 4.5) return 'Delighted';
      if (value >= 3.5) return 'Happy';
      if (value >= 2.5) return 'Normal';
      if (value >= 1.5) return 'Sad';
      if (value >= 0.5) return 'Heartbroken';
      return 'Nil';
    }
    if (metricKey == 'hobby_level') {
      if (value >= 4.5) return 'Expert';
      if (value >= 3.5) return 'Talented';
      if (value >= 2.5) return 'Developing';
      if (value >= 1.5) return 'Exploring';
      if (value >= 0.5) return 'Not Started';
      return 'Nil';
    }
    return value.toStringAsFixed(0);
  }

  // Restored Normalize with full mapping for Mood and Hobby Level
  double _normalize(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();

    Map<String, double> scores = {
      'delighted': 5, 'happy': 4, 'normal': 3, 'sad': 2, 'heartbroken': 1,
      'expert': 4, 'talented': 3, 'developing': 2, 'exploring': 1,
    };
    return scores[val.toString().toLowerCase()] ?? 0.0;
  }

  void _drawText(Canvas canvas, Offset offset, String text, Color color, double fontSize) {
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace'
          )
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset - Offset(tp.width / 2, 0));
  }

  @override
  bool shouldRepaint(MetricLinePainter oldDelegate) => true;
}

class ThinkingCloudPainter extends CustomPainter {
  final Color color;
  final double pulse;
  ThinkingCloudPainter({required this.color, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.12 + (pulse * 0.05))
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = color.withOpacity(0.4 + (pulse * 0.4))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    final path = Path();
    final w = size.width;
    final h = size.height;

    // Start at the bottom left area
    path.moveTo(w * 0.15, h * 0.75);

    // RESTORED DESIGN: 8-Point Puffy Structure (now stretched)
    path.arcToPoint(Offset(w * 0.05, h * 0.5), radius: const Radius.circular(20), clockwise: true);
    path.arcToPoint(Offset(w * 0.15, h * 0.15), radius: const Radius.circular(25), clockwise: true);
    path.arcToPoint(Offset(w * 0.5, h * 0.05), radius: const Radius.circular(60), clockwise: true); // STRETCHED TOP
    path.arcToPoint(Offset(w * 0.85, h * 0.15), radius: const Radius.circular(60), clockwise: true); // STRETCHED TOP
    path.arcToPoint(Offset(w * 0.95, h * 0.5), radius: const Radius.circular(25), clockwise: true);
    path.arcToPoint(Offset(w * 0.8, h * 0.85), radius: const Radius.circular(25), clockwise: true);
    path.arcToPoint(Offset(w * 0.4, h * 0.85), radius: const Radius.circular(50), clockwise: true); // STRETCHED BOTTOM

    // THE SHARP TAIL (Protruding outside)
    path.lineTo(w * 0.1, h * 1.0);
    path.lineTo(w * 0.15, h * 0.75);

    path.close();

    canvas.drawShadow(path, color.withOpacity(0.3), 4 + (pulse * 6), true);
    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant ThinkingCloudPainter oldDelegate) =>
      oldDelegate.pulse != pulse || oldDelegate.color != color;
}