import 'package:flutter/material.dart';
import '../../../core/shared/shimmer_loading.dart';
import '../../../core/theme/app_colors.dart';

/// Skeleton placeholder for the dashboard (Accueil) tab, mirroring the
/// performance header, KPI grid and metrics card while stats load.
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final topPadding = MediaQuery.of(context).padding.top;
    final textScale =
        MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.6).toDouble();
    final isSmallScreen = size.width < 360;
    final baseKpiAspectRatio = size.height < 600
        ? 1.15
        : size.height < 700
            ? 1.25
            : size.height < 800
                ? 1.3
                : 1.4;
    final kpiChildAspectRatio =
        (baseKpiAspectRatio / textScale).clamp(0.78, 1.4);

    return Container(
      color: AppColors.backgroundColor,
      child: ShimmerLoading(
        child: Column(
          children: [
            // Performance index header
            Container(
              margin: EdgeInsets.only(
                left: 16,
                right: 16,
                top: topPadding + 100,
                bottom: 12,
              ),
              padding: EdgeInsets.all(isSmallScreen ? 12 : 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ShimmerBox(
                              width: isSmallScreen ? 28 : 30,
                              height: isSmallScreen ? 28 : 30,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            const SizedBox(width: 10),
                            ShimmerBox(
                              width: isSmallScreen ? 110 : 130,
                              height: 13,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ShimmerBox(
                          width: 84,
                          height: isSmallScreen ? 20 : 22,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        SizedBox(height: isSmallScreen ? 8 : 10),
                        ShimmerBox(
                          width: 128,
                          height: isSmallScreen ? 28 : 30,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        const SizedBox(height: 6),
                      ],
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 10 : 12),
                  ShimmerBox(
                    width: isSmallScreen ? 72 : 80,
                    height: isSmallScreen ? 72 : 80,
                    shape: BoxShape.circle,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // Overview section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const ShimmerBox(width: 120, height: 20),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: kpiChildAspectRatio,
                          children:
                              List.generate(6, (_) => const _KpiSkeleton()),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Performance metrics section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const ShimmerBox(width: 170, height: 20),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: List.generate(
                              4,
                              (index) => Padding(
                                padding: EdgeInsets.only(
                                    bottom: index == 3 ? 0 : 16),
                                child: const _MetricSkeleton(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiSkeleton extends StatelessWidget {
  const _KpiSkeleton();

  @override
  Widget build(BuildContext context) {
    final textScale =
        MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.6).toDouble();
    final compact = textScale > 1.15;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerBox(
                width: compact ? 30 : 36,
                height: compact ? 30 : 36,
                borderRadius: BorderRadius.circular(12),
              ),
              const ShimmerBox(width: 6, height: 6, shape: BoxShape.circle),
            ],
          ),
          SizedBox(height: compact ? 6 : 10),
          const ShimmerBox(width: 78, height: 11),
          SizedBox(height: compact ? 4 : 6),
          const ShimmerBox(width: 56, height: 16),
          SizedBox(height: compact ? 0 : 2),
        ],
      ),
    );
  }
}

class _MetricSkeleton extends StatelessWidget {
  const _MetricSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            ShimmerBox(width: 96, height: 12),
            ShimmerBox(width: 56, height: 12),
          ],
        ),
        const SizedBox(height: AppColors.spacingS),
        ShimmerBox(
          height: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}
