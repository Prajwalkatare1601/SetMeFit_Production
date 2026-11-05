// lib/widgets/questions_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'cards_UI.dart';

/// A reusable questions page that supports the Activity flow (slider + pill edit)
class QuestionsPage extends StatelessWidget {
  final CardItem activeItem;
  final List<double> activityValues;
  final List<String> activityUnits;
  final List<double> activityMin;
  final List<double> activityMax;
  final List<String> activityQuestions;
  final int currentQuestion;
  final ValueChanged<double> onSliderChanged;
  final VoidCallback onNext;
  final VoidCallback onPrev;
  final VoidCallback onStartEditPill;
  final bool isEditingPill;
  final String activityLabel;
  final double sliderValue;

  // NEW: accept a TextEditingController and onSave callback so pill can show TextField
  final TextEditingController? pillController;
  final VoidCallback? onSaveEdit;

  const QuestionsPage({
    super.key,
    required this.activeItem,
    required this.activityValues,
    required this.activityUnits,
    required this.activityMin,
    required this.activityMax,
    required this.activityQuestions,
    required this.currentQuestion,
    required this.onSliderChanged,
    required this.onNext,
    required this.onPrev,
    required this.onStartEditPill,
    required this.isEditingPill,
    required this.activityLabel,
    required this.sliderValue,
    this.pillController,
    this.onSaveEdit,
  });

  String _activityValueLabel() {
    final units = activityUnits[currentQuestion];
    final value = sliderValue;
    if (units == 'steps') return '${value.toInt()} steps';
    if (units == 'min/day') return '${value.toInt()} min';
    return '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)} hrs/week';
  }

  @override
  Widget build(BuildContext context) {
    final units = activityUnits[currentQuestion];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${activeItem.title} Questions',
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800, color: activeItem.color),
        ),
        const SizedBox(height: 14),

        // top-right Q box + edit
        Align(
          alignment: Alignment.topRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
                child: Text('Q ${currentQuestion + 1}/${activityQuestions.length}', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70)),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: onStartEditPill,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
                  child: Row(children: [const Icon(Icons.edit, size: 16, color: Colors.white70), const SizedBox(width: 8), Text('Edit', style: GoogleFonts.poppins(color: Colors.white70))]),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        Expanded(
          child: LayoutBuilder(builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // keep your existing top spacing and text exactly as before
                      Text(activityQuestions[currentQuestion],
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withOpacity(0.96),
                              height: 1.35)),
                      const SizedBox(height: 20),

                      // --- your pill / editable pill area (same code you had) ---
                      GestureDetector(
                        onTap: onStartEditPill,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 260),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          decoration: BoxDecoration(
                            color: isEditingPill ? Colors.white : Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: activeItem.color.withOpacity(0.95), width: isEditingPill ? 2 : 1),
                          ),
                          child: isEditingPill
                              ? SizedBox(
                            width: 220,
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: pillController,
                                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                                    style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 18),
                                    decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                                    onSubmitted: (_) => onSaveEdit?.call(),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.check, color: Colors.black),
                                  onPressed: onSaveEdit,
                                ),
                              ],
                            ),
                          )
                              : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_activityValueLabel(), style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                              if (units.isNotEmpty) const SizedBox(width: 6),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // --- slider (same as before) ---
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: activeItem.color,
                            inactiveTrackColor: Colors.white12,
                            trackHeight: 8,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
                            thumbColor: activeItem.color,
                            overlayColor: activeItem.color.withOpacity(0.14),
                            valueIndicatorColor: activeItem.color,
                          ),
                          child: Slider(
                            min: activityMin[currentQuestion],
                            max: activityMax[currentQuestion],
                            divisions: (activityMax[currentQuestion] - activityMin[currentQuestion]) ~/
                                ((activityUnits[currentQuestion] == 'steps') ? 1000 : (activityUnits[currentQuestion].contains('min') ? 5 : 1)),
                            label: _activityValueLabel(),
                            value: sliderValue.clamp(activityMin[currentQuestion], activityMax[currentQuestion]),
                            onChanged: onSliderChanged,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('${activityMin[currentQuestion].toInt()}', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
                        Text('${activityMax[currentQuestion].toInt()}', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12))
                      ]),

                      // bottom padding so content clears the fixed buttons
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),

        // bottom controls
        Column(children: [
          const SizedBox(height: 8),
          Center(child: Row(mainAxisSize: MainAxisSize.min, children: List.generate(activityQuestions.length, (idx) {
            final bool active = idx == currentQuestion;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 6),
              width: active ? 18 : 8,
              height: 8,
              decoration: BoxDecoration(color: active ? activeItem.color : Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
            );
          }))),
          const SizedBox(height: 14),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            ElevatedButton(onPressed: onPrev, style: ElevatedButton.styleFrom(backgroundColor: Colors.white10, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0), child: Text('Prev', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14))),
            ElevatedButton(onPressed: onNext, style: ElevatedButton.styleFrom(backgroundColor: activeItem.color, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 8), child: Text(currentQuestion < activityQuestions.length - 1 ? 'Next' : 'Continue', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14))),
          ]),
          const SizedBox(height: 6),
        ])
      ],
    );
  }
}
