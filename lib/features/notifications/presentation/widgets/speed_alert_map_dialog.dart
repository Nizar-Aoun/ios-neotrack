import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:taxi_driver_app/core/theme/app_colors.dart';
import 'package:taxi_driver_app/config/env.dart';
import 'package:taxi_driver_app/providers/cached_tile_provider.dart';
import 'package:taxi_driver_app/l10n/app_localizations.dart';

/// Speed Alert Map Dialog - Shows location of speed alert on map
class SpeedAlertMapDialog extends StatefulWidget {
  final List<double> coordinates; // [longitude, latitude]
  final String title;
  final String content;
  final DateTime timestamp;
  final double? speed;
  final double? limit;

  const SpeedAlertMapDialog({
    super.key,
    required this.coordinates,
    required this.title,
    required this.content,
    required this.timestamp,
    this.speed,
    this.limit,
  });

  @override
  State<SpeedAlertMapDialog> createState() => _SpeedAlertMapDialogState();
}

class _SpeedAlertMapDialogState extends State<SpeedAlertMapDialog> {
  String _address = '';
  bool _isLoadingAddress = true;

  @override
  void initState() {
    super.initState();
    _fetchAddress();
  }

  Future<void> _fetchAddress() async {
    final longitude = widget.coordinates[0];
    final latitude = widget.coordinates[1];

    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude&zoom=18&addressdetails=1');

      final response = await Future.any([
        Future.delayed(const Duration(seconds: 5),
            () => throw TimeoutException('Request timeout')),
        http.get(url, headers: {
          'User-Agent': 'NeoTrackMobileApp/1.0',
          'Accept-Language': 'fr,ar,en',
        }),
      ]);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final address = jsonData['address'] as Map<String, dynamic>?;

        if (address != null) {
          final zone = address['suburb'] ??
              address['neighbourhood'] ??
              address['city_district'] ??
              address['quarter'] ??
              address['hamlet'] ??
              address['town'] ??
              address['city'] ??
              '';

          final road = address['road'] ?? '';
          final city = address['city'] ??
              address['town'] ??
              address['village'] ??
              address['municipality'] ??
              '';

          String displayAddress = '';

          if (road.isNotEmpty) {
            displayAddress = road;
          }

          if (zone.isNotEmpty) {
            if (displayAddress.isNotEmpty) {
              displayAddress = '$displayAddress, $zone';
            } else {
              displayAddress = zone;
            }
          }

          if (city.isNotEmpty && city != zone && city != road) {
            displayAddress =
                displayAddress.isEmpty ? city : '$displayAddress, $city';
          }

          setState(() {
            _address = displayAddress.isEmpty
                ? jsonData['display_name'] ?? 'Address not available'
                : displayAddress;
            _isLoadingAddress = false;
          });
        } else {
          setState(() {
            _address = jsonData['display_name'] ?? 'Address not available';
            _isLoadingAddress = false;
          });
        }
      } else {
        setState(() {
          _address = 'Address not available';
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      setState(() {
        _address = 'Address not available';
        _isLoadingAddress = false;
      });
    }
  }

  String _formatTimestamp(DateTime timestamp, AppLocalizations? l10n) {
    // Return exact local date and time
    try {
      final local = timestamp.toLocal();
      final fmt = DateFormat('yyyy-MM-dd HH:mm:ss');
      return fmt.format(local);
    } catch (_) {
      return timestamp.toIso8601String();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final longitude = widget.coordinates[0];
    final latitude = widget.coordinates[1];
    final position = LatLng(latitude, longitude);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 680),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.warningColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.speed,
                      color: AppColors.textPrimary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n?.translate('SpeedAlertLocation') ??
                          'Speed Alert Location',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),

            // Alert Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Time of violation
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        _formatTimestamp(widget.timestamp, l10n),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Address
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: _isLoadingAddress
                            ? Row(
                                children: [
                                  SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.brandBlue,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    l10n?.translate('Loading address...') ??
                                        'Loading address...',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                _address,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Speed limit (if available)
                  Row(
                    children: [
                      Icon(Icons.speed,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        widget.limit != null
                            ? '${l10n?.translate('Limit') ?? 'Limit'}: ${widget.limit!.toStringAsFixed(0)} ${l10n?.translate('km/h') ?? 'km/h'}'
                            : '${l10n?.translate('Limit') ?? 'Limit'}: N/A',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Map
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderColor),
                ),
                clipBehavior: Clip.antiAlias,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: position,
                    initialZoom: 15.0,
                    minZoom: 5.0,
                    maxZoom: 18.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: Env.mapTileUrlTemplate,
                      tileProvider: CachedTileProvider(
                          urlTemplate: Env.mapTileUrlTemplate,
                          userAgentPackageName: 'com.neos.taxi_driver_app'),
                      userAgentPackageName: 'com.neos.taxi_driver_app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: position,
                          width: 100,
                          height: 80,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: (widget.speed != null &&
                                          widget.limit != null &&
                                          widget.speed! > widget.limit!)
                                      ? AppColors.errorColor
                                      : AppColors.brandBlue,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: ((widget.speed != null &&
                                                  widget.limit != null &&
                                                  widget.speed! > widget.limit!)
                                              ? AppColors.errorColor
                                              : AppColors.brandBlue)
                                          .withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.speed,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        widget.speed != null
                                            ? '${widget.speed!.toStringAsFixed(0)} km/h'
                                            : (l10n?.translate('N/A') ?? 'N/A'),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        softWrap: false,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: (widget.speed != null &&
                                          widget.limit != null &&
                                          widget.speed! > widget.limit!)
                                      ? AppColors.errorColor
                                      : AppColors.brandBlue,
                                ),
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Pulsing circle animation for emphasis
                  ],
                ),
              ),
            ),

            // Close Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonBg,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    l10n?.translate('close') ?? 'fermer',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
