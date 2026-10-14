import 'package:flutter/material.dart';
import 'package:taxi_driver_app/core/theme/app_colors.dart';

/// Drives a single synchronized shimmer animation for every [ShimmerBox]
/// placed below it, so a whole skeleton screen pulses as one.
class ShimmerLoading extends StatefulWidget {
  final Widget child;

  const ShimmerLoading({super.key, required this.child});

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ShimmerScope(animation: _controller, child: widget.child);
  }
}

class _ShimmerScope extends InheritedWidget {
  final Animation<double> animation;

  const _ShimmerScope({required this.animation, required super.child});

  static Animation<double>? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ShimmerScope>()?.animation;

  @override
  bool updateShouldNotify(_ShimmerScope oldWidget) =>
      animation != oldWidget.animation;
}

/// A single skeleton block. Animates only when wrapped in a [ShimmerLoading],
/// otherwise it renders as a static placeholder.
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadiusGeometry? borderRadius;
  final BoxShape shape;
  final Widget? child;
  final Color baseColor;
  final Color highlightColor;

  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
    this.child,
    this.baseColor = AppColors.surfaceMuted,
    this.highlightColor = const Color(0xFFF8FAFA),
  });

  @override
  Widget build(BuildContext context) {
    final animation = _ShimmerScope.maybeOf(context);
    if (animation == null) return _box(0);

    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) => _box(animation.value),
    );
  }

  Widget _box(double progress) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        shape: shape,
        borderRadius: shape == BoxShape.circle
            ? null
            : (borderRadius ?? BorderRadius.circular(6)),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [baseColor, highlightColor, baseColor],
          stops: const [0.1, 0.5, 0.9],
          transform: _SweepTransform(progress),
        ),
      ),
      child: child,
    );
  }
}

/// Slides the shimmer gradient across the box from left to right.
class _SweepTransform extends GradientTransform {
  final double progress;

  const _SweepTransform(this.progress);

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues((progress * 2 - 1) * bounds.width, 0.0, 0.0);
}
