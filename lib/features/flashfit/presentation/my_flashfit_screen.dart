import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/booking_model.dart';
import '../models/subscription_model.dart';
import '../providers/flashfit_providers.dart';
import '../services/flashfit_service.dart';

class MyFlashFitScreen extends ConsumerStatefulWidget {
  const MyFlashFitScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MyFlashFitScreen> createState() => _MyFlashFitScreenState();
}

class _MyFlashFitScreenState extends ConsumerState<MyFlashFitScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleCancelBooking(FlashFitBooking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14141E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFEC4899),
              size: 24,
            ),
            SizedBox(width: 8),
            Text(
              'Cancel Workout?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to cancel your session at ${booking.gymName}?',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF00E5FF).withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF00E5FF).withOpacity(0.2),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFF00E5FF),
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your workout pass credit will be refunded immediately back to your membership.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Keep Booking',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEC4899),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final userId = FlashFitService().currentUserId;
      final result = await FlashFitService().cancelBooking(
        bookingId: booking.id,
        userId: userId,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        ref.invalidate(flashFitBookingsProvider);
        ref.invalidate(flashFitSubscriptionProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF14141E),
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF10B981),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    result['message'] ?? 'Booking cancelled and credit refunded.',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade900,
            content: Text(
              result['message'] ?? 'Failed to cancel booking',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      }
    }
  }

  void _showPassDetailsModal(FlashFitBooking booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF14141E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00E5FF), Color(0xFF6366F1)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'FLASHFIT PASS',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  booking.gymName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  booking.gymAddress,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 20),

                // Digital Turnstile QR Code Simulation
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildSimulatedQRCode(),
                      const SizedBox(height: 10),
                      Text(
                        booking.bookingCode,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Scan this pass at the gym entrance turnstile / front desk',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildPassMeta(
                        'DATE',
                        booking.bookingDate,
                      ),
                      _buildPassMeta(
                        'TIME',
                        booking.startTime,
                      ),
                      _buildPassMeta(
                        'STATUS',
                        booking.status.toUpperCase(),
                        color: booking.isUpcoming
                            ? const Color(0xFF10B981)
                            : booking.isCompleted
                                ? const Color(0xFF6366F1)
                                : const Color(0xFFEC4899),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSimulatedQRCode() {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: CustomPaint(
        painter: _SimulatedQRPainter(),
      ),
    );
  }

  Widget _buildPassMeta(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: color ?? Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final subAsync = ref.watch(flashFitSubscriptionProvider);
    final bookingsAsync = ref.watch(flashFitBookingsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF08080C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF08080C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My FlashFit Passes',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: () {
              ref.invalidate(flashFitBookingsProvider);
              ref.invalidate(flashFitSubscriptionProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // User Pass Summary Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: subAsync.when(
              data: (sub) => _buildMembershipCard(sub),
              loading: () => const SizedBox(height: 90),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),

          // Custom Segmented Tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF14141E),
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF00E5FF),
                    Color(0xFF6366F1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.white60,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'Upcoming'),
                Tab(text: 'Completed'),
                Tab(text: 'Cancelled'),
              ],
            ),
          ),

          // Bookings Tab Views
          Expanded(
            child: bookingsAsync.when(
              data: (bookings) {
                final upcoming = bookings.where((b) => b.isUpcoming).toList();
                final completed = bookings.where((b) => b.isCompleted).toList();
                final cancelled = bookings.where((b) => b.isCancelled).toList();

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBookingsList(upcoming, 'upcoming'),
                    _buildBookingsList(completed, 'completed'),
                    _buildBookingsList(cancelled, 'cancelled'),
                  ],
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
              ),
              error: (err, _) => Center(
                child: Text(
                  'Error loading passes: $err',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembershipCard(FlashFitSubscription sub) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E1B4B),
            Color(0xFF0F172A),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF6366F1).withOpacity(0.4),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.bolt_rounded,
                      color: Color(0xFF00E5FF),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    sub.planName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFF10B981).withOpacity(0.4),
                  ),
                ),
                child: const Text(
                  'ACTIVE',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMembershipStat(
                'Available Workouts',
                '${sub.remainingSessions}',
                highlight: true,
              ),
              _buildMembershipStat(
                'Used this month',
                '${sub.sessionsUsed}',
              ),
              _buildMembershipStat(
                'Pass Renews In',
                '${sub.daysRemaining} days',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMembershipStat(String label, String value, {bool highlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: highlight ? const Color(0xFF00E5FF) : Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildBookingsList(List<FlashFitBooking> list, String type) {
    if (list.isEmpty) {
      String msg = 'No upcoming workout sessions.';
      if (type == 'completed') msg = 'No completed workout sessions yet.';
      if (type == 'cancelled') msg = 'No cancelled sessions.';

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.confirmation_number_outlined,
              size: 48,
              color: Colors.white.withOpacity(0.2),
            ),
            const SizedBox(height: 12),
            Text(
              msg,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
            if (type == 'upcoming') ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.search_rounded, size: 16),
                label: const Text('Discover Studios'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: list.length,
      itemBuilder: (context, idx) {
        final booking = list[idx];
        return _buildBookingTicket(booking);
      },
    );
  }

  Widget _buildBookingTicket(FlashFitBooking booking) {
    final bool isUpcoming = booking.isUpcoming;
    final bool isCompleted = booking.isCompleted;

    Color statusColor = const Color(0xFF10B981);
    if (isCompleted) statusColor = const Color(0xFF6366F1);
    if (booking.isCancelled) statusColor = const Color(0xFFEC4899);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF14141E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Column(
        children: [
          // Upper Ticket Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gym thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 60,
                    height: 60,
                    color: const Color(0xFF1E1E2C),
                    child: booking.gymImage != null
                        ? Image.network(
                            booking.gymImage!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.fitness_center_rounded,
                              color: Colors.white38,
                            ),
                          )
                        : const Icon(
                            Icons.fitness_center_rounded,
                            color: Colors.white38,
                          ),
                  ),
                ),
                const SizedBox(width: 14),

                // Gym Name & Booking Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              booking.gymName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              booking.status.toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        booking.gymAddress,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 12,
                            color: const Color(0xFF00E5FF).withOpacity(0.8),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            booking.bookingDate,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.access_time_rounded,
                            size: 12,
                            color: const Color(0xFF00E5FF).withOpacity(0.8),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            booking.startTime,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Dashed Divider / Ticket Perforation
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: List.generate(
                30,
                (index) => Expanded(
                  child: Container(
                    color: index % 2 == 0 ? Colors.transparent : Colors.white12,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),

          // Lower Ticket Footer: Code & Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'BOOKING CODE',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      booking.bookingCode,
                      style: const TextStyle(
                        color: Color(0xFF00E5FF),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    // View Digital Pass (QR)
                    OutlinedButton.icon(
                      onPressed: () => _showPassDetailsModal(booking),
                      icon: const Icon(Icons.qr_code_rounded, size: 16),
                      label: const Text('Digital Pass'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withOpacity(0.2),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),

                    if (isUpcoming) ...[
                      const SizedBox(width: 8),
                      // Cancel Button
                      TextButton(
                        onPressed: () => _handleCancelBooking(booking),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFEC4899),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter for Simulated QR Code Pattern
class _SimulatedQRPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    // Corner positioning squares (top-left, top-right, bottom-left)
    _drawCornerSquare(canvas, 10, 10, 36, paint);
    _drawCornerSquare(canvas, size.width - 46, 10, 36, paint);
    _drawCornerSquare(canvas, 10, size.height - 46, 36, paint);

    // Decorative inner blocks to simulate real QR
    final randomBlocks = [
      Rect.fromLTWH(56, 14, 8, 8),
      Rect.fromLTWH(72, 14, 16, 8),
      Rect.fromLTWH(56, 30, 12, 12),
      Rect.fromLTWH(80, 28, 8, 14),
      Rect.fromLTWH(20, 56, 14, 8),
      Rect.fromLTWH(44, 56, 20, 8),
      Rect.fromLTWH(74, 56, 12, 14),
      Rect.fromLTWH(96, 56, 16, 8),
      Rect.fromLTWH(120, 56, 14, 14),
      Rect.fromLTWH(16, 78, 10, 10),
      Rect.fromLTWH(36, 74, 14, 14),
      Rect.fromLTWH(60, 80, 20, 8),
      Rect.fromLTWH(90, 76, 16, 12),
      Rect.fromLTWH(116, 76, 22, 10),
      Rect.fromLTWH(24, 98, 16, 10),
      Rect.fromLTWH(52, 98, 24, 12),
      Rect.fromLTWH(86, 98, 14, 14),
      Rect.fromLTWH(110, 96, 18, 12),
      Rect.fromLTWH(56, 120, 16, 14),
      Rect.fromLTWH(82, 122, 22, 8),
      Rect.fromLTWH(114, 120, 20, 14),
      Rect.fromLTWH(56, 140, 28, 8),
      Rect.fromLTWH(94, 138, 14, 10),
      Rect.fromLTWH(118, 140, 18, 8),
    ];

    for (final rect in randomBlocks) {
      canvas.drawRect(rect, paint);
    }
  }

  void _drawCornerSquare(Canvas canvas, double x, double y, double sz, Paint paint) {
    // Outer border
    canvas.drawRect(Rect.fromLTWH(x, y, sz, sz), paint);
    // Inner clear
    canvas.drawRect(
      Rect.fromLTWH(x + 5, y + 5, sz - 10, sz - 10),
      Paint()..color = Colors.white,
    );
    // Center filled block
    canvas.drawRect(
      Rect.fromLTWH(x + 10, y + 10, sz - 20, sz - 20),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
