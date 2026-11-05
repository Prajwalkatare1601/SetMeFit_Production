import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import 'dart:ui';

class TongueHealthApp extends StatelessWidget {
  const TongueHealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    const jetBlack = Color(0xFF000000);
    const accentOrange = Color(0xFFFF9500);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tongue Health Oracle',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: jetBlack,
        colorScheme: ColorScheme.dark(
          primary: accentOrange,
          surface: const Color(0xFF0A0A0A),
          background: jetBlack,
        ),
        cardColor: const Color(0xFF0A0A0A),
        appBarTheme: const AppBarTheme(
          backgroundColor: jetBlack,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
      ),
      home: const TongueDashboardPage(),
    );
  }
}

class TongueRecord {
  final Uint8List? imageBytes;
  final Map<String, String> metrics;
  final DateTime timestamp;
  final int score;
  final List<String> observations;
  final List<String> suggestions;

  TongueRecord({
    this.imageBytes,
    required this.metrics,
    required this.timestamp,
    required this.score,
    required this.observations,
    required this.suggestions,
  });
}

class TongueDashboardPage extends StatefulWidget {
  const TongueDashboardPage({super.key});

  @override
  State<TongueDashboardPage> createState() => _TongueDashboardPageState();
}

class _TongueDashboardPageState extends State<TongueDashboardPage> {
  final ImagePicker _picker = ImagePicker();
  final SupabaseClient _supabase = Supabase.instance.client;

  Uint8List? _currentImageBytes;
  Map<String, String>? _currentMetrics;
  List<String>? _currentObservations;
  List<String>? _currentSuggestions;
  String _lastScanDisplay = 'No scan yet';

  List<TongueRecord> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final response = await _supabase
          .from('tongue_records')
          .select()
          .eq('user_id', user.id)
          .order('timestamp', ascending: false);

      final List<TongueRecord> loadedHistory = [];

      for (var item in response) {
        loadedHistory.add(
          TongueRecord(
            imageBytes: null,
            metrics: {
              'color': item['color'],
              'coating': item['coating'],
              'cracks': item['cracks'],
              'moisture': item['moisture'],
              'shape': item['shape'],
            },
            timestamp: DateTime.parse(item['timestamp']),
            score: item['score'],
            observations: List<String>.from(item['observations']),
            suggestions: List<String>.from(item['suggestions']),
          ),
        );
      }

      setState(() {
        _history = loadedHistory;
        if (_history.isNotEmpty) {
          final latest = _history.first;
          _currentMetrics = latest.metrics;
          _currentObservations = latest.observations;
          _currentSuggestions = latest.suggestions;
          _updateLastScanTime();
        }
      });
    } catch (_) {}
  }

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() => _currentImageBytes = bytes);
  }

  Future<void> _submitRecord({
    required Map<String, String> metrics,
    Uint8List? imageBytes,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final score = _calculateScore(metrics);
    final observations = _getObservations(metrics);
    final suggestions = _getSuggestions(metrics);

    await _supabase.from('tongue_records').insert({
      'user_id': user.id,
      'color': metrics['color'],
      'coating': metrics['coating'],
      'cracks': metrics['cracks'],
      'moisture': metrics['moisture'],
      'shape': metrics['shape'],
      'score': score,
      'observations': observations,
      'suggestions': suggestions,
    });

    final record = TongueRecord(
      imageBytes: imageBytes,
      metrics: metrics,
      timestamp: DateTime.now(),
      score: score,
      observations: observations,
      suggestions: suggestions,
    );

    setState(() {
      _history.insert(0, record);
      _currentMetrics = metrics;
      _currentObservations = observations;
      _currentSuggestions = suggestions;
      _updateLastScanTime();
    });
  }

  void _updateLastScanTime() {
    if (_history.isEmpty) {
      _lastScanDisplay = 'No scan yet';
      return;
    }
    final last = _history.first.timestamp;
    _lastScanDisplay =
    'Last scan: ${last.day.toString().padLeft(2, '0')} '
        '${['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][last.month - 1]} '
        '${last.year}, '
        '${last.hour % 12 == 0 ? 12 : last.hour % 12}:'
        '${last.minute.toString().padLeft(2, '0')} '
        '${last.hour >= 12 ? 'PM' : 'AM'}';
  }

  int _calculateScore(Map<String, String> data) {
    final colorScores = {
      'Normal Pink': 20,
      'Pale': 10,
      'Red': 15,
      'Deep Red': 10,
      'Purple': 5,
      'Blue': 5,
    };
    final coatingScores = {
      'None': 10,
      'Thin White': 20,
      'Thick White': 15,
      'Yellow': 10,
      'Greasy': 10,
      'Peeled': 10,
    };
    final cracksScores = {
      'None': 20,
      'Mild': 15,
      'Moderate': 10,
      'Deep': 5,
      'Horizontal': 10,
      'Vertical': 10,
    };
    final moistureScores = {
      'Dry': 10,
      'Slightly Dry': 15,
      'Normal': 20,
      'Moist': 15,
      'Excessively Wet': 10,
    };
    final shapeScores = {
      'Normal': 20,
      'Swollen': 10,
      'Thin': 10,
      'Scalloped (Teeth Marks)': 10,
      'Stiff': 10,
      'Flabby': 10,
    };

    int score = 0;
    score += colorScores[data['color']] ?? 0;
    score += coatingScores[data['coating']] ?? 0;
    score += cracksScores[data['cracks']] ?? 0;
    score += moistureScores[data['moisture']] ?? 0;
    score += shapeScores[data['shape']] ?? 0;

    return score.clamp(0, 100);
  }

  List<String> _getObservations(Map<String, String> data) {
    List<String> obs = [];
    if (data['color'] == 'Pale') obs.add('Pale tongue may indicate Qi or blood deficiency.');
    if (data['color'] == 'Red' || data['color'] == 'Deep Red') obs.add('Red tongue suggests internal heat.');
    if (data['coating'] == 'Thick White') obs.add('Thick white coating indicates cold-dampness.');
    if (data['moisture'] == 'Dry') obs.add('Dry tongue suggests Yin deficiency.');
    if (obs.isEmpty) obs.add('Balanced tongue appearance.');
    return obs;
  }

  List<String> _getSuggestions(Map<String, String> data) {
    List<String> sug = [];
    if (data['color'] == 'Pale') sug.add('Tonify Qi and blood with warming foods like ginger.');
    if (data['moisture'] == 'Dry') sug.add('Nourish Yin with hydrating foods like pears.');
    if (sug.isEmpty) sug.add('Continue maintaining good hydration and diet.');
    return sug;
  }

  void _showHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF0A0A0A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: const BoxConstraints(maxHeight: 700),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Scan History', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Color(0xFFFF9500)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _history.isEmpty
                    ? const Center(child: Text('No records yet', style: TextStyle(color: Colors.white54)))
                    : ListView.builder(
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    return _HistoryCard(record: _history[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF9500), Color(0xFFFF5722)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: const Color(0xFFFF9500).withOpacity(0.5), blurRadius: 12),
                ],
              ),
              alignment: Alignment.center,
              child: const Text('👅', style: TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 14),
            const Text(
              'Tongue AI',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 24,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFF9500), Color(0xFFFF5722)]),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(color: const Color(0xFFFF9500).withOpacity(0.4), blurRadius: 12),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield_moon_outlined, size: 18, color: Colors.black),
                SizedBox(width: 4),
                Text(
                  'Oral Wellness',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black),
                ),
              ],
            ),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_outlined, color: Color(0xFFFF9500))),
          IconButton(
            onPressed: _showHistoryDialog,
            icon: const Icon(Icons.history, color: Color(0xFFFF9500)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Dashboard',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.8,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(_lastScanDisplay, style: const TextStyle(fontSize: 13, color: Colors.white60)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF9500).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: const Color(0xFFFF9500).withOpacity(0.4)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle, size: 10, color: Color(0xFFFF9500)),
                              SizedBox(width: 6),
                              Text('Active', style: TextStyle(color: Color(0xFFFF9500), fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Your animated tongue section here (keep your existing _AnimatedTongueMap)
                _AnimatedTongueMap(metrics: _currentMetrics),

                const SizedBox(height: 32),

                // Intelligence card (keep your existing _HealthIntelligenceCard)
                _HealthIntelligenceCard(
                  metrics: _currentMetrics,
                  observations: _currentObservations,
                  suggestions: _currentSuggestions,
                ),

                const SizedBox(height: 32),

                // Manual entry card (keep your existing _TongueScanRecordCard)
                _TongueScanRecordCard(
                  imageBytes: _currentImageBytes,
                  onPickImage: _pickImage,
                  onSubmit: _submitRecord,
                ),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}
// New merged card combining last scan display and manual entry
class _TongueScanRecordCard extends StatefulWidget {
  final Uint8List? imageBytes;
  final VoidCallback onPickImage;
  final Future<void> Function({required Map<String, String> metrics, Uint8List? imageBytes}) onSubmit;

  const _TongueScanRecordCard({
    super.key,
    this.imageBytes,
    required this.onPickImage,
    required this.onSubmit,
  });

  @override
  State<_TongueScanRecordCard> createState() => _TongueScanRecordCardState();
}

class _TongueScanRecordCardState extends State<_TongueScanRecordCard> {
  String? _color;
  String? _coating;
  String? _cracks;
  String? _moisture;
  String? _shape;

  bool get _canSubmit =>
      _color != null && _coating != null && _cracks != null && _moisture != null && _shape != null;

  Future<void> _submit() async {
    if (!_canSubmit) return;

    await widget.onSubmit(
      metrics: {
        'color': _color!,
        'coating': _coating!,
        'cracks': _cracks!,
        'moisture': _moisture!,
        'shape': _shape!,
      },
      imageBytes: widget.imageBytes,
    );

    // Reset form fields only
    setState(() {
      _color = _coating = _cracks = _moisture = _shape = null;
    });
  }

  Widget _buildDropdown(String label, String? value, List<String> items, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
        const SizedBox(height: 8),
        DropdownMenu<String>(
          width: MediaQuery.of(context).size.width > 600 ? 600 : double.infinity,
          menuStyle: MenuStyle(
            backgroundColor: WidgetStateProperty.all(const Color(0xFF1A1A1A)),
            surfaceTintColor: WidgetStateProperty.all(Colors.white),
            elevation: WidgetStateProperty.all(12),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF111111),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF333333))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF333333))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFFF9500), width: 2)),
          ),
          hintText: 'Select $label',
          initialSelection: value,
          dropdownMenuEntries: items.map((e) => DropdownMenuEntry(value: e, label: e)).toList(),
          onSelected: onChanged,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    final ImageProvider<Object> imageProvider = widget.imageBytes != null
        ? MemoryImage(widget.imageBytes!)
        : const AssetImage('assets/tongue_placeholder.png');

    return Card(
      color: const Color(0xFF111111),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Scan your tongue', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFFF9500), Color(0xFFFF4D00)]),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.auto_awesome, size: 16, color: Colors.black),
                    SizedBox(width: 6),
                    Text('Most recent', style: TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text('Visual scan only • Manual entry below', style: TextStyle(fontSize: 13, color: Colors.white54)),
            const SizedBox(height: 20),

            AspectRatio(
              aspectRatio: 4 / 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
                        border: Border.all(color: const Color(0xFF333333), width: 1),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Colors.black87, Colors.transparent],
                          ),
                        ),
                        child: const Row(children: [
                          Icon(Icons.search_rounded, size: 18, color: Colors.white70),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text('Tap “View insights” to analyse this scan in detail.', style: TextStyle(fontSize: 12, color: Colors.white70)),
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            Center(
              child: OutlinedButton.icon(
                onPressed: widget.onPickImage,
                icon: const Icon(Icons.add_a_photo_outlined, color: Color(0xFFFF9500)),
                label: Text(widget.imageBytes != null ? 'Change Image' : 'Add Image', style: const TextStyle(color: Color(0xFFFF9500))),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFF9500), width: 1.5),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),

            const SizedBox(height: 32),
            const Divider(color: Color(0xFF333333)),
            const SizedBox(height: 24),

            const Text('Add / Update Manual Record', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 16),

            _buildDropdown('Tongue Color', _color, ['Normal Pink', 'Pale', 'Red', 'Deep Red', 'Purple', 'Blue'],
                    (v) => setState(() => _color = v)),
            const SizedBox(height: 16),
            _buildDropdown('Tongue Coating', _coating, ['None', 'Thin White', 'Thick White', 'Yellow', 'Greasy', 'Peeled'],
                    (v) => setState(() => _coating = v)),
            const SizedBox(height: 16),
            _buildDropdown('Cracks', _cracks, ['None', 'Mild', 'Moderate', 'Deep', 'Horizontal', 'Vertical'],
                    (v) => setState(() => _cracks = v)),
            const SizedBox(height: 16),
            _buildDropdown('Moisture', _moisture, ['Dry', 'Slightly Dry', 'Normal', 'Moist', 'Excessively Wet'],
                    (v) => setState(() => _moisture = v)),
            const SizedBox(height: 16),
            _buildDropdown('Shape', _shape, ['Normal', 'Swollen', 'Thin', 'Scalloped (Teeth Marks)', 'Stiff', 'Flabby'],
                    (v) => setState(() => _shape = v)),

            const SizedBox(height: 32),

            Center(
              child: ElevatedButton(
                onPressed: _canSubmit ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  disabledBackgroundColor: const Color(0xFF333333),
                  padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 8,
                  shadowColor: accent.withOpacity(0.5),
                ),
                child: const Text('Submit Record', style: TextStyle(fontSize: 17, color: Colors.black, fontWeight: FontWeight.w700)),
              ),
            ),

            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(onPressed: () {}, icon: const Icon(Icons.insights_outlined, size: 20, color: Color(0xFFFF9500)), label: const Text('View insights', style: TextStyle(color: Color(0xFFFF9500)))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final TongueRecord record;
  const _HistoryCard({required this.record});

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final mon = monthNames[date.month - 1];
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final ampm = date.hour >= 12 ? 'PM' : 'AM';
    return '$day $mon ${date.year} • $hour:$minute $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: const Color(0xFF111111),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(_formatDate(record.timestamp), style: const TextStyle(fontSize: 13, color: Colors.white54)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: record.score >= 80
                        ? const Color(0xFF22D3EE).withOpacity(0.15)
                        : record.score >= 60
                        ? const Color(0xFFFF9500).withOpacity(0.15)
                        : const Color(0xFFEF4444).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    '${record.score}/100',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: record.score >= 80 ? const Color(0xFF22D3EE) : record.score >= 60 ? const Color(0xFFFF9500) : const Color(0xFFEF4444),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (record.imageBytes != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.memory(record.imageBytes!, height: 180, width: double.infinity, fit: BoxFit.cover),
              )
            else
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(16)),
                alignment: Alignment.center,
                child: const Text('No Image', style: TextStyle(color: Colors.white38, fontSize: 16)),
              ),
            const SizedBox(height: 16),
            Text(
              'Color: ${record.metrics['color']} • Coating: ${record.metrics['coating']} • Cracks: ${record.metrics['cracks']} • Moisture: ${record.metrics['moisture']} • Shape: ${record.metrics['shape']}',
              style: const TextStyle(fontSize: 13.5, color: Colors.white70),
            ),
            const SizedBox(height: 16),
            const Text('Insights', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white)),
            const SizedBox(height: 8),
            ...record.observations.map((o) => _BulletPoint(text: o)),
            const SizedBox(height: 12),
            ...record.suggestions.map((s) => _BulletPoint(text: s)),
          ],
        ),
      ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final String text;
  const _BulletPoint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('• ', style: TextStyle(fontSize: 15, height: 1.4, color: Color(0xFFFF9500))),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13.5, color: Colors.white70, height: 1.45))),
      ]),
    );
  }
}

// ULTRA PREMIUM HOLOGRAPHIC TONGUE ORACLE (top of page)
class _AnimatedTongueMap extends StatefulWidget {
  final Map<String, String>? metrics;
  const _AnimatedTongueMap({this.metrics, super.key});

  @override
  State<_AnimatedTongueMap> createState() => _AnimatedTongueMapState();
}

class _AnimatedTongueMapState extends State<_AnimatedTongueMap>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _wobble;
  late Animation<double> _breathe;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    _wobble = Tween<double>(begin: -3.5, end: 3.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    _breathe = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.metrics ?? {};

    return Column(
      children: [
        const Row(
          children: [
            Icon(Icons.biotech, color: Color(0xFFFF9500), size: 26),
            SizedBox(width: 12),
            Text(
              'HYPER-REALISTIC TONGUE ANALYSIS',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        Container(
          height: 350,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0A),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0xFFFF9500).withOpacity(0.35), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF9500).withOpacity(0.28),
                blurRadius: 40,
                spreadRadius: 6,
              ),
              BoxShadow(
                color: const Color(0xFFEC4899).withOpacity(0.15),
                blurRadius: 70,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none, // ← important → allows arrows to go outside
            children: [
              // Main animated tongue
              Center(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _breathe.value,
                      child: Transform.rotate(
                        angle: _wobble.value * 0.01745, // degrees → radians
                        child: Container(
                          width: 280,
                          height: 220,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFFFF8A80),
                                Color(0xFFF06292),
                                Color(0xFFEC407A),
                                Color(0xFFD81B60),
                              ],
                              stops: [0.0, 0.3, 0.7, 1.0],
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(100),
                              topRight: Radius.circular(100),
                              bottomLeft: Radius.circular(160),
                              bottomRight: Radius.circular(160),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.7),
                                blurRadius: 35,
                                offset: const Offset(0, 20),
                              ),
                              // Wet gloss highlight
                              BoxShadow(
                                color: Colors.white.withOpacity(0.18),
                                blurRadius: 60,
                                spreadRadius: -20,
                                offset: const Offset(-40, -60),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // Realistic texture / taste buds simulation
                              Positioned.fill(
                                child: Opacity(
                                  opacity: 0.15,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: RadialGradient(
                                        colors: [Colors.white, Colors.transparent],
                                        stops: const [0.0, 0.8],
                                        center: Alignment(0.4, -0.3),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const Center(
                                child: Text(
                                  '👅',
                                  style: TextStyle(fontSize: 160, color: Colors.white54),
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

              // ────────────────────────────────────────────────
              //  Metric labels + curved arrows pointing to regions
              // ────────────────────────────────────────────────

              // 1. Tip – Color
              if (m['color'] != null) ...[
                Positioned(
                  top: 30,
                  left: 40,
                  child: _MetricLabelWithArrow(
                    label: 'Color',
                    value: m['color']!,
                    color: const Color(0xFFEC4899),
                    alignment: Alignment.topRight,
                  ),
                ),
              ],

              // 2. Middle – Coating
              if (m['coating'] != null) ...[
                Positioned(
                  top: 70,
                  right: 20,
                  child: _MetricLabelWithArrow(
                    label: 'Coating',
                    value: m['coating']!,
                    color: const Color(0xFFFDD835),
                    alignment: Alignment.topLeft,
                  ),
                ),
              ],

              // 3. Left side – Cracks
              if (m['cracks'] != null) ...[
                Positioned(
                  bottom: 50,
                  left: 30,
                  child: _MetricLabelWithArrow(
                    label: 'Cracks',
                    value: m['cracks']!,
                    color: const Color(0xFFAB47BC),
                    alignment: Alignment.bottomRight,
                  ),
                ),
              ],

              // 4. Right side – Moisture
              if (m['moisture'] != null) ...[
                Positioned(
                  bottom: 30,
                  right: 25,
                  child: _MetricLabelWithArrow(
                    label: 'Moisture',
                    value: m['moisture']!,
                    color: const Color(0xFF26C6DA),
                    alignment: Alignment.bottomLeft,
                  ),
                ),
              ],

              // 5. Root / back – Shape
              if (m['shape'] != null) ...[
                Positioned(
                  top: 10,
                  left: 90,
                  right: 90,
                  child: Center(
                    child: _MetricLabelWithArrow(
                      label: 'Shape',
                      value: m['shape']!,
                      color: const Color(0xFFFF9800),
                      alignment: Alignment.topCenter,
                    ),
                  ),
                ),
              ],

              // Placeholder when no data
              if (m.isEmpty)
                const Center(
                  child: Text(
                    'Submit a record to see detailed mapping',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white38, fontSize: 14),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────
//  Reusable label + curved arrow widget
// ────────────────────────────────────────────────

class _MetricLabelWithArrow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Alignment alignment;

  const _MetricLabelWithArrow({
    required this.label,
    required this.value,
    required this.color,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.75),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: color, width: 1.8),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.55), blurRadius: 16, spreadRadius: 1),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.3,
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),

        // Curved arrow
        SizedBox(
          height: 50,
          width: 80,
          child: CustomPaint(
            painter: _CurvedArrowPainter(
              color: color,
              alignment: alignment,
            ),
          ),
        ),
      ],
    );
  }
}

class _CurvedArrowPainter extends CustomPainter {
  final Color color;
  final Alignment alignment;

  _CurvedArrowPainter({required this.color, required this.alignment});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final path = Path();

    // Start from center of label area
    final start = Offset(size.width / 2, 0);

    // End point inside tongue area (adjusted per alignment)
    late Offset end; // ← use late instead of const

    switch (alignment) {
      case Alignment.topLeft:
        end = Offset(20, 60);
        break;
      case Alignment.topRight:
        end = Offset(size.width - 20, 60);
        break;
      case Alignment.bottomLeft:
        end = Offset(20, size.height - 40);
        break;
      case Alignment.bottomRight:
        end = Offset(size.width - 20, size.height - 40);
        break;
      case Alignment.bottomCenter:
      default:
        end = Offset(size.width / 2, size.height - 30);
        break;
    }

    // Quadratic Bézier curve for nice arc
    path.moveTo(start.dx, start.dy);
    path.quadraticBezierTo(
      (start.dx + end.dx) / 2,
      start.dy + (end.dy - start.dy) * 0.7,
      end.dx,
      end.dy,
    );

    canvas.drawPath(path, paint);

    // Arrow head
    final angle = (end - start).direction;
    const arrowSize = 10.0;

    final p1 = end + Offset(
      cos(angle + 2.356) * arrowSize,
      sin(angle + 2.356) * arrowSize,
    );

    final p2 = end + Offset(
      cos(angle - 2.356) * arrowSize,
      sin(angle - 2.356) * arrowSize,
    );

    final arrowPath = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(p1.dx, p1.dy)
      ..moveTo(end.dx, end.dy)
      ..lineTo(p2.dx, p2.dy);

    canvas.drawPath(arrowPath, paint);
  }

  @override
  bool shouldRepaint(covariant _CurvedArrowPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.alignment != alignment;
  }
}

// ORACLE INTELLIGENCE PANEL – CIRCULAR GAUGE + ANIMATED TREND + INSIGHTS
class _HealthIntelligenceCard extends StatefulWidget {
  final Map<String, String>? metrics;
  final List<String>? observations;
  final List<String>? suggestions;
  const _HealthIntelligenceCard({super.key, this.metrics, this.observations, this.suggestions});

  @override
  State<_HealthIntelligenceCard> createState() => _HealthIntelligenceCardState();
}

class _HealthIntelligenceCardState extends State<_HealthIntelligenceCard> with SingleTickerProviderStateMixin {
  late AnimationController _scoreController;
  late Animation<double> _scoreAnim;
  int _displayScore = 78;

  @override
  void initState() {
    super.initState();
    _scoreController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
    _scoreAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _scoreController, curve: Curves.easeOutCubic));
  }

  @override
  void didUpdateWidget(covariant _HealthIntelligenceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.metrics != oldWidget.metrics && widget.metrics != null) {
      final score = _calculateScore(widget.metrics!);
      _displayScore = score;
      _scoreController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _scoreController.dispose();
    super.dispose();
  }

  int _calculateScore(Map<String, String> data) {
    final colorScores = {'Normal Pink': 20, 'Pale': 10, 'Red': 15, 'Deep Red': 10, 'Purple': 5, 'Blue': 5};
    final coatingScores = {'None': 10, 'Thin White': 20, 'Thick White': 15, 'Yellow': 10, 'Greasy': 10, 'Peeled': 10};
    final cracksScores = {'None': 20, 'Mild': 15, 'Moderate': 10, 'Deep': 5, 'Horizontal': 10, 'Vertical': 10};
    final moistureScores = {'Dry': 10, 'Slightly Dry': 15, 'Normal': 20, 'Moist': 15, 'Excessively Wet': 10};
    final shapeScores = {'Normal': 20, 'Swollen': 10, 'Thin': 10, 'Scalloped (Teeth Marks)': 10, 'Stiff': 10, 'Flabby': 10};

    int score = 0;
    score += colorScores[data['color']] ?? 0;
    score += coatingScores[data['coating']] ?? 0;
    score += cracksScores[data['cracks']] ?? 0;
    score += moistureScores[data['moisture']] ?? 0;
    score += shapeScores[data['shape']] ?? 0;
    return score.clamp(0, 100);
  }

  String _getHealthLevel(int score) {
    if (score >= 80) return 'OPTIMAL';
    if (score >= 60) return 'BALANCED';
    if (score >= 40) return 'CAUTION';
    return 'ATTENTION REQUIRED';
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final int score = widget.metrics != null ? _calculateScore(widget.metrics!) : 78;
    final String level = _getHealthLevel(score);
    final List<String> obs = widget.observations ?? ['Mild dryness detected.', 'Slight white coating at the center region.', 'No major cracks or lesions observed.'];
    final List<String> sug = widget.suggestions ?? ['Drink 6–8 glasses of water.', 'Limit very spicy and oily foods.', 'Brush tongue gently during oral hygiene routine.'];

    return Card(
      color: const Color(0xFF111111),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.psychology_outlined, size: 28, color: accent),
              const SizedBox(width: 12),
              const Text('ORACLE INTELLIGENCE', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 2)),
            ]),
            const SizedBox(height: 6),
            const Text('Real-time AI analysis • Holographic trend', style: TextStyle(fontSize: 13, color: Colors.white54)),

            const SizedBox(height: 32),

            // CIRCULAR NEON SCORE GAUGE
            Center(
              child: SizedBox(
                width: 210,
                height: 210,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 210,
                      height: 210,
                      child: CircularProgressIndicator(
                        value: score / 100,
                        strokeWidth: 18,
                        backgroundColor: const Color(0xFF222222),
                        valueColor: AlwaysStoppedAnimation(accent),
                      ),
                    ),
                    SizedBox(
                      width: 170,
                      height: 170,
                      child: CircularProgressIndicator(
                        value: score / 100,
                        strokeWidth: 8,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation(const Color(0xFFEC4899)),
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _scoreAnim,
                      builder: (_, __) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${(_displayScore * _scoreAnim.value).toInt()}', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: Colors.white)),
                          Text('/100', style: TextStyle(fontSize: 18, color: Colors.white70)),
                          Text(level, style: TextStyle(fontSize: 12, color: accent, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ANIMATED TREND CHART
            const Text('7-DAY ENERGY TREND', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 14),
            Container(
              height: 140,
              decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(7, (i) {
                    final height = [62, 88, 79, 104, 92, 118, 105][i].toDouble();
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 400 + i * 80),
                          height: height,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [accent, const Color(0xFFEC4899)],
                            ),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            boxShadow: [BoxShadow(color: accent.withOpacity(0.4), blurRadius: 12)],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('MON', style: TextStyle(fontSize: 11, color: Colors.white54)),
              Text('SUN', style: TextStyle(fontSize: 11, color: Colors.white54)),
            ]),

            const SizedBox(height: 32),

            // OBSERVATIONS & SUGGESTIONS
            const Text('AI OBSERVATIONS', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 10),
            ...obs.map((o) => _BulletPoint(text: o)),
            const SizedBox(height: 24),
            const Text('ORACLE RECOMMENDATIONS', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 10),
            ...sug.map((s) => _BulletPoint(text: s)),
          ],
        ),
      ),
    );
  }
}