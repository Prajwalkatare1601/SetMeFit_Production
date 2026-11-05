// chat_page.dart
import 'dart:async';
import 'dart:io';
import 'dart:ui'; // for ImageFilter
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '/services/gemini_service.dart';
import 'home_page.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final GeminiService _gemini = GeminiService();
  final List<Map<String, String>> _messages = [];


  bool isListening = false;
  bool _suppressSttUpdates = false;

  Timer? midnightTimer;

  // Controller for the neon background animation
  late AnimationController _neonController;

  @override
  void initState() {
    super.initState();


    // Initialize neon animation
    _neonController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
  }

  // ============================
  // DAILY COUNTERS
  // ============================
  int totalFoodCalories = 0;
  int totalCarbs = 0;
  int totalProtein = 0;
  int totalFat = 0;
  int totalExerciseCalories = 0;

  int targetCalories = 2000;
  int targetCarbs = 250;
  int targetProtein = 125;
  int targetFat = 56;

  int get remCalories =>
      (targetCalories - (totalFoodCalories + totalExerciseCalories))
          .clamp(0, targetCalories);

  // ============================
  // PARSE BOT REPLY
  // ============================
  void parseNutritionFromBot(String reply) {
    String type = _guessTitleFromBotText(reply);

    final calMatch = RegExp(r'Calories[:\s]+(\d+)').firstMatch(reply);
    final carbMatch = RegExp(r'Carbs[:\s]+(\d+)').firstMatch(reply);
    final protMatch = RegExp(r'Protein[:\s]+(\d+)').firstMatch(reply);
    final fatMatch = RegExp(r'Fat[:\s]+(\d+)').firstMatch(reply);

    final int? cal = int.tryParse(calMatch?.group(1) ?? '');
    final int? carb = int.tryParse(carbMatch?.group(1) ?? '');
    final int? prot = int.tryParse(protMatch?.group(1) ?? '');
    final int? fat = int.tryParse(fatMatch?.group(1) ?? '');

    if (type == "Food item") {
      if (cal != null) totalFoodCalories += cal;
      if (carb != null) totalCarbs += carb;
      if (prot != null) totalProtein += prot;
      if (fat != null) totalFat += fat;
    }

    if (type == "Exercise") {
      if (cal != null) totalExerciseCalories += cal;
    }

    setState(() {});
  }

  String _guessTitleFromBotText(String text) {
    if (text.startsWith("Food Item:")) {
      return "Food item";
    } else if (text.startsWith("Exercise:")) {
      return "Exercise";
    }
    return "Item";
  }

  // ============================
  // SEND MESSAGE
  // ============================
  Future<void> sendTextMessage() async {
    _suppressSttUpdates = true;


    if (mounted) setState(() => isListening = false);

    final userMsg = _controller.text.trim();
    if (userMsg.isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "msg": userMsg});
    });

    _controller.clear();

    String botReply;
    try {
      botReply = await _gemini.sendText(userMsg);
    } catch (_) {
      botReply = "Error: failed to get reply";
    }

    parseNutritionFromBot(botReply);

    if (mounted) {
      setState(() {
        _messages.add({"role": "bot", "msg": botReply});
      });
    }

    _suppressSttUpdates = false;
  }

  // ============================
  // PICK IMAGE
  // ============================
  Future<void> pickImage() async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (img == null) return;

    setState(() {
      _messages.add({"role": "user", "msg": "[Image uploaded]"});
    });

    final reply = await _gemini.sendImage(File(img.path));

    parseNutritionFromBot(reply);

    setState(() {
      _messages.add({"role": "bot", "msg": reply});
    });
  }


  @override
  void dispose() {
    _neonController.dispose();
    _controller.dispose();
    midnightTimer?.cancel();

    super.dispose();
  }

  // ============================
  // UI WIDGETS
  // ============================
  Widget _buildTopSummary() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(child: _CaloriesSummaryCard()),
          const SizedBox(width: 12),
          Expanded(child: _MacrosSummaryCard()),
        ],
      ),
    );
  }

  Widget _buildMessageItem(int index) {
    final m = _messages[index];
    final role = m["role"] ?? "bot";
    final text = m["msg"] ?? "";

    if (role == "user") {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: const BoxConstraints(maxWidth: 280),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.18),
                blurRadius: 12,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
        ),
      );
    } else {
      final hasCalories = RegExp(r'Calories[:\s]+\d+').hasMatch(text);
      final hasCarbs = RegExp(r'Carbs[:\s]+\d+').hasMatch(text);
      final hasProtein = RegExp(r'Protein[:\s]+\d+').hasMatch(text);
      final hasFat = RegExp(r'Fat[:\s]+\d+').hasMatch(text);

      final calMatch = RegExp(r'Calories[:\s]+(\d+)').firstMatch(text);
      final int cal = int.tryParse(calMatch?.group(1) ?? '') ?? 0;

      if (hasCarbs || hasProtein || hasFat) {
        final carbMatch = RegExp(r'Carbs[:\s]+(\d+)').firstMatch(text);
        final protMatch = RegExp(r'Protein[:\s]+(\d+)').firstMatch(text);
        final fatMatch = RegExp(r'Fat[:\s]+(\d+)').firstMatch(text);

        final int carb = int.tryParse(carbMatch?.group(1) ?? '') ?? 0;
        final int prot = int.tryParse(protMatch?.group(1) ?? '') ?? 0;
        final int fat = int.tryParse(fatMatch?.group(1) ?? '') ?? 0;

        return Align(
          alignment: Alignment.centerLeft,
          child: BotNutritionCard(
            rawText: text,
            title: _guessTitleFromBotText(text),
            calories: cal,
            carbs: carb,
            protein: prot,
            fat: fat,
          ),
        );
      } else if (hasCalories) {
        return Align(
          alignment: Alignment.centerLeft,
          child: BotExerciseCard(
            rawText: text,
            title: _guessTitleFromBotText(text),
            calories: cal,
          ),
        );
      } else {
        return Align(
          alignment: Alignment.centerLeft,
          child: BotReplyCard(message: text),
        );
      }
    }
  }

  // ============================
  // BUILD
  // ============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Set to transparent to show the neon background underneath
      backgroundColor: const Color(0xFF050505),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Health Bot",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: false,
      ),
      body: Stack(
        children: [
          // THE SHARED NEON BACKGROUND FROM HOME PAGE
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _neonController,
              builder: (context, child) {
                return CustomPaint(
                  painter: UltimateNeonPainter(_neonController.value),
                );
              },
            ),
          ),

          // MAIN CONTENT
          SafeArea(
            child: Column(
              children: [
                // Frosted top container (Updated for dark theme)
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                  child: Container(
                    padding: const EdgeInsets.only(bottom: 8),
                    color: Colors.black.withOpacity(0.3), // Darker for neon depth
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Column(
                        children: [
                          _buildTopSummary(),
                        ],
                      ),
                    ),
                  ),
                ),

                // Chat messages
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) {
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 450),
                        curve: Curves.easeOut,
                        builder: (context, v, child) {
                          return Opacity(
                            opacity: v,
                            child: Transform.translate(
                              offset: Offset(0, (1 - v) * 12),
                              child: child,
                            ),
                          );
                        },
                        child: _buildMessageItem(i),
                      );
                    },
                  ),
                ),

                // Input area (Updated for dark premium theme)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111113).withOpacity(0.95),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.camera_alt),
                        color: Colors.blueAccent,
                        onPressed: pickImage,
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        //onTap: startVoiceInput,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: isListening
                                ? [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.35),
                                blurRadius: 20,
                                spreadRadius: 2,
                              )
                            ]
                                : [],
                          ),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: isListening ? Colors.red : const Color(0xFF1E3A8A),
                            child: Icon(
                              isListening ? Icons.mic : Icons.mic_none,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: TextField(
                            controller: _controller,
                            style: const TextStyle(fontSize: 15, color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: "Type your message...",
                              hintStyle: TextStyle(color: Colors.white38),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      InkWell(
                        onTap: sendTextMessage,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF012A4A),
                                Color(0xFF0077B6),
                                Color(0xFF3B82F6),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: const Icon(Icons.send, color: Colors.white),
                        ),
                      ),
                    ],
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

// ============================
// BOT CARDS & SUMMARY CARDS
// ============================

class _CaloriesSummaryCard extends StatelessWidget {
  const _CaloriesSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final _ChatPageState? parent = context.findAncestorStateOfType<_ChatPageState>();
    final foodValue = parent?.totalFoodCalories ?? 0;
    final exerciseValue = parent?.totalExerciseCalories ?? 0;
    final remCalories = parent?.remCalories ?? 0;
    final targetCalories = parent?.targetCalories ?? 2000;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [ Color(0xFFFF7043), Color(0xFFFFA726), ],),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withOpacity(0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.local_fire_department, color: Color(0xFFFFA726)),
              SizedBox(width: 8),
              Text("Calories", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("$foodValue", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    const Text("Food", style: TextStyle(color: Colors.black54)),
                    const SizedBox(height: 8),
                    _NeonProgressBar(value: (foodValue / targetCalories).clamp(0.0, 1.0), accent: Colors.yellow),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("$exerciseValue", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    const Text("Exercise", style: TextStyle(color: Colors.black54)),
                    const SizedBox(height: 8),
                    _NeonProgressBar(value: (exerciseValue / targetCalories).clamp(0.0, 1.0), accent: Colors.yellow),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("$remCalories", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    const Text("Left", style: TextStyle(color: Colors.black54)),
                    const SizedBox(height: 8),
                    _NeonProgressBar(value: (remCalories / targetCalories).clamp(0.0, 1.0), accent: Colors.yellow),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacrosSummaryCard extends StatelessWidget {
  const _MacrosSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final _ChatPageState? parent = context.findAncestorStateOfType<_ChatPageState>();
    final totalCarbs = parent?.totalCarbs ?? 0;
    final totalProtein = parent?.totalProtein ?? 0;
    final totalFat = parent?.totalFat ?? 0;
    final targetCarbs = parent?.targetCarbs ?? 250;
    final targetProtein = parent?.targetProtein ?? 125;
    final targetFat = parent?.targetFat ?? 56;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF66BB6A), Color(0xFF43A047)],),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.teal.withOpacity(0.18), blurRadius: 16, offset: Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.pie_chart, color: Color(0xFF43A047)),
              SizedBox(width: 8),
              Text("Macros", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _MacroSmall(label: "Carbs", value: "$totalCarbs/$targetCarbs", percent: (totalCarbs/targetCarbs).clamp(0.0,1.0), accent: Colors.blue.shade400),
              const SizedBox(width: 8),
              _MacroSmall(label: "Protein", value: "$totalProtein/$targetProtein", percent: (totalProtein/targetProtein).clamp(0.0,1.0), accent: Colors.pinkAccent),
              const SizedBox(width: 8),
              _MacroSmall(label: "Fat", value: "$totalFat/$targetFat", percent: (totalFat/targetFat).clamp(0.0,1.0), accent: Colors.red),
            ],
          )
        ],
      ),
    );
  }
}

/// small macro widget used in Macros summary
class _MacroSmall extends StatelessWidget {
  final String label;
  final String value;
  final double percent;
  final Color accent;

  const _MacroSmall({
    super.key,
    required this.label,
    required this.value,
    required this.percent,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
          const SizedBox(height: 8),
          _NeonProgressBar(value: percent, accent: accent),
        ],
      ),
    );
  }
}

/// Neon-like glowing progress bar with animation
class _NeonProgressBar extends StatelessWidget {
  final double value;
  final Color? accent;

  const _NeonProgressBar({super.key, required this.value, this.accent});

  @override
  Widget build(BuildContext context) {
    final accentColor = accent ?? Colors.blueAccent;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: value.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, val, child) {
        return Stack(
          alignment: Alignment.centerLeft,
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            Container(
              height: 8,
              width: MediaQuery.of(context).size.width * 0.25 * val,
              // width scaled relative to screen for consistent look inside summary cards
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [accentColor.withOpacity(0.95), accentColor.withOpacity(0.6)]),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(color: accentColor.withOpacity(0.22), blurRadius: 10, spreadRadius: 1),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Bot reply card: general free-text response styled as premium card
class BotReplyCard extends StatelessWidget {
  final String message;
  const BotReplyCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      constraints: const BoxConstraints(maxWidth: 320),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE1BEE7), Color(0xFFCE93D8)], // Light Purple → Medium Purple
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Text(
        message,
        style: const TextStyle(color: Colors.white, fontSize: 15),
      ),
    );
  }
}
String showFrom6thLine(String text) {
  final lines = text.split('\n');
  if (lines.length <= 5) return '';
  return lines.sublist(5).join('\n');
}
/// BotNutritionCard: structured UI for nutrition replies
class BotNutritionCard extends StatelessWidget {
  final String rawText;
  final String title;
  final int calories;
  final int carbs;
  final int protein;
  final int fat;

  const BotNutritionCard({
    super.key,
    required this.rawText,
    required this.title,
    required this.calories,
    required this.carbs,
    required this.protein,
    required this.fat,
  });

  @override
  Widget build(BuildContext context) {
    // Targets: use parent's targets to compute percent bars
    final _ChatPageState? parent = context.findAncestorStateOfType<_ChatPageState>();
    final tCals = parent?.targetCalories ?? 2000;
    final tCarbs = parent?.targetCarbs ?? 250;
    final tProt = parent?.targetProtein ?? 125;
    final tFat = parent?.targetFat ?? 56;

    final calPct = (calories / tCals).clamp(0.0, 1.0);
    final carbPct = (carbs / tCarbs).clamp(0.0, 1.0);
    final protPct = (protein / tProt).clamp(0.0, 1.0);
    final fatPct = (fat / tFat).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(18),
      width: 350,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFCC80), Color(0xFFFFAB91)], // Light Orange → Salmon Orange
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(
          color: Colors.orange.withOpacity(0.25),
          blurRadius: 12,
          offset: const Offset(0, 6),
        )],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rawText,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.black54,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _NutritionMetric(
                  label: "Calories",
                  value: "$calories",
                  percent: calPct,
                  accent: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _NutritionMetric(
                  label: "Carbs",
                  value: "${carbs}g",
                  percent: carbPct,
                  accent: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _NutritionMetric(
                  label: "Protein",
                  value: "${protein}g",
                  percent: protPct,
                  accent: Colors.pinkAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _NutritionMetric(
                  label: "Fat",
                  value: "${fat}g",
                  percent: fatPct,
                  accent: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            showFrom6thLine(rawText),
            style: const TextStyle(fontSize: 13, color: Colors.black54),
            /*maxLines: 1,
            overflow: TextOverflow.ellipsis,*/
          ),
        ],
      ),
    );
  }
}
String showFrom3rdLine(String text) {
  final lines = text.split('\n');
  if (lines.length <= 2) return '';
  return lines.sublist(2).join('\n');
}
/// BotExerciseCard: structured UI for exercise replies
class BotExerciseCard extends StatelessWidget {
  final String rawText;
  final String title;
  final int calories;

  const BotExerciseCard({
    super.key,
    required this.rawText,
    required this.title,
    required this.calories,
  });

  @override
  Widget build(BuildContext context) {
    // Use parent's target calories if available
    final _ChatPageState? parent = context.findAncestorStateOfType<_ChatPageState>();
    final tCals = parent?.targetCalories ?? 2000;

    final calPct = (calories / tCals).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(18),
      width: 350,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors:[
            Color(0xFFFFA6C1), // Light Pink
            Color(0xFFFF6B9B), // Deep Pink
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rawText,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.black54,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _NutritionMetric(
                  label: "Calories",
                  value: "$calories",
                  percent: calPct,
                  accent: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            showFrom3rdLine(rawText),
            style: const TextStyle(fontSize: 13, color: Colors.black54),
            /*maxLines: 1,
            overflow: TextOverflow.ellipsis,*/
          ),
        ],
      ),
    );
  }
}


/// small block inside nutrition card
class _NutritionMetric extends StatelessWidget {
  final String label;
  final String value;
  final double percent;
  final Color accent;

  const _NutritionMetric({
    super.key,
    required this.label,
    required this.value,
    required this.percent,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _NeonProgressBar(value: percent, accent: accent),
        const SizedBox(height: 6),
        Text("${(percent * 100).round()}%", style: const TextStyle(fontSize: 12, color: Colors.black45)),
      ],
    );
  }
}
