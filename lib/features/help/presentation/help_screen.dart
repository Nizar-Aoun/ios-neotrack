import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:taxi_driver_app/core/theme/app_colors.dart';
import 'package:taxi_driver_app/l10n/app_localizations.dart';
import 'package:taxi_driver_app/features/help/provider/help_controller.dart';
import 'package:taxi_driver_app/features/help/domain/help_video_model.dart';
import 'package:taxi_driver_app/features/help/presentation/video_player_screen.dart';
import 'package:taxi_driver_app/core/controllers/language_controller.dart';
import 'package:taxi_driver_app/core/shared/snackbar.dart';
import 'package:taxi_driver_app/core/shared/shimmer_loading.dart';

class HelpScreen extends GetView<HelpController> {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageController = Get.find<LanguageController>();
    final isSmallScreen = MediaQuery.of(context).size.height < 650;

    return Scaffold(
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.backgroundColor, AppColors.white],
                stops: [0.0, 0.45],
              ),
            ),
          ),
          Column(
            children: [
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return _buildShimmerGrid(isSmallScreen);
                  }
                  if (controller.errorMessage.value != null ||
                      controller.videos.isEmpty) {
                    return _buildEmptyState(
                      l10n,
                      isSmallScreen,
                      controller.errorMessage.value,
                    );
                  }
                  return _buildVideosGrid(
                    context,
                    l10n,
                    languageController,
                    isSmallScreen,
                  );
                }),
              ),
            ],
          ),

          // Floating call button (compact)
          Positioned(
            right: isSmallScreen ? 16 : 20,
            bottom: isSmallScreen ? 16 : 20,
            child: _buildFloatingCallButton(isSmallScreen),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerGrid(bool isSmallScreen) {
    final spacing = isSmallScreen ? 8.0 : 12.0;
    return ShimmerLoading(
      child: Center(
        child: GridView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.all(spacing),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.82,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
          ),
          itemCount: 6,
          itemBuilder: (_, __) => const _ShimmerCard(),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
      AppLocalizations l10n, bool isSmallScreen, String? error) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isSmallScreen ? 20 : 28),
        child: Column(
          children: [
            Icon(
              error != null ? Icons.cloud_off : Icons.video_library_outlined,
              size: isSmallScreen ? 64 : 80,
              color:
                  error != null ? AppColors.errorColor : AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              error != null
                  ? l10n.translate('videoLoadingError')
                  : l10n.translate('noVideosAvailable'),
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.w600,
                color: error != null
                    ? AppColors.errorColor
                    : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: controller.refreshVideos,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(l10n.translate('retry')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonBg,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 20 : 24,
                  vertical: isSmallScreen ? 10 : 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideosGrid(
    BuildContext context,
    AppLocalizations l10n,
    LanguageController languageController,
    bool isSmallScreen,
  ) {
    final spacing = isSmallScreen ? 8.0 : 12.0;

    return Obx(() {
      final videos = controller.videos;

      return Center(
        child: GridView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.all(spacing),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.82,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
          ),
          itemCount: videos.length,
          itemBuilder: (context, index) => _VideoCard(
            video: videos[index],
            isSmallScreen: isSmallScreen,
            onTap: () => _openVideo(context, videos[index]),
          ),
        ),
      );
    });
  }

  Widget _buildFloatingCallButton(bool isSmallScreen) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.7, end: 1.0),
      curve: Curves.elasticOut,
      builder: (_, scale, child) => Transform.scale(
        scale: scale,
        child: child,
      ),
      child: FloatingActionButton(
        backgroundColor: AppColors.successColor,
        elevation: 6,
        highlightElevation: 12,
        onPressed: () => _makePhoneCall(),
        child: const Icon(Icons.phone, color: Colors.white, size: 36),
      ),
    );
  }

  void _openVideo(BuildContext context, HelpVideoModel video) {
    controller.incrementViewCount(video.id);
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) => VideoPlayerScreen(video: video),
        transitionsBuilder: (_, a, __, c) =>
            FadeTransition(opacity: a, child: c),
      ),
    );
  }

  Future<void> _makePhoneCall() async {
    const phone = '71610911';
    final l10n = Get.context != null ? AppLocalizations.of(Get.context!) : null;

    try {
      await launchUrl(Uri.parse('tel:$phone'),
          mode: LaunchMode.externalApplication);
    } catch (_) {
      try {
        await launchUrl(Uri.parse('tel://$phone'),
            mode: LaunchMode.externalApplication);
      } catch (_) {
        await Clipboard.setData(const ClipboardData(text: phone));
        if (Get.context != null && Get.context!.mounted) {
          CustomSnackBar.info(
            title: l10n?.translate('phoneNumberCopied') ?? '',
            message: phone,
          );
        }
      }
    }
  }
}

class _VideoCard extends StatelessWidget {
  final HelpVideoModel video;
  final bool isSmallScreen;
  final VoidCallback onTap;

  const _VideoCard({
    required this.video,
    required this.isSmallScreen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white.withOpacity(0.94),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              Expanded(
                flex: 5,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      video.youtubeThumbnail,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, progress) =>
                          progress == null ? child : const _ShimmerThumbnail(),
                      errorBuilder: (_, __, ___) => const _ShimmerThumbnail(
                        child: Icon(Icons.video_library,
                            size: 32, color: AppColors.textTertiary),
                      ),
                    ),
                    // Play icon
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.textSecondary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow,
                            color: Colors.white, size: 28),
                      ),
                    ),
                    // Duration badge
                    if (video.duration > 0)
                      Positioned(
                        bottom: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            video.formattedDuration,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Title only
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
                  child: Text(
                    video.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textOnSecondary,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Shimmer helpers
// ──────────────────────────────────────────────────────────────
class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          Expanded(
            flex: 5,
            child: ShimmerBox(borderRadius: BorderRadius.zero),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(height: 12),
                  SizedBox(height: 6),
                  ShimmerBox(height: 10, width: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerThumbnail extends StatelessWidget {
  final Widget? child;
  const _ShimmerThumbnail({this.child});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: ShimmerBox(
        borderRadius: BorderRadius.zero,
        child: Center(child: child ?? const SizedBox()),
      ),
    );
  }
}
