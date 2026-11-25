import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subscription_model.dart';
import '../services/flashfit_service.dart';
import '../providers/flashfit_providers.dart';

class SubscriptionGateDialog extends ConsumerStatefulWidget {
  final VoidCallback? onActivated;

  const SubscriptionGateDialog({Key? key, this.onActivated}) : super(key: key);

  static Future<bool> show(BuildContext context, {VoidCallback? onActivated}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => SubscriptionGateDialog(onActivated: onActivated),
    );
    return result ?? false;
  }

  @override
  ConsumerState<SubscriptionGateDialog> createState() =>
      _SubscriptionGateDialogState();
}

class _SubscriptionGateDialogState extends ConsumerState<SubscriptionGateDialog> {
  bool _isUpgrading = false;

  void _activatePass() async {
    setState(() => _isUpgrading = true);
    final userId = FlashFitService().currentUserId;
    final eliteSub = FlashFitSubscription(
      userId: userId,
      planName: 'FlashFit Elite All-Access Pass',
      tier: 'ELITE',
      isActive: true,
      sessionsPerMonth: 30,
      sessionsUsed: 0,
      validUntil: DateTime.now().add(const Duration(days: 30)),
    );

    await FlashFitService().saveSubscription(eliteSub);
    ref.invalidate(flashFitSubscriptionProvider);

    if (mounted) {
      setState(() => _isUpgrading = false);
      Navigator.of(context).pop(true);
      widget.onActivated?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF10B981),
          content: Text(
            '🎉 FlashFit Elite All-Access Pass activated! You can now book unlimited sessions.',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF181F33),
              Color(0xFF0F1322),
            ],
          ),
          border: Border.all(
            color: const Color(0xFF00E5FF).withOpacity(0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00E5FF).withOpacity(0.2),
              blurRadius: 30,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.8),
              blurRadius: 40,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Crown / Bolt Icon Badge
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF00E5FF), Color(0xFF6366F1)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withOpacity(0.4),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Icon(
                Icons.flash_on_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
            const SizedBox(height: 16),

            // Title
            const Text(
              'FLASHFIT ELITE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'By SetMeFit',
              style: TextStyle(
                color: const Color(0xFF00E5FF).withOpacity(0.85),
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 14),

            // Description
            Text(
              'Your current membership tier requires an active SetMeFit All-Access Pass to book multi-gym sessions.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),

            // Perks checklist
            _buildPerkRow('Access to 150+ premium partner gyms & studios'),
            _buildPerkRow('No lock-in contracts • 30 sessions per month'),
            _buildPerkRow('Cardio, Olympic lifting, Swimming & CrossFit pools'),
            _buildPerkRow('Free cancellations up to 2 hours before slot'),

            const SizedBox(height: 24),

            // Activate button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isUpgrading ? null : _activatePass,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00E5FF), Color(0xFF6366F1)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E5FF).withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isUpgrading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'ACTIVATE FLASHFIT PASS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Dismiss Button
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Maybe Later',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerkRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF00FF88),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
