import 'package:flutter/material.dart';
import 'package:taxi_driver_app/core/theme/app_colors.dart';
import 'package:taxi_driver_app/core/theme/text_styles.dart';
import 'package:taxi_driver_app/core/shared/loading_gif.dart';

/// Loading State Widget - Shows circular progress indicator
class NotificationLoadingState extends StatelessWidget {
  const NotificationLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: LoadingGif(
        width: 60,
        height: 60,
      ),
    );
  }
}
