import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:taxi_driver_app/core/theme/app_colors.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/services.dart';
import 'package:taxi_driver_app/l10n/app_localizations.dart';
import 'package:taxi_driver_app/core/shared/snackbar.dart';
import 'package:taxi_driver_app/services/checkForUpdate_service.dart';

class UpdateScreen extends StatefulWidget {
  const UpdateScreen({super.key});

  @override
  State<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final CheckForUpdateService _updateService = CheckForUpdateService();
  bool _isUpdating = false;
  bool _autoUpdateFailed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController.forward();
    _startAutomaticUpdate();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _startAutomaticUpdate() async {
    if (_isUpdating) return;

    setState(() {
      _isUpdating = true;
      _autoUpdateFailed = false;
    });

    final outcome = await _updateService.performAutomaticUpdate();

    if (!mounted) return;

    switch (outcome) {
      case InAppUpdateOutcome.success:
        // Play restarts the app after an immediate update.
        // For flexible updates the install completes and we stay here until relaunch.
        setState(() => _isUpdating = false);
        break;
      case InAppUpdateOutcome.userCanceled:
      case InAppUpdateOutcome.unavailable:
      case InAppUpdateOutcome.failed:
        setState(() {
          _isUpdating = false;
          _autoUpdateFailed = true;
        });
        break;
    }
  }

  Future<void> _openPlayStore() async {
    const url =
        'https://play.google.com/store/apps/details?id=com.fds.neotrack';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _makePhoneCall() async {
    const phone = '71610911';
    final localizations = AppLocalizations.of(context);

    try {
      await launchUrl(
        Uri.parse('tel:$phone'),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      try {
        await launchUrl(
          Uri.parse('tel://$phone'),
          mode: LaunchMode.externalApplication,
        );
      } catch (_) {
        await Clipboard.setData(const ClipboardData(text: phone));
        if (mounted) {
          CustomSnackBar.info(
            title: localizations.translate('phoneNumberCopied'),
            message: phone,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final title = _isUpdating
        ? localizations.translate('updatingApp')
        : localizations.translate('updateAvailable');
    final description = _isUpdating
        ? localizations.translate('updatingAppDescription')
        : localizations.translate('updateDescription').replaceAll('\\n', '\n');

    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.8, end: 1.0),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeInOut,
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppColors.brandBlue.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: _isUpdating
                            ? Padding(
                                padding: const EdgeInsets.all(28),
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: AppColors.brandBlue,
                                ),
                              )
                            : Icon(
                                FeatherIcons.downloadCloud,
                                size: 50,
                                color: AppColors.brandBlue,
                              ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 56),
                if (!_isUpdating) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _startAutomaticUpdate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonBg,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shadowColor: AppColors.buttonBg.withValues(alpha: 0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(FeatherIcons.download, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            localizations.translate('updateNow'),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_autoUpdateFailed) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: _openPlayStore,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.brandBlue,
                          side: BorderSide(color: AppColors.brandBlue),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          localizations.translate('openPlayStore'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 600),
        tween: Tween(begin: 0.7, end: 1.0),
        curve: Curves.elasticOut,
        builder: (_, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: FloatingActionButton(
          backgroundColor: AppColors.buttonBg,
          elevation: 6,
          highlightElevation: 12,
          onPressed: _makePhoneCall,
          child: const Icon(Icons.phone, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}
