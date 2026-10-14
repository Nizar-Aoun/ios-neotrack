import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taxi_driver_app/core/shared/shimmer_loading.dart';
import 'package:taxi_driver_app/core/theme/app_colors.dart';
import 'dart:ui' as ui;

/// Shared address bubble widget for map markers
/// Used in both history tracking and ride details screens
class AddressBubbleMarker extends StatelessWidget {
  final bool showBubble;
  final bool isLoadingAddress;
  final String address;
  final VoidCallback onClose;

  const AddressBubbleMarker({
    super.key,
    required this.showBubble,
    required this.isLoadingAddress,
    required this.address,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 35), // Space for car below
        AnimatedScale(
          scale: showBubble ? 1.0 : 0.8,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            opacity: showBubble ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 320, minWidth: 200),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primaryColor,
                          AppColors.primaryColor.withOpacity(0.9),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                      color: AppColors.primaryColor.withOpacity(0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: isLoadingAddress
                              ? const AddressBubbleShimmer()
                              : Text(
                                  address,
                                  style: GoogleFonts.barlow(
                                    fontSize: 14,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: onClose,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Transform.flip(
                    flipY: true,
                    child: CustomPaint(
                      size: const Size(20, 10),
                      painter: BubbleArrowPainter(
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Text-shaped shimmer tinted to blend into the blue address bubble.
class AddressBubbleShimmer extends StatelessWidget {
  const AddressBubbleShimmer({super.key});

  static const _baseColor = Color(0x33FFFFFF);
  static const _highlightColor = Color(0x66FFFFFF);

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          ShimmerBox(
            width: 88,
            height: 9,
            borderRadius: BorderRadius.all(Radius.circular(5)),
            baseColor: _baseColor,
            highlightColor: _highlightColor,
          ),
          SizedBox(width: 7),
          ShimmerBox(
            width: 22,
            height: 9,
            borderRadius: BorderRadius.all(Radius.circular(5)),
            baseColor: _baseColor,
            highlightColor: _highlightColor,
          ),
        ],
      ),
    );
  }
}

/// Custom painter for bubble arrow pointing to car
class BubbleArrowPainter extends CustomPainter {
  final Color color;

  BubbleArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = ui.Path()
      ..moveTo(size.width / 2 - 8, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width / 2 + 8, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
