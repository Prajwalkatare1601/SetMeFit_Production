import 'dart:async';
import 'dart:ui';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter/cupertino.dart';
import '../providers/food_provider.dart';
import 'custom_meal_page.dart';

class AddFoodPage extends ConsumerStatefulWidget {
  const AddFoodPage({super.key});

  @override
  ConsumerState<AddFoodPage> createState() => _AddFoodPageState();
}

class _AddFoodPageState extends ConsumerState<AddFoodPage>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _bottomInputController = TextEditingController();

  String _query = "";
  String _filter = "all";

  //late stt.SpeechToText _speech;
  bool _isListening = false;

  double _soundLevel = 0.0;
  Timer? _levelDebounce;

  bool _showBottomBar = true;
  late AnimationController _overlayAnimController;

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text.toLowerCase();
      });
    });

    _overlayAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 0.0,
    );
  }

  @override
  void dispose() {
    _levelDebounce?.cancel();
    _overlayAnimController.dispose();

    _searchController.dispose();
    _bottomInputController.dispose();
    super.dispose();
  }

  /// Open quantity sheet (keeps bottom bar visible as requested)
  Future<void> _openQuantitySheet(dynamic item, {bool isMeal = false}) async {
    final TextEditingController qtyController = TextEditingController(text: "1");
    TimeOfDay selectedTime = TimeOfDay.now();
    // bottom bar frozen
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            double getQty() => double.tryParse(qtyController.text) ?? 0;
            double finalQuantity = getQty();

            double carbs = (item['carbs'] ?? 0) * getQty() / 100;
            double protein = (item['protein'] ?? 0) * getQty() / 100;
            double fat = (item['fat'] ?? 0) * getQty() / 100;
            double calories = (item['calories'] ?? 0) * getQty() / 100;

            void _updateQty(double change) {
              double newQty = getQty() + change;
              if (newQty < 0) newQty = 0;
              qtyController.text = newQty.toStringAsFixed(0);
              finalQuantity = newQty;
              setSheetState(() {});
            }

            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("${item['emoji'] ?? "🍴"} ${item['name']}",
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 16),

                  // Textbox
                  Container(
                    width: 200,
                    alignment: Alignment.center,
                    child: TextField(
                      controller: qtyController,
                      keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.orangeAccent),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.orangeAccent),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                          const BorderSide(color: Colors.orange, width: 2),
                        ),
                      ),
                      onChanged: (_) {
                        setSheetState(() {});
                      },
                      onTap: () {
                        // Clear default value when tapped
                        if (qtyController.text == "1") {
                          qtyController.clear();
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Increment/Decrement Buttons
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () => _updateQty(-2),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[900],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 28, vertical: 12),
                        ),
                        child: const Text("-2"),
                      ),
                      ElevatedButton(
                        onPressed: () => _updateQty(-1),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 10),
                        ),
                        child: const Text("-1"),
                      ),
                      ElevatedButton(
                        onPressed: () => _updateQty(1),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 10),
                        ),
                        child: const Text("+1"),
                      ),
                      ElevatedButton(
                        onPressed: () => _updateQty(2),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[900],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 12),
                        ),
                        child: const Text("+2"),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Time Picker
                  TextButton.icon(
                    icon: const Icon(Icons.access_time, color: Colors.orangeAccent),
                    label: Text(
                        "🕒 Time: ${selectedTime.format(context)} [Change]",
                        style: const TextStyle(color: Colors.orangeAccent)),
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: Colors.orangeAccent,
                                onPrimary: Colors.black,
                                surface: Color(0xFF1E1E1E),
                                onSurface: Colors.white,
                              ),
                              dialogBackgroundColor: const Color(0xFF121212),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) setSheetState(() => selectedTime = picked);
                    },
                  ),

                  const SizedBox(height: 16),

                  // Macro Chips
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _macroChip("Carbs", "${carbs.toStringAsFixed(1)} g",
                          Colors.orangeAccent),
                      _macroChip("Protein", "${protein.toStringAsFixed(1)} g",
                          Colors.greenAccent),
                      _macroChip("Fat", "${fat.toStringAsFixed(1)} g",
                          Colors.blueAccent),
                      _macroChip("Calories", "${calories.toStringAsFixed(0)} kcal",
                          Colors.redAccent),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Add to Log Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.orange[900],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        try {
                          // Capture final quantity before inserting
                          finalQuantity = getQty();

                          final now = DateTime.now();
                          final consumedAt = DateTime(
                            now.year,
                            now.month,
                            now.day,
                            selectedTime.hour,
                            selectedTime.minute,
                          ).toIso8601String();

                          final supabase = ref.read(supabaseProvider);
                          final userId = supabase.auth.currentUser?.id;
                          if (userId == null) throw Exception("User not logged in");

                          if (isMeal) {
                            await supabase.from('meal_logs').insert({
                              'user_id': userId,
                              'meal_id': item['id'],
                              'quantity': finalQuantity,
                              'consumed_at': consumedAt,
                            });
                          } else {
                            await supabase.from('food_logs').insert({
                              'user_id': userId,
                              'food_id': item['id'],
                              'quantity': finalQuantity,
                              'consumed_at': consumedAt,
                            });
                          }

                          Navigator.pop(context);
                          Navigator.pop(context, item['name']); // Return to HomePage

                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Failed to add: $e"),
                              backgroundColor: Colors.red[900],
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      },
                      child: const Text("Add to Log"),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      // keep bottom bar visible
      if (mounted) setState(() => _showBottomBar = true);
    });
  }

  Widget _macroChip(String label, String value, Color color) {
    return Chip(
      label: Text("$label: $value"),
      backgroundColor: color.withOpacity(0.15),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
      side: BorderSide(color: color.withOpacity(0.4)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final foodsAsync = ref.watch(sortedFoodsProvider);
    final favoritesAsync = ref.watch(favoritesProvider);
    final mealsAsync = ref.watch(userMealsProvider);
    final ImagePicker _picker = ImagePicker();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text("Add Food"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Hidden search bar for internal filtering only
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Type to search foods...",
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    prefixIcon: const Icon(Icons.search, color: Colors.orangeAccent),
                    filled: true,
                    fillColor: Colors.grey[900],
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.orangeAccent, width: 1.5),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _filterButton("All", "all"),
                    //_filterButton("My Meals", "meals"),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Builder(builder: (context) {
                    final favorites = favoritesAsync.asData?.value ?? [];
                    final allFoods =
                    foodsAsync.maybeWhen(data: (f) => f, orElse: () => []);
                    final allMeals =
                    mealsAsync.maybeWhen(data: (m) => m, orElse: () => []);

                    List<dynamic> filteredFoods = [];
                    List<dynamic> filteredMeals = [];

                    switch (_filter) {
                      case "all":
                        filteredFoods = allFoods
                            .where((f) =>
                            f['name'].toString().toLowerCase().contains(_query))
                            .toList()
                          ..sort((a, b) {
                            final aFav = favorites.contains(a['id']) ? 0 : 1;
                            final bFav = favorites.contains(b['id']) ? 0 : 1;
                            return aFav.compareTo(bFav);
                          });
                        break;
                      case "meals":
                        filteredMeals = allMeals
                            .where((m) =>
                            m['name'].toString().toLowerCase().contains(_query))
                            .toList();
                        break;
                    }

                    if (filteredFoods.isEmpty && filteredMeals.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          ":( No items found :(",
                          style: TextStyle(
                            color: Colors.orangeAccent,
                            fontStyle: FontStyle.italic,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_filter == "meals" && filteredMeals.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: ExpansionTile(
                              initiallyExpanded: true,
                              backgroundColor: Colors.grey[900],
                              collapsedBackgroundColor: Colors.grey[900],
                              title: const Text("My Meals",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                              iconColor: Colors.orangeAccent,
                              collapsedIconColor: Colors.orangeAccent,
                              children:
                              filteredMeals.map((meal) => _mealCard(meal, allFoods)).toList(),
                            ),
                          ),
                        if (filteredFoods.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_filter == "all")
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Text("Common Foods",
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white70)),
                                  ),
                                ...filteredFoods.map((food) => _foodCard(food)),
                              ],
                            ),
                          ),
                      ],
                    );
                  }),
                ),
              ),
              if (_filter == "meals")
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text("Add Custom Meal"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[900],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        final added = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CustomMealPage()),
                        );
                        if (added == true) {
                          ref.refresh(userMealsProvider);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Custom meal added ✅"),
                              backgroundColor: Color(0xFF1B5E20),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),
            ],
          ),

          // Bottom frozen bar with mic (single)
          if (_showBottomBar)
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                top: false,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.92),
                    border: Border(top: BorderSide(color: Colors.grey.shade800)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      // Camera
                      IconButton(
                        icon: const Icon(Icons.camera_alt),
                        color: Colors.orangeAccent,
                        onPressed: () async {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            barrierColor: Colors.black.withOpacity(0.85),
                            builder: (context) {
                              return Center(
                                child: HoloGlassDialog(
                                  onCapture: () async {
                                    final XFile? image =
                                    await _picker.pickImage(source: ImageSource.camera);
                                    if (image != null) {
                                      print("Captured Image path: ${image.path}");
                                    }
                                    //Navigator.pop(context);
                                  },
                                  onUpload: () async {
                                    final XFile? image = await _picker.pickImage(
                                        source: ImageSource.gallery);
                                    if (image != null) {
                                      print("Uploaded Image path: ${image.path}");
                                    }
                                    //Navigator.pop(context);
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),

                      // Text input (Flexible prevents overflow)
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey[850],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: _bottomInputController,
                            maxLines: 4,
                            minLines: 1,
                            keyboardType: TextInputType.multiline,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isCollapsed: true,
                              hintText: "Type or speak here...",
                              hintStyle: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        //onTap: _startListening,
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: _isListening ? Colors.red[700] : Colors.orange[800],
                          child: Icon(_isListening ? Icons.mic : Icons.mic_none,
                              color: Colors.white, size: 24),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          backgroundColor: Colors.orange[900],
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          final text = _bottomInputController.text.trim();
                          if (text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Nothing to send")));
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Sent: $text")));
                          _bottomInputController.clear();
                        },
                        child: const Icon(Icons.send),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Full-screen glassmorphism overlay with ripple animation
          AnimatedBuilder(
            animation: _overlayAnimController,
            builder: (context, child) {
              final opacity = _overlayAnimController.value;
              if (!_isListening && opacity == 0.0) return const SizedBox.shrink();
              return Opacity(opacity: opacity, child: child);
            },
            child: (_isListening)
                ? Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                //onTap: _stopListening,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    /// FULL SCREEN GLASSMORPHISM
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: Colors.black.withOpacity(0.65),
                      ),
                    ),

                    /// --- Ripple + Mic at EXACT CENTER ---
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RippleMic(level: _soundLevel),
                        const SizedBox(height: 0),
                      ],
                    ),

                    /// Large glowing mic on top of ripple
                    _AnimatedGlowingMic(),

                    /// --- Listening Text ---
                    Positioned(
                      bottom: MediaQuery.of(context).size.height * 0.20,
                      child: Column(
                        children: const [
                          Text(
                            "Listening . . .",
                            style: TextStyle(
                              color: Colors.orangeAccent,
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Tap anywhere to stop recording",
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _filterButton(String label, String value) {
    final bool isSelected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange[900] : Colors.grey[850],
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: Colors.orange.withOpacity(0.35),
              offset: const Offset(0, 4),
              blurRadius: 10,
            )
          ]
              : [],
        ),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 250),
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          child: Text(label),
        ),
      ),
    );
  }

  Widget _mealCard(dynamic meal, List<dynamic> foodsData) {
    double carbs = 0, protein = 0, fat = 0, calories = 0;

    final ingredients = meal['user_meal_items'] ?? [];
    for (var ing in ingredients) {
      final Map<String, dynamic>? food = foodsData
          .cast<Map<String, dynamic>?>()
          .firstWhere((f) => f?['id'] == ing['food_id'], orElse: () => null);

      if (food != null) {
        final qty = ing['quantity']?.toDouble() ?? 0;
        carbs += (food['carbs'] ?? 0) * qty;
        protein += (food['protein'] ?? 0) * qty;
        fat += (food['fat'] ?? 0) * qty;
        calories += (food['calories'] ?? 0) * qty;
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: ListTile(
        leading: Text(meal['emoji'] ?? "🍱", style: const TextStyle(fontSize: 28)),
        title: Text(meal['name'],
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        subtitle: Text(
          "🍚 ${carbs.toStringAsFixed(1)}g  |  🥩 ${protein.toStringAsFixed(1)}g  |  🧈 ${fat.toStringAsFixed(1)}g  |  🔥 ${calories.toStringAsFixed(0)} kcal",
          style: TextStyle(fontSize: 12, color: Colors.grey[300]),
        ),
        onTap: () => _openQuantitySheet(meal, isMeal: true),
      ),
    );
  }

  Widget _foodCard(dynamic food) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading:
        Text(food['emoji'] ?? "🍴", style: const TextStyle(fontSize: 28)),
        title: Text(food['name'],
            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
        subtitle: Text(
          "Carbs: ${food['carbs']}g | Protein: ${food['protein']}g | Fat: ${food['fat']}g",
          style: TextStyle(fontSize: 12, color: Colors.grey[400]),
        ),
        trailing: Consumer(
          builder: (context, ref, _) {
            final favorites = ref.watch(favoritesProvider).asData?.value ?? [];
            final isFav = favorites.contains(food['id']);
            return IconButton(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  key: ValueKey(food['id']),
                  color: isFav ? Colors.redAccent : Colors.grey[600],
                ),
              ),
              onPressed: () {
                final toggleFavorite = ref.read(favoriteActionsProvider);
                toggleFavorite(food['id'], isFav);
              },
            );
          },
        ),
        onTap: () => _openQuantitySheet(food, isMeal: false),
      ),
    );
  }
}

/// Unique ripple animation for mic overlay
class RippleMic extends StatelessWidget {
  final double level;
  const RippleMic({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    final double baseSize = 48;
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (int i = 1; i <= 3; i++)
            Container(
              width: baseSize + level * 40.0 * i,
              height: baseSize + level * 40.0 * i,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.orangeAccent.withOpacity(0.12 / i + level * 0.25),
              ),
            ),
        ],
      ),
    );
  }
}

/// Animated bouncing + glowing mic icon
class _AnimatedGlowingMic extends StatefulWidget {
  @override
  State<_AnimatedGlowingMic> createState() => _AnimatedGlowingMicState();
}

class _AnimatedGlowingMicState extends State<_AnimatedGlowingMic>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _scaleAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _glowAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) {
        return Transform.scale(
          scale: _scaleAnim.value,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.orangeAccent.withOpacity(_glowAnim.value * 0.7),
                  blurRadius: 60,
                  spreadRadius: 25,
                ),
              ],
              gradient: LinearGradient(
                colors: [
                  Colors.orangeAccent.withOpacity(0.9),
                  Colors.deepOrange.withOpacity(0.75),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: const Icon(Icons.mic, size: 70, color: Colors.white),
          ),
        );
      },
    );
  }
}

class HoloGlassDialog extends StatelessWidget {
  final VoidCallback onCapture;
  final VoidCallback onUpload;

  const HoloGlassDialog({
    super.key,
    required this.onCapture,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.orangeAccent.withOpacity(0.6),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.orangeAccent.withOpacity(0.4),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.75),
                    const Color(0xFF1A0F00).withOpacity(0.65),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Select Option",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withOpacity(0.95),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Choose how you want to add an image",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontStyle: FontStyle.italic,
                      color: Colors.white.withOpacity(0.75),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Capture Live
                  GestureDetector(
                    onTap: onCapture,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [
                            Colors.orangeAccent.withOpacity(0.8),
                            Colors.deepOrangeAccent.withOpacity(0.8),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orangeAccent.withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          "Capture Live",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Upload Image
                  GestureDetector(
                    onTap: onUpload,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orangeAccent.withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          "Upload Image",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 17,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Cancel
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.25),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          "Cancel",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                            fontSize: 16,
                          ),
                        ),
                      ),
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
}