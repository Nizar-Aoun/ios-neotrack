import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:google_fonts/google_fonts.dart';
import 'package:taxi_driver_app/core/theme/app_colors.dart';
import 'package:taxi_driver_app/config/env.dart';
import 'package:taxi_driver_app/features/home/application/live_tracking_pip_coordinator.dart';
import 'package:taxi_driver_app/features/home/controller/live_tracking_controller.dart';
import 'package:taxi_driver_app/features/home/domain/taxi_meter_status.dart';
import 'package:taxi_driver_app/features/home/controller/map_controller.dart';
import 'package:taxi_driver_app/features/home/presentation/widgets/info_item.dart';
import 'package:taxi_driver_app/l10n/app_localizations.dart';
import 'package:taxi_driver_app/core/shared/location_permission_dialog.dart';
import 'package:taxi_driver_app/widgets/shared/address_bubble_marker.dart';
import 'package:taxi_driver_app/widgets/shared/ride_completed_cue.dart';
import 'package:taxi_driver_app/services/permission_service.dart';
import 'package:taxi_driver_app/providers/cached_tile_provider.dart';
import 'package:taxi_driver_app/utils/image_cache_helper.dart';

class LiveTrackingTab extends StatelessWidget {
  final bool isSmallScreen;

  const LiveTrackingTab({
    super.key,
    required this.isSmallScreen,
  });
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LiveTrackingController>();
    final mapCtrl = Get.find<MapController>();
    final l10n = AppLocalizations.of(context);

    return Obx(() {
      final selectedVehicle = mapCtrl.selectedVehicle.value;
      final carPos = controller.carPosition.value;
      final isLoading = controller.isLoading.value;
      final error = controller.error.value;
      final onlineVehicles = mapCtrl.onlineVehicles;
      final inPip = Get.isRegistered<LiveTrackingPipCoordinator>() &&
          Get.find<LiveTrackingPipCoordinator>().isInPip.value;

      if (kIsWeb && carPos != null) {}

      return Material(
        child: Stack(
          children: [
            // Map and its overlays
            Stack(
              children: [
                Container(
                  color: AppColors.backgroundColor,
                ),
                AbsorbPointer(
                  absorbing: selectedVehicle == null || error != null || inPip,
                  child: Opacity(
                    opacity: selectedVehicle == null ? 0.5 : 1.0,
                    child: Stack(
                      children: [
                        fm.FlutterMap(
                          mapController: controller.flutterMapController,
                          options: fm.MapOptions(
                            initialCenter:
                                carPos ?? const LatLng(36.8065, 10.1815),
                            initialZoom: 16.0,
                            minZoom: 12.0,
                            maxZoom: 19.0, // Limited max zoom to prevent issues
                            interactionOptions: fm.InteractionOptions(
                              enableMultiFingerGestureRace: true,
                              rotationThreshold: 20.0,
                              flags: inPip
                                  ? fm.InteractiveFlag.none
                                  : fm.InteractiveFlag.all,
                            ),
                            onMapEvent: (event) {
                              // Disable auto-follow for ANY user interaction including rotation and zoom
                              if (event is fm.MapEventMoveStart) {
                                // Check if this is a user gesture (not programmatic)
                                if (event.source ==
                                        fm.MapEventSource.dragStart ||
                                    event.source ==
                                        fm.MapEventSource
                                            .flingAnimationController ||
                                    event.source ==
                                        fm.MapEventSource
                                            .doubleTapZoomAnimationController) {
                                  controller.onMapInteraction();
                                }
                              } else if (event is fm.MapEventMove) {
                                // Detect zoom changes during user interaction (pinch-to-zoom)
                                // This captures two-finger zoom gestures
                                if (event.source !=
                                        fm.MapEventSource.mapController &&
                                    event.source !=
                                        fm.MapEventSource
                                            .flingAnimationController &&
                                    controller.lastKnownZoom != null &&
                                    (event.camera.zoom -
                                                controller.lastKnownZoom!)
                                            .abs() >
                                        0.01) {
                                  controller.onMapInteraction();
                                }
                                controller.lastKnownZoom = event.camera.zoom;
                              } else if (event is fm.MapEventMoveEnd) {
                                controller.handleZoomChange(event.camera.zoom);
                              } else if (event is fm.MapEventRotateStart) {
                                // Disable auto-follow when user rotates the map
                                controller.onMapInteraction();
                              } else if (event is fm.MapEventScrollWheelZoom) {
                                // Disable auto-follow when user zooms with scroll wheel
                                controller.onMapInteraction();
                              }
                            },
                          ),
                          children: [
                            fm.TileLayer(
                              urlTemplate: Env.mapTileUrlTemplate,
                              userAgentPackageName: 'com.example.app',
                              tileProvider: CachedTileProvider(
                                urlTemplate: Env.mapTileUrlTemplate,
                                userAgentPackageName: 'com.example.app',
                                maxRetries: 2, // Reduced for faster failover
                                timeout: const Duration(seconds: 5),
                              ),
                              maxZoom: 19.0,
                              minZoom: 12.0,
                              // ✅ Enhanced performance settings
                              keepBuffer:
                                  4, // Optimized buffer for smooth scrolling
                              panBuffer: 1, // Reduced for better performance
                              retinaMode:
                                  false, // Significantly improves performance
                              // ✅ Instant tile display for live tracking - no fade delays
                              tileDisplay: const fm.TileDisplay.instantaneous(),
                              // ✅ Silent error handling
                              errorTileCallback: (tile, error, stackTrace) {
                                // Handled by CachedTileProvider
                              },
                            ),
                            // Draw the route before markers so it stays under the car
                            Obx(() {
                              final route = controller.userToCarRoute;
                              if (route.length < 2 ||
                                  controller.hasArrivedAtTaxi.value) {
                                // Must stay a map layer — SizedBox breaks FlutterMap
                                return const fm.PolylineLayer<Object>(
                                  polylines: [],
                                );
                              }
                              final start = controller.polylineVisualStart.value;
                              final points = start == null
                                  ? route.toList()
                                  : <LatLng>[start, ...route.skip(1)];
                              return fm.PolylineLayer(
                                polylines: [
                                  // Soft glow under the route
                                  fm.Polyline(
                                    points: points,
                                    strokeWidth: 12,
                                    color:
                                        AppColors.brandBlue.withOpacity(0.16),
                                  ),
                                  // Main route with white outline (map-readable)
                                  fm.Polyline(
                                    points: points,
                                    strokeWidth: 5,
                                    color: AppColors.brandBlue,
                                    borderStrokeWidth: 3.5,
                                    borderColor:
                                        AppColors.white.withOpacity(0.92),
                                  ),
                                ],
                              );
                            }),
                            // Car marker layer — always present (empty when no position)
                            RepaintBoundary(
                              child: Obx(() {
                                // Force rebuild when position changes
                                final position = controller.carPosition.value;
                                if (position == null) {
                                  return const fm.MarkerLayer(markers: []);
                                }

                                return fm.MarkerLayer(
                                  markers: [
                                    // Address bubble marker - positioned above car
                                    if (controller.showAddressBubble.value &&
                                        !(Get.isRegistered<
                                                LiveTrackingPipCoordinator>() &&
                                            Get.find<LiveTrackingPipCoordinator>()
                                                .isInPip
                                                .value))
                                      fm.Marker(
                                        point: position,
                                        width: 320,
                                        height: 200,
                                        alignment: Alignment.topCenter,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const SizedBox(
                                                height:
                                                    35), // Space for car below
                                            AnimatedScale(
                                              scale: controller
                                                      .showAddressBubble.value
                                                  ? 1.0
                                                  : 0.8,
                                              duration: const Duration(
                                                  milliseconds: 200),
                                              curve: Curves.easeOut,
                                              child: AnimatedOpacity(
                                                opacity: controller
                                                        .showAddressBubble.value
                                                    ? 1.0
                                                    : 0.0,
                                                duration: const Duration(
                                                    milliseconds: 200),
                                                child: Container(
                                                  constraints:
                                                      const BoxConstraints(
                                                          maxWidth: 320,
                                                          minWidth: 200),
                                                  margin: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 16),
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 14,
                                                                vertical: 10),
                                                        decoration:
                                                            BoxDecoration(
                                                          gradient:
                                                              LinearGradient(
                                                            begin: Alignment
                                                                .topLeft,
                                                            end: Alignment
                                                                .bottomRight,
                                                            colors: [
                                                              AppColors
                                                                  .primaryColor,
                                                              AppColors
                                                                  .primaryColor
                                                                  .withOpacity(
                                                                      0.9),
                                                            ],
                                                          ),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(18),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: AppColors
                                                                  .primaryColor
                                                                  .withOpacity(
                                                                      0.3),
                                                              blurRadius: 12,
                                                              offset:
                                                                  const Offset(
                                                                      0, 4),
                                                            ),
                                                          ],
                                                        ),
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(6),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: Colors
                                                                    .white
                                                                    .withOpacity(
                                                                        0.2),
                                                                shape: BoxShape
                                                                    .circle,
                                                              ),
                                                              child: const Icon(
                                                                Icons
                                                                    .location_on,
                                                                color: Colors
                                                                    .white,
                                                                size: 16,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                width: 10),
                                                            Flexible(
                                                              child: controller
                                                                      .isLoadingAddress
                                                                      .value
                                                                  ? const AddressBubbleShimmer()
                                                                  : Text(
                                                                      controller
                                                                          .currentAddress
                                                                          .value,
                                                                      style: GoogleFonts
                                                                          .barlow(
                                                                        fontSize:
                                                                            14,
                                                                        color: Colors
                                                                            .white,
                                                                        fontWeight:
                                                                            FontWeight.w600,
                                                                      ),
                                                                      textAlign:
                                                                          TextAlign
                                                                              .center,
                                                                    ),
                                                            ),
                                                            const SizedBox(
                                                                width: 8),
                                                            GestureDetector(
                                                              onTap: () =>
                                                                  controller
                                                                      .hideAddressBubble(),
                                                              child: Container(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .all(4),
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: Colors
                                                                      .white
                                                                      .withOpacity(
                                                                          0.2),
                                                                  shape: BoxShape
                                                                      .circle,
                                                                ),
                                                                child:
                                                                    const Icon(
                                                                  Icons.close,
                                                                  size: 14,
                                                                  color: Colors
                                                                      .white,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Transform.flip(
                                                        flipY: true,
                                                        child: CustomPaint(
                                                          size: const Size(
                                                              20, 10),
                                                          painter:
                                                              _BubbleArrowPainter(
                                                            color: AppColors
                                                                .primaryColor
                                                                .withOpacity(
                                                                    0.9),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    // Blue circle around car - use reactive position
                                    fm.Marker(
                                      point: position,
                                      width: 150,
                                      height: 150,
                                      child: RepaintBoundary(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: AppColors.brandBlue
                                                .withOpacity(0.2),
                                            border: Border.all(
                                              color: AppColors.brandBlue
                                                  .withOpacity(0.4),
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Car marker with tap handler - use reactive position
                                    fm.Marker(
                                      point: position,
                                      width: 70,
                                      height: 70,
                                      child: GestureDetector(
                                        onTap: () =>
                                            controller.toggleAddressBubble(),
                                        child: RepaintBoundary(
                                          child: Transform.rotate(
                                            angle: controller
                                                    .getCarRotationAngle() *
                                                math.pi /
                                                180,
                                            child: ImageCacheHelper
                                                .buildAssetImage(
                                              controller.getCarMarkerPath(),
                                              width: 70,
                                              height: 70,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ),
                            // GPS accuracy ring under the navigation icon
                            Obx(() {
                              final userPos =
                                  controller.userMarkerPosition.value ??
                                      controller.userPosition.value;
                              final accuracy =
                                  controller.userGpsAccuracyMeters.value;
                              if (userPos == null ||
                                  !controller.isTrackingUser.value ||
                                  accuracy < 8) {
                                return const fm.CircleLayer<Object>(
                                  circles: [],
                                );
                              }
                              return fm.CircleLayer<Object>(
                                circles: [
                                  fm.CircleMarker<Object>(
                                    point: userPos,
                                    radius: accuracy,
                                    useRadiusInMeter: true,
                                    color:
                                        AppColors.brandBlue.withOpacity(0.12),
                                    borderColor:
                                        AppColors.brandBlue.withOpacity(0.35),
                                    borderStrokeWidth: 1,
                                  ),
                                ],
                              );
                            }),
                            // Navigation icon; blue circle only while actively tracking position
                            Obx(() {
                              final userPos =
                                  controller.userMarkerPosition.value ??
                                      controller.userPosition.value;
                              if (userPos == null) {
                                return const fm.MarkerLayer(markers: []);
                              }
                              final tracking =
                                  controller.shouldFollowUser.value;
                              // Heading-up follow: GPS course. Icon tip stays
                              // travel-direction (screen-up once the map rotates).
                              final heading = controller.userHeading.value;
                              final iconAngle = heading * math.pi / 180;
                              return fm.MarkerLayer(
                                rotate: false,
                                markers: [
                                  fm.Marker(
                                    point: userPos,
                                    width: tracking ? 44 : 30,
                                    height: tracking ? 44 : 30,
                                    alignment: Alignment.center,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // Circle only when user tapped locate / follow
                                        if (tracking)
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: AppColors.brandBlue
                                                  .withOpacity(0.18),
                                              border: Border.all(
                                                color: AppColors.brandBlue
                                                    .withOpacity(0.55),
                                                width: 1.5,
                                              ),
                                            ),
                                          ),
                                        Transform.rotate(
                                          angle: iconAngle,
                                          alignment: Alignment.center,
                                          child: Image.asset(
                                            'assets/images/icons8-navigation-94.png',
                                            width: 26,
                                            height: 26,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ],
                        ),
                        // Overlays — full chrome when not in Picture-in-Picture
                        // (do not require carPos, so hot reload / brief nulls don't hide the card)
                        if (selectedVehicle != null && !inPip)
                          Stack(
                            children: [
                              // Vehicle selector button (multiple vehicles)
                              if (onlineVehicles.length > 1)
                                Positioned(
                                  right: 16,
                                  bottom: 200,
                                  child: Material(
                                    color: Colors.transparent,
                                    child: FloatingActionButton(
                                      heroTag: 'settings_button_live',
                                      onPressed: () =>
                                          _showVehicleSelector(context),
                                      backgroundColor: AppColors.white,
                                      elevation: 4,
                                      mini: true,
                                      child: Icon(
                                        Icons.directions_car,
                                        color: AppColors.brandBlue,
                                        size: isSmallScreen ? 16 : 20,
                                      ),
                                    ),
                                  ),
                                ),

                              // Locate me (phone GPS) — left
                              Positioned(
                                left: 16,
                                bottom: 140,
                                child: Obx(() {
                                  final locating = controller.isLocatingUser.value;
                                  final following =
                                      controller.shouldFollowUser.value;
                                  final hasRoute =
                                      controller.userToCarRoute.length >= 2 &&
                                          !controller.hasArrivedAtTaxi.value;
                                  return _AnimatedLocateButton(
                                    heroTag: 'locate_me_button_live',
                                    tooltip: l10n.translate('locateMe'),
                                    assetPath:
                                        'assets/images/icons8-navigation-94.png',
                                    isActive: following,
                                    isLoading: locating,
                                    isSmallScreen: isSmallScreen,
                                    activeColor: AppColors.brandBlue,
                                    onLongPress: hasRoute
                                        ? controller.cancelUserRoute
                                        : controller.isTrackingUser.value
                                            ? controller
                                                .stopUserLocationTracking
                                            : null,
                                    onPressed: () async {
                                      final errorKey =
                                          await controller.locateUser();
                                      if (errorKey == null || !context.mounted) {
                                        return;
                                      }
                                      if (errorKey == 'locationPermissionDenied' ||
                                          errorKey == 'locationServiceDisabled') {
                                        await showLocationRequiredDialog(
                                          context,
                                          serviceDisabled: errorKey ==
                                              'locationServiceDisabled',
                                        );
                                        return;
                                      }
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            l10n.translate(errorKey),
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                                  );
                                }),
                              ),

                              // Locate taxi / center on car — right
                              Positioned(
                                right: 16,
                                bottom: 140,
                                child: Obx(() {
                                  final following =
                                      controller.shouldFollowCar.value;
                                  return _AnimatedLocateButton(
                                    heroTag: onlineVehicles.length > 1
                                        ? 'center_button_live_info'
                                        : 'center_button_live_single',
                                    tooltip: l10n.translate('followVehicle'),
                                    assetPath:
                                        'assets/images/icons8-taxi-location-94.png',
                                    isActive: following,
                                    isSmallScreen: isSmallScreen,
                                    activeColor: AppColors.tertiaryColor,
                                    onPressed: controller.centerOnCar,
                                  );
                                }),
                              ),

                              // Distance / ETA / arrival chip + weak GPS — top of map
                              Obx(() {
                                final arrived =
                                    controller.hasArrivedAtTaxi.value;
                                final hasRoute =
                                    controller.userToCarRoute.length >= 2;
                                final remaining =
                                    controller.userToCarRemainingMeters.value;
                                final duration =
                                    controller.userToCarDurationSeconds.value;
                                final total =
                                    controller.userToCarDistanceMeters.value;
                                final street =
                                    controller.nextManeuverStreet.value;
                                final maneuver =
                                    controller.nextManeuverType.value;
                                final showChip = arrived || hasRoute;
                                final weak =
                                    controller.isTrackingUser.value &&
                                        controller.userGpsAccuracyMeters
                                                .value >
                                            40;
                                return Positioned(
                                  top: MediaQuery.of(context).padding.top +
                                      (isSmallScreen ? 84 : 100),
                                  left: 16,
                                  right: 16,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (showChip)
                                        _RouteStatusChip(
                                            arrived: arrived,
                                            remainingMeters: remaining,
                                            durationSeconds: duration,
                                            totalMeters: total,
                                            street: street,
                                            maneuver: maneuver,
                                            l10n: l10n,
                                            onClear: controller.cancelUserRoute,
                                            onOpenMaps: controller
                                                .openExternalNavigationToTaxi,
                                          ),
                                      if (showChip && weak)
                                        const SizedBox(height: 8),
                                      if (weak)
                                        Material(
                                          color: Colors.transparent,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.white
                                                  .withOpacity(0.94),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppColors.black
                                                      .withOpacity(0.08),
                                                  blurRadius: 8,
                                                ),
                                              ],
                                            ),
                                            child: Text(
                                              l10n.translate(
                                                  'waitingBetterGps'),
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.barlow(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textTertiary,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              }),

                              // Info box (speed / taximeter / door) — own Obx so it
                              // always rebuilds even if carPos briefly flickers
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 30,
                                child: Center(
                                  child: Obx(() {
                                    final speed = controller.currentSpeed.value;
                                    final meterStatus =
                                        controller.taxiMeterStatus.value;
                                    final meterPrice =
                                        controller.taximeterPrice.value;
                                    final compteurColor =
                                        TaxiMeterStatus.color(meterStatus);
                                    final compteurLabel = l10n.translate(
                                      TaxiMeterStatus.localizationKey(
                                          meterStatus),
                                    );
                                    final doorOpen =
                                        controller.isDoorOpen.value;
                                    return Container(
                                      margin: EdgeInsets.symmetric(
                                        horizontal: isSmallScreen ? 8 : 20,
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isSmallScreen ? 8 : 16,
                                        vertical: isSmallScreen ? 6 : 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.white.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(
                                          isSmallScreen ? 10 : 16,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.black
                                                .withOpacity(0.1),
                                            blurRadius: 10,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          InfoItem(
                                            icon: Icons.speed_outlined,
                                            iconBg: AppColors.brandBlue,
                                            label: l10n.translate('speed'),
                                            value:
                                                '${speed.toStringAsFixed(1)} ${l10n.translate('speedUnit')}',
                                            textColor: AppColors.brandBlue,
                                            valueFontSize:
                                                isSmallScreen ? 10 : 12,
                                            showLabel: false,
                                          ),
                                          if (PermissionService
                                              .hasWalletPermission(
                                                  context)) ...[
                                            Container(
                                              height: isSmallScreen ? 18 : 30,
                                              width: 1,
                                              color: AppColors.dividerStrong
                                                  .withOpacity(0.2),
                                            ),
                                            InfoItem(
                                              icon: meterStatus ==
                                                      TaxiMeterStatus.occupe
                                                  ? null
                                                  : (meterStatus ==
                                                          TaxiMeterStatus.pause
                                                      ? Icons.pause_circle_filled
                                                      : Icons.circle),
                                              imagePath: meterStatus ==
                                                      TaxiMeterStatus.occupe
                                                  ? TaxiMeterStatus
                                                      .occupiedImagePath
                                                  : null,
                                              iconBg: compteurColor,
                                              label:
                                                  l10n.translate('taximeter'),
                                              value: meterStatus ==
                                                          TaxiMeterStatus.occupe &&
                                                      meterPrice != null
                                                  ? '${meterPrice.toStringAsFixed(3)} ${l10n.translate('currencySymbol')}'
                                                  : compteurLabel,
                                              textColor: compteurColor,
                                              valueFontSize:
                                                  isSmallScreen ? 10 : 12,
                                              colorImage: false,
                                              showLabel: false,
                                            ),
                                          ],
                                          Container(
                                            height: isSmallScreen ? 18 : 30,
                                            width: 1,
                                            color: AppColors.dividerStrong
                                                .withOpacity(0.2),
                                          ),
                                          InfoItem(
                                            imagePath: doorOpen
                                                ? 'assets/images/door_open.png'
                                                : 'assets/images/door_close.png',
                                            iconBg: doorOpen
                                                ? AppColors.tertiaryColor
                                                : AppColors.textTertiary,
                                            label: l10n.translate('doorStatus'),
                                            value: doorOpen
                                                ? l10n.translate('doorOpen')
                                                : l10n.translate('doorClosed'),
                                            textColor: doorOpen
                                                ? AppColors.tertiaryColor
                                                : AppColors.textTertiary,
                                            valueFontSize:
                                                isSmallScreen ? 10 : 12,
                                            showLabel: false,
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ),
                              ),

                              // Attribution
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
                          ),

                        // Compact PiP overlays
                        if (carPos != null)
                          Positioned(
                            top: inPip ? 42 : 14,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Obx(() => RideCompletedCue(
                                    visible: controller
                                        .showRideCompletedCue.value,
                                    eventVersion: controller
                                        .rideCompletedCueVersion.value,
                                    fare: controller.completedRideFare.value,
                                    rideLabel: l10n
                                        .translate('ride')
                                        .toLowerCase(),
                                    currencyLabel:
                                        l10n.translate('currencySymbol'),
                                  )),
                            ),
                          ),

                        if (inPip) ...[
                          // ETA chip when A→B is active
                          Obx(() {
                            final arrived = controller.hasArrivedAtTaxi.value;
                            final hasRoute =
                                controller.userToCarRoute.length >= 2;
                            if (!arrived && !hasRoute) {
                              return const SizedBox.shrink();
                            }
                            final remaining =
                                controller.userToCarRemainingMeters.value;
                            final duration =
                                controller.userToCarDurationSeconds.value;
                            final total =
                                controller.userToCarDistanceMeters.value;
                            return Positioned(
                              top: 6,
                              left: 6,
                              right: 6,
                              child: _PipRouteChip(
                                arrived: arrived,
                                remainingMeters: remaining,
                                durationSeconds: duration,
                                totalMeters: total,
                                l10n: l10n,
                              ),
                            );
                          }),
                          // Speed + compteur when focused on the taxi
                          Obx(() {
                            final followTaxi =
                                controller.shouldFollowCar.value ||
                                    !controller.shouldFollowUser.value;
                            if (!followTaxi) {
                              return const SizedBox.shrink();
                            }
                            final speed = controller.currentSpeed.value;
                            final meterStatus =
                                controller.taxiMeterStatus.value;
                            final meterPrice =
                                controller.taximeterPrice.value;
                            final showCompteur =
                                PermissionService.hasWalletPermission(context);
                            return Positioned(
                              left: 6,
                              right: 6,
                              bottom: 6,
                              child: _PipTaxiStatusCard(
                                speed: speed,
                                taxiMeterStatus: meterStatus,
                                meterPrice: meterPrice,
                                showCompteur: showCompteur,
                                l10n: l10n,
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                ),

                if (isLoading && (selectedVehicle == null || carPos == null))
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
                      child: Container(color: Colors.transparent),
                    ),
                  ),

                // No vehicle selected
                if (selectedVehicle == null && onlineVehicles.length > 1)
                  Container(
                    color: AppColors.textLight.withOpacity(0.15),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.directions_car,
                            size: 48,
                            color: AppColors.brandBlue.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.translate('selectVehicleToSeePosition'),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: AppColors.brandBlue,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () => _showVehicleSelector(context),
                            icon: Icon(
                              Icons.directions_car,
                              color: AppColors.white,
                              size: isSmallScreen ? 18 : 20,
                            ),
                            label: Text(
                              l10n.translate('selectVehicle'),
                              style: GoogleFonts.barlow(
                                color: AppColors.white,
                                fontSize: isSmallScreen ? 14 : 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.brandBlue,
                              foregroundColor: AppColors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 20 : 24,
                                vertical: isSmallScreen ? 12 : 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Loading (only show if car is not displayed yet)
                if (isLoading && (selectedVehicle == null || carPos == null))
                  Container(
                    color: AppColors.textLight.withOpacity(0.15),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 64,
                            height: 64,
                            child: Image.asset(
                              'assets/images/loader.gif',
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.translate('loading'),
                            style: const TextStyle(
                              fontFamily: 'Barlow',
                              fontWeight: FontWeight.bold,
                              color: AppColors.brandBlue,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
    });
  }

  // Vehicle selector
  void _showVehicleSelector(BuildContext context) {
    final controller = Get.find<LiveTrackingController>();
    final mapController = Get.find<MapController>();
    final l10n = AppLocalizations.of(context);
    final onlineVehicles = mapController.onlineVehicles;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.dividerStrong.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, isSmallScreen ? 16 : 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.brandBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.directions_car,
                      color: AppColors.brandBlue,
                      size: isSmallScreen ? 20 : 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      l10n.translate('selectVehicleToTrack'),
                      style: GoogleFonts.barlow(
                        color: AppColors.brandBlue,
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFDFE3E8)),
            // List
            Flexible(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(
                  vertical: isSmallScreen ? 8 : 12,
                  horizontal: isSmallScreen ? 12 : 16,
                ),
                itemCount: onlineVehicles.length,
                itemBuilder: (context, index) {
                  final car = onlineVehicles[index];
                  final isSelected =
                      mapController.liveTrackingVehicle.value?['car_id'] ==
                          car['car_id'];
                  return Container(
                    margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.brandBlue.withOpacity(0.1)
                          : AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.brandBlue
                            : AppColors.dividerStrong.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          controller.changeVehicle(car);
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.brandBlue
                                      : AppColors.lightGrey2.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.directions_car,
                                  color: isSelected
                                      ? AppColors.white
                                      : AppColors.brandBlue,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      car['plate_number'] ?? 'Unknown',
                                      textDirection: TextDirection.ltr,
                                      style: GoogleFonts.barlow(
                                        fontSize: isSmallScreen ? 14 : 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.brandBlue,
                                      ),
                                    ),
                                    if (car['car_name'] != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        car['car_name'],
                                        style: GoogleFonts.barlow(
                                          fontSize: isSmallScreen ? 12 : 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Map control button with press bounce + active color feedback.
class _AnimatedLocateButton extends StatefulWidget {
  final String heroTag;
  final String tooltip;
  final String assetPath;
  final bool isActive;
  final bool isLoading;
  final bool isSmallScreen;
  final Color activeColor;
  final VoidCallback onPressed;
  final VoidCallback? onLongPress;

  const _AnimatedLocateButton({
    required this.heroTag,
    required this.tooltip,
    required this.assetPath,
    required this.isActive,
    required this.isSmallScreen,
    required this.activeColor,
    required this.onPressed,
    this.isLoading = false,
    this.onLongPress,
  });

  @override
  State<_AnimatedLocateButton> createState() => _AnimatedLocateButtonState();
}

class _AnimatedLocateButtonState extends State<_AnimatedLocateButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.82)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.82, end: 1.12)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.12, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 25,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (widget.isLoading) return;
    await _controller.forward(from: 0);
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.isSmallScreen ? 40.0 : 48.0;
    final iconSize = widget.isSmallScreen ? 22.0 : 26.0;
    final active = widget.isActive;

    return Hero(
      tag: widget.heroTag,
      child: ScaleTransition(
        scale: _scale,
        child: Tooltip(
          message: widget.tooltip,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.isLoading ? null : _handleTap,
              onLongPress: widget.isLoading ? null : widget.onLongPress,
              customBorder: const CircleBorder(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: active
                      ? widget.activeColor.withOpacity(0.18)
                      : AppColors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: active
                        ? widget.activeColor
                        : AppColors.dividerStrong.withOpacity(0.25),
                    width: active ? 2.2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: active
                          ? widget.activeColor.withOpacity(0.45)
                          : Colors.black.withOpacity(0.16),
                      blurRadius: active ? 14 : 8,
                      spreadRadius: active ? 1 : 0,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: widget.isLoading
                      ? SizedBox(
                          width: iconSize * 0.7,
                          height: iconSize * 0.7,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: widget.activeColor,
                          ),
                        )
                      : AnimatedScale(
                          scale: active ? 1.08 : 1.0,
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutBack,
                          child: Image.asset(
                            widget.assetPath,
                            width: iconSize,
                            height: iconSize,
                            fit: BoxFit.contain,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter for bubble arrow pointing to car
class _BubbleArrowPainter extends CustomPainter {
  final Color color;

  _BubbleArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2 - 8, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width / 2 + 8, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PipTaxiStatusCard extends StatelessWidget {
  final double speed;
  final int taxiMeterStatus;
  final double? meterPrice;
  final bool showCompteur;
  final AppLocalizations l10n;

  const _PipTaxiStatusCard({
    required this.speed,
    required this.taxiMeterStatus,
    required this.meterPrice,
    required this.showCompteur,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.white.withOpacity(0.94),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.10),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.speed_outlined,
              size: 16,
              color: AppColors.brandBlue,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                '${speed.toStringAsFixed(0)} ${l10n.translate('speedUnit')}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.barlow(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                  color: AppColors.brandBlue,
                ),
              ),
            ),
            if (showCompteur) ...[
              Container(
                width: 1,
                height: 10,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: AppColors.dividerStrong.withOpacity(0.25),
              ),
              if (taxiMeterStatus == TaxiMeterStatus.occupe)
                Image.asset(
                  TaxiMeterStatus.occupiedImagePath,
                  width: 16,
                  height: 16,
                )
              else if (taxiMeterStatus == TaxiMeterStatus.pause)
                Icon(
                  Icons.pause_circle_filled,
                  size: 14,
                  color: TaxiMeterStatus.color(taxiMeterStatus),
                )
              else
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.errorColor,
                    shape: BoxShape.circle,
                  ),
                ),
              const SizedBox(width: 2),
              Text(
                taxiMeterStatus == TaxiMeterStatus.occupe && meterPrice != null
                    ? '${meterPrice!.toStringAsFixed(3)} ${l10n.translate('currencySymbol')}'
                    : l10n.translate(
                        TaxiMeterStatus.localizationKey(taxiMeterStatus),
                      ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.barlow(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                  color: TaxiMeterStatus.color(taxiMeterStatus),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PipRouteChip extends StatelessWidget {
  final bool arrived;
  final double remainingMeters;
  final double durationSeconds;
  final double totalMeters;
  final AppLocalizations l10n;

  const _PipRouteChip({
    required this.arrived,
    required this.remainingMeters,
    required this.durationSeconds,
    required this.totalMeters,
    required this.l10n,
  });

  String _distanceLabel() {
    if (remainingMeters >= 1000) {
      return '${(remainingMeters / 1000).toStringAsFixed(1)} ${l10n.translate('kilometersShort')}';
    }
    return '${remainingMeters.round()} ${l10n.translate('metersShort')}';
  }

  String _etaLabel() {
    final ratio =
        totalMeters > 0 ? (remainingMeters / totalMeters).clamp(0.0, 1.0) : 1.0;
    final seconds = durationSeconds * ratio;
    final totalMinutes = math.max(1, (seconds / 60).ceil());
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    final hourUnit = l10n.translate('hoursShort');
    if (hours <= 0) {
      return '0 $hourUnit ${minutes.toString().padLeft(2, '0')}';
    }
    return '$hours $hourUnit ${minutes.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.white.withOpacity(0.94),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.10),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          arrived
              ? l10n.translate('arrivedAtTaxi')
              : '${_distanceLabel()} · ${_etaLabel()}',
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.barlow(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            height: 1.15,
            color: arrived ? AppColors.successColor : AppColors.brandBlue,
          ),
        ),
      ),
    );
  }
}

class _RouteStatusChip extends StatelessWidget {
  final bool arrived;
  final double remainingMeters;
  final double durationSeconds;
  final double totalMeters;
  final String street;
  final String maneuver;
  final AppLocalizations l10n;
  final VoidCallback onClear;
  final VoidCallback onOpenMaps;

  const _RouteStatusChip({
    required this.arrived,
    required this.remainingMeters,
    required this.durationSeconds,
    required this.totalMeters,
    required this.street,
    required this.maneuver,
    required this.l10n,
    required this.onClear,
    required this.onOpenMaps,
  });

  String _distanceLabel() {
    if (remainingMeters >= 1000) {
      return '${(remainingMeters / 1000).toStringAsFixed(1)} ${l10n.translate('kilometersShort')}';
    }
    return '${remainingMeters.round()} ${l10n.translate('metersShort')}';
  }

  String _etaLabel() {
    final ratio =
        totalMeters > 0 ? (remainingMeters / totalMeters).clamp(0.0, 1.0) : 1.0;
    final seconds = durationSeconds * ratio;
    final totalMinutes = math.max(1, (seconds / 60).ceil());
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    final hourUnit = l10n.translate('hoursShort');
    if (hours <= 0) {
      return '0 $hourUnit ${minutes.toString().padLeft(2, '0')}';
    }
    return '$hours $hourUnit ${minutes.toString().padLeft(2, '0')}';
  }

  String? _maneuverLabel() {
    if (street.isEmpty && maneuver.isEmpty) return null;
    String action = '';
    if (maneuver.contains('left')) {
      action = l10n.translate('turnLeft');
    } else if (maneuver.contains('right')) {
      action = l10n.translate('turnRight');
    } else if (maneuver.contains('uturn')) {
      action = l10n.translate('uturn');
    } else if (maneuver.contains('straight') || maneuver.contains('continue')) {
      action = l10n.translate('continueStraight');
    }
    if (action.isNotEmpty && street.isNotEmpty) {
      return '$action · $street';
    }
    if (street.isNotEmpty) return street;
    return action.isEmpty ? null : action;
  }

  @override
  Widget build(BuildContext context) {
    final hint = _maneuverLabel();
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
        decoration: BoxDecoration(
          color: AppColors.white.withOpacity(0.96),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: AppColors.surfaceMuted.withOpacity(0.9),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.10),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            _RouteCardIconButton(
              icon: Icons.close_rounded,
              tooltip: l10n.translate('clearRoute'),
              foreground: AppColors.textSecondary,
              background: AppColors.surfaceMuted.withOpacity(0.7),
              onPressed: onClear,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    arrived
                        ? l10n.translate('arrivedAtTaxi')
                        : '${_distanceLabel()} · ${_etaLabel()}',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.barlow(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: arrived
                          ? AppColors.successColor
                          : AppColors.brandBlue,
                    ),
                  ),
                  if (!arrived && hint != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      hint,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.barlow(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (arrived)
              const SizedBox(width: 36, height: 36)
            else
              _RouteCardIconButton(
                tooltip: l10n.translate('openInMaps'),
                foreground: AppColors.textSecondary,
                background: AppColors.white,
                assetPath: 'assets/images/icons8-google-maps-96.png',
                onPressed: onOpenMaps,
              ),
          ],
        ),
      ),
    );
  }
}

class _RouteCardIconButton extends StatelessWidget {
  final IconData? icon;
  final String? assetPath;
  final String tooltip;
  final Color foreground;
  final Color background;
  final VoidCallback onPressed;

  const _RouteCardIconButton({
    this.icon,
    this.assetPath,
    required this.tooltip,
    required this.foreground,
    required this.background,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Center(
              child: assetPath != null
                  ? Image.asset(
                      assetPath!,
                      width: 22,
                      height: 22,
                      fit: BoxFit.contain,
                    )
                  : Icon(icon, size: 18, color: foreground),
            ),
          ),
        ),
      ),
    );
  }
}
