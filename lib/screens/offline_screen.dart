import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:taxi_driver_app/core/controllers/connectivity_controller.dart';
import 'package:taxi_driver_app/core/theme/app_colors.dart';
import 'package:taxi_driver_app/router.dart';
import 'package:taxi_driver_app/l10n/app_localizations.dart';

class OfflineScreen extends StatefulWidget {
  final VoidCallback? onRetry;

  const OfflineScreen({
    super.key,
    this.onRetry,
  });

  @override
  State<OfflineScreen> createState() => _OfflineScreenState();
}

class _OfflineScreenState extends State<OfflineScreen> {
  bool _isChecking = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.brandBlue.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Image.asset(
                    'assets/images/icons8-wi-fi-off-94.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                l10n.translate('noInternetConnection'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.translate('noInternetConnectionMessage'),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // Try Again Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isChecking
                      ? null
                      : () async {
                          setState(() {
                            _isChecking = true;
                          });

                          try {
                            if (widget.onRetry != null) {
                              widget.onRetry!();
                            } else {
                              // Default retry behavior with force check
                              final connectivityController =
                                  Get.find<ConnectivityController>();
                              await connectivityController.forceCheck();

                              // Check if connection is good now
                              if (connectivityController.isConnected.value &&
                                  connectivityController
                                      .hasGoodConnection.value) {
                                // Connection restored - return to splash
                                Get.offAllNamed(Routes.splash);
                              }
                            }
                          } finally {
                            if (mounted) {
                              setState(() {
                                _isChecking = false;
                              });
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonBg,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isChecking
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.refresh_rounded, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              l10n.translate('tryAgain'),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // Offline Features Info
            ],
          ),
        ),
      ),
    );
  }

  // Widget _buildOfflineFeature(BuildContext context, String feature) {
  //   return Padding(
  //     padding: const EdgeInsets.only(bottom: 8),
  //     child: Row(
  //       children: [
  //         Icon(
  //           Icons.check_circle_outline_rounded,
  //           size: 16,
  //           color: AppColors.successColor,
  //         ),
  //         const SizedBox(width: 8),
  //         Expanded(
  //           child: Text(
  //             feature,
  //             style: Theme.of(context).textTheme.bodyMedium?.copyWith(
  //               color: AppColors.textLight,
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
}
