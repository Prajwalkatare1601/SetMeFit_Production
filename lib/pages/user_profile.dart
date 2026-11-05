import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import '../login/login_page.dart';
import 'dart:ui';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: UserProfilePage(),
  ));
}

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();

  Uint8List? _profileBytes;
  Uint8List? _backgroundBytes;
  Map<String, dynamic>? _cardAvatar;

  String userName = 'YOUR_USER_NAME';
  String firstName = "";
  String nickName = "";
  String lastName = "";
  String userBio = 'Bio-Metric Status: Optimal. Neural Link: Stable. Current Objective: Peak Physical Transcendence.';
  String userAge = 'NM';
  String userGender = 'NM';
  String userHeight = '0';
  String userWeight = '0';
  String userGoal = 'NA';
  String healthScore = '0';
  double userBMI = 0.0;

  String userDOB = ""; // Add this to your State class variables

  Future<void> _fetchUserData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final data = await Supabase.instance.client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();

    setState(() {
      firstName = data['first_name'] ?? "USER";
      lastName = data['last_name'] ?? "X";
      nickName = data['nickname'] ?? "X";
      userAge = data['age']?.toString() ?? "0";
      userHeight = data['height']?.toString() ?? "0";
      userWeight = data['weight']?.toString() ?? "0";
      userGender = data['gender'] ?? "N/A";
      userGoal = data['goal'] ?? "N/A";
      userBMI = (data['bmi'] ?? 0.0).toDouble();
      healthScore = data['health_score']?.toString() ?? "0";
      // Fetching the new DOB column
      userDOB = data['dob'] ?? "NOT_SET";
    });
  }

  List<Map<String, dynamic>> userAchievements = [
    {'title': 'HEART_SYNC', 'icon': Icons.monitor_heart, 'color': Colors.redAccent, 'endorsements': 0, 'details': ''},
    {'title': 'OXYGEN_MAX', 'icon': Icons.air, 'color': Colors.deepPurpleAccent, 'endorsements': 0, 'details': ''},
  ];

  List<Map<String, dynamic>> _cyberPosts = [];

  final TextEditingController _editController = TextEditingController();
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();

  final List<IconData> _healthIcons = [
    Icons.monitor_heart, Icons.fitness_center, Icons.directions_run, Icons.self_improvement,
    Icons.local_fire_department, Icons.water_drop, Icons.restaurant, Icons.timer,
    Icons.bolt, Icons.spa, Icons.medication, Icons.psychology,
    Icons.height, Icons.speed, Icons.shield, Icons.biotech,
    Icons.pool, Icons.directions_bike, Icons.nightlight_round, Icons.scale,
  ];

  final List<Color> _neonColors = [
    Colors.cyanAccent, Colors.greenAccent, Colors.purpleAccent, Colors.pinkAccent,
    Colors.orangeAccent, Colors.redAccent, Colors.yellowAccent, Colors.indigoAccent,
    const Color(0xFF00FF88), const Color(0xFFCCFF00), const Color(0xFFFF00FF), const Color(0xFF7000FF),
  ];

  // Emoji-based avatars with individual background colors
  final List<Map<String, dynamic>> _maleAvatars = [
    {'emoji': '👨‍⚕️', 'label': 'DOCTOR', 'bgColor': Colors.redAccent},
    {'emoji': '👨‍🏫', 'label': 'TRAINER', 'bgColor': Colors.greenAccent},
    {'emoji': '👨‍🔬', 'label': 'SCIENTIST', 'bgColor': Colors.purpleAccent},
    {'emoji': '👨‍💻', 'label': 'PROGRAMMER', 'bgColor': Colors.indigoAccent},
    {'emoji': '👨‍🚀', 'label': 'ASTRONAUT', 'bgColor': Colors.blueAccent},
    {'emoji': '👨‍✈️', 'label': 'PILOT', 'bgColor': Colors.orangeAccent},
    {'emoji': '👨‍🚒', 'label': 'FIREFIGHTER', 'bgColor': Colors.red},
    {'emoji': '👮‍♂️', 'label': 'POLICE', 'bgColor': Colors.blue},
    {'emoji': '👷‍♂️', 'label': 'CONSTRUCTION', 'bgColor': Colors.yellowAccent},
    {'emoji': '🏃‍♂️', 'label': 'RUNNER', 'bgColor': Colors.orange},
    {'emoji': '🏊‍♂️', 'label': 'SWIMMER', 'bgColor': Colors.cyan},
    {'emoji': '🚴‍♂️', 'label': 'CYCLIST', 'bgColor': Colors.green},
    {'emoji': '🏋️‍♂️', 'label': 'WEIGHTLIFTER', 'bgColor': Colors.purple},
    {'emoji': '🤸‍♂️', 'label': 'GYMNAST', 'bgColor': Colors.pinkAccent},
    {'emoji': '⛹️‍♂️', 'label': 'BASKETBALL', 'bgColor': Colors.orange},
    {'emoji': '⚽', 'label': 'FOOTBALLER', 'bgColor': Colors.greenAccent},
    {'emoji': '🎾', 'label': 'TENNIS', 'bgColor': Colors.yellow},
    {'emoji': '🏐', 'label': 'VOLLEYBALL', 'bgColor': Colors.lightBlueAccent},
    {'emoji': '🥋', 'label': 'MARTIAL ARTIST', 'bgColor': Colors.black},
    {'emoji': '🏄‍♂️', 'label': 'SURFER', 'bgColor': Colors.cyanAccent},
    {'emoji': '🏂', 'label': 'SNOWBOARDER', 'bgColor': Colors.blueGrey},
    {'emoji': '⛷️', 'label': 'SKIER', 'bgColor': Colors.lightBlue},
    {'emoji': '🧗‍♂️', 'label': 'CLIMBER', 'bgColor': Colors.deepOrange},
    {'emoji': '🤺', 'label': 'FENCER', 'bgColor': Colors.purpleAccent},
    {'emoji': '🏌️‍♂️', 'label': 'GOLFER', 'bgColor': Colors.green},
    {'emoji': '🏇', 'label': 'HORSE RACING', 'bgColor': Colors.brown},
    {'emoji': '🛼', 'label': 'SKATER', 'bgColor': Colors.pink},
    {'emoji': '🧘‍♂️', 'label': 'YOGI', 'bgColor': Colors.teal},
    {'emoji': '💪', 'label': 'STRONG MAN', 'bgColor': Colors.redAccent},
    {'emoji': '👨‍🍳', 'label': 'NUTRITIONIST', 'bgColor': Colors.limeAccent},
  ];

  final List<Map<String, dynamic>> _femaleAvatars = [
    {'emoji': '👩‍⚕️', 'label': 'DOCTOR', 'bgColor': Colors.redAccent},
    {'emoji': '👩‍🏫', 'label': 'TRAINER', 'bgColor': Colors.greenAccent},
    {'emoji': '👩‍🔬', 'label': 'SCIENTIST', 'bgColor': Colors.purpleAccent},
    {'emoji': '👩‍💻', 'label': 'PROGRAMMER', 'bgColor': Colors.indigoAccent},
    {'emoji': '👩‍🚀', 'label': 'ASTRONAUT', 'bgColor': Colors.blueAccent},
    {'emoji': '👩‍✈️', 'label': 'PILOT', 'bgColor': Colors.orangeAccent},
    {'emoji': '👩‍🚒', 'label': 'FIREFIGHTER', 'bgColor': Colors.red},
    {'emoji': '👮‍♀️', 'label': 'POLICE', 'bgColor': Colors.blue},
    {'emoji': '👷‍♀️', 'label': 'CONSTRUCTION', 'bgColor': Colors.yellowAccent},
    {'emoji': '🏃‍♀️', 'label': 'RUNNER', 'bgColor': Colors.orange},
    {'emoji': '🏊‍♀️', 'label': 'SWIMMER', 'bgColor': Colors.cyan},
    {'emoji': '🚴‍♀️', 'label': 'CYCLIST', 'bgColor': Colors.green},
    {'emoji': '🏋️‍♀️', 'label': 'WEIGHTLIFTER', 'bgColor': Colors.purple},
    {'emoji': '🤸‍♀️', 'label': 'GYMNAST', 'bgColor': Colors.pinkAccent},
    {'emoji': '⛹️‍♀️', 'label': 'BASKETBALL', 'bgColor': Colors.orange},
    {'emoji': '⚽', 'label': 'FOOTBALLER', 'bgColor': Colors.greenAccent},
    {'emoji': '🎾', 'label': 'TENNIS', 'bgColor': Colors.yellow},
    {'emoji': '🏐', 'label': 'VOLLEYBALL', 'bgColor': Colors.lightBlueAccent},
    {'emoji': '🥋', 'label': 'MARTIAL ARTIST', 'bgColor': Colors.black},
    {'emoji': '🏄‍♀️', 'label': 'SURFER', 'bgColor': Colors.cyanAccent},
    {'emoji': '🏂', 'label': 'SNOWBOARDER', 'bgColor': Colors.blueGrey},
    {'emoji': '⛷️', 'label': 'SKIER', 'bgColor': Colors.lightBlue},
    {'emoji': '🧗‍♀️', 'label': 'CLIMBER', 'bgColor': Colors.deepOrange},
    {'emoji': '🤺', 'label': 'FENCER', 'bgColor': Colors.purpleAccent},
    {'emoji': '🏌️‍♀️', 'label': 'GOLFER', 'bgColor': Colors.green},
    {'emoji': '🏇', 'label': 'HORSE RACING', 'bgColor': Colors.brown},
    {'emoji': '🛼', 'label': 'SKATER', 'bgColor': Colors.pink},
    {'emoji': '🧘‍♀️', 'label': 'YOGI', 'bgColor': Colors.teal},
    {'emoji': '💪', 'label': 'STRONG WOMAN', 'bgColor': Colors.redAccent},
    {'emoji': '👩‍🍳', 'label': 'NUTRITIONIST', 'bgColor': Colors.limeAccent},
  ];

  bool _isMaleSection = true;

  late AnimationController _rocketController;
  late Animation<double> _rocketAnimation;

  bool _showRocketOverlay = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _rocketController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _rocketAnimation = Tween<double>(begin: 1.2, end: -1.8).animate(
      CurvedAnimation(parent: _rocketController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _rocketController.dispose();
    _editController.dispose();
    _captionController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _handleImagePick(ImageSource source, String target) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 95,
      maxWidth: 2048,
      maxHeight: 2048,
    );
    if (image != null) {
      final Uint8List bytes = await image.readAsBytes();
      if (target == 'gallery') {
        _showPostCreator(bytes);
      } else {
        setState(() {
          if (target == 'profile') {
            _profileBytes = bytes;
          }
          if (target == 'background') _backgroundBytes = bytes;
        });
      }
    }
  }

  void _showPostCreator(Uint8List bytes) {
    _captionController.clear();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: 400,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.cyanAccent.withOpacity(0.3), width: 1.2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("UPLOAD_MEMORY", style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, letterSpacing: 4, fontSize: 13)),
                    const SizedBox(height: 20),
                    ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.memory(bytes, height: 200, width: double.infinity, fit: BoxFit.cover)),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _captionController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(hintText: "WRITE_CAPTION...", hintStyle: TextStyle(color: Colors.white12)),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);

                        setState(() {
                          _cyberPosts.insert(0, {
                            'image': bytes,
                            'caption': _captionController.text,
                            'likes': 0,
                            'isLiked': false,
                            'comments': <Map<String, String>>[],
                            'reactions': 0,
                            'selectedReactions': <String>[],
                          });
                          _showRocketOverlay = true;
                        });

                        _rocketController.reset();
                        _rocketController.forward().then((_) {
                          setState(() {
                            _showRocketOverlay = false;
                          });
                        });
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
                      child: const Text("LAUNCH", style: TextStyle(color: Colors.black)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showNeonDialog({required String title, required Widget content, List<Widget>? actions, double width = 550}) {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: width,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.cyanAccent.withOpacity(0.3), width: 1.2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(title, style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, letterSpacing: 4, fontSize: 13)),
                const SizedBox(height: 20),
                content,
                if (actions != null) ...[const SizedBox(height: 20), Row(mainAxisAlignment: MainAxisAlignment.end, children: actions)]
              ]),
            ),
          ),
        ),
      ),
    );
  }

  void _manageAchievements() {
    _showNeonDialog(
      title: "PROTOCOL_ACCESS",
      width: 400,
      content: Column(
        children: [
          _buildActionTile(Icons.add_circle_outline, "ADD NEW PROTOCOL", Colors.cyanAccent, _showAchieveCreator),
          _buildActionTile(Icons.remove_circle_outline, "PURGE DATA", Colors.redAccent, _showAchieveDeleter),
        ],
      ),
    );
  }

  void _showAchieveCreator() {
    Navigator.pop(context);
    IconData selectedIcon = _healthIcons[0];
    Color selectedColor = _neonColors[0];
    _editController.clear();

    _showNeonDialog(
      title: "INITIALIZE_NEW_DATA",
      width: 600,
      content: StatefulBuilder(
        builder: (context, setST) => Column(
          children: [
            TextField(
              controller: _editController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "PROTOCOL_ID",
                hintStyle: const TextStyle(color: Colors.white60),
                filled: true, fillColor: Colors.white10,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),
            const Text("MAPPING_ICON", style: TextStyle(color: Colors.cyanAccent, fontSize: 10)),
            const SizedBox(height: 10),
            Container(
              height: 180,
              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(20)),
              child: GridView.builder(
                padding: const EdgeInsets.all(10),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, mainAxisSpacing: 8, crossAxisSpacing: 8),
                itemCount: _healthIcons.length,
                itemBuilder: (context, i) => GestureDetector(
                  onTap: () => setST(() => selectedIcon = _healthIcons[i]),
                  child: Container(
                    decoration: BoxDecoration(
                      color: selectedIcon == _healthIcons[i] ? Colors.cyanAccent.withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: selectedIcon == _healthIcons[i] ? Colors.cyanAccent : Colors.transparent),
                    ),
                    child: Icon(_healthIcons[i], color: selectedIcon == _healthIcons[i] ? Colors.cyanAccent : Colors.white24, size: 20),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10, runSpacing: 10,
              children: _neonColors.map((c) => GestureDetector(
                onTap: () => setST(() => selectedColor = c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: c, shape: BoxShape.circle,
                    border: Border.all(color: selectedColor == c ? Colors.white : Colors.transparent, width: 2),
                    boxShadow: [if(selectedColor == c) BoxShadow(color: c.withOpacity(0.5), blurRadius: 10)],
                  ),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            if (_editController.text.isNotEmpty) {
              setState(() => userAchievements.add({'title': _editController.text.toUpperCase(), 'icon': selectedIcon, 'color': selectedColor, 'endorsements': 0, 'details': ''}));
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
          child: const Text("SYNC_DATA"),
        )
      ],
    );
  }

  void _showAchieveDeleter() {
    Navigator.pop(context);
    _showNeonDialog(
      title: "TERMINATE_PROTOCOLS",
      width: 400,
      content: SizedBox(
        height: 250, width: double.maxFinite,
        child: ListView.builder(
          itemCount: userAchievements.length,
          itemBuilder: (context, i) => ListTile(
            leading: Icon(userAchievements[i]['icon'], color: userAchievements[i]['color']),
            title: Text(userAchievements[i]['title'], style: const TextStyle(color: Colors.white, fontSize: 12)),
            trailing: const Icon(Icons.close, color: Colors.redAccent, size: 16),
            onTap: () { setState(() => userAchievements.removeAt(i)); Navigator.pop(context); },
          ),
        ),
      ),
    );
  }

  void _showEditProfileDialog() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final TextEditingController firstNameController = TextEditingController(text: firstName);
    final TextEditingController lastNameController = TextEditingController(text: lastName);
    final TextEditingController nickNameController = TextEditingController(text: nickName);
    final TextEditingController heightController = TextEditingController(text: userHeight);
    final TextEditingController weightController = TextEditingController(text: userWeight);

    String? selectedGoal = ["Lose Weight", "Gain Weight", "Maintain Weight"].contains(userGoal)
        ? userGoal
        : "Maintain Weight";

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Center(
          child: SingleChildScrollView(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.cyanAccent.withOpacity(0.4)),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("UPDATE AGENT DATA",
                          style: TextStyle(color: Colors.cyanAccent, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 4)),
                      const SizedBox(height: 20),

                      // --- READ ONLY DATA SECTION (LOCKED) ---
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.lock_outline, color: Colors.amberAccent, size: 14),
                                SizedBox(width: 8),
                                Text("LOCKED IDENTITY PROTOCOLS",
                                    style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildLockedData("DOB", userDOB),
                                _buildLockedData("AGE", userAge),
                                _buildLockedData("GENDER", userGender),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // --- EDITABLE FIELDS ---
                      Row(
                        children: [
                          Expanded(child: _buildDialogField("FIRST NAME", firstNameController)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildDialogField("LAST NAME", lastNameController)),
                        ],
                      ),
                      _buildDialogField("NICKNAME", nickNameController),

                      const SizedBox(height: 15),

                      DropdownButtonFormField<String>(
                        value: selectedGoal,
                        dropdownColor: Colors.black,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: "GOAL",
                          labelStyle: TextStyle(color: Colors.cyanAccent, fontSize: 12),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                        ),
                        items: ["Lose Weight", "Gain Weight", "Maintain Weight"]
                            .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (val) => setDialogState(() => selectedGoal = val),
                      ),

                      const SizedBox(height: 15),

                      Row(
                        children: [
                          Expanded(child: _buildDialogField("HEIGHT (CM)", heightController, isNumber: true)),
                          const SizedBox(width: 15),
                          Expanded(child: _buildDialogField("WEIGHT (KG)", weightController, isNumber: true)),
                        ],
                      ),

                      const SizedBox(height: 30),

                      InkWell(
                        onTap: () async {
                          double h = double.tryParse(heightController.text) ?? 0;
                          double w = double.tryParse(weightController.text) ?? 0;
                          double bmiValue = (h > 0 && w > 0) ? (w / ((h / 100) * (h / 100))) : 0;
                          // BMI kept to 1 decimal point as per your requirement
                          bmiValue = double.parse(bmiValue.toStringAsFixed(1));

                          try {
                            await Supabase.instance.client.from('profiles').update({
                              'first_name': firstNameController.text.trim(),
                              'last_name': lastNameController.text.trim(),
                              'nickname': nickNameController.text.trim(),
                              'goal': selectedGoal,
                              'height': h,
                              'weight': w,
                              'bmi': bmiValue,
                              // Note: age, dob, and gender are excluded from update
                              // to prevent any edit access as requested.
                            }).eq('id', user.id);

                            await _fetchUserData();

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("PROFILE PROTOCOL UPDATED", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                  backgroundColor: Colors.cyanAccent,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              Navigator.pop(context);
                            }
                          } catch (error) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("UPDATE FAILED: ${error.toString().toUpperCase()}"),
                                  backgroundColor: Colors.redAccent,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                              color: Colors.cyanAccent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(color: Colors.cyanAccent.withOpacity(0.3), blurRadius: 10)
                              ]
                          ),
                          child: const Center(child: Text("UPDATE DATABASE", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

// Helper widget to build the read-only pods
  Widget _buildLockedData(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildDialogField(String label, TextEditingController controller, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.cyanAccent),
          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
        ),
      ),
    );
  }

  void _showAvatarSelector() {
    _isMaleSection = (userGender == 'Male');
    _showNeonDialog(
      title: "SELECT_AVATAR_PROTOCOL",
      width: 680,
      content: StatefulBuilder(
        builder: (context, setDialogState) {
          final currentList = _isMaleSection ? _maleAvatars : _femaleAvatars;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => setDialogState(() => _isMaleSection = true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isMaleSection ? Colors.cyanAccent : Colors.black38,
                      minimumSize: const Size(100, 40),
                    ),
                    child: const Text("MALE", style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(width: 30),
                  ElevatedButton(
                    onPressed: () => setDialogState(() => _isMaleSection = false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !_isMaleSection ? Colors.cyanAccent : Colors.black38,
                      minimumSize: const Size(100, 40),
                    ),
                    child: const Text("FEMALE", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 520,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 15,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: currentList.length,
                  itemBuilder: (context, i) {
                    final avatar = currentList[i];
                    final Color bg = avatar['bgColor'] ?? Colors.cyanAccent;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _cardAvatar = {
                            'emoji': avatar['emoji'],
                            'label': avatar['label'],
                            'color': bg,
                          };
                        });
                        Navigator.pop(context);
                      },
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: bg.withOpacity(0.25),
                              border: Border.all(color: bg, width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: bg.withOpacity(0.5),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                avatar['emoji'],
                                style: const TextStyle(fontSize: 42),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            avatar['label'],
                            style: const TextStyle(color: Colors.white70, fontSize: 10.5, letterSpacing: 1.5),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSettingsMenu(BuildContext context, Offset offset) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(offset, offset),
        Offset.zero & overlay.size,
      ),
      color: Colors.black87.withOpacity(0.9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.cyanAccent.withOpacity(0.4), width: 1.5),
      ),
      elevation: 0,
      items: [
        PopupMenuItem(
          enabled: false,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMenuItem(Icons.edit, "EDIT PROFILE", null, () {
                  Navigator.pop(context);
                  _showEditProfileDialog();
                }),
                const Divider(color: Colors.white10, height: 20),
                _buildMenuItem(Icons.person_outline, "CHANGE AVATAR", null, () {
                  Navigator.pop(context);
                  _showAvatarSelector();
                }),
                const Divider(color: Colors.white10, height: 20),
                _buildMenuItem(Icons.logout, "LOGOUT", Colors.red, () async {
                  Navigator.pop(context);

                  try {
                    await Supabase.instance.client.auth.signOut();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("LOGGED OUT SUCCESSFULLY", style: TextStyle(color: Colors.black)),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                     Navigator.pushAndRemoveUntil(
                       context,
                       MaterialPageRoute(builder: (context) => LoginPage(preLoginData: {})),
                       (route) => false,
                    );
                  } catch (error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Logout failed: $error"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String label, [Color? color, VoidCallback? onTap]) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color ?? Colors.cyanAccent, size: 18),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: color ?? Colors.white,
              fontSize: 12,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _endorseAchievement(int index) {
    setState(() {
      userAchievements[index]['endorsements']++;
    });
  }

  void _showAchievementDetails(int index) {
    _detailsController.text = userAchievements[index]['details'];
    _showNeonDialog(
      title: "ACHIEVEMENT_DETAILS",
      width: 400,
      content: Column(
        children: [
          Text(userAchievements[index]['title'], style: const TextStyle(color: Colors.white, fontSize: 16)),
          const SizedBox(height: 10),
          TextField(
            controller: _detailsController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(hintText: "Why did you choose this? When did you do it? etc.", hintStyle: TextStyle(color: Colors.white12)),
            maxLines: 5,
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            setState(() {
              userAchievements[index]['details'] = _detailsController.text;
            });
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
          child: const Text("SAVE", style: TextStyle(color: Colors.black)),
        )
      ],
    );
  }

  Widget _buildAgentIdSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "AGENT'S ID (PRIVATE TO YOU)",
          style: TextStyle(color: Colors.cyanAccent, fontSize: 12, letterSpacing: 3, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.cyanAccent.withOpacity(0.25), width: 1.2),
          ),
          child: Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _cardAvatar != null ? (_cardAvatar!['color'] as Color).withOpacity(0.22) : Colors.white10,
                      border: Border.all(
                        color: _cardAvatar != null ? _cardAvatar!['color'] as Color : Colors.white30,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_cardAvatar?['color'] as Color? ?? Colors.cyanAccent).withOpacity(0.3),
                          blurRadius: 12,
                        )
                      ],
                    ),
                    child: _cardAvatar != null
                        ? Center(
                      child: Text(
                        _cardAvatar!['emoji'],
                        style: const TextStyle(fontSize: 52),
                      ),
                    )
                        : const Icon(Icons.person, color: Colors.white38, size: 48),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "$firstName $lastName".toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 2),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildInfoField("Age", userAge),
                        _buildInfoField("Gender", userGender),
                        _buildInfoField("Height", "$userHeight cm"),
                        _buildInfoField("Weight", "$userWeight Kg"),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildInfoField("BMI", userBMI.toStringAsFixed(1)),
                        _buildInfoField("Goal", userGoal, isHighlighted: true),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00FF88).withOpacity(0.7),
                                    blurRadius: 25,
                                    spreadRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.workspace_premium, color: Colors.yellowAccent.withOpacity(0.7), size: 55),
                            const Positioned(
                              top: 10,
                              child: Text(
                                "HEALTH SCORE",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.cyanAccent,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                  height: 1.1,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 5,
                              child: Text(
                                "$healthScore",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                  shadows: [
                                    Shadow(color: Color(0xFF00FF88), blurRadius: 15),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoField(String label, String value, {bool isHighlighted = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: const TextStyle(color: Colors.cyanAccent, fontSize: 9.5, letterSpacing: 2)),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: isHighlighted ? 18 : 14,
            fontWeight: FontWeight.w600,
            shadows: isHighlighted ? [Shadow(color: Colors.yellowAccent, blurRadius: 5)] : null,
          ),
        ),
      ],
    );
  }

  Widget _buildGridFeed() {
    if (_cyberPosts.isEmpty) {
      return const Center(
        child: Text("NO_DATA_STREAM", style: TextStyle(color: Colors.white24, fontSize: 12, letterSpacing: 3)),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 1.0,
      ),
      itemCount: _cyberPosts.length,
      itemBuilder: (context, index) {
        final post = _cyberPosts[index];
        final heroTag = 'post_hero_$index';
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 800),
                reverseTransitionDuration: const Duration(milliseconds: 600),
                pageBuilder: (_, __, ___) => PostFeedDetailPage(
                  posts: _cyberPosts,
                  initialIndex: index,
                  profileBytes: _profileBytes,
                  userName: userName,
                  onPostChanged: () => setState(() {}),
                ),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
              ),
            );
          },
          child: Hero(
            tag: heroTag,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(post['image'], fit: BoxFit.cover),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAchievementRow() {
    return SizedBox(
      height: 130,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: userAchievements.length,
        itemBuilder: (context, i) => GestureDetector(
          onTap: () => _showAchievementDetails(i),
          child: Stack(
            children: [
              Column(
                children: [
                  Container(
                    width: 95,
                    height: 85,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: userAchievements[i]['color'].withOpacity(0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: userAchievements[i]['color'].withOpacity(0.2)),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(userAchievements[i]['icon'], color: userAchievements[i]['color'], size: 24),
                      const SizedBox(height: 6),
                      Text(userAchievements[i]['title'], style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold)),
                    ]),
                  ),
                  const SizedBox(height: 4),
                  IconButton(
                    icon: const Icon(Icons.thumb_up, color: Colors.white38, size: 20),
                    onPressed: () => _endorseAchievement(i),
                  ),
                ],
              ),
              if (userAchievements[i]['endorsements'] > 0)
                Positioned(
                  top: 1,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${userAchievements[i]['endorsements']}',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      backgroundColor: Colors.black,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            _backgroundBytes != null ? Image.memory(_backgroundBytes!, fit: BoxFit.cover) : Container(color: Colors.blueGrey[900]),
            Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Color(0xFF010101)]))),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => _handleImagePick(ImageSource.gallery, 'profile'),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.cyanAccent.withOpacity(0.5))),
                      child: CircleAvatar(
                        radius: 65,
                        backgroundColor: Colors.white10,
                        backgroundImage: _profileBytes != null ? MemoryImage(_profileBytes!) : null,
                        child: _profileBytes == null ? const Icon(Icons.person_add, color: Colors.cyanAccent, size: 60) : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  GestureDetector(
                    onTap: () => _editInfo("ID", userName, (v) => userName = v),
                    child: Text(userName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 5)),
                  ),
                ],
              ),
            ),
            Positioned(bottom: 25, right: 25, child: IconButton(icon: const Icon(Icons.center_focus_strong, color: Colors.cyanAccent), onPressed: () => _handleImagePick(ImageSource.gallery, 'background'))),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderRow(String title, IconData icon, VoidCallback? action) {
    return Row(children: [
      Icon(icon, color: Colors.cyanAccent, size: 14),
      const SizedBox(width: 8),
      Text(title, style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, letterSpacing: 3, fontSize: 10)),
      const Spacer(),
      if (action != null) IconButton(onPressed: action, icon: const Icon(Icons.settings_input_component, color: Colors.cyanAccent, size: 16))
    ]);
  }

  Widget _buildGlassPanel(String text) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white10)),
      child: Text(text, style: const TextStyle(color: Colors.white60, fontSize: 12, height: 1.6)),
    );
  }

  void _editInfo(String label, String current, Function(String) save) {
    _editController.text = current;
    _showNeonDialog(title: "UPDATE_$label", content: TextField(controller: _editController, style: const TextStyle(color: Colors.white, fontSize: 13), decoration: const InputDecoration(filled: true, fillColor: Colors.white10)), actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text("ABORT")),
      ElevatedButton(onPressed: () { setState(() => save(_editController.text)); Navigator.pop(context); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent), child: const Text("SYNC", style: TextStyle(color: Colors.black)))
    ]);
  }

  Widget _buildActionTile(IconData icon, String label, Color color, VoidCallback onTap) {
    return ListTile(dense: true, leading: Icon(icon, color: color, size: 20), title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)), onTap: onTap);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: const Color(0xFF010101), // Background color moved here
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                _buildSliverHeader(),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeaderRow("STATUS_LOG", Icons.analytics, () => _editInfo("BIO", userBio, (v) => userBio = v)),
                        _buildGlassPanel(userBio),
                        const SizedBox(height: 35),
                        _buildAgentIdSection(),
                        const SizedBox(height: 35),
                        _buildHeaderRow("ACTIVE_PROTOCOLS", Icons.hub, _manageAchievements),
                        _buildAchievementRow(),
                        const SizedBox(height: 35),
                        _buildHeaderRow("DATA_FEED", Icons.sensors, () => _handleImagePick(ImageSource.gallery, 'gallery')),
                        _buildGridFeed(),
                        const SizedBox(height: 120), // Extra bottom space to clear BottomNavigationBar
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              right: 16,
              child: GestureDetector(
                onTapDown: (details) {
                  _showSettingsMenu(context, details.globalPosition);
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                    border: Border.all(color: Colors.cyanAccent.withOpacity(0.4), width: 1),
                  ),
                  child: const Icon(Icons.settings, color: Colors.cyanAccent, size: 22),
                ),
              ),
            ),
            if (_showRocketOverlay)
              AnimatedBuilder(
                animation: _rocketController,
                builder: (context, child) {
                  return IgnorePointer(
                    child: Container(
                      color: Colors.transparent,
                      child: Center(
                        child: Transform.translate(
                          offset: Offset(0, MediaQuery.of(context).size.height * _rocketAnimation.value),
                          child: ShaderMask(
                            shaderCallback: (Rect bounds) {
                              return const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.yellowAccent,
                                  Colors.orange,
                                  Colors.redAccent,
                                ],
                                stops: [0.0, 0.5, 1.0],
                              ).createShader(bounds);
                            },
                            blendMode: BlendMode.srcIn,
                            child: Icon(
                              Icons.rocket_launch,
                              size: 300,
                              color: Colors.white,
                              shadows: const [
                                BoxShadow(
                                  color: Colors.red,
                                  blurRadius: 100,
                                  spreadRadius: 50,
                                  offset: Offset(0, 0),
                                ),
                                BoxShadow(
                                  color: Colors.orange,
                                  blurRadius: 60,
                                  spreadRadius: 20,
                                ),
                                BoxShadow(
                                  color: Colors.yellow,
                                  blurRadius: 30,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

// PostFeedDetailPage remains exactly the same as before
class PostFeedDetailPage extends StatefulWidget {
  final List<Map<String, dynamic>> posts;
  final int initialIndex;
  final Uint8List? profileBytes;
  final String userName;
  final VoidCallback onPostChanged;

  const PostFeedDetailPage({
    required this.posts,
    required this.initialIndex,
    required this.profileBytes,
    required this.userName,
    required this.onPostChanged,
    super.key,
  });

  @override
  State<PostFeedDetailPage> createState() => _PostFeedDetailPageState();
}

class _PostFeedDetailPageState extends State<PostFeedDetailPage> with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _rocketController;
  late Animation<double> _rocketTranslate;
  late Animation<double> _rocketScale;
  late Animation<double> _rocketGlow;

  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    _rocketController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

    _rocketTranslate = Tween<double>(begin: 1.0, end: -1.5).animate(
      CurvedAnimation(parent: _rocketController, curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic)),
    );

    _rocketScale = Tween<double>(begin: 0.8, end: 1.4).animate(
      CurvedAnimation(parent: _rocketController, curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack)),
    );

    _rocketGlow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rocketController, curve: const Interval(0.2, 0.9, curve: Curves.easeOut)),
    );

    _rocketController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialIndex > 0 && widget.posts.isNotEmpty) {
        const double approximatePostHeight = 500.0;
        final double offset = widget.initialIndex * approximatePostHeight;
        _scrollController.animateTo(
          offset.clamp(0.0, _scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _rocketController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _addComment(Map<String, dynamic> post) {
    _commentController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: const Text("ADD COMMENT", style: TextStyle(color: Colors.cyanAccent, fontSize: 13)),
        content: TextField(
          controller: _commentController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: "Enter comment...", hintStyle: TextStyle(color: Colors.white38)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () {
              if (_commentController.text.isNotEmpty) {
                setState(() {
                  post['comments'].add({
                    'user': widget.userName,
                    'text': _commentController.text,
                  });
                });
                widget.onPostChanged();
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
            child: const Text("POST", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _showReactions(Map<String, dynamic> post) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: const Text("REACT", style: TextStyle(color: Colors.cyanAccent)),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            GestureDetector(onTap: () => _addReaction(post, '😍'), child: const Text('😍', style: TextStyle(fontSize: 32))),
            GestureDetector(onTap: () => _addReaction(post, '🔥'), child: const Text('🔥', style: TextStyle(fontSize: 32))),
            GestureDetector(onTap: () => _addReaction(post, '💪'), child: const Text('💪', style: TextStyle(fontSize: 32))),
            GestureDetector(onTap: () => _addReaction(post, '👏'), child: const Text('👏', style: TextStyle(fontSize: 32))),
            GestureDetector(onTap: () => _addReaction(post, '😂'), child: const Text('😂', style: TextStyle(fontSize: 32))),
            GestureDetector(onTap: () => _addReaction(post, '🤯'), child: const Text('🤯', style: TextStyle(fontSize: 32))),
            GestureDetector(onTap: () => _addReaction(post, '🥳'), child: const Text('🥳', style: TextStyle(fontSize: 32))),
          ],
        ),
      ),
    );
  }

  void _addReaction(Map<String, dynamic> post, String emoji) {
    setState(() {
      if (!post['selectedReactions'].contains(emoji)) {
        post['selectedReactions'].add(emoji);
      }
      post['reactions'] = post['selectedReactions'].length;
    });
    widget.onPostChanged();
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Reacted with $emoji")),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post, int index) {
    final heroTag = 'post_hero_$index';
    return Container(
      margin: const EdgeInsets.only(top: 15),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ListTile(
          dense: true,
          leading: CircleAvatar(radius: 12, backgroundImage: widget.profileBytes != null ? MemoryImage(widget.profileBytes!) : null),
          title: Text(widget.userName, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          trailing: PopupMenuButton(
            icon: const Icon(Icons.more_vert, color: Colors.white38, size: 18),
            color: Colors.black87,
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Row(children: [Icon(Icons.edit, size: 16, color: Colors.cyanAccent), SizedBox(width: 8), Text("Edit Caption", style: TextStyle(color: Colors.white, fontSize: 12))]),
                onTap: () {
                  final TextEditingController captionCtrl = TextEditingController(text: post['caption']);
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: Colors.black87,
                      title: const Text("EDIT_CAPTION", style: TextStyle(color: Colors.cyanAccent, fontSize: 13)),
                      content: TextField(
                        controller: captionCtrl,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 4,
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
                        ElevatedButton(
                          onPressed: () {
                            setState(() => post['caption'] = captionCtrl.text);
                            widget.onPostChanged();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
                          child: const Text("SAVE", style: TextStyle(color: Colors.black)),
                        ),
                      ],
                    ),
                  );
                },
              ),
              PopupMenuItem(
                child: const Row(children: [Icon(Icons.delete, size: 16, color: Colors.redAccent), SizedBox(width: 8), Text("Delete Post", style: TextStyle(color: Colors.redAccent, fontSize: 12))]),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: Colors.black87,
                      title: const Text("TERMINATE_POST?", style: TextStyle(color: Colors.redAccent)),
                      content: const Text("This action cannot be undone.", style: TextStyle(color: Colors.white)),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text("ABORT")),
                        TextButton(
                          onPressed: () {
                            setState(() => widget.posts.remove(post));
                            widget.onPostChanged();
                            Navigator.pop(context);
                          },
                          child: const Text("PURGE", style: TextStyle(color: Colors.redAccent)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 320,
              width: double.infinity,
              child: Hero(
                tag: heroTag,
                child: Image.memory(
                  post['image'],
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    post['isLiked'] = !post['isLiked'];
                    post['likes'] += post['isLiked'] ? 1 : -1;
                  });
                  widget.onPostChanged();
                },
                child: Icon(post['isLiked'] ? Icons.favorite : Icons.favorite_border,
                    color: post['isLiked'] ? Colors.red[900] : Colors.white, size: 24),
              ),
              const SizedBox(width: 18),
              GestureDetector(
                onTap: () => _addComment(post),
                child: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 18),
              GestureDetector(
                onTap: () => _showReactions(post),
                child: const Icon(Icons.sentiment_satisfied_alt, color: Colors.yellowAccent, size: 24),
              ),
              const Spacer(),
              if (post['selectedReactions'] != null && post['selectedReactions'].isNotEmpty)
                Row(
                  children: post['selectedReactions'].map<Widget>((emoji) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 26),
                      ),
                    );
                  }).toList(),
                ),
            ]),
            const SizedBox(height: 8),
            Text("${post['likes']} Likes • ${post['reactions']} Reactions", style: const TextStyle(color: Colors.deepOrange, fontSize: 10, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            RichText(text: TextSpan(style: const TextStyle(fontSize: 11.5), children: [
              TextSpan(text: "${widget.userName} ", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              TextSpan(text: post['caption'], style: const TextStyle(color: Colors.white70)),
            ])),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: post['comments'].map<Widget>((commentMap) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 11),
                      children: [
                        TextSpan(
                          text: "${commentMap['user']} ",
                          style:  TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[900]),
                        ),
                        TextSpan(
                          text: commentMap['text'],
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ]),
        )
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF010101),
      appBar: AppBar(
        backgroundColor: Colors.black54,
        title: const Text("DATA_FEED", style: TextStyle(color: Colors.cyanAccent, letterSpacing: 3, fontSize: 14)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          widget.posts.isEmpty
              ? const Center(child: Text("NO POSTS", style: TextStyle(color: Colors.white38)))
              : ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: widget.posts.length,
            itemBuilder: (context, index) {
              return _buildPostCard(widget.posts[index], index);
            },
          ),
        ],
      ),
    );
  }
}

