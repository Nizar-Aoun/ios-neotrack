import 'package:flutter/material.dart';
import 'package:taxi_driver_app/core/shared/loading_gif.dart';
import 'package:taxi_driver_app/core/theme/app_colors.dart';

/// Optimized image cache management for map tiles and assets
class ImageCacheHelper {
  static bool _configured = false;

  /// Configure Flutter's image cache for optimal tile rendering
  static void configureImageCache() {
    if (_configured) return;

    final imageCache = PaintingBinding.instance.imageCache;
    imageCache.maximumSize = 500; // Reduced from 1000
    imageCache.maximumSizeBytes = 100 << 20; // 100 MB (reduced from 200MB)

    _configured = true;
  }

  /// Precache critical images to prevent loading delays
  static Future<void> precacheImages(BuildContext context) async {
    configureImageCache();

    const imagePaths = [
      'assets/images/car_marker.png',
      'assets/images/louage_marker.png',
      'assets/images/tms_yellow.png',
      'assets/images/door_open.png',
      'assets/images/door_close.png',
      'assets/images/loader.gif',
    ];

    await Future.wait(
      imagePaths.map((path) =>
          precacheImage(AssetImage(path), context).catchError((_) => null)),
    );
  }

  /// Build optimized asset image with error handling
  static Widget buildAssetImage(
    String path, {
    double? width,
    double? height,
    BoxFit? fit,
    Color? color,
    BlendMode? colorBlendMode,
    FilterQuality filterQuality = FilterQuality.medium,
  }) {
    return Image.asset(
      path,
      width: width,
      height: height,
      fit: fit ?? BoxFit.contain,
      color: color,
      colorBlendMode: colorBlendMode,
      gaplessPlayback: true,
      filterQuality: filterQuality,
      errorBuilder: (_, __, ___) => SizedBox(
        width: width,
        height: height,
        child: const Icon(Icons.broken_image, color: AppColors.textTertiary),
      ),
    );
  }

  /// Build animated GIF with optimized settings
  static Widget buildAnimatedGif(
    String path, {
    double? width,
    double? height,
  }) {
    return Image.asset(
      path,
      width: width,
      height: height,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      filterQuality: FilterQuality.low,
      errorBuilder: (_, __, ___) => SizedBox(
        width: width,
        height: height,
        child: LoadingGif(
          width: width != null ? width / 2 : 30,
          height: height != null ? height / 2 : 30,
        ),
      ),
    );
  }

  /// Expense category icons ship as ~532x532 PNGs but are never drawn larger
  /// than 60dp. Decoding them at full size costs ~1.1 MB each and stalls the
  /// frame that opens the expense dialog, so every call site goes through this
  /// downscaled provider: one shared cache entry of ~100 KB.
  static const int categoryIconDecodeSize = 160;

  static ImageProvider categoryIconProvider(String assetPath) => ResizeImage(
        AssetImage(assetPath),
        width: categoryIconDecodeSize,
        height: categoryIconDecodeSize,
      );

  /// Warms the cache so the first expense dialog opens without a decode stall.
  /// Failures are ignored: a missing asset falls back to a placeholder icon.
  static Future<void> precacheCategoryIcons(
    BuildContext context,
    Iterable<String> assetPaths,
  ) {
    return Future.wait(
      assetPaths.map(
        (path) => precacheImage(
          categoryIconProvider(path),
          context,
          onError: (_, __) {},
        ),
      ),
    );
  }

  /// Clear entire image cache
  static void clearCache() {
    imageCache.clear();
    imageCache.clearLiveImages();
  }

  /// Evict specific image from cache
  static void evictImage(String path) => AssetImage(path).evict();
}
