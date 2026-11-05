import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:math' as math;
import '/providers/health_score_engine.dart';
import 'home_page.dart';

class ScoreCalculator extends ConsumerStatefulWidget {
  const ScoreCalculator({super.key});

  @override
  ConsumerState<ScoreCalculator> createState() => _ScoreCalculatorState();
}

class _ScoreCalculatorState extends ConsumerState<ScoreCalculator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(healthDataStreamProvider);
    final scoreAsync = ref.watch(finalScoreProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Detailed Clinical Report", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
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
          dataAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
            error: (err, stack) => Center(child: Text("Error: $err", style: const TextStyle(color: Colors.white))),
            data: (data) {
              final double? currentScore = scoreAsync.maybeWhen(data: (s) => s, orElse: () => null);
              final flags = _generateDeepClinicalFlags(data);
              final plan = _generateDeepClinicalPlan(data);

              return SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildScoreHeader(currentScore),
                      const SizedBox(height: 20),

                      _sectionTitle("Clinical Risk Flags & Insights"),
                      _insightBox(flags, Colors.redAccent),

                      const SizedBox(height: 12),
                      _sectionTitle("Personalized Treatment Plan"),
                      _insightBox(plan, Colors.greenAccent),

                      const SizedBox(height: 24),
                      _sectionTitle("Detailed Diagnostic Breakdown"),

                      _dataSummaryCard("Activity & Movement", [
                        "Steps: ${data['activity']['steps'] ?? '0'}",
                        "Gym: ${data['activity']['gym_min'] ?? '0'}m",
                        "Yoga: ${data['activity']['yoga_min'] ?? '0'}m",
                      ], Icons.run_circle_outlined, const Color(0xFF4CAF50)),

                      _dataSummaryCard("Wellbeing & Sleep", [
                        "Sleep: ${data['wellbeing']['sleep_hours'] ?? '0'} hrs",
                        "Meditation: ${data['wellbeing']['meditation_min'] ?? '0'}m",
                        "Mood: ${data['wellbeing']['happiness_mood'] ?? 'N/A'}",
                      ], Icons.psychology_outlined, const Color(0xFF9C27B0)),

                      _dataSummaryCard("Diet & Habits", [
                        "Calories: ${data['diet']['total_calories'] ?? 'N/A'}",
                        "Protein: ${data['diet']['total_protein'] ?? '--'}",
                        "Carbs: ${data['diet']['total_carbs'] ?? '--'}",
                        "Fat: ${data['diet']['total_fat'] ?? '--'}",
                      ], Icons.fastfood_outlined, const Color(0xFFFBC02D)),

                      _dataSummaryCard("Medical Vitals", [
                        "Sugar: ${data['vitals']['sugar'] ?? 'N/A'}",
                        "BP: ${data['vitals']['systolic'] ?? '0'}/${data['vitals']['diastolic'] ?? '--/--'}",
                        "HbA1c: ${data['vitals']['hba1c'] ?? 'N/A'}",
                      ], Icons.volunteer_activism_outlined, const Color(0xFFE53935)),

                      _dataSummaryCard("Tongue Diagnostic (TCM)", [
                        "Color: ${data['tongue']['color'] ?? 'N/A'}",
                        "Coat: ${data['tongue']['coating'] ?? 'N/A'}",
                        "Cracks: ${data['tongue']['cracks'] ?? 'N/A'}",
                      ], Icons.face, const Color(0xFF00ACC1)),

                      const SizedBox(height: 30),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 60),
                          backgroundColor: const Color(0xFF1A1A1A),
                          side: BorderSide(color: Colors.white.withOpacity(0.2)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () => _printPdf(currentScore ?? 0, flags, plan, data),
                        icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                        label: const Text("DOWNLOAD FULL MEDICAL PDF",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildScoreHeader(double? score) {
    bool isNil = score == null;
    Color color = isNil ? Colors.grey : (score > 750 ? Colors.green : (score > 500 ? Colors.orange : Colors.red));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withOpacity(0.8)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          const Text("TOTAL HEALTH INDEX", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          Text(isNil ? "---" : score.toInt().toString(), style: const TextStyle(fontSize: 84, color: Colors.white, fontWeight: FontWeight.w900)),
          Text(isNil ? "Start Logging to Get Personalised Report" : _getRatingText(score), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _dataSummaryCard(String title, List<String> values, IconData icon, Color accentColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: accentColor.withOpacity(0.15), shape: BoxShape.circle),
          child: Icon(icon, color: accentColor, size: 24),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Text(values.join("  •  "), style: const TextStyle(color: Colors.white60, fontSize: 13)),
        ),
      ),
    );
  }

  Widget _insightBox(List<String> items, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((e) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(padding: const EdgeInsets.only(top: 2), child: Icon(Icons.emergency_outlined, size: 14, color: color)),
            const SizedBox(width: 8),
            Expanded(child: Text(e, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: Colors.white))),
          ]),
        )).toList(),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4),
    child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white70)),
  );

  String _getRatingText(double s) => s > 750 ? "OPTIMAL HEALTH" : (s > 500 ? "MODERATE RISK" : "CRITICAL ATTENTION");
  double _parse(dynamic val) => double.tryParse(val?.toString() ?? '0') ?? 0.0;

  List<String> _generateDeepClinicalFlags(Map<String, dynamic> data) {
    List<String> f = [];
    final v = data['vitals'] ?? {};
    final t = data['tongue'] ?? {};
    final w = data['wellbeing'] ?? {};
    final d = data['diet'] ?? {};
    final a = data['activity'] ?? {};

    double _parse(dynamic val) => double.tryParse(val?.toString() ?? '0') ?? 0.0;

    // --- Cardiovascular & Metabolic ---
    double sys = _parse(v['systolic']);
    double dia = _parse(v['diastolic']);
    if (sys >= 140 || dia >= 90) f.add("I10: Hypertension Stage 2 - Significant vascular pressure.");

    double sugar = _parse(v['sugar_level_fasting']);
    if (sugar >= 126) f.add("E11.9: Hyperglycemia - Fasting levels indicate Type 2 Diabetes risk.");
    else if (sugar >= 100) f.add("R73.03: Prediabetes - Impaired fasting glucose.");

    double ldl = _parse(v['ldl']);
    double tri = _parse(v['triglycerides']);
    if (ldl > 130 || tri > 150) f.add("E78.5: Dyslipidemia - High LDL/Triglycerides (Atherosclerotic risk).");

    // --- Hematology & Organ Stress ---
    double hb = _parse(v['hemoglobin']);
    if (hb > 0 && hb < 12) f.add("D64.9: Anemia - Low Hemoglobin levels (Oxygen transport deficit).");
    if (v['gastric'] == 'yes') f.add("K30: Functional Dyspepsia - Chronic gastric/digestive irritation.");

    // --- Activity & Movement ---
    double steps = _parse(a['steps']);
    if (steps > 0 && steps < 5000) f.add("Z72.3: Sedentary Behavior - Risk of metabolic syndrome.");

    // --- Wellbeing & Mental Health ---
    double sleep = _parse(w['sleep_hours']);
    if (sleep > 0 && sleep < 6) f.add("G47.00: Sleep Deprivation - Hormonal & Cognitive recovery impaired.");

    String mood = (w['happiness'] ?? '').toString().toLowerCase();
    if (['sad', 'heartbroken'].contains(mood)) f.add("F32.9: Emotional Distress - Low mood markers logged.");

    // --- Tongue Diagnosis (TCM) ---
    String color = (t['color'] ?? '').toLowerCase();
    String coat = (t['coating'] ?? '').toLowerCase();
    String shape = (t['shape'] ?? '').toLowerCase();

    if (['deep red', 'purple'].contains(color)) f.add("TCM-BS: Blood Stasis - Possible circulation stagnation.");
    if (['thick white', 'yellow', 'greasy'].contains(coat)) f.add("TCM-D: Internal Dampness - Metabolic sluggishness.");
    if (['scalloped', 'swollen'].contains(shape)) f.add("TCM-SP: Spleen Qi Deficiency - Fluid retention & systemic fatigue.");

    return f.isEmpty ? ["Z00.00: No critical clinical flags detected."] : f;
  }

  List<String> _generateDeepClinicalPlan(Map<String, dynamic> data) {
    List<String> p = [];
    final v = data['vitals'] ?? {};
    final d = data['diet'] ?? {};
    final w = data['wellbeing'] ?? {};
    final a = data['activity'] ?? {};
    final t = data['tongue'] ?? {};

    double _parse(dynamic val) => double.tryParse(val?.toString() ?? '0') ?? 0.0;

    // --- Medical & Nutritional Correction ---
    if (_parse(v['systolic']) >= 130) p.add("Vascular: DASH Protocol (Low Sodium) to manage Blood Pressure.");
    if (_parse(v['sugar_level_fasting']) >= 100) p.add("Metabolic: Eliminate processed sugars; switch to High-Fiber complex carbs.");
    if (_parse(v['ldl']) > 130) p.add("Lipids: Increase Soluble Fiber (Oats/Legumes) to clear LDL cholesterol.");
    if (v['gastric'] == 'yes') p.add("Gut: Maintain a 3-hour gap between last meal and sleep; avoid spicy irritants.");

    // --- Physical & Recovery Interventions ---
    if (_parse(a['steps']) < 10000) p.add("Activity: Target 10k steps daily to improve glucose clearance.");
    if (_parse(a['gym_min']) + _parse(a['yoga_min']) < 30) p.add("Strength: 20m of structured Yoga/Gym to support metabolic rate.");

    // --- Neuro-Wellbeing Interventions ---
    if (_parse(w['sleep_hours']) < 7) p.add("Sleep: 'Digital Sunset' (no screens 60m before bed) for Melatonin support.");
    if (_parse(w['meditation_min']) < 10) p.add("Stress: 10m Diaphragmatic breathing to lower sympathetic tone.");
    if (w['hobby'] == 'exploring') p.add("Cognitive: Increase time in hobby to expert-level to trigger 'Flow State' neurochemistry.");

    // --- Tongue Diagnostic Corrective Actions ---
    if (t['coating'] == 'yellow' || t['coating'] == 'greasy') p.add("TCM Diet: Reduce fried/fatty foods to clear 'Internal Heat/Dampness'.");
    if (t['moisture_level'] == 'dry') p.add("Hydration: Increase cellular hydration via electrolytes (Magnesium/Potassium).");
    if (t['shape'] == 'scalloped') p.add("Metabolism: Focus on warm, easy-to-digest cooked meals to support 'Spleen Fire'.");

    return p.isEmpty ? ["Plan: Maintain current health and daily logging."] : p;
  }

  Future<void> _printPdf(double score, List<String> flags, List<String> plan, Map<String, dynamic> data) async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) => pw.Padding(
        padding: const pw.EdgeInsets.all(32),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("COMPREHENSIVE HEALTH DIAGNOSTIC REPORT", style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Divider(thickness: 2),
            pw.SizedBox(height: 20),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Text("Health Index Score: ${score == 0 ? '---' : score.toInt()} / 1000"),
              pw.Text("Status: ${score == 0 ? 'NO DATA' : _getRatingText(score)}"),
            ]),
            pw.SizedBox(height: 30),
            pw.Text("ICD Clinical Risk Flags:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ...flags.map((f) => pw.Bullet(text: f, style: const pw.TextStyle(fontSize: 10))),
            pw.SizedBox(height: 25),
            pw.Text("Clinical Intervention Plan:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ...plan.map((p) => pw.Bullet(text: p, style: const pw.TextStyle(fontSize: 10))),
          ],
        ),
      ),
    ));
    await Printing.layoutPdf(onLayout: (f) => pdf.save());
  }
}