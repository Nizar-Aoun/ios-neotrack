import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taxi_driver_app/core/theme/app_colors.dart';

class RideCompletedCue extends StatelessWidget {
  final bool visible;
  final int eventVersion;
  final double? fare;
  final String rideLabel;
  final String currencyLabel;

  const RideCompletedCue({
    super.key,
    required this.visible,
    required this.eventVersion,
    required this.fare,
    required this.rideLabel,
    required this.currencyLabel,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 360),
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: animation, child: child),
        ),
        child: visible
            ? Container(
                key: ValueKey(eventVersion),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.successColor,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withOpacity(0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: AppColors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '+1 $rideLabel',
                      style: GoogleFonts.barlow(
                        color: AppColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (fare != null) ...[
                      const SizedBox(width: 10),
                      Container(
                        width: 1,
                        height: 18,
                        color: AppColors.white.withOpacity(0.4),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '+${fare!.toStringAsFixed(3)} $currencyLabel',
                        style: GoogleFonts.barlow(
                          color: AppColors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              )
            : const SizedBox.shrink(key: ValueKey('hidden-ride-complete')),
      ),
    );
  }
}
