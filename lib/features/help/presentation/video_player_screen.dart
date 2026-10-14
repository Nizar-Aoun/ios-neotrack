import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:taxi_driver_app/core/theme/app_colors.dart';
import 'package:taxi_driver_app/core/theme/text_styles.dart';
import 'package:taxi_driver_app/l10n/app_localizations.dart';
import 'package:taxi_driver_app/features/help/domain/help_video_model.dart';
import 'package:taxi_driver_app/core/controllers/language_controller.dart';
import 'package:taxi_driver_app/core/shared/snackbar.dart';

/// Video Player Screen - Plays YouTube videos in-app
class VideoPlayerScreen extends StatefulWidget {
  final HelpVideoModel video;

  const VideoPlayerScreen({
    super.key,
    required this.video,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late YoutubePlayerController _controller;
  bool _isPlayerReady = false;

  @override
  void initState() {
    super.initState();
    // Lock orientation to portrait while on this screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    _initializePlayer();
  }

  void _initializePlayer() {
    final videoId = YoutubePlayer.convertUrlToId(widget.video.youtubeUrl);

    if (videoId == null) {
      // If invalid URL, just return - user can open in YouTube app
      return;
    }

    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
        controlsVisibleAtStart: true,
        hideControls: false,
        forceHD: false,
      ),
    )..addListener(() {
        if (_controller.value.isReady && !_isPlayerReady) {
          setState(() {
            _isPlayerReady = true;
          });
          // Do not auto-toggle fullscreen to avoid unwanted rotation
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    // Restore orientations after leaving this screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  Future<void> _openInYouTube() async {
    try {
      final Uri youtubeUri = Uri.parse(widget.video.youtubeUrl);
      await launchUrl(youtubeUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        CustomSnackBar.error(
          title: l10n.translate('error'),
          message: l10n.translate('couldNotOpenYoutube'),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageController = Get.find<LanguageController>();
    final isArabic =
        languageController.currentLocale.value.languageCode == 'ar';
    final isSmallScreen = MediaQuery.of(context).size.height < 650;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Make player take up more vertical space
    // Option 1: Use a fixed percentage of screen height (e.g., 40%)
    final playerHeight = screenHeight * 0.7;

    // Option 2: Use a larger aspect ratio multiplier
    // final playerHeight = screenWidth * (12 / 16); // 3:4 aspect ratio

    // Option 3: Use fixed height
    // final playerHeight = 350.0;

    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: AppColors.brandBlue,
        progressColors: ProgressBarColors(
          playedColor: AppColors.brandBlue,
          handleColor: AppColors.brandBlue,
        ),
        onReady: () {
          setState(() {
            _isPlayerReady = true;
          });
        },
        onEnded: (data) {
          // Video ended
        },
      ),
      builder: (context, player) {
        return Scaffold(
          backgroundColor: AppColors.baseColor,
          appBar: AppBar(
            centerTitle: true,
            backgroundColor: AppColors.baseColor,
            iconTheme: const IconThemeData(color: Colors.white),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Get.back(),
            ),
            title: Text(
              l10n.translate('watchVideo'),
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.open_in_new),
                tooltip: l10n.translate('watchOnYoutube'),
                color: Colors.white,
                onPressed: _openInYouTube,
              ),
            ],
            elevation: 0,
          ),
          body: Column(
            children: [
              // YouTube Player - Now taller!
              SizedBox(
                height: playerHeight,
                width: double.infinity,
                child: player,
              ),

              // Video Info
              Expanded(
                child: Container(
                  color: Colors.black,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                    child: _buildVideoInfo(l10n, isArabic, isSmallScreen),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVideoInfo(
    AppLocalizations l10n,
    bool isArabic,
    bool isSmallScreen,
  ) {
    final category =
        widget.video.getCategoryDisplayName(isArabic ? 'ar' : 'fr');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Badge
        if (widget.video.category.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 12),
            decoration: BoxDecoration(
              color: AppColors.brandBlue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              category,
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: isSmallScreen ? 12 : 14,
                color: AppColors.brandBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

        // Title
        Text(
          widget.video.title,
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: isSmallScreen ? 18 : 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.3,
          ),
        ),
        SizedBox(height: isSmallScreen ? 8 : 12),

        // Description
        if (widget.video.description.isNotEmpty) ...[
          Text(
            widget.video.description,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: isSmallScreen ? 14 : 16,
              color: Colors.white.withOpacity(0.8),
              height: 1.4,
            ),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
        ],

        // Video Stats
        Row(
          children: [
            Icon(
              Icons.access_time,
              size: isSmallScreen ? 16 : 18,
              color: Colors.white.withOpacity(0.6),
            ),
            const SizedBox(width: 6),
            Text(
              widget.video.formattedDuration,
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: isSmallScreen ? 12 : 14,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
            const SizedBox(width: 16),
            Icon(
              Icons.visibility,
              size: isSmallScreen ? 16 : 18,
              color: Colors.white.withOpacity(0.6),
            ),
            const SizedBox(width: 6),
            Text(
              '${widget.video.viewCount} ${l10n.translate('views')}',
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: isSmallScreen ? 12 : 14,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
