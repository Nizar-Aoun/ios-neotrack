import 'package:flutter/material.dart';
import 'package:taxi_driver_app/core/shared/shimmer_loading.dart';
import 'package:taxi_driver_app/core/theme/app_colors.dart';

/// Skeleton placeholder for the transactions (rides / expenses) list,
/// mirroring the layout of [TransactionItemWidget] while data loads.
class TransactionListSkeleton extends StatelessWidget {
  final bool isVerySmallScreen;
  final bool isSmallScreen;
  final int itemCount;

  const TransactionListSkeleton({
    super.key,
    required this.isVerySmallScreen,
    required this.isSmallScreen,
    this.itemCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.only(
            bottom: isVerySmallScreen
                ? 60
                : isSmallScreen
                    ? 70
                    : 80),
        itemCount: itemCount,
        itemBuilder: (_, __) => _TransactionCardSkeleton(
          isVerySmallScreen: isVerySmallScreen,
          isSmallScreen: isSmallScreen,
        ),
      ),
    );
  }
}

class _TransactionCardSkeleton extends StatelessWidget {
  final bool isVerySmallScreen;
  final bool isSmallScreen;

  const _TransactionCardSkeleton({
    required this.isVerySmallScreen,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    final gap = isVerySmallScreen
        ? 4.0
        : isSmallScreen
            ? 6.0
            : 8.0;
    final iconSize = isVerySmallScreen
        ? 16.0
        : isSmallScreen
            ? 18.0
            : 20.0;
    final radius = isVerySmallScreen
        ? 10.0
        : isSmallScreen
            ? 12.0
            : 14.0;

    return Container(
      margin: EdgeInsets.only(bottom: gap),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.borderColor, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: AppColors.lightShadowColor,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isVerySmallScreen
            ? 8
            : isSmallScreen
                ? 10
                : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: type icon + label
            Row(
              children: [
                ShimmerBox(
                  width: iconSize,
                  height: iconSize,
                  borderRadius: BorderRadius.circular(5),
                ),
                SizedBox(width: gap),
                ShimmerBox(
                  width: isVerySmallScreen ? 48 : 60,
                  height: isVerySmallScreen ? 9 : 11,
                ),
              ],
            ),
            SizedBox(height: gap),
            // Amount + badges
            Row(
              children: [
                ShimmerBox(
                  width: isVerySmallScreen
                      ? 70
                      : isSmallScreen
                          ? 85
                          : 100,
                  height: isVerySmallScreen ? 13 : 16,
                ),
                const Spacer(),
                ShimmerBox(
                  width: isVerySmallScreen ? 42 : 54,
                  height: isVerySmallScreen ? 14 : 17,
                ),
                SizedBox(width: gap),
                ShimmerBox(
                  width: isVerySmallScreen ? 42 : 54,
                  height: isVerySmallScreen ? 14 : 17,
                ),
              ],
            ),
            SizedBox(height: gap),
            // Date + max speed badge
            Row(
              children: [
                ShimmerBox(
                  width: isVerySmallScreen ? 80 : 104,
                  height: isVerySmallScreen ? 8 : 9,
                ),
                const Spacer(),
                ShimmerBox(
                  width: isVerySmallScreen ? 66 : 84,
                  height: isVerySmallScreen ? 14 : 17,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
