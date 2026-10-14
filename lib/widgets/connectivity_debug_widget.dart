import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taxi_driver_app/core/theme/app_colors.dart';
import 'package:taxi_driver_app/services/connectivity_service.dart';

class ConnectivityDebugWidget extends StatelessWidget {
  const ConnectivityDebugWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityService>(
      builder: (context, connectivityService, _) {
        return GestureDetector(
          onTap: () {
            // Manual trigger for testing
            connectivityService.triggerImmediateCheck();
            connectivityService.forceUpdate();

            // Force multiple notifications to ensure UI updates
            Future.delayed(const Duration(milliseconds: 50), () {
              connectivityService.forceUpdate();
            });
            Future.delayed(const Duration(milliseconds: 100), () {
              connectivityService.forceUpdate();
            });
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.baseColor.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                connectivityService.isConnected
                    ? const Icon(
                        Icons.wifi_rounded,
                        color: AppColors.successColor,
                        size: 16,
                      )
                    : Image.asset(
                        'assets/images/icons8-wi-fi-off-94.png',
                        width: 16,
                        height: 16,
                        fit: BoxFit.contain,
                      ),
                const SizedBox(width: 8),
                Text(
                  connectivityService.isConnected ? 'Online' : 'Offline',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  connectivityService.isInitialized ? '✓' : '⏳',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.http,
                  color: AppColors.brandBlue,
                  size: 12,
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.touch_app,
                  color: AppColors.tertiaryColor,
                  size: 12,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
