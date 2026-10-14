import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;

/// Enhanced cache manager with better memory and disk management
class MapTileCacheManager extends CacheManager with ImageCacheManager {
  static const key = 'mapTilesCache';

  static final MapTileCacheManager _instance = MapTileCacheManager._();

  factory MapTileCacheManager() {
    return _instance;
  }

  MapTileCacheManager._()
      : super(Config(
          key,
          // Increased cache duration for better offline support
          stalePeriod: const Duration(days: 30),
          // Increased cache size for smoother experience (2000 tiles � 100-200MB)
          maxNrOfCacheObjects: 2000,
          repo: JsonCacheInfoRepository(databaseName: key),
          fileService: HttpFileService(),
        )) {
    // Disable cache manager on web to prevent errors
    if (kIsWeb) {}
  }

  /// Clear old tiles to free up space
  Future<void> clearOldTiles() async {
    try {
      await emptyCache();
    } catch (e) {}
  }

  /// Get cache size info (approximate)
  Future<int> getCacheSize() async {
    try {
      final files = await getFileFromCache(key);
      // Approximate size calculation
      return files != null ? await files.file.length() : 0;
    } catch (e) {
      return 0;
    }
  }
}

/// Enhanced tile provider with advanced caching and error handling
class CachedTileProvider extends TileProvider {
  final String urlTemplate;
  final String userAgentPackageName;
  final Duration maxStale;
  final Duration cacheDuration;
  final int maxRetries;
  final Duration timeout;

  // Lazy initialization to avoid cache manager on web
  MapTileCacheManager? _cacheManager;
  MapTileCacheManager get cacheManager {
    _cacheManager ??= MapTileCacheManager();
    return _cacheManager!;
  }

  CachedTileProvider({
    required this.urlTemplate,
    required this.userAgentPackageName,
    this.maxStale = const Duration(days: 30),
    this.cacheDuration = const Duration(days: 60),
    this.maxRetries = 3,
    this.timeout = const Duration(seconds: 10),
  });

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final url = getTileUrl(coordinates, options);

    // On web, use NetworkImage directly to avoid cache manager issues
    if (kIsWeb) {
      return NetworkImage(url);
    }

    return _CachedTileImageProvider(
      url: url,
      cacheManager: cacheManager,
      maxRetries: maxRetries,
      timeout: timeout,
      headers: {
        'User-Agent': 'NeoTrack/1.0 ($userAgentPackageName)',
        'Accept': 'image/png,image/jpeg,image/*',
        'Accept-Encoding': 'gzip, deflate',
      },
    );
  }

  String getTileUrl(TileCoordinates coordinates, TileLayer options) {
    return urlTemplate
        .replaceAll('{x}', coordinates.x.toString())
        .replaceAll('{y}', coordinates.y.toString())
        .replaceAll('{z}', coordinates.z.toString());
  }

  /// Preload tiles for a specific area to improve UX
  Future<void> preloadTilesForArea({
    required LatLng center,
    required int zoom,
    int radiusTiles = 2,
  }) async {
    // Skip preloading on web to avoid CORS and caching issues
    if (kIsWeb) {
      return;
    }

    final centerTile = _latLngToTile(center, zoom);

    for (int x = centerTile.x - radiusTiles;
        x <= centerTile.x + radiusTiles;
        x++) {
      for (int y = centerTile.y - radiusTiles;
          y <= centerTile.y + radiusTiles;
          y++) {
        try {
          final coords = TileCoordinates(x, y, zoom);
          final url = getTileUrl(coords, TileLayer());

          // Check if already cached
          final cached = await cacheManager.getFileFromCache(url);
          if (cached == null) {
            // Download and cache
            final response = await http.get(
              Uri.parse(url),
              headers: {
                'User-Agent': 'NeoTrack/1.0 ($userAgentPackageName)',
              },
            ).timeout(timeout);

            if (response.statusCode == 200) {
              await cacheManager.putFile(url, response.bodyBytes);
            }
          }
        } catch (e) {
          // Silently ignore preload errors
        }
      }
    }
  }

  /// Convert lat/lng to tile coordinates
  TileCoordinates _latLngToTile(LatLng latLng, int zoom) {
    final n = 1 << zoom;
    final latRad = latLng.latitude * math.pi / 180.0;
    final x = ((latLng.longitude + 180.0) / 360.0 * n).floor();
    final y =
        ((1.0 - math.log(math.tan(latRad) + (1 / math.cos(latRad))) / math.pi) /
                2.0 *
                n)
            .floor();
    return TileCoordinates(x, y, zoom);
  }
}

/// Enhanced image provider with retry logic and better error handling
class _CachedTileImageProvider extends ImageProvider<_CachedTileImageProvider> {
  final String url;
  final CacheManager cacheManager;
  final Map<String, String> headers;
  final int maxRetries;
  final Duration timeout;

  _CachedTileImageProvider({
    required this.url,
    required this.cacheManager,
    required this.headers,
    this.maxRetries = 3,
    this.timeout = const Duration(seconds: 10),
  });

  @override
  Future<_CachedTileImageProvider> obtainKey(
      ImageConfiguration configuration) async {
    return this;
  }

  @override
  ImageStreamCompleter loadBuffer(
      _CachedTileImageProvider key,
      Future<ui.Codec> Function(ui.ImmutableBuffer,
              {bool allowUpscaling, int? cacheHeight, int? cacheWidth})
          decode) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(),
      scale: 1.0,
      debugLabel: url,
      informationCollector: () => <DiagnosticsNode>[
        DiagnosticsProperty<String>('URL', url),
        DiagnosticsProperty<int>('Max retries', maxRetries),
      ],
    );
  }

  Future<ui.Codec> _loadAsync() async {
    try {
      // Try to load from cache first (fastest)
      final fileInfo = await cacheManager.getFileFromCache(url);
      if (fileInfo != null && fileInfo.file.existsSync()) {
        try {
          final bytes = await fileInfo.file.readAsBytes();
          if (bytes.isNotEmpty) {
            return await ui.instantiateImageCodec(bytes);
          }
        } catch (e) {
          // Remove corrupted cache entry
          await cacheManager.removeFile(url);
        }
      }

      // Download with retry logic
      return await _downloadWithRetry();
    } catch (e) {
      rethrow;
    }
  }

  Future<ui.Codec> _downloadWithRetry() async {
    Exception? lastException;

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final response =
            await http.get(Uri.parse(url), headers: headers).timeout(timeout);

        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          final bytes = response.bodyBytes;

          // Cache the downloaded tile
          try {
            await cacheManager.putFile(url, bytes);
          } catch (e) {
            // Continue even if caching fails
          }

          return await ui.instantiateImageCodec(bytes);
        } else if (response.statusCode == 404) {
          // Don't retry 404s
          throw Exception('Tile not found (404): $url');
        } else {
          throw Exception('HTTP ${response.statusCode}');
        }
      } on TimeoutException catch (e) {
        lastException = e;
        if (attempt < maxRetries - 1) {
          await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
        }
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        if (attempt < maxRetries - 1) {
          await Future.delayed(Duration(milliseconds: 300 * (attempt + 1)));
        }
      }
    }

    throw lastException ??
        Exception('Failed to load tile after $maxRetries attempts');
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is _CachedTileImageProvider && other.url == url;
  }

  @override
  int get hashCode => url.hashCode;
}
