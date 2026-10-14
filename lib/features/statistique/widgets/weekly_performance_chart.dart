import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../l10n/app_localizations.dart';
import 'dart:ui' as ui;

/// Widget pour afficher le graphique de performance hebdomadaire (LineChart moderne)
class WeeklyPerformanceChart extends StatelessWidget {
  final List<double> weeklyData;
  final List<String> labels;
  final bool isPercentage;

  const WeeklyPerformanceChart({
    super.key,
    required this.weeklyData,
    required this.labels,
    this.isPercentage = false,
  });

  Color _getLineColor(bool isPercentage) {
    return isPercentage ? AppColors.secondaryColor : AppColors.brandBlue;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (weeklyData.isEmpty) {
      return const Center(
        child: Text('Aucune donnée disponible'),
      );
    }

    final maxValue = isPercentage
        ? 100.0
        : (weeklyData.reduce((a, b) => a > b ? a : b) * 1.2)
            .clamp(1.0, double.infinity);

    return Column(
      children: [
        Container(
          height: 240,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceColor,
            borderRadius: AppColors.cardBorderRadius,
            boxShadow: AppColors.lightCardShadow,
          ),
          child: Column(
            children: [
              Expanded(
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _LineChartPainter(
                    data: weeklyData,
                    labels: labels,
                    maxValue: maxValue,
                    lineColor: _getLineColor(isPercentage),
                    isPercentage: isPercentage,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Simple legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 16,
              height: 3,
              decoration: BoxDecoration(
                color: _getLineColor(isPercentage),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              isPercentage
                  ? l10n.translate('loadRate')
                  : '${l10n.translate('totalRevenue')} (${l10n.translate('currencySymbol')})',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> data;
  final List<String> labels;
  final double maxValue;
  final Color lineColor;
  final bool isPercentage;

  _LineChartPainter({
    required this.data,
    required this.labels,
    required this.maxValue,
    required this.lineColor,
    required this.isPercentage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(0, size.height),
        [
          lineColor.withOpacity(0.3),
          lineColor.withOpacity(0.05),
        ],
      )
      ..style = PaintingStyle.fill;

    final pointPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    final pointBorderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final gridPaint = Paint()
      ..color = AppColors.dividerColor.withOpacity(0.3)
      ..strokeWidth = 1;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    // Chart area with padding for labels
    final chartTop = 30.0;
    final chartBottom = size.height - 30.0;
    final chartHeight = chartBottom - chartTop;
    final chartLeft = 30.0;
    final chartRight = size.width - 10.0;
    final chartWidth = chartRight - chartLeft;

    // Draw horizontal grid lines
    for (int i = 0; i <= 4; i++) {
      final y = chartBottom - (chartHeight * i / 4);
      canvas.drawLine(
        Offset(chartLeft, y),
        Offset(chartRight, y),
        gridPaint,
      );

      // Draw Y-axis labels
      final value = (maxValue * i / 4);
      textPainter.text = TextSpan(
        text: isPercentage
            ? '${value.toStringAsFixed(0)}%'
            : '${value.toStringAsFixed(2)} TND',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 9,
          fontWeight: FontWeight.w500,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(chartLeft - textPainter.width - 5, y - textPainter.height / 2),
      );
    }

    // Calculate points
    final points = <Offset>[];
    final stepX = chartWidth / (data.length - 1).clamp(1, double.infinity);

    for (int i = 0; i < data.length; i++) {
      final x = chartLeft + (i * stepX);
      final normalizedValue = (data[i] / maxValue).clamp(0.0, 1.0);
      final y = chartBottom - (normalizedValue * chartHeight);
      points.add(Offset(x, y));

      // Draw X-axis labels
      textPainter.text = TextSpan(
        text: labels[i],
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, chartBottom + 8),
      );
    }

    // Draw gradient fill
    if (points.length > 1) {
      final fillPath = Path();
      fillPath.moveTo(points.first.dx, chartBottom);
      fillPath.lineTo(points.first.dx, points.first.dy);

      for (int i = 1; i < points.length; i++) {
        final prev = points[i - 1];
        final current = points[i];
        final controlPoint1 = Offset(
          prev.dx + (current.dx - prev.dx) / 3,
          prev.dy,
        );
        final controlPoint2 = Offset(
          prev.dx + 2 * (current.dx - prev.dx) / 3,
          current.dy,
        );
        fillPath.cubicTo(
          controlPoint1.dx,
          controlPoint1.dy,
          controlPoint2.dx,
          controlPoint2.dy,
          current.dx,
          current.dy,
        );
      }

      fillPath.lineTo(points.last.dx, chartBottom);
      fillPath.close();
      canvas.drawPath(fillPath, fillPaint);
    }

    // Draw line
    if (points.length > 1) {
      final linePath = Path();
      linePath.moveTo(points.first.dx, points.first.dy);

      for (int i = 1; i < points.length; i++) {
        final prev = points[i - 1];
        final current = points[i];
        final controlPoint1 = Offset(
          prev.dx + (current.dx - prev.dx) / 3,
          prev.dy,
        );
        final controlPoint2 = Offset(
          prev.dx + 2 * (current.dx - prev.dx) / 3,
          current.dy,
        );
        linePath.cubicTo(
          controlPoint1.dx,
          controlPoint1.dy,
          controlPoint2.dx,
          controlPoint2.dy,
          current.dx,
          current.dy,
        );
      }

      canvas.drawPath(linePath, paint);
    }

    // Draw points and values
    for (int i = 0; i < points.length; i++) {
      final point = points[i];

      // Draw point
      canvas.drawCircle(point, 5, pointBorderPaint);
      canvas.drawCircle(point, 4, pointPaint);

      // Draw value label above point
      final value = data[i];
      if (value > 0) {
        textPainter.text = TextSpan(
          text: isPercentage
              ? '${value.toStringAsFixed(0)}%'
              : value.toStringAsFixed(2),
          style: TextStyle(
            color: lineColor,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(point.dx - textPainter.width / 2, point.dy - 20),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.labels != labels ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.lineColor != lineColor;
  }
}
