import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:taxi_driver_app/core/theme/app_colors.dart';

class PerformanceMonitor extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const PerformanceMonitor({
    super.key,
    required this.child,
    this.enabled = kDebugMode,
  });

  @override
  State<PerformanceMonitor> createState() => _PerformanceMonitorState();
}

class _PerformanceMonitorState extends State<PerformanceMonitor>
    with WidgetsBindingObserver {
  int _frameCount = 0;
  int _lastFrameCount = 0;
  DateTime _lastUpdate = DateTime.now();
  double _fps = 0.0;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      WidgetsBinding.instance.addObserver(this);
      _startMonitoring();
    }
  }

  @override
  void dispose() {
    if (widget.enabled) {
      WidgetsBinding.instance.removeObserver(this);
    }
    super.dispose();
  }

  void _startMonitoring() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.enabled) {
        _frameCount++;
        _updateFPS();
        _startMonitoring();
      }
    });
  }

  void _updateFPS() {
    final now = DateTime.now();
    final elapsed = now.difference(_lastUpdate).inMilliseconds;

    if (elapsed >= 1000) {
      // Update every second
      final frameDiff = _frameCount - _lastFrameCount;
      _fps = (frameDiff * 1000) / elapsed;

      if (mounted) {
        setState(() {});
      }

      _lastFrameCount = _frameCount;
      _lastUpdate = now;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isVisible = state == AppLifecycleState.resumed;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.enabled && _isVisible)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _fps < 30
                    ? AppColors.errorColor
                    : _fps < 50
                        ? AppColors.tertiaryColor
                        : AppColors.successColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'FPS: ${_fps.toStringAsFixed(1)}',
                style: TextStyle(
                  color: _fps >= 30 && _fps < 50
                      ? AppColors.textPrimary
                      : AppColors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
