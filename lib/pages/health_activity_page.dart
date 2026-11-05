import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'dart:ui' as ui;
import 'dart:math' as math;
import '/features/workout/presentation/workout_screen.dart';
import 'package:confetti/confetti.dart';

class ActivityTrackingPage extends StatefulWidget {
  @override
  _ActivityTrackingPageState createState() => _ActivityTrackingPageState();
}

class _ActivityTrackingPageState extends State<ActivityTrackingPage> with TickerProviderStateMixin {
  final TextEditingController _stepsController = TextEditingController();
  final TextEditingController _gymController = TextEditingController();
  final TextEditingController _yogaController = TextEditingController();
  final TextEditingController _sportsController = TextEditingController();
  final TextEditingController _editController = TextEditingController();
  final TextEditingController _targetEditController = TextEditingController();

  // Inside _ActivityTrackingPageState
  bool _isAddingMore = false; // Tracks if the selection menu is open
  final TextEditingController _dynamicInputController = TextEditingController();
  String? _selectedActivity;

  // Map defining activities for each Pillar
  final Map<String, List<String>> _pillarMap = {
    "EXERCISES": ["Steps", "Skipping", "Cycling", "Stair Climb", "Burpees"],
    "GYM CORE": ["Treadmill", "Squats", "Weight Lifting", "Pushups", "Pullups", "Plank", "Bench Press"],
    "YOGA": ["Surya Namaskar", "Vrikshasana", "Shavasana", "Tadasana", "Pranayama", "Meditation"],
    "SPORTS": ["Football", "Cricket", "Swimming", "Badminton", "Basketball", "Tennis", "Boxing"],
  };

  // Mapping for Background Images exactly from your file logic
  final Map<String, String> _activityBgs = {
    "steps": "assets/steps_bg.png",
    "run_data": "assets/run_bg.png",
    "jog_data": "assets/jog_bg.png",
    "treadmill": "assets/tredmill_bg.png",
    "pushups": "assets/pushups_bg.png",
    "squats": "assets/squats_bg.png",
    "burpees": "assets/gym_bg.png",
    "surya_namaskar": "assets/suryanamaskar_bg.png",
    "vrikshasana": "assets/vrikshasana_bg.png",
    "swimming": "assets/swimming_bg.png",
    "football": "assets/sports_bg.png",
    "cricket": "assets/cricket_bg.png",
  };

  // Mapping for Icons exactly from your file logic
  final Map<String, IconData> _activityIcons = {
    "steps": Icons.directions_walk,
    "run_data": Icons.speed,
    "jog_data": Icons.timer,
    "treadmill": Icons.directions_run,
    "pushups": Icons.upload,
    "squats": Icons.download,
    "burpees": Icons.repeat,
    "surya_namaskar": Icons.wb_sunny,
    "vrikshasana": Icons.park,
    "swimming": Icons.pool,
    "football": Icons.sports_football,
    "cricket": Icons.sports_cricket,
  };

  late PageController _insightPageController;
  final ScrollController _timelineScrollController = ScrollController();

  int _activeDayIndex = DateTime.now().day - 1;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  String _selectedFilter = "Day"; // Options: "Day", "Week", "Month"
  String _activeCategory = "EXERCISES"; // Default section

  bool _showBackToTop = false;
  final ScrollController _mainScrollController = ScrollController(); // Add this

  final DateTime _maxDate = DateTime(DateTime.now().year, DateTime.now().month);
  final DateTime _minDate = DateTime(DateTime.now().year - 1, DateTime.now().month);

  List<Map<String, dynamic>?> _monthData = [];
  bool _isLoading = false;
  late AnimationController _bgAnimationController;

  Map<String, double> _userTargets = {};
  Map<String, dynamic> _userProfile = {};

  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _insightPageController = PageController(initialPage: _activeDayIndex);
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));

    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _fetchMonthData();
    _fetchUserTargets();
    _fetchUserProfile();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToActiveDay();
    });

    _mainScrollController.addListener(() {
      if (_mainScrollController.offset > 300 && !_showBackToTop) {
        setState(() => _showBackToTop = true);
      } else if (_mainScrollController.offset <= 300 && _showBackToTop) {
        setState(() => _showBackToTop = false);
      }
    });
  }

  Future<void> _fetchUserProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final data = await Supabase.instance.client
          .from('profiles')
          .select('nickname, bmi, weight, goal')
          .eq('id', user.id)
          .maybeSingle();

      if (data != null) {
        setState(() => _userProfile = data);
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    }
  }

  Future<void> _fetchUserTargets() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final data = await Supabase.instance.client
          .from('user_targets')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (data != null) {
        setState(() {
          _userTargets = {
            "steps": (data['target_steps'] ?? 8000).toDouble(),
            "gym_min": (data['target_gym_mins'] ?? 0).toDouble(),
            "yoga_min": (data['target_yoga_mins'] ?? 0).toDouble(),
            "sports_min": (data['target_sports_mins'] ?? 0).toDouble(),
            "walk_data": 30.0,
            "run_data": 30.0,
            "jog_data": 30.0,
          };
        });
      }
    } catch (e) {
      debugPrint("Error fetching targets: $e");
    }
  }

  void _scrollToActiveDay() {
    if (_timelineScrollController.hasClients) {
      double screenWidth = MediaQuery.of(context).size.width;
      double targetScroll = (_activeDayIndex * 60.0) - (screenWidth / 2) + 30;
      _timelineScrollController.animateTo(
        targetScroll.clamp(0.0, _timelineScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _stepsController.dispose(); _gymController.dispose();
    _yogaController.dispose(); _sportsController.dispose();
    _editController.dispose(); _insightPageController.dispose();
    _targetEditController.dispose();
    _mainScrollController.dispose();
    _timelineScrollController.dispose();
    _bgAnimationController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _fetchMonthData() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final daysInMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
      final firstDay = DateTime(_selectedYear, _selectedMonth, 1);
      final lastDay = DateTime(_selectedYear, _selectedMonth, daysInMonth);

      final response = await Supabase.instance.client.from('activity_logs').select()
          .eq('user_id', user.id)
          .gte('date', DateFormat('yyyy-MM-dd').format(firstDay))
          .lte('date', DateFormat('yyyy-MM-dd').format(lastDay))
          .order('date', ascending: true);

      List<Map<String, dynamic>?> tempMonthly = List.filled(daysInMonth, null);
      for (var record in (response as List)) {
        DateTime recordDate = DateTime.parse(record['date']);
        if (recordDate.month == _selectedMonth && recordDate.year == _selectedYear) {
          tempMonthly[recordDate.day - 1] = record;
        }
      }

      setState(() {
        _monthData = tempMonthly;
        _isLoading = false;

        // Update the logical index
        if (_selectedMonth == DateTime.now().month && _selectedYear == DateTime.now().year) {
          _activeDayIndex = DateTime.now().day - 1;
        } else {
          _activeDayIndex = 0;
        }
      });

      // CRITICAL: Wait for the build to finish before moving controllers
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_insightPageController.hasClients) {
          _insightPageController.jumpToPage(_activeDayIndex);
        }
        _scrollToActiveDay();
      });

    } catch (e) {
      debugPrint(e.toString());
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateMetric(String key, dynamic val, int idx) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime(_selectedYear, _selectedMonth, idx + 1));
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final existing = _monthData[idx] ?? {};
      await Supabase.instance.client.from('activity_logs').upsert({
        'user_id': user!.id,
        'date': dateStr,
        ...existing,
        key: val,
      }, onConflict: 'user_id,date');
      _fetchMonthData();
    } catch (e) { debugPrint(e.toString()); }
  }
  // ─────────────────────────────────────────────────────────────
  // JSON sub-activity update (pushups, squats, surya_namaskar, ...)
  // ─────────────────────────────────────────────────────────────
  Future<void> _updateSubActivity({
    required String jsonColumn,
    required String subKey,
    required dynamic newValue,
    required int dayIndex,
  }) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(
      DateTime(_selectedYear, _selectedMonth, dayIndex + 1),
    );

    try {
      final user = Supabase.instance.client.auth.currentUser;
      final existing = _monthData[dayIndex] ?? {};

      Map<String, dynamic> updatedJson = Map.from(existing[jsonColumn] ?? {});
      updatedJson[subKey] = newValue;

      await Supabase.instance.client.from('activity_logs').upsert({
        'user_id': user!.id,
        'date': dateStr,
        jsonColumn: updatedJson,
      }, onConflict: 'user_id,date');

      _fetchMonthData();
    } catch (e) {
      debugPrint("Sub-update error: $e");
    }
  }

  Future<void> _submitData() async {
    // 1. Basic validation to prevent null selection errors
    if (_selectedActivity == null || _dynamicInputController.text.isEmpty) return;

    setState(() => _isLoading = true);
    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      int inputValue = int.tryParse(_dynamicInputController.text) ?? 0;
      String mainCol = "";
      String jsonCol = "";

      // 2. Mapping UI Pillars to Database Columns
      if (_activeCategory == "EXERCISES") {
        mainCol = (_selectedActivity == "Steps") ? "steps" : "gym_min";
        jsonCol = "exercises_data";
      } else if (_activeCategory == "GYM CORE") {
        mainCol = "gym_min";
        jsonCol = "gym_data";
      } else if (_activeCategory == "YOGA") {
        mainCol = "yoga_min";
        jsonCol = "yoga_data";
      } else if (_activeCategory == "SPORTS") {
        mainCol = "sports_min";
        jsonCol = "sports_data";
      }

      // 3. Fix Null Receiver Error: Safely access existing data
      final existingData = (_monthData.isNotEmpty && _activeDayIndex < _monthData.length)
          ? (_monthData[_activeDayIndex] ?? {})
          : {};

      // 4. Update JSON data (Incrementing value)
      Map<String, dynamic> currentJson = Map<String, dynamic>.from(existingData[jsonCol] ?? {});
      String activityKey = _selectedActivity!.toLowerCase().replaceAll(" ", "_");
      currentJson[activityKey] = (currentJson[activityKey] ?? 0) + inputValue;

      // 5. Update Main Total Column
      int currentTotal = (existingData[mainCol] ?? 0);
      int newTotal = currentTotal + inputValue;

      // 6. Push to Supabase with Conflict Resolution
      await Supabase.instance.client.from('activity_logs').upsert({
        'user_id': user.id,
        'date': dateStr,
        mainCol: newTotal,
        jsonCol: currentJson,
      }, onConflict: 'user_id,date');

      // 7. GOAL CELEBRATION TRIGGER
      // Accessing _userTargets with null-safety
      double targetValue = (_userTargets != null && _userTargets!.containsKey(mainCol))
          ? (_userTargets![mainCol]?.toDouble() ?? 0.0)
          : 0.0;

      if (currentTotal < targetValue && newTotal >= targetValue && targetValue > 0) {
        _showGoalCelebration(_selectedActivity!);
      }

      // 8. Reset UI and Refresh View
      _dynamicInputController.clear();
      setState(() {
        _selectedActivity = null;
        _isAddingMore = false;
      });

      await _fetchMonthData();

    } catch (e) {
      debugPrint("Submit Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _navigateToWorkout(String type) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => WorkoutScreen(activityType: type))).then((_) => _fetchMonthData());
  }

  void _changeMonth(int delta) {
    DateTime target = DateTime(_selectedYear, _selectedMonth + delta);
    if (target.isBefore(_minDate) || target.isAfter(_maxDate)) return;
    setState(() {
      _selectedMonth = target.month;
      _selectedYear = target.year;
    });
    _fetchMonthData();
  }

  // Logic to calculate totals based on selection
  Map<String, double> _calculateFilteredTotals() {
    double steps = 0;
    double gym = 0;
    double sports = 0;
    double yoga = 0;

    if (_monthData.isEmpty) {
      return {"steps": 0, "distance": 0, "calories": 0};
    }

    if (_selectedFilter == "Day") {
      final dayData = _monthData[_activeDayIndex];
      steps = (dayData?['steps'] ?? 0).toDouble();
      gym = (dayData?['gym_min'] ?? 0).toDouble();
      sports = (dayData?['sports_min'] ?? 0).toDouble();
      yoga = (dayData?['yoga_min'] ?? 0).toDouble();
    } else if (_selectedFilter == "Week") {
      // Calculate start and end of the current week relative to active day
      int start = math.max(0, _activeDayIndex - 6);
      for (int i = start; i <= _activeDayIndex; i++) {
        steps += (_monthData[i]?['steps'] ?? 0);
        gym += (_monthData[i]?['gym_min'] ?? 0);
        sports += (_monthData[i]?['sports_min'] ?? 0);
        yoga += (_monthData[i]?['yoga_min'] ?? 0);
      }
    } else {
      // Month total
      for (var day in _monthData) {
        steps += (day?['steps'] ?? 0);
        gym += (day?['gym_min'] ?? 0);
        sports += (day?['sports_min'] ?? 0);
        yoga += (day?['yoga_min'] ?? 0);
      }
    }

    // Formulas matching your calorie logic
    double distance = steps * 0.0008; // Roughly 0.8 meters per step -> km
    double calories = (steps * 0.04) + (gym * 6.0) + (yoga * 3.0) + (sports * 8.0);

    return {"steps": steps, "distance": distance, "calories": calories};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080400),
      // Position both buttons on the right side
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 1. SCROLL TO TOP BUTTON (Appears on top)
          if (_showBackToTop)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FloatingActionButton(
                mini: true,
                heroTag: "btn_scroll_top", // Unique tag to prevent hero errors
                backgroundColor: Colors.black.withOpacity(0.7),
                onPressed: () {
                  _mainScrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeInOutCubic,
                  );
                },
                child: const Icon(Icons.arrow_upward, color: Colors.orangeAccent),
              ),
            ),

          // 2. TODAY BUTTON
          if (_activeDayIndex != (DateTime.now().day - 1) || _selectedMonth != DateTime.now().month)
            FloatingActionButton.extended(
              heroTag: "btn_today", // Unique tag
              backgroundColor: Colors.orangeAccent,
              onPressed: () {
                setState(() {
                  _selectedMonth = DateTime.now().month;
                  _selectedYear = DateTime.now().year;
                  _activeDayIndex = DateTime.now().day - 1;
                });
                _fetchMonthData();
                if (_insightPageController.hasClients) {
                  _insightPageController.animateToPage(
                    _activeDayIndex,
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutBack,
                  );
                }
              },
              icon: const Icon(Icons.today, color: Colors.black),
              label: const Text("TODAY",
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildMonthSelector(),
                _buildTimeline(),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _mainScrollController, // Attached main controller
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        _buildTopSummarySection(),
                        const SizedBox(height: 10),
                        _buildInsightPager(),
                        const SizedBox(height: 10),
                        const Divider(color: Colors.white10, thickness: 1, indent: 20, endIndent: 20),
                        const SizedBox(height: 10),
                        _buildHistoryFilterSection(),

                        const SizedBox(height: 20),
                        _buildControlPanel(),
                        const SizedBox(height: 20),
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

  Widget _buildTopSummarySection() {
    if (_monthData.isEmpty || _activeDayIndex >= _monthData.length) {
      return const SizedBox(
          height: 220,
          child: Center(child: CircularProgressIndicator(color: Colors.orangeAccent))
      );
    }
    final data = _monthData[_activeDayIndex] ?? {};
    final Map<String, double> currentValues = {
      "steps": (data['steps'] ?? 0).toDouble(),
      "gym_min": (data['gym_min'] ?? 0).toDouble(),
      "sports_min": (data['sports_min'] ?? 0).toDouble(),
      "yoga_min": (data['yoga_min'] ?? 0).toDouble(),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.orangeAccent.withOpacity(0.05), Colors.transparent]
          )
      ),
      child: Row(
        children: [
          const SizedBox(width: 20),
          // Left: Expanded Spiral Rings
          SizedBox(
            height: 220, // Increased Size
            width: 220,
            child: AnimatedBuilder(
                animation: _bgAnimationController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: SpiralRingPainter(
                        values: currentValues,
                        targets: _userTargets,
                        animationValue: _bgAnimationController.value // Link glow to existing animation
                    ),
                  );
                }
            ),
          ),
          const SizedBox(width: 50),
          // Right: Profile Information
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userProfile['nickname']?.toString().toUpperCase() ?? "AGENT",
                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -1),
                ),
                const SizedBox(height: 5),
                Container(height: 3, width: 40, color: Colors.cyanAccent),
                const SizedBox(height: 15),
                _profileMetricTile("BMI", "${_userProfile['bmi'] ?? '--'}", Icons.man),
                _profileMetricTile("WEIGHT", "${_userProfile['weight'] ?? '--'} KG", Icons.monitor_weight),
                _profileMetricTile("GOAL", "${_userProfile['goal'] ?? 'MAINTAIN'}", Icons.flag),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileMetricTile(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.white24, size: 14),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
              Text(value, style: const TextStyle(color: Colors.orangeAccent, fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  // --- INSIGHT PAGER WIDGET (REPLACES CONTROL PANEL LOGIC) ---
  Widget _buildInsightPager() {
    if (_monthData.isEmpty) {
      return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
    }

    bool _isEditable() {
      final DateTime selectedDate = DateTime(_selectedYear, _selectedMonth, _activeDayIndex + 1);
      final DateTime now = DateTime.now();
      final DateTime today = DateTime(now.year, now.month, now.day);
      final DateTime yesterday = today.subtract(const Duration(days: 1));

      return selectedDate.isAtSameMomentAs(today) ||
          selectedDate.isAtSameMomentAs(yesterday);
    }

    final data = (_activeDayIndex < _monthData.length) ? _monthData[_activeDayIndex] : null;
    final prevData = (_activeDayIndex > 0) ? _monthData[_activeDayIndex - 1] : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Remark uses both data and prevData → perfect place to use them
          _buildRemark(data, prevData),
          const SizedBox(height: 20),

          // Category selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryBtn("EXERCISES", Icons.bolt, Colors.cyanAccent),
                _buildCategoryBtn("GYM CORE", Icons.fitness_center, Colors.orange),
                _buildCategoryBtn("YOGA", Icons.self_improvement, Colors.orangeAccent),
                _buildCategoryBtn("SPORTS", Icons.sports_soccer, Colors.yellowAccent),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // All cards
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (_activeCategory == "EXERCISES") ...[
                _bentoCard("STEPS", "${data?['steps'] ?? 0}", _activityIcons["steps"]!, Colors.yellow, 0.94, "steps", _activeDayIndex, _activityBgs["steps"]!),
                if (data?['run_data'] != null)
                  _bentoCard("RUN GPS", "${data!['run_data']['time'] ?? 0} min", _activityIcons["run_data"]!, Colors.yellow, 0.94, "run_data", _activeDayIndex, _activityBgs["run_data"]!, isJson: true, disableEdit: true),
                if (data?['jog_data'] != null)
                  _bentoCard("JOG GPS", "${data!['jog_data']['time'] ?? 0} min", _activityIcons["jog_data"]!, Colors.orangeAccent, 0.94, "jog_data", _activeDayIndex, _activityBgs["jog_data"]!, isJson: true, disableEdit: true),
                ..._buildDynamicLoggedCards(data?['exercises_data'], ["steps"], _activeDayIndex, Colors.cyanAccent, "exercises_data"),
              ],

              if (_activeCategory == "GYM CORE") ...[
                _bentoCard("TREADMILL", "${data?['gym_data']?['treadmill'] ?? 0} MINS", _activityIcons["treadmill"]!, Colors.orange, 0.94, "gym_min", _activeDayIndex, _activityBgs["treadmill"]!, jsonColumn: "gym_data", subKey: "treadmill"),
                _bentoCard("BURPEES", "${data?['gym_data']?['burpees'] ?? 0} REPS", _activityIcons["burpees"]!, Colors.orange, 0.94, "gym_min", _activeDayIndex, _activityBgs["burpees"]!, jsonColumn: "gym_data", subKey: "burpees"),
                _bentoCard("PUSHUPS", "${data?['gym_data']?['pushups'] ?? 0} REPS", _activityIcons["pushups"]!, Colors.orange, 0.94, "gym_min", _activeDayIndex, _activityBgs["pushups"]!, jsonColumn: "gym_data", subKey: "pushups"),
                _bentoCard("SQUATS", "${data?['gym_data']?['squats'] ?? 0} REPS", _activityIcons["squats"]!, Colors.orange, 0.94, "gym_min", _activeDayIndex, _activityBgs["squats"]!, jsonColumn: "gym_data", subKey: "squats"),
                ..._buildDynamicLoggedCards(data?['gym_data'], ["treadmill", "burpees", "pushups", "squats"], _activeDayIndex, Colors.orange, "gym_data"),
              ],

              if (_activeCategory == "YOGA") ...[
                _bentoCard("SURYA NAMASKAR", "${data?['yoga_data']?['surya_namaskar'] ?? 0} SETS", _activityIcons["surya_namaskar"]!, Colors.orangeAccent, 0.94, "yoga_min", _activeDayIndex, _activityBgs["surya_namaskar"]!, jsonColumn: "yoga_data", subKey: "surya_namaskar"),
                _bentoCard("VRIKSHASANA", "${data?['yoga_data']?['vrikshasana'] ?? 0} MINS", _activityIcons["vrikshasana"]!, Colors.orangeAccent, 0.94, "yoga_min", _activeDayIndex, _activityBgs["vrikshasana"]!, jsonColumn: "yoga_data", subKey: "vrikshasana"),
                ..._buildDynamicLoggedCards(data?['yoga_data'], ["surya_namaskar", "vrikshasana"], _activeDayIndex, Colors.orangeAccent, "yoga_data"),
              ],

              if (_activeCategory == "SPORTS") ...[
                _bentoCard("FOOTBALL", "${data?['sports_data']?['football'] ?? 0} MINS", _activityIcons["football"]!, Colors.yellowAccent, 0.94, "sports_min", _activeDayIndex, _activityBgs["football"] ?? "assets/sports_bg.png", jsonColumn: "sports_data", subKey: "football"),
                _bentoCard("CRICKET", "${data?['sports_data']?['cricket'] ?? 0} MINS", _activityIcons["cricket"]!, Colors.yellowAccent, 0.94, "sports_min", _activeDayIndex, _activityBgs["cricket"] ?? "assets/sports_bg.png", jsonColumn: "sports_data", subKey: "cricket"),
                _bentoCard("SWIMMING", "${data?['sports_data']?['swimming'] ?? 0} MINS", _activityIcons["swimming"]!, Colors.yellowAccent, 0.94, "sports_min", _activeDayIndex, _activityBgs["swimming"] ?? "assets/sports_bg.png", jsonColumn: "sports_data", subKey: "swimming"),
                ..._buildDynamicLoggedCards(data?['sports_data'], ["football", "cricket", "swimming"], _activeDayIndex, Colors.yellowAccent, "sports_data"),
              ],
            ],
          ),

          const SizedBox(height: 16),

          // ADD MORE – only for editable days (today + yesterday)
          if (_isEditable()) ...[
            if (_isAddingMore)
              _buildAddMoreSelectionMenu()
            else
              Center(
                child: GestureDetector(
                  onTap: () => setState(() => _isAddingMore = true),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orangeAccent.withOpacity(0.18), Colors.orangeAccent.withOpacity(0.08)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.orangeAccent.withOpacity(0.45)),
                      boxShadow: [
                        BoxShadow(color: Colors.orangeAccent.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.add_circle_outline_rounded, color: Colors.orangeAccent, size: 24),
                        SizedBox(width: 12),
                        Text(
                          "ADD MORE",
                          style: TextStyle(
                            color: Colors.orangeAccent,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
  Widget _buildAddMoreSelectionMenu() {
    final activities = _pillarMap[_activeCategory] ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orangeAccent.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Select Activity",
                style: TextStyle(color: Colors.orangeAccent, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54),
                onPressed: () => setState(() => _isAddingMore = false),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: activities.map((activity) {
              bool isSelected = _selectedActivity == activity;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedActivity = activity;
                    _dynamicInputController.clear();
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.orangeAccent.withOpacity(0.25) : Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? Colors.orangeAccent : Colors.white24),
                  ),
                  child: Text(
                    activity,
                    style: TextStyle(
                      color: isSelected ? Colors.orangeAccent : Colors.white70,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Input field appears only after selection
          if (_selectedActivity != null) ...[
            TextField(
              controller: _dynamicInputController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Enter value for $_selectedActivity",
                labelStyle: const TextStyle(color: Colors.white60),
                filled: true,
                fillColor: Colors.white.withOpacity(0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedActivity = null;
                      _dynamicInputController.clear();
                    });
                  },
                  child: const Text("Cancel", style: TextStyle(color: Colors.white70)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: _submitData,  // your existing submit logic
                  child: const Text("JOURNALIZE"),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
// --- UPDATED GOAL CELEBRATION (FIXED CONFETTI ERRORS) ---
  void _showGoalCelebration(String activity) {
    _confettiController.play();

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (context) {
        Future.delayed(const Duration(seconds: 3), () {
          if (Navigator.canPop(context)) Navigator.pop(context);
        });

        return Stack(
          alignment: Alignment.center,
          children: [
            ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive, // Error Fixed
              shouldLoop: false,
              colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
              numberOfParticles: 30,
              gravity: 0.1,
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.greenAccent.withOpacity(0.5),
                        blurRadius: 100,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.emoji_events, color: Colors.yellowAccent, size: 90),
                ),
                const SizedBox(height: 30),
                Text(
                  "${activity.toUpperCase()} GOAL MET!",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                    decoration: TextDecoration.none, // Required for Dialogs
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildDynamicLoggedCards(Map? jsonMap, List<String> defaults, int index, Color color, String dbKey) {
    if (jsonMap == null) return [];

    return jsonMap.entries.where((entry) => !defaults.contains(entry.key)).map((entry) {
      String label = entry.key.replaceAll("_", " ").toUpperCase();
      String value = "${entry.value}";

      return _bentoCard(
          label,
          value,
          _activityIcons[entry.key] ?? Icons.bolt,
          color, 0.94,
          dbKey == "exercises_data" ? "gym_min" : dbKey.replaceAll("_data", "_min"),
          index,
          _activityBgs[entry.key] ?? "assets/gym_bg.png",
          subKey: entry.key
      );
    }).toList();
  }

  Widget _buildCategoryBtn(String label, IconData icon, Color color) {
    bool isSelected = _activeCategory == label;
    return GestureDetector(
      onTap: () => setState(() => _activeCategory = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? color : Colors.white10),
          boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10)] : [],
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? color : Colors.white38, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.arrow_back, color: Colors.orangeAccent, size: 20), onPressed: () => Navigator.pop(context)),
          const SizedBox(width: 5),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("FITNESS CORE | HEALTH PILLAR", style: TextStyle(color: Colors.orangeAccent, letterSpacing: 4, fontSize: 10)),
            const Text("ACTIVITY TRACKING PAGE", style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
          ]),
          const Spacer(),
          IconButton(icon: const Icon(Icons.refresh, color: Colors.orangeAccent), onPressed: _fetchMonthData),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    String monthStr = DateFormat('MMMM yyyy').format(DateTime(_selectedYear, _selectedMonth)).toUpperCase();
    bool canGoBack = DateTime(_selectedYear, _selectedMonth - 1).isAtSameMomentAs(_minDate) || DateTime(_selectedYear, _selectedMonth - 1).isAfter(_minDate);
    bool canGoForward = DateTime(_selectedYear, _selectedMonth + 1).isBefore(_maxDate) || DateTime(_selectedYear, _selectedMonth + 1).isAtSameMomentAs(_maxDate);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
              icon: Icon(Icons.arrow_back_ios, color: canGoBack ? Colors.orangeAccent : Colors.white30, size: 20),
              onPressed: canGoBack ? () => _changeMonth(-1) : null
          ),
          Text(monthStr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 2)),
          IconButton(
              icon: Icon(Icons.arrow_forward_ios, color: canGoForward ? Colors.orangeAccent : Colors.white30, size: 20),
              onPressed: canGoForward ? () => _changeMonth(1) : null
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    final daysInMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
    return SizedBox(
      height: 80,
      child: ListView.builder(
        controller: _timelineScrollController,
        scrollDirection: Axis.horizontal,
        itemCount: daysInMonth,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemBuilder: (context, index) {
          bool isSelected = _activeDayIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() => _activeDayIndex = index);
              // No more PageView controller needed!
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 50, margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.orangeAccent : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("${index + 1}", style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
                  Text(DateFormat('E').format(DateTime(_selectedYear, _selectedMonth, index + 1)).toUpperCase(),
                      style: TextStyle(color: isSelected ? Colors.black54 : Colors.white24, fontSize: 8)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRemark(Map? cur, Map? prev) {
    if (cur == null) return const SizedBox.shrink();
    int stepsToday = cur['steps'] ?? 0;
    int stepsYesterday = prev?['steps'] ?? 0;
    int gymToday = cur['gym_min'] ?? 0;
    int gymYesterday = prev?['gym_min'] ?? 0;
    String msg = "NEURAL SYNC: STABLE";
    Color themeColor = Colors.orangeAccent;
    IconData statusIcon = Icons.sensors_rounded;
    if (stepsYesterday > 0) {
      if (stepsToday >= stepsYesterday) {
        msg = "GROWTH: +${stepsToday - stepsYesterday} steps above yesterday's baseline.";
        themeColor = Colors.greenAccent; statusIcon = Icons.trending_up;
      } else {
        msg = "CAUTION: ${stepsYesterday - stepsToday} steps below yesterday's performance.";
        themeColor = Colors.redAccent; statusIcon = Icons.trending_down;
      }
    }
    if (gymToday > gymYesterday && gymYesterday > 0) {
      msg = "INTENSITY: Gym duration increased by ${gymToday - gymYesterday}m!";
      themeColor = Colors.greenAccent;
    }
    if (stepsToday == 0 && gymToday == 0) {
      msg = "WARNING: No neural data detected for the current cycle.";
      themeColor = Colors.redAccent; statusIcon = Icons.warning_amber_rounded;
    }
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: themeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: themeColor.withOpacity(0.3))),
      child: Row(children: [Icon(statusIcon, color: themeColor, size: 20), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(themeColor == Colors.redAccent ? "PERFORMANCE DROP" : "OPTIMAL PERFORMANCE", style: TextStyle(color: themeColor, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)), const SizedBox(height: 2), Text(msg, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500))]))]),
    );
  }

  Widget _bentoCard(
      String label,
      String val,
      IconData icon,
      Color color,
      double width,
      String key,
      int idx,
      String bgImage, {
        bool isJson = false,
        String? subKey,
        String? jsonColumn,
        bool disableEdit = false,
      }) {
    List<double> pts = [];
    List<String> dates = [];
    double targetValue = _userTargets[key] ?? 0.0;

    double calories = 0;
    double numericVal = double.tryParse(val.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    if (key == "steps") calories = numericVal * 0.04;
    else if (key == "gym_min") calories = numericVal * 6.0;
    else if (key == "yoga_min") calories = numericVal * 3.0;
    else if (key == "sports_min") calories = numericVal * 8.0;
    else if (key == "walk_data") calories = numericVal * 3.5;
    else if (key == "run_data") calories = numericVal * 11.5;
    else if (key == "jog_data") calories = numericVal * 7.5;

    for (int i = idx - 4; i <= idx; i++) {
      if (i < 0 || i >= _monthData.length) {
        pts.add(0);
      } else {
        var dayEntry = _monthData[i];
        if (subKey != null && jsonColumn != null) {
          Map details = dayEntry?[jsonColumn] ?? {};
          pts.add((details[subKey] ?? 0).toDouble());
        } else if (isJson && dayEntry?[key] is Map) {
          pts.add(double.tryParse(dayEntry![key]['time'].toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0);
        } else {
          pts.add((dayEntry?[key] ?? 0).toDouble());
        }
      }
      DateTime labelDate = DateTime(_selectedYear, _selectedMonth, i + 1);
      dates.add(DateFormat('MMM d').format(labelDate));
    }

    DateTime now = DateTime.now();
    bool isToday = (idx == now.day - 1 && _selectedMonth == now.month);
    bool isEditable = (now.day - 1 - idx).abs() <= 1 && _selectedMonth == now.month;

    return Container(
      width: (MediaQuery.of(context).size.width - 55) * width,
      height: 180,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Stack(
          children: [
            Positioned.fill(child: Opacity(opacity: 0.35, child: Image.asset(bgImage, fit: BoxFit.cover))),
            Positioned.fill(child: CustomPaint(painter: GraphPainter(pts, dates, color, targetValue))),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label, style: const TextStyle(color: Colors.yellow, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 0.5),
                          Row(
                            children: [
                              Icon(icon, color: Colors.orange[900], size: 22),
                              const SizedBox(width: 4),
                              Text("$val/ ${targetValue.toInt()}", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(10)),
                        child: Text("🔥 ${calories.toInt()} KCAL BURNT", style: const TextStyle(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.w900)),
                      ),
                      const SizedBox(width: 4),
                      if ((isToday || isEditable) && !disableEdit)
                        GestureDetector(
                          onTap: () => _showEdit(
                            key,
                            idx,
                            val,
                            subKey: subKey,
                            jsonColumn: jsonColumn,
                          ),
                          child: Row(
                            children: [
                              Text("EDIT", style: TextStyle(color: Colors.orangeAccent.withOpacity(0.9), fontSize: 10, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 2),
                              Icon(Icons.edit_note, color: Colors.orangeAccent.withOpacity(0.9), size: 20),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEdit(String mainKey, int idx, String val, {String? subKey, String? jsonColumn}) {
    _editController.text = val.replaceAll(RegExp(r'[^0-9]'), '');
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF121212),
        title: Text("UPDATE ${mainKey.toUpperCase()}", style: const TextStyle(color: Colors.orangeAccent, fontSize: 16)),
        content: TextField(
          controller: _editController,
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("CANCEL", style: TextStyle(color: Colors.white24))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
            onPressed: () {
              final newVal = int.tryParse(_editController.text) ?? 0;

              if (subKey != null && jsonColumn != null) {
                _updateSubActivity(
                  jsonColumn: jsonColumn,
                  subKey: subKey,
                  newValue: newVal,
                  dayIndex: idx,
                );
              } else {
                _updateMetric(mainKey, newVal, idx);
              }

              Navigator.pop(c);
            },
            child: const Text("SAVE", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryFilterSection() {
    final totals = _calculateFilteredTotals();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          // Filter Tabs (Day, Week, Month)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ["Day", "Week", "Month"].map((filter) {
              bool isSelected = _selectedFilter == filter;
              return GestureDetector(
                onTap: () => setState(() => _selectedFilter = filter),
                child: Column(
                  children: [
                    Text(
                      filter,
                      style: TextStyle(
                        color: isSelected ? Colors.cyanAccent : Colors.white38,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (isSelected)
                      Container(height: 2, width: 40, color: Colors.cyanAccent)
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          // The 3 Top Cards
          Row(
            children: [
              _buildHistoryMiniCard("${totals['steps']!.toInt()}", "Steps", Colors.orangeAccent),
              const SizedBox(width: 10),
              _buildHistoryMiniCard(totals['distance']!.toStringAsFixed(1), "Distance (km)", Colors.blueAccent),
              const SizedBox(width: 10),
              _buildHistoryMiniCard("${totals['calories']!.toInt()}", "Calories (kCal)", Colors.redAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryMiniCard(String val, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(val, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildControlPanel() {
    // Always show GPS buttons ONLY when the selected day is TODAY
    final now = DateTime.now();
    final selectedDate = DateTime(_selectedYear, _selectedMonth, _activeDayIndex + 1);

    final isToday =
        selectedDate.year == now.year &&
            selectedDate.month == now.month &&
            selectedDate.day == now.day;

    if (!isToday) {
      return const SizedBox.shrink();
    }

    return _gpsButtons();  // always return the buttons when it's today
  }

// Separate helper to keep the logic clean
  Widget _gpsButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: Colors.white10, thickness: 1),
          const SizedBox(height: 20),
          const Text(
              "LIVE GPS TRACKING",
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2)
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _miniBtn("TRACK RUN", Colors.orange, () => _navigateToWorkout('run_data'))),
              const SizedBox(width: 12),
              Expanded(child: _miniBtn("TRACK JOG", Colors.yellowAccent, () => _navigateToWorkout('jog_data'))),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _miniBtn(String t, Color c, VoidCallback o) {
    return GestureDetector(
      onTap: o,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: c.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: c.withOpacity(0.3)),
        ),
        child: Center(
          child: Text(
            t,
            style: TextStyle(color: c, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(animation: _bgAnimationController, builder: (context, child) => Stack(children: [Positioned.fill(child: CustomPaint(painter: MeshPainter(_bgAnimationController.value))), Positioned.fill(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: Container(color: Colors.transparent)))]));
  }
}

class MeshPainter extends CustomPainter {
  final double val; MeshPainter(this.val);
  @override void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size; final pos = val * 2 * math.pi;
    final paint = Paint()..shader = RadialGradient(colors: [Colors.orange.withOpacity(0.2), Colors.transparent], center: Alignment(0.6 * math.cos(pos), 0.6 * math.sin(pos)), radius: 1.5).createShader(rect);
    canvas.drawRect(rect, paint);
  }
  @override bool shouldRepaint(covariant CustomPainter old) => true;
}

class GraphPainter extends CustomPainter {
  final List<double> pts; final List<String> dates; final Color color; final double target;
  GraphPainter(this.pts, this.dates, this.color, this.target);

  @override
  void paint(Canvas canvas, Size size) {
    if (pts.isEmpty) return;
    final paint = Paint()..color = Colors.orangeAccent..style = PaintingStyle.stroke..strokeWidth = 2;
    final axisPaint = Paint()..color = Colors.white60..strokeWidth = 1;
    double maxV = math.max(pts.reduce(math.max), target); if (maxV == 0) maxV = 1;
    double pL = 30, pB = 30, pT = 60; double cW = size.width - pL - 10, cH = size.height - pB - pT;

    final tP = Paint()..color = Colors.lightGreenAccent..style = PaintingStyle.stroke..strokeWidth = 1;
    double tY = (size.height - pB) - (target / maxV * cH);
    double sX = pL; while (sX < size.width - 10) { canvas.drawLine(Offset(sX, tY), Offset(math.min(sX + 5, size.width - 10), tY), tP); sX += 8; }

    canvas.drawLine(Offset(pL, pT), Offset(pL, size.height - pB), axisPaint);
    canvas.drawLine(Offset(pL, size.height - pB), Offset(size.width - 10, size.height - pB), axisPaint);

    final path = Path(); double xS = cW / (pts.length - 1);
    for (int i = 0; i < pts.length; i++) {
      double x = pL + (i * xS), y = (size.height - pB) - (pts[i] / maxV * cH);
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);

      Color performanceColor;
      double ratio = target > 0 ? (pts[i] / target) : 1.0;
      if (ratio >= 1.0) performanceColor = Colors.green;
      else if (ratio >= 0.5) performanceColor = Colors.yellow;
      else performanceColor = Colors.red;

      canvas.drawCircle(Offset(x, y), 3, Paint()..color = performanceColor);
      final tp = TextPainter(text: TextSpan(text: pts[i].toInt().toString(), style: TextStyle(color: performanceColor, fontSize: 12, fontWeight: FontWeight.bold)), textDirection: ui.TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(x - (tp.width / 2), y - 15));
      final dl = TextPainter(text: TextSpan(text: dates[i], style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)), textDirection: ui.TextDirection.ltr)..layout();
      dl.paint(canvas, Offset(x - (dl.width / 2), size.height - pB + 5));
    }
    canvas.drawPath(path, paint);
  }
  @override bool shouldRepaint(covariant CustomPainter old) => true;
}

class SpiralRingPainter extends CustomPainter {
  final Map<String, double> values;
  final Map<String, double> targets;
  final double animationValue; // Linked to a controller for pulsing effect

  SpiralRingPainter({
    required this.values,
    required this.targets,
    required this.animationValue
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const double strokeWidth = 14.0;
    const double spacing = 14.0;

    final pillars = [
      {'key': 'steps', 'color': Colors.cyanAccent, 'icon': Icons.directions_walk, 'label': 'STEPS'},
      {'key': 'gym_min', 'color': Colors.orange, 'icon': Icons.fitness_center, 'label': 'GYM'},
      {'key': 'sports_min', 'color': Colors.yellowAccent, 'icon': Icons.sports_soccer, 'label': 'SPORTS'},
      {'key': 'yoga_min', 'color': Colors.orangeAccent, 'icon': Icons.self_improvement, 'label': 'YOGA'},
    ];

    for (int i = 0; i < pillars.length; i++) {
      final p = pillars[i];
      final double radius = (size.width / 2) - (i * (strokeWidth + spacing));
      final double target = targets[p['key']] ?? 1.0;
      final double value = (values[p['key']] ?? 0.0).toDouble();
      final double progress = (target > 0) ? (value / target).clamp(0.0, 1.0) : 0.0;
      final Color baseColor = p['color'] as Color;

      // 1. Draw Track
      canvas.drawCircle(center, radius, Paint()..color = Colors.white.withOpacity(0.05)..style = PaintingStyle.stroke..strokeWidth = strokeWidth);

      // 2. Draw Progress with Pulsing Glow
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..color = baseColor.withOpacity(0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..maskFilter = MaskFilter.blur(BlurStyle.solid, 2 + (animationValue * 4)), // Pulsing Glow
      );

      // 3. Draw Icon & HUD Text
      _drawHUDText(canvas, center, radius, p['icon'] as IconData, p['label'] as String, "${value.toInt()}/${target.toInt()}");
    }
  }

  void _drawHUDText(Canvas canvas, Offset center, double radius, IconData icon, String label, String metrics) {
    final TextPainter tp = TextPainter(textDirection: ui.TextDirection.ltr);

    tp.text = TextSpan(
      children: [
        TextSpan(text: String.fromCharCode(icon.codePoint), style: TextStyle(fontSize: 13, fontFamily: icon.fontFamily, package: icon.fontPackage, color: Colors.white)),
        TextSpan(text: "  $label :", style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
        TextSpan(text: "$metrics min", style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
      ],
      style: const TextStyle(shadows: [Shadow(blurRadius: 4, color: Colors.black)]),
    );

    tp.layout();
    tp.paint(canvas, Offset(center.dx - 8, center.dy - radius - (tp.height / 2)));
  }

  @override
  bool shouldRepaint(covariant SpiralRingPainter old) => true;
}