import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// -------------------------------------------------------------------------
// REFINED MODEL: ALL METRICS RESTORED
// -------------------------------------------------------------------------
class VitalsModel extends ChangeNotifier {
  String gender = 'Male';
  // Use placeholders as the default state
  String sugar = '--', systolic = '--', diastolic = '--', pulse = '--';
  String hba1c = '--', hb = '--', ldl = '--', hdl = '--', triglycerides = '--';
  bool gastric = false;
  String gastricSeverity = 'Normal', thyroidTSH = '--';

  // Menstruation Data
  String womensLastPeriod = '2023-11-20';
  String womensCycleLength = '28';
  String womensFlow = 'Normal';



  // NEW: Safely calculate current day of cycle
  int get currentDay {
    try {
      DateTime lastDate = DateTime.parse(womensLastPeriod);
      int diff = DateTime.now().difference(lastDate).inDays + 1;
      int len = int.tryParse(womensCycleLength) ?? 28;
      if (diff <= 0) return 1;
      return (diff > len) ? (diff % len == 0 ? len : diff % len) : diff;
    } catch (e) { return 1; }
  }

  void setGender(String g) { gender = g; notifyListeners(); }
  void toggleGastric(bool val) { gastric = val; notifyListeners(); }

  void updateMetric(String key, String val) {
    switch (key) {
      case 'm_len': womensCycleLength = val; break;
      case 'm_flow': womensFlow = val; break;
      case 'm_date': womensLastPeriod = val; break;
      default:
      // handle other metrics...
        break;
    }
    notifyListeners();
  }
}
// -------------------------------------------------------------------------
// CORE ANIMATIONS
// -------------------------------------------------------------------------

class SovereignECGPainter extends CustomPainter {
  final double animation; // Should be a value from 0.0 to 1.0
  SovereignECGPainter(this.animation);

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final double midY = size.height / 2;

    // 1. Solid Dark Base & Medical Grid
    canvas.drawRect(rect, Paint()..color = const Color(0xFF000808));
    _drawGrid(canvas, size);

    // 2. Determine the "Scanning Head" position
    double headX = size.width * animation;

    // We use a single loop to draw segments with varying opacity
    for (double x = 0; x < size.width; x += 1.5) {
      // Calculate distance from the scanning head to create a trail
      double distanceFromHead = (headX - x);
      if (distanceFromHead < 0) distanceFromHead += size.width; // Wrap around

      // Calculate opacity: 1.0 at the head, 0.0 at the far tail
      double opacity = (1.0 - (distanceFromHead / size.width)).clamp(0.0, 1.0);
      // Square the opacity for a more realistic "fast fade"
      opacity = opacity * opacity;

      if (opacity < 0.05) continue; // Skip drawing invisible segments

      final segmentPaint = Paint()
        ..color = Colors.cyanAccent.withOpacity(opacity)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;

      // Glow effect for the bright "head" of the pulse
      final glowPaint = Paint()
        ..color = Colors.cyanAccent.withOpacity(opacity * 0.3)
        ..strokeWidth = 6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      // Waveform Logic (P-QRS-T)
      double cycle = (x / 150) % 1.0;
      double dy = 0;
      if (cycle > 0.1 && cycle < 0.18) dy = -6 * _pulse(cycle, 0.1, 0.18);
      else if (cycle > 0.22 && cycle < 0.24) dy = 8 * _pulse(cycle, 0.22, 0.24);
      else if (cycle > 0.24 && cycle < 0.28) dy = -80 * _pulse(cycle, 0.24, 0.28);
      else if (cycle > 0.28 && cycle < 0.31) dy = 12 * _pulse(cycle, 0.28, 0.31);
      else if (cycle > 0.45 && cycle < 0.62) dy = -15 * _pulse(cycle, 0.45, 0.62);

      Offset p1 = Offset(x, midY + dy);
      // Small line segment
      Offset p2 = Offset(x + 1.5, midY + dy);

      // Draw the glow and the line segment
      canvas.drawLine(p1, p2, glowPaint);
      canvas.drawLine(p1, p2, segmentPaint);

      // Add a bright "dot" at the very leading edge (the electron beam)
      if ((x - headX).abs() < 2) {
        canvas.drawCircle(p1, 3, Paint()..color = Colors.white..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
      }
    }
  }

  double _pulse(double t, double s, double e) => (1 - ((t - (s+e)/2).abs() / ((e-s)/2))).clamp(0, 1);

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()..style = PaintingStyle.stroke;
    for (double x = 0; x < size.width; x += 20) {
      gridPaint.color = (x % 100 == 0) ? const Color(0xFF004444) : const Color(0xFF001F1F);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 20) {
      gridPaint.color = (y % 100 == 0) ? const Color(0xFF004444) : const Color(0xFF001F1F);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(SovereignECGPainter old) => true;
}// -------------------------------------------------------------------------
// MAIN UI PAGE
// -------------------------------------------------------------------------

class VitalsPage extends StatefulWidget {
  const VitalsPage({super.key});
  @override State<VitalsPage> createState() => _VitalsPageState();
}

class _VitalsPageState extends State<VitalsPage> with TickerProviderStateMixin {
  final VitalsModel model = VitalsModel();
  late AnimationController _heartCtrl, _ecgCtrl, _bloodCtrl;
  String lastUpdatedDisplay = "";

  @override
  void initState() {
    super.initState();
    _heartCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _ecgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _bloodCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat();
    _fetchUserGender();
    _fetchLatestVitals();
    model.addListener(() => setState(() {}));
  }

  @override
  void dispose() { _heartCtrl.dispose(); _ecgCtrl.dispose(); _bloodCtrl.dispose(); super.dispose(); }

  Future<void> _fetchLatestVitals() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final data = await supabase
          .from('medical_vitals')
          .select()
          .eq('user_id', user.id)
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (data != null) {
        setState(() {
          model.sugar = data['sugar']?.toString() ?? '--';
          model.systolic = data['systolic']?.toString() ?? '--';
          model.diastolic = data['diastolic']?.toString() ?? '--';
          model.pulse = data['pulse']?.toString() ?? '--';
          model.hba1c = data['hba1c']?.toString() ?? '--';
          model.hb = data['hb']?.toString() ?? '--';
          model.ldl = data['ldl']?.toString() ?? '--';
          model.hdl = data['hdl']?.toString() ?? '--';
          model.triglycerides = data['triglycerides']?.toString() ?? '--';
          model.thyroidTSH = data['thyroid_tsh']?.toString() ?? '--';

          final DateTime lastUpd = DateTime.parse(data['updated_at']).toLocal();
          lastUpdatedDisplay = "Last Updated: ${lastUpd.day}/${lastUpd.month}/${lastUpd.year.toString().substring(2)}";
        });
      }
    } catch (e) {
      debugPrint("Error fetching vitals: $e");
    }
  }

  // Updated Sync for Daily Upsert
  Future<void> _sync(String field, dynamic val) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    // Map Flutter keys to Supabase Table Column Names
    Map<String, String> columnMap = {
      'systolic': 'systolic',
      'diastolic': 'diastolic',
      'pulse': 'pulse',
      'hb': 'hb',
      'sugar': 'sugar',
      'hba1c': 'hba1c',
      'tsh': 'thyroid_tsh',
      'ldl': 'ldl',
      'hdl': 'hdl',
      'tri': 'triglycerides',
      'gastric': 'gastric_severity', // Maps the toggle/severity to this column
    };

    String dbColumn = columnMap[field] ?? field;
    final today = DateTime.now().toIso8601String().split('T')[0];

    try {
      await supabase.from('medical_vitals').upsert({
        'user_id': user.id,
        'log_date': today, // Ensures one row per user per day
        dbColumn: val,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,log_date');

      _fetchLatestVitals(); // Refresh the "Last Updated" text
    } catch (e) {
      debugPrint("Sync Error ($dbColumn): $e");
    }
  }

  Future<void> _fetchUserGender() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final data = await supabase
          .from('profiles')
          .select('gender')
          .eq('id', user.id)
          .single();

      if (data['gender'] != null) {
        model.setGender(data['gender']); // Assigns 'Male' or 'Female' from DB
      }
    } catch (e) {
      debugPrint("Error fetching gender: $e");
    }
  }

  void _showCenterInput(String title, String field, String current) {
    TextEditingController c = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (ctx) => Center(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: Colors.white24),
              boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.1), blurRadius: 40)],
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title.toUpperCase(), style: const TextStyle(color: Colors.orangeAccent, letterSpacing: 5, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: c, autofocus: true, keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 50, fontWeight: FontWeight.w900),
                    textAlign: TextAlign.center, decoration: const InputDecoration(border: InputBorder.none),
                  ),
                  const SizedBox(height: 30),
                  GestureDetector(
                    onTap: () { model.updateMetric(field, c.text); _sync(field, double.tryParse(c.text) ?? c.text); Navigator.pop(context); },
                    child: Container(
                      height: 60, width: double.infinity,
                      decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(20)),
                      child: const Center(child: Text("CONFIRM DATA", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 2))),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _backgroundCanvas(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _header(),
                  _theGodTrinity(),
                  const SizedBox(height: 10),
                  _glassSectionTitle("BIOMETRIC CORE"),
                  _ringDashboard(),
                  const SizedBox(height: 10),
                  _glassSectionTitle("ORGAN & METABOLIC STATUS"),
                  _lipidOrganPanel(),
                  if (model.gender == 'Female') ...[
                    const SizedBox(height: 10),
                    _glassSectionTitle("CYCLE ANALYSIS"),
                    menstruationPanel(model),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _backgroundCanvas() {
    return Stack(
      children: [
        Positioned(top: -100, left: -50, child: _nebulaGlow(Colors.orange.withOpacity(0.1))),
        Positioned(bottom: 200, right: -100, child: _nebulaGlow(Colors.red.withOpacity(0.1))),
      ],
    );
  }

  Widget _nebulaGlow(Color c) => Container(width: 500, height: 500, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: c, blurRadius: 200, spreadRadius: 50)]));

// Replace your existing _header() method with this:
  Widget _header() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios_new, color: Colors.orange, size: 28)),
          Column(
            children: [
              const Text("MEDICAL VITALS", style: TextStyle(color: Colors.orange, letterSpacing: 8, fontWeight: FontWeight.w900, fontSize: 16)),
              if (lastUpdatedDisplay.isNotEmpty)
                Text(lastUpdatedDisplay, style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(model.gender == 'Male' ? Icons.person : Icons.person_3, color: Colors.deepOrangeAccent, size: 28),
          ),
        ],
      ),
    );
  }
  Widget _theGodTrinity() {
    return SizedBox(
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Realistic Hospital ECG
          AnimatedBuilder(
              animation: _ecgCtrl,
              builder: (c, w) => CustomPaint(
                  size: const Size(double.infinity, 120),
                  painter: SovereignECGPainter(_ecgCtrl.value)
              )
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _trinityTile("HEMOGLOBIN", model.hb, Colors.pink, _hb3DAnim(), 'hb'),
              _trinityTile("HEART RATE", model.pulse, Colors.redAccent, _heart3DAnim(), 'pulse', isCore: true),
              // Inside _theGodTrinity()
              _trinityTile(
                  "BLOOD PRESSURE",
                  "${model.systolic}/${model.diastolic}",
                  Colors.deepOrange,
                  _bp3DAnim(),
                  'bp_trigger' // This will now trigger the special dialog
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showBPDialog() {
    TextEditingController sysC = TextEditingController(text: model.systolic == '--' ? '' : model.systolic);
    TextEditingController diaC = TextEditingController(text: model.diastolic == '--' ? '' : model.diastolic);

    showDialog(
      context: context,
      builder: (ctx) => Center(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: Colors.white24),
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("BLOOD PRESSURE", style: TextStyle(color: Colors.orangeAccent, letterSpacing: 5, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: sysC, autofocus: true, keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900),
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(hintText: "SYS", hintStyle: TextStyle(color: Colors.white10), border: InputBorder.none),
                        ),
                      ),
                      const Text("/", style: TextStyle(color: Colors.white24, fontSize: 40)),
                      Expanded(
                        child: TextField(
                          controller: diaC, keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900),
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(hintText: "DIA", hintStyle: TextStyle(color: Colors.white10), border: InputBorder.none),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      model.systolic = sysC.text;
                      model.diastolic = diaC.text;
                      _sync('systolic', int.tryParse(sysC.text) ?? 0);
                      _sync('diastolic', int.tryParse(diaC.text) ?? 0);
                      Navigator.pop(context);
                    },
                    child: const Text("CONFIRM"),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _trinityTile(String lab, String val, Color c, Widget graphic, String f, {bool isCore = false}) {
    return GestureDetector(
// Update the onTap in _trinityTile
      onTap: () {
        if (f == 'bp_trigger') {
          _showBPDialog();
        } else {
          _showCenterInput(lab, f, val);
        }
      },      child: Container(
        // Proportional width to ensure 3 tiles fit perfectly in one row
        width: MediaQuery.of(context).size.width * 0.3,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. BIOLOGICAL ANIMATION AREA
            // Increased height to prevent the widened heart/drop from clipping
            SizedBox(
                height: 85,
                child: Center(child: graphic)
            ),

            const SizedBox(height: 12),

            // 2. DATA VALUE
            // Using monospaced font for a "digital monitor" feel
            Text(
              val,
              style: TextStyle(
                color: Colors.white,
                fontSize: isCore ? 34 : 22, // Pulse is slightly larger
                fontWeight: FontWeight.w900,
                fontFamily: 'monospace',
                letterSpacing: -1,
                shadows: [
                  Shadow(
                    color: c.withOpacity(0.6),
                    blurRadius: 15,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // 3. LABEL & INTERACTION INDICATOR
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  lab,
                  style: TextStyle(
                    color: c.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(width: 4),
                // Subtle edit icon to signal tap-to-log
                Icon(
                    Icons.mode_edit_outline_rounded,
                    color: Colors.white24,
                    size: 13
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  // 1. Widened 3D Pulsing Heart
  Widget _heart3DAnim() {
    return AnimatedBuilder(
      animation: _heartCtrl,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (0.1 * _heartCtrl.value),
          child: CustomPaint(
            size: const Size(70, 60), // Widened
            painter: Heart3DPainter(_heartCtrl.value),
          ),
        );
      },
    );
  }

// 2. Falling Blood Drop (Hemoglobin)
  Widget _hb3DAnim() {
    return AnimatedBuilder(
      animation: _bloodCtrl,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 15 * _bloodCtrl.value), // Dropping animation
          child: Opacity(
            opacity: 1.0 - (_bloodCtrl.value * 0.5),
            child: CustomPaint(
              size: const Size(45, 60), // Widened drop
              painter: BloodDrop3DPainter(),
            ),
          ),
        );
      },
    );
  }

// 3. Flowing Blood Vessel (Blood Pressure)
  Widget _bp3DAnim() {
    return AnimatedBuilder(
      animation: _bloodCtrl,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(60, 50),
          painter: VesselFlowPainter(_bloodCtrl.value),
        );
      },
    );
  }


  Widget _ringDashboard() {
    return Container(
      height: 140, // Keeps the same compact height
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Stack(
        children: [
          // Background Neuron Animation
          AnimatedBuilder(
            animation: _ecgCtrl, // Using your existing ECG controller for sync
            builder: (context, child) {
              return CustomPaint(
                size: const Size(double.infinity, 140),
                painter: NeuronPainter(
                    _ecgCtrl.value,
                    [Colors.orange, Colors.yellowAccent, Colors.deepOrange]
                ),
              );
            },
          ),

          // The Data Nodes
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _synapticNode("SUGAR", model.sugar, Colors.orange, 'sugar'),
                _synapticNode("HbA1c", model.hba1c, Colors.yellowAccent, 'hba1c'),
                _synapticNode("TSH", model.thyroidTSH, Colors.deepOrange, 'tsh'),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _synapticNode(String label, String value, Color color, String field) {
    return GestureDetector(
      onTap: () => _showCenterInput(label, field, value),
      child: Container(
        width: 100,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // The "Cell Nucleus"
            Stack(
              alignment: Alignment.center,
              children: [
                // Outer Glow
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, spreadRadius: 2)
                    ],
                    border: Border.all(color: color.withOpacity(0.2), width: 1),
                  ),
                ),
                // The Icon/Edit Layer
                Icon(Icons.add_chart_rounded, color: color.withOpacity(0.4), size: 25),
                // A tiny pulsing dot
                AnimatedBuilder(
                  animation: _heartCtrl,
                  builder: (context, child) => Opacity(
                    opacity: _heartCtrl.value,
                    child: Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Value Display
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace', // Futuristic lab look
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.edit, color: color.withOpacity(0.5), size: 13),
              ],
            ),
            Text(
              label,
              style: TextStyle(
                color: color.withOpacity(0.8),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lipidOrganPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          // THE SPECTRAL GRAPH ROW
          SizedBox(
            height: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _spectralBar("LDL", model.ldl, 0.7, Colors.redAccent, 'ldl'),
                _spectralBar("HDL", model.hdl, 0.5, Colors.pink, 'hdl'),
                _spectralBar("TRIG", model.triglycerides, 0.6, Colors.amberAccent, 'tri'),
              ],
            ),
          ),

          const SizedBox(height: 20),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 15),

          // GASTRIC SYSTEM STATUS (Redesigned as a subtle status bar)
          _gastricStatusBar(),
        ],
      ),
    );
  }
  Widget _spectralBar(String lab, String val, double pct, Color c, String f) {
    return GestureDetector(
      onTap: () => _showCenterInput(lab, f, val),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // Background Track
                Container(
                  width: 20,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                // Glowing Progress Beam
                AnimatedContainer(
                  duration: const Duration(seconds: 1),
                  width: 20,
                  height: 80 * pct, // Animated height based on percentage
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [c, c.withOpacity(0.3)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: c.withOpacity(0.3), blurRadius: 8)],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(val, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(lab, style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(width: 4),
              Icon(Icons.edit, color: Colors.white24, size: 13),
            ],
          ),
        ],
      ),
    );
  }

  Widget _gastricStatusBar() {
    return Row(
      children: [
        Icon(Icons.monitor_heart_outlined, color: Colors.deepOrangeAccent.withOpacity(0.5), size: 22),
        const SizedBox(width: 12),
        const Expanded(
          child: Text("GASTRIC BIO-STATUS",
              style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2)),
        ),
        // Display text based on the boolean status
        Text(
          model.gastric ? "ACTIVE" : "STABLE",
          style: TextStyle(color: model.gastric ? Colors.orange : Colors.white24, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        Switch(
            value: model.gastric,
            activeColor: Colors.deepOrangeAccent,
            onChanged: (v) {
              model.toggleGastric(v);
              // Send the boolean value 'v' directly to the DB
              _sync('gastric', v);
            }
        ),
      ],
    );
  }
  Widget menstruationPanel(VitalsModel model) {
    final phase = _getPhaseData(model.currentDay);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // Pink/Rose background instead of white
        color: Colors.pink[50]!.withOpacity(0.15),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.pinkAccent.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: Colors.pink.withOpacity(0.05), blurRadius: 20)],
      ),
      child: Column(
        children: [
          // Header with smaller font
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Icon(Icons.auto_awesome, color: Colors.pinkAccent, size: 16),
                const SizedBox(width: 8),
                const Text("CYCLE INSIGHTS", style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
              ]),
              _badge(phase.title, phase.mainColor, phase.accentColor),
            ],
          ),
          const SizedBox(height: 12),

          // Compact Insight Message
          Text(
            "“${phase.message}”",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.pink[400], fontSize: 12, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 16),

          // THE 3 LOG METRICS (Interactive)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _logTile("CYCLE", "${model.womensCycleLength}d", Icons.refresh, () => _showCenterInput("Cycle Length", "m_len", model.womensCycleLength)),
              _logTile("FLOW", model.womensFlow, Icons.water_drop, () => _cycleFlow(model)),
              _logTile("LAST", model.womensLastPeriod.split('-').last, Icons.calendar_today, () => _pickDate(model, phase)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _logTile(String label, String value, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.pinkAccent.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.pinkAccent[700], size: 14),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: Colors.pink[300], fontSize: 8, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // Helpers for Log Options
  void _cycleFlow(VitalsModel model) {
    List<String> flows = ["Light", "Normal", "Heavy"];
    int idx = flows.indexOf(model.womensFlow);
    String next = flows[(idx + 1) % flows.length];
    model.updateMetric('m_flow', next);
    _sync('mens_flow', next);
  }

  void _pickDate(VitalsModel model, PhaseConfig phase) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(colorScheme: ColorScheme.dark(primary: Colors.pinkAccent, onPrimary: Colors.white, surface: Colors.white24)),
        child: child!,
      ),
    );
    if (picked != null) {
      String dateStr = picked.toIso8601String().split('T')[0];
      model.updateMetric('m_date', dateStr);
      _sync('mens_last_period', dateStr);
    }
  }

  Widget _badge(String text, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(10)),
      child: Text(text.toUpperCase(), style: TextStyle(color: textCol, fontSize: 8, fontWeight: FontWeight.bold)),
    );
  }


  Widget _glassSectionTitle(String t) => Padding(padding: const EdgeInsets.only(bottom: 12, left: 5), child: Row(children: [Container(width: 4, height: 15, color: Colors.pinkAccent), const SizedBox(width: 10), Text(t, style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 3))]));

}

class PhaseConfig {
  final String title;
  final String message;
  final String tip;
  final IconData tipIcon;
  final Color mainColor;
  final Color accentColor;

  PhaseConfig({
    required this.title,
    required this.message,
    required this.tip,
    required this.tipIcon,
    required this.mainColor,
    required this.accentColor
  });
}

PhaseConfig _getPhaseData(int day) {
  if (day >= 1 && day <= 5) {
    return PhaseConfig(
      title: "Menstrual Phase",
      message: "Your energy is naturally inward. It's a time for renewal.",
      tip: "Try a warm ginger tea or a 10-minute meditation.",
      tipIcon: Icons.coffee_rounded,
      mainColor: const Color(0xFFFFB7B7), // Rose
      accentColor: const Color(0xFF8E3E3E),
    );
  } else if (day >= 6 && day <= 12) {
    return PhaseConfig(
      title: "Follicular Phase",
      message: "Your hormones are rising, bringing fresh perspective.",
      tip: "Perfect day for a brisk walk or starting a new book.",
      tipIcon: Icons.auto_stories,
      mainColor: const Color(0xFFFFE0B2), // Peach
      accentColor: const Color(0xFF9E6E2E),
    );
  } else if (day >= 13 && day <= 16) {
    return PhaseConfig(
      title: "Ovulatory Phase",
      message: "You're at your most communicative and vibrant!",
      tip: "Socialize! It's a great time for a dinner date or a workout.",
      tipIcon: Icons.celebration_rounded,
      mainColor: const Color(0xFFC8E6C9), // Sage
      accentColor: const Color(0xFF2E7D32),
    );
  } else {
    return PhaseConfig(
      title: "Luteal Phase",
      message: "Your body is preparing to reset. Slow and steady wins.",
      tip: "Dim the lights early and try some gentle Yin Yoga.",
      tipIcon: Icons.nightlight_round,
      mainColor: const Color(0xFFD1C4E9), // Lavender
      accentColor: const Color(0xFF512DA8),
    );
  }
}


class NeuronPainter extends CustomPainter {
  final double animationValue;
  final List<Color> colors;

  NeuronPainter(this.animationValue, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final double y = size.height / 2.5; // Vertical alignment of the connection
    final double nodeWidth = size.width / 3;

    for (int i = 0; i < 2; i++) {
      final path = Path();
      double startX = (i * nodeWidth) + (nodeWidth * 0.7);
      double endX = ((i + 1) * nodeWidth) + (nodeWidth * 0.3);

      // Create a "Synaptic" curve between nodes
      path.moveTo(startX, y);
      path.cubicTo(
          startX + 20, y - 10,
          endX - 20, y + 10,
          endX, y
      );

      // Draw background dim connection
      paint.color = colors[i].withOpacity(0.1);
      canvas.drawPath(path, paint);

      // Draw animated "Signal Pulse"
      final pathMetrics = path.computeMetrics().first;
      final extractPath = pathMetrics.extractPath(
        pathMetrics.length * (animationValue - 0.2).clamp(0.0, 1.0),
        pathMetrics.length * animationValue,
      );

      paint.color = colors[i+1];
      paint.maskFilter = const MaskFilter.blur(BlurStyle.solid, 3);
      canvas.drawPath(extractPath, paint);
    }
  }

  @override
  bool shouldRepaint(NeuronPainter oldDelegate) => true;
}


class ArteryPainter extends CustomPainter {
  final double animation;
  ArteryPainter(this.animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.redAccent.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    // Draw a wave-like arterial flow background
    final path = Path();
    path.moveTo(0, size.height * 0.7);
    for (double i = 0; i <= size.width; i++) {
      path.lineTo(i, size.height * 0.7 + math.sin((i / size.width * 2 * math.pi) + (animation * 2 * math.pi)) * 10);
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
class Heart3DPainter extends CustomPainter {
  final double pulse;
  Heart3DPainter(this.pulse);
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Intense Outer Aura
    canvas.drawCircle(center, 25, Paint()
      ..color = Colors.redAccent.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15));

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.redAccent, Colors.red.shade900],
        center: const Alignment(-0.2, -0.3),
      ).createShader(Offset.zero & size);

    Path path = Path();
    path.moveTo(size.width * 0.5, size.height * 0.25);
    path.cubicTo(size.width * 0.1, -10, -15, size.height * 0.6, size.width * 0.5, size.height);
    path.cubicTo(size.width + 15, size.height * 0.6, size.width * 0.9, -10, size.width * 0.5, size.height * 0.25);

    canvas.drawShadow(path, Colors.redAccent, 15, true); // Increased Elevation
    canvas.drawPath(path, paint);
  }
  @override bool shouldRepaint(Heart3DPainter old) => true;
}

class BloodDrop3DPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Background Glow
    canvas.drawCircle(Offset(size.width/2, size.height/2), 20, Paint()
      ..color = Colors.pinkAccent.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Colors.red, Colors.red.shade900],
      ).createShader(Offset.zero & size);

    Path path = Path();
    path.moveTo(size.width / 2, 0);
    path.cubicTo(size.width * 1.3, size.height * 0.7, size.width * 0.9, size.height, size.width / 2, size.height);
    path.cubicTo(size.width * 0.1, size.height, -size.width * 0.3, size.height * 0.7, size.width / 2, 0);
    canvas.drawPath(path, paint);
  }
  @override bool shouldRepaint(BloodDrop3DPainter old) => false;
}

class VesselFlowPainter extends CustomPainter {
  final double flow;
  VesselFlowPainter(this.flow);
  @override
  void paint(Canvas canvas, Size size) {
    // Flowing "Plasma" Glow
    final cellGlow = Paint()..color = Colors.red..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final cellCore = Paint()..color = Colors.white;

    // Vessel Path
    final vPath = Path();
    vPath.moveTo(0, size.height * 0.5);
    vPath.lineTo(size.width * 0.4, size.height * 0.5);
    vPath.lineTo(size.width * 0.9, size.height * 0.2);
    vPath.moveTo(size.width * 0.4, size.height * 0.5);
    vPath.lineTo(size.width * 0.9, size.height * 0.8);

    canvas.drawPath(vPath, Paint()..color = Colors.red.withOpacity(0.5)..style = PaintingStyle.stroke..strokeWidth = 14..strokeCap = StrokeCap.round);

    for (int i = 0; i < 3; i++) {
      double x = ((flow + i / 3) % 1.0) * size.width;
      canvas.drawCircle(Offset(x, size.height * 0.5), 5, cellGlow); // Intense Glow
      canvas.drawCircle(Offset(x, size.height * 0.5), 2, cellCore); // Bright Center
    }
  }
  @override bool shouldRepaint(VesselFlowPainter old) => true;
}