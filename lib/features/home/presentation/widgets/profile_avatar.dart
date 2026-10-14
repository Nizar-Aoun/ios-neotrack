import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:taxi_driver_app/core/theme/app_colors.dart';
import 'package:taxi_driver_app/core/shared/loading_gif.dart';

class ProfileAvatar extends StatefulWidget {
  final String? imageUrl;
  final double radius;
  final VoidCallback onTap;

  const ProfileAvatar({
    super.key,
    this.imageUrl,
    this.radius = 22,
    required this.onTap,
  });

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.white,
          border: Border.all(
            color: AppColors.brandBlue,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.brandBlue.withOpacity(0.18),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.all(widget.radius <= 16 ? 1 : 2),
        child: CircleAvatar(
          radius: widget.radius,
          backgroundColor: AppColors.brandBlue.withOpacity(0.12),
          child: _buildAvatarContent(),
        ),
      ),
    );
  }

  Widget _buildAvatarContent() {
    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      return _buildProfileImage();
    }

    return _buildDefaultIcon();
  }

  /// Profile image widget with optimized caching
  Widget _buildProfileImage() {
    return ClipOval(
      child: CachedNetworkImage(
        key: ValueKey(widget.imageUrl), // Stable key
        imageUrl: widget.imageUrl!,
        width: widget.radius * 2,
        height: widget.radius * 2,
        fit: BoxFit.cover,
        memCacheWidth: (widget.radius * 4).toInt(), // Optimize memory usage
        memCacheHeight: (widget.radius * 4).toInt(),
        maxWidthDiskCache: (widget.radius * 6).toInt(), // Optimize disk cache
        maxHeightDiskCache: (widget.radius * 6).toInt(),
        fadeInDuration:
            Duration.zero, // Remove fade animation to prevent flicker
        fadeOutDuration: Duration.zero,
        placeholder: (context, url) => _buildLoadingIndicator(),
        errorWidget: (context, url, error) {
          return _buildDefaultIcon();
        },
      ),
    );
  }

  /// Loading indicator widget
  Widget _buildLoadingIndicator() {
    return Center(
      child: LoadingGif(
        width: widget.radius * 1.5,
        height: widget.radius * 1.5,
      ),
    );
  }

  /// Default profile icon widget
  Widget _buildDefaultIcon() {
    return Image.asset(
      'assets/images/icons8-add-user-male-94.png',
      width: widget.radius * 1.4,
      height: widget.radius * 1.4,
      fit: BoxFit.contain,
    );
  }
}
