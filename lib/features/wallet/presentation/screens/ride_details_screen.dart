import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:taxi_driver_app/core/shared/playback_controls.dart';
import 'package:taxi_driver_app/core/theme/app_colors.dart';
import 'package:taxi_driver_app/core/theme/text_styles.dart';
import 'package:taxi_driver_app/features/wallet/provider/ride_details_controller.dart';
import 'package:taxi_driver_app/l10n/app_localizations.dart';
import 'package:taxi_driver_app/config/env.dart';
import 'package:taxi_driver_app/providers/cached_tile_provider.dart';
import 'package:taxi_driver_app/widgets/shared/address_bubble_marker.dart';

/// Ride Details Screen with map playback, sharing the history tracking
/// playback panel so both replay experiences behave the same.
class RideDetailsScreen extends GetView<RideDetailsController> {
  const RideDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: AppColors.cardColor,
        elevation: 0,
        title: Text(
          l10n.translate('rideDetails'),
          style: AppTextStyles.appBarTitle.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.error.value.isNotEmpty) {
          return _buildErrorState(l10n);
        }

        return _buildMapView(context, l10n);
      }),
    );
  }

  Widget _buildErrorState(AppLocalizations l10n) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.errorColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 34,
                color: AppColors.errorColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              controller.error.value,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: BorderSide(
                        color: AppColors.dividerStrong.withOpacity(0.25),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      l10n.translate('goBack'),
                      style: AppTextStyles.labelLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => controller.reload(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandBlue,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      l10n.translate('retry'),
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapView(BuildContext context, AppLocalizations l10n) {
    // This page has no bottom navigation bar, so the panel adds the equivalent
    // gap itself to sit where the history tab's panel sits.
    final panelBottomInset = playbackPanelBottomInset(context);

    return Stack(
      children: [
        // Background color to prevent grey appearance
        Container(
          color: AppColors.backgroundColor,
        ),
        // Map
        Obx(() => FlutterMap(
              mapController: controller.mapController,
              options: MapOptions(
                initialCenter: controller.initialMapCenter,
                initialZoom: 16.0,
                minZoom: 12.0,
                maxZoom: 19.0,
                interactionOptions: const InteractionOptions(
                  enableMultiFingerGestureRace: true,
                  rotationThreshold: 20.0,
                  flags: InteractiveFlag.all, // Enable rotation
                ),
                onMapEvent: (event) {
                  // Disable centering immediately on ANY interaction
                  if (event is MapEventMoveStart ||
                      event is MapEventRotateStart ||
                      event is MapEventDoubleTapZoomStart ||
                      event is MapEventScrollWheelZoom ||
                      event is MapEventFlingAnimationStart) {
                    controller.onMapInteraction();
                  } else if (event is MapEventMoveEnd) {
                    controller.onZoomChange(event.camera.zoom);
                  }
                },
                onTap: (tapPosition, point) {
                  // Disable centering on tap
                  controller.onMapInteraction();
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: Env.mapTileUrlTemplate,
                  userAgentPackageName: 'com.neos.taxidriver',
                  tileProvider: CachedTileProvider(
                    urlTemplate: Env.mapTileUrlTemplate,
                    userAgentPackageName: 'com.neos.taxidriver',
                    maxRetries: 2,
                    timeout: const Duration(seconds: 8),
                  ),
                  maxZoom: 19,
                  minZoom: 12,
                  // Optimized for smooth playback performance
                  keepBuffer: 4, // Balanced buffer
                  panBuffer: 1, // Reduced for better performance
                  retinaMode: false, // Significantly improves performance
                  // Smooth tile transitions
                  tileDisplay: const TileDisplay.fadeIn(
                    duration: Duration(milliseconds: 200),
                  ),
                  // Suppress tile errors
                  errorTileCallback: (tile, error, stackTrace) {
                    // Handled by CachedTileProvider
                  },
                ),
                // Route polylines
                RepaintBoundary(
                  child: PolylineLayer(
                    polylines: controller.getColoredSegments(),
                  ),
                ),
                // Car marker with address bubble
                if (controller.currentPosition.value != null)
                  Obx(() => RepaintBoundary(
                        child: MarkerLayer(
                          markers: [
                            // Address bubble marker - positioned above car
                            if (controller.showAddressBubble.value)
                              Marker(
                                point: controller.currentPosition.value!,
                                width: 320,
                                height: 200,
                                alignment: Alignment.topCenter,
                                child: AddressBubbleMarker(
                                  showBubble:
                                      controller.showAddressBubble.value,
                                  isLoadingAddress:
                                      controller.isLoadingAddress.value,
                                  address: controller.currentAddress.value,
                                  onClose: () => controller.hideAddressBubble(),
                                ),
                              ),
                            // Car marker
                            Marker(
                              point: controller.currentPosition.value!,
                              width: 70,
                              height: 70,
                              child: GestureDetector(
                                onTap: () => controller.toggleAddressBubble(),
                                child: Transform.rotate(
                                  angle: controller.getCarRotationAngle() *
                                      (3.14159 / 180),
                                  child: Image.asset(
                                    controller.getCarMarkerPath(),
                                    width: 70,
                                    height: 70,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                // OpenStreetMap attribution
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.6),
                    ),
                    child: const Text(
                      '© OpenMapTiles © OpenStreetMap contributors',
                      style: TextStyle(
                        fontSize: 8,
                        color: AppColors.black,
                        fontFamily: 'Barlow',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            )),

        // Ride summary at top
        Positioned(
          top: 10,
          left: 16,
          right: 16,
          child: _buildRideInfoCard(context, l10n),
        ),

        // Map controls + playback panel
        Positioned(
          bottom: panelBottomInset,
          left: 16,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMapControls(l10n),
              const SizedBox(height: 12),
              // The panel has nothing to replay until the route is snapped.
              Obx(() => controller.routePoints.isEmpty
                  ? const SizedBox.shrink()
                  : _buildPlaybackPanel(l10n)),
            ],
          ),
        ),

        // Loading overlay above the map, same as history tracking
        Positioned.fill(
          child: Obx(() => controller.isLoading.value
              ? PlaybackLoadingOverlay(
                  message: l10n.translate('loadingRideData'),
                )
              : const SizedBox.shrink()),
        ),
      ],
    );
  }

  Widget _buildRideInfoCard(BuildContext context, AppLocalizations l10n) {
    final ride = controller.ride;
    final startDate = ride.startDate ?? DateTime.now();
    final locale = Localizations.localeOf(context).languageCode;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.brandBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.directions_car,
                  color: AppColors.brandBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ride.car.plateNumber,
                      textDirection: ui.TextDirection.ltr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${ride.car.brand} ${ride.car.model}'.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              // Exact time verified icon
              if (!controller.dateRangeAlert.value)
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Icon(
                    Icons.verified_outlined,
                    color: AppColors.successColor,
                    size: 20,
                  ),
                ),
              if (ride.isDeleted == true)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.errorColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: AppColors.errorColor,
                      size: 18,
                    ),
                  ),
                ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.successColor.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  '${(controller.ride.rideAmount ?? 0).toStringAsFixed(3)} ${l10n.translate('currencySymbol')}',
                  textDirection: ui.TextDirection.ltr,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.successColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildInfoChip(
                  icon: Icons.event,
                  label: '${DateFormat('dd', 'en').format(startDate)} '
                      '${DateFormat('MMM', locale).format(startDate)} '
                      '${DateFormat('yyyy', 'en').format(startDate)}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInfoChip(
                  icon: Icons.access_time,
                  label: DateFormat('HH:mm').format(startDate),
                ),
              ),
              if (controller.maxSpeed.value != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoChip(
                    icon: Icons.speed,
                    label:
                        '${controller.maxSpeed.value!.toStringAsFixed(0)} ${l10n.translate('speedUnit')}',
                    tooltip: l10n.translate('maxSpeed'),
                    color: AppColors.brandBlue,
                  ),
                ),
              ],
            ],
          ),
          if (controller.dateRangeAlert.value) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.warningColor.withOpacity(0.16),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.warningColor.withOpacity(0.45),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.errorColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.translate('dateRangeAlertWarning'),
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    String? tooltip,
    Color? color,
  }) {
    final chipColor = color ?? AppColors.textSecondary;

    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: chipColor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              textDirection: ui.TextDirection.ltr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSmall.copyWith(
                color: chipColor,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    return tooltip == null ? chip : Tooltip(message: tooltip, child: chip);
  }

  Widget _buildMapControls(AppLocalizations l10n) {
    return Obx(() => FloatingActionButton(
          heroTag: 'center_ride',
          mini: true,
          tooltip: l10n.translate('followVehicle'),
          onPressed: () => controller.centerOnCar(),
          backgroundColor: controller.shouldFollowCar.value
              ? AppColors.brandBlue
              : AppColors.white,
          elevation: controller.shouldFollowCar.value ? 8 : 4,
          child: Icon(
            controller.shouldFollowCar.value
                ? Icons.my_location
                : Icons.location_searching,
            size: 22,
            color: controller.shouldFollowCar.value
                ? AppColors.white
                : AppColors.textTertiary,
          ),
        ));
  }

  Widget _buildPlaybackPanel(AppLocalizations l10n) {
    return Obx(() => PlaybackPanel(
          isExpanded: controller.isPanelExpanded.value,
          header: _buildPanelHeader(l10n),
          metrics: _buildPanelMetrics(l10n),
          timeline: _buildPanelTimeline(),
          controls: _buildPanelControls(l10n),
        ));
  }

  Widget _buildPanelHeader(AppLocalizations l10n) {
    return Obx(() => PlaybackPanelHeader(
          leading: const PlaybackStatusIcon(
            icon: Icons.local_taxi,
            color: AppColors.brandBlue,
          ),
          title: controller.ride.car.plateNumber,
          subtitle:
              '${DateFormat('HH:mm:ss').format(controller.getPlaybackTime())}'
              ' · ${controller.getCurrentFare().toStringAsFixed(3)} ${l10n.translate('currencySymbol')}',
          isPlaying: controller.isPlaying.value,
          onPlayPause: controller.togglePlayback,
          isExpanded: controller.isPanelExpanded.value,
          onToggleExpanded: controller.isPanelExpanded.toggle,
        ));
  }

  Widget _buildPanelMetrics(AppLocalizations l10n) {
    return Obx(() => Row(
          children: [
            Expanded(
              child: PlaybackMetricChip(
                icon: Icons.speed_rounded,
                color: AppColors.brandBlue,
                label:
                    '${controller.currentSpeed.value.toStringAsFixed(0)} ${l10n.translate('speedUnit')}',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: PlaybackMetricChip(
                icon: Icons.route_rounded,
                color: AppColors.successColor,
                label:
                    '${controller.getCurrentDistance().toStringAsFixed(1)} ${l10n.translate('distanceUnitKm')}',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: PlaybackMetricChip(
                icon: Icons.timer_rounded,
                color: AppColors.textSecondary,
                label: formatPlaybackDuration(controller.elapsedRideDuration),
              ),
            ),
          ],
        ));
  }

  Widget _buildPanelTimeline() {
    return Obx(() => PlaybackTimeline(
          progress: controller.playbackPosition.value,
          segments: const [
            PlaybackSegment(start: 0, end: 1, color: AppColors.brandBlue),
          ],
          onSeek: controller.updatePosition,
          leadingLabel: formatPlaybackDuration(controller.elapsedRideDuration),
          trailingLabel: formatPlaybackDuration(controller.totalRideDuration),
        ));
  }

  Widget _buildPanelControls(AppLocalizations l10n) {
    return PlaybackControlsRow(
      buttons: [
        PlaybackCircleButton(
          icon: Icons.restart_alt_rounded,
          tooltip: l10n.translate('restart'),
          onTap: controller.restartPlayback,
        ),
        PlaybackCircleButton(
          icon: Icons.replay_10_rounded,
          onTap: () => controller.seekBy(const Duration(seconds: -10)),
        ),
        PlaybackCircleButton(
          icon: Icons.forward_10_rounded,
          onTap: () => controller.seekBy(const Duration(seconds: 10)),
        ),
      ],
      trailing: Obx(() => PlaybackSpeedSelector(
            currentSpeed: controller.playbackSpeed.value,
            onSpeedChanged: controller.setPlaybackSpeed,
          )),
    );
  }
}
