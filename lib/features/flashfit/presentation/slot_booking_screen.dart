import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/gym_model.dart';
import '../models/slot_model.dart';
import '../providers/flashfit_providers.dart';
import 'booking_confirmation_sheet.dart';

class SlotBookingScreen extends ConsumerStatefulWidget {
  final FlashFitGym gym;

  const SlotBookingScreen({Key? key, required this.gym}) : super(key: key);

  @override
  ConsumerState<SlotBookingScreen> createState() => _SlotBookingScreenState();
}

class _SlotBookingScreenState extends ConsumerState<SlotBookingScreen> {
  late DateTime _selectedDate;
  WorkoutSlot? _selectedSlot;
  String _timeOfDayFilter = 'All'; // 'All', 'Morning', 'Afternoon', 'Evening'

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  String _formatDateString(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  String _getHumanDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dt.year, dt.month, dt.day);
    final diff = target.difference(today).inDays;

    final weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    final wd = weekdayNames[dt.weekday - 1];
    final m = monthNames[dt.month - 1];

    if (diff == 0) return 'Today, $m ${dt.day}';
    if (diff == 1) return 'Tomorrow, $m ${dt.day}';
    return '$wd, $m ${dt.day}';
  }

  bool _slotMatchesFilter(WorkoutSlot slot) {
    if (_timeOfDayFilter == 'All') return true;
    final timeStr = slot.startTime.toUpperCase();

    // Check if slot falls in morning, afternoon, or evening
    if (_timeOfDayFilter == 'Morning') {
      if (timeStr.contains('AM')) return true;
      if (timeStr.startsWith('12:')) return false;
      return false;
    } else if (_timeOfDayFilter == 'Afternoon') {
      if (timeStr.contains('12:') && timeStr.contains('PM')) return true;
      if (timeStr.contains('01:') ||
          timeStr.contains('02:') ||
          timeStr.contains('03:') ||
          timeStr.contains('04:')) {
        return timeStr.contains('PM');
      }
      return false;
    } else if (_timeOfDayFilter == 'Evening') {
      if (timeStr.contains('PM')) {
        if (timeStr.contains('05:') ||
            timeStr.contains('06:') ||
            timeStr.contains('07:') ||
            timeStr.contains('08:') ||
            timeStr.contains('09:') ||
            timeStr.contains('10:')) {
          return true;
        }
      }
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = _formatDateString(_selectedDate);
    final queryParams = SlotQueryParams(gymId: widget.gym.id, date: dateStr);
    final slotsAsync = ref.watch(flashFitSlotsProvider(queryParams));

    return Scaffold(
      backgroundColor: const Color(0xFF08080C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF08080C),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Workout Slot',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              widget.gym.name,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Gym Quick Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF14141E),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    widget.gym.heroImage,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 44,
                      height: 44,
                      color: Colors.white10,
                      child: const Icon(Icons.fitness_center, size: 20, color: Colors.white54),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.gym.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 11,
                            color: Color(0xFF00E5FF),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${widget.gym.locality} • ${widget.gym.distanceKm.toStringAsFixed(1)} km',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xFF10B981).withOpacity(0.4),
                    ),
                  ),
                  child: const Text(
                    'All-Access',
                    style: TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Date Picker Bar (Horizontal 10 days)
          Container(
            height: 90,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: 14,
              itemBuilder: (context, idx) {
                final date = DateTime.now().add(Duration(days: idx));
                final isSelected = date.year == _selectedDate.year &&
                    date.month == _selectedDate.month &&
                    date.day == _selectedDate.day;

                final weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                final monthNames = [
                  'Jan',
                  'Feb',
                  'Mar',
                  'Apr',
                  'May',
                  'Jun',
                  'Jul',
                  'Aug',
                  'Sep',
                  'Oct',
                  'Nov',
                  'Dec'
                ];
                final wd = weekdayNames[date.weekday - 1];
                final m = monthNames[date.month - 1];

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = date;
                      _selectedSlot = null; // reset selected slot when date changes
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 60,
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFF00E5FF),
                                Color(0xFF6366F1),
                              ],
                            )
                          : null,
                      color: isSelected
                          ? null
                          : const Color(0xFF14141E),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : Colors.white.withOpacity(0.08),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          idx == 0
                              ? 'TODAY'
                              : idx == 1
                                  ? 'TMRW'
                                  : wd.toUpperCase(),
                          style: TextStyle(
                            color: isSelected
                                ? Colors.black87
                                : Colors.white.withOpacity(0.5),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          m.toUpperCase(),
                          style: TextStyle(
                            color: isSelected
                                ? Colors.black87
                                : Colors.white.withOpacity(0.5),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Time of Day Filter Chips
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildTimeFilterChip('All'),
                const SizedBox(width: 8),
                _buildTimeFilterChip('Morning'),
                const SizedBox(width: 8),
                _buildTimeFilterChip('Afternoon'),
                const SizedBox(width: 8),
                _buildTimeFilterChip('Evening'),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Slots Grid / List
          Expanded(
            child: slotsAsync.when(
              data: (allSlots) {
                final filteredSlots = allSlots.where(_slotMatchesFilter).toList();

                // Auto-select first available slot if none selected
                if (_selectedSlot == null && allSlots.isNotEmpty) {
                  final firstAvailable = allSlots.firstWhere(
                    (s) => !s.isFullyBooked && _slotMatchesFilter(s),
                    orElse: () => allSlots.firstWhere(
                      (s) => !s.isFullyBooked,
                      orElse: () => allSlots.first,
                    ),
                  );
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && _selectedSlot == null) {
                      setState(() {
                        _selectedSlot = firstAvailable;
                      });
                    }
                  });
                }

                if (filteredSlots.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy_rounded,
                          size: 44,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No workout slots available',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Try selecting a different date or time period.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                  itemCount: filteredSlots.length,
                  itemBuilder: (context, idx) {
                    final slot = filteredSlots[idx];
                    final isSelected = _selectedSlot?.id == slot.id;
                    return _buildSlotCard(slot, isSelected);
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
              ),
              error: (err, _) => Center(
                child: Text(
                  'Error loading slots: $err',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            ),
          ),
        ],
      ),

      // Bottom Sticky Booking Bar
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        decoration: BoxDecoration(
          color: const Color(0xFF0E0E16),
          border: Border(
            top: BorderSide(
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.7),
              blurRadius: 20,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedSlot != null
                        ? '${_selectedSlot!.startTime} - ${_selectedSlot!.endTime}'
                        : 'Select a time slot',
                    style: TextStyle(
                      color: _selectedSlot != null
                          ? Colors.white
                          : Colors.white54,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getHumanDate(_selectedDate),
                    style: const TextStyle(
                      color: Color(0xFF00E5FF),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                var slotToBook = _selectedSlot;

                if (slotToBook == null) {
                  final allSlots = slotsAsync.asData?.value;
                  if (allSlots != null && allSlots.isNotEmpty) {
                    slotToBook = allSlots.firstWhere(
                      (s) => !s.isFullyBooked && _slotMatchesFilter(s),
                      orElse: () => allSlots.firstWhere(
                        (s) => !s.isFullyBooked,
                        orElse: () => allSlots.first,
                      ),
                    );
                    setState(() => _selectedSlot = slotToBook);
                  }
                }

                if (slotToBook == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Color(0xFF14141E),
                      content: Row(
                        children: [
                          Icon(Icons.touch_app_rounded, color: Color(0xFF00E5FF), size: 18),
                          SizedBox(width: 8),
                          Text('Please select an available workout slot first.'),
                        ],
                      ),
                    ),
                  );
                  return;
                }

                if (slotToBook.isFullyBooked) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Color(0xFFEF4444),
                      content: Text(
                        'This slot is fully booked. Please select an available slot.',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                  return;
                }

                BookingConfirmationSheet.show(
                  context,
                  gym: widget.gym,
                  slot: slotToBook,
                  formattedDate: _getHumanDate(_selectedDate),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: EdgeInsets.zero,
              ),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF00E5FF),
                      Color(0xFF6366F1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Confirm Session',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: Colors.black,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeFilterChip(String label) {
    final isSelected = _timeOfDayFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _timeOfDayFilter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00E5FF).withOpacity(0.15)
              : const Color(0xFF14141E),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF00E5FF)
                : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF00E5FF) : Colors.white70,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSlotCard(WorkoutSlot slot, bool isSelected) {
    final isFull = slot.isFullyBooked;
    final isAlmostFull = slot.isAlmostFull;

    Color badgeColor = const Color(0xFF10B981);
    if (isFull) badgeColor = const Color(0xFF6B7280);
    if (isAlmostFull) badgeColor = const Color(0xFFF59E0B);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF00E5FF).withOpacity(0.1)
            : const Color(0xFF14141E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF00E5FF)
              : isFull
                  ? Colors.white.withOpacity(0.04)
                  : Colors.white.withOpacity(0.08),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isFull
              ? null
              : () {
                  setState(() {
                    _selectedSlot = slot;
                  });
                },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Radio/Check indicator
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF00E5FF)
                          : Colors.white38,
                      width: 2,
                    ),
                    color: isSelected
                        ? const Color(0xFF00E5FF)
                        : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 14, color: Colors.black)
                      : null,
                ),
                const SizedBox(width: 14),

                // Slot Time & Session Type
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${slot.startTime} - ${slot.endTime}',
                            style: TextStyle(
                              color: isFull ? Colors.white38 : Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isAlmostFull)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Filling Fast',
                                style: TextStyle(
                                  color: Color(0xFFF59E0B),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        slot.sessionType,
                        style: TextStyle(
                          color: isFull
                              ? Colors.white24
                              : Colors.white.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Availability Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: badgeColor.withOpacity(0.4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isFull
                            ? 'FULL'
                            : '${slot.availableSpots} SPOTS',
                        style: TextStyle(
                          color: badgeColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'of ${slot.totalCapacity}',
                        style: TextStyle(
                          color: badgeColor.withOpacity(0.7),
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
