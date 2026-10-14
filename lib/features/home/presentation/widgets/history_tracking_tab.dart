import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:taxi_driver_app/core/shared/playback_controls.dart';
import 'package:taxi_driver_app/core/theme/app_colors.dart';
import 'package:taxi_driver_app/core/theme/text_styles.dart';
import 'package:taxi_driver_app/features/home/controller/history_tracking_controller.dart';
import 'package:taxi_driver_app/core/shared/timepicker.dart';
import 'package:taxi_driver_app/features/home/controller/map_controller.dart'
    as app;
import 'package:taxi_driver_app/l10n/app_localizations.dart';
import 'package:taxi_driver_app/config/env.dart';
import 'package:taxi_driver_app/providers/cached_tile_provider.dart';
import 'package:taxi_driver_app/core/shared/loading_gif.dart';
import 'package:taxi_driver_app/widgets/shared/address_bubble_marker.dart';
import 'package:taxi_driver_app/widgets/shared/ride_completed_cue.dart';
import 'package:taxi_driver_app/core/shared/app_date_picker.dart';

/// History Tracking Tab - Shows historical vehicle tracking with playback
class HistoryTrackingTab extends StatelessWidget {
  final bool isSmallScreen;

  const HistoryTrackingTab({
    super.key,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HistoryTrackingController>();
    final l10n = AppLocalizations.of(context);

    return Obx(() {
      // Show combined selector if no data loaded
      if (controller.locationHistory.isEmpty && !controller.isLoading.value) {
        return _buildCombinedSelector(context, controller, l10n);
      }

      // Show main map with history playback
      return _buildHistoryMap(context, controller, l10n, isSmallScreen);
    });
  }

  // ---------------------------------------------------------------------------
  // Selection screen
  // ---------------------------------------------------------------------------

  Widget _buildCombinedSelector(BuildContext context,
      HistoryTrackingController controller, AppLocalizations? l10n) {
    final mapCtrl = Get.find<app.MapController>();
    final headerInset = MediaQuery.of(context).padding.top + 72;

    // Auto-select first vehicle if none selected
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.selectedVehicle.value == null &&
          mapCtrl.allVehicles.isNotEmpty) {
        controller.setSelectedVehicle(mapCtrl.allVehicles.first);
      }
    });

    return Container(
      color: AppColors.backgroundColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableHeight = math.max(
            0.0,
            constraints.maxHeight - headerInset - 24,
          );

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, headerInset, 20, 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: availableHeight),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildSelectorCard(context, controller, mapCtrl, l10n),
                      const SizedBox(height: 12),
                      Obx(() => _buildFetchError(controller)),
                      const SizedBox(height: 4),
                      _buildLoadButton(controller, l10n),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Card title: what the screen is and what the driver has to pick.
  Widget _buildSelectorIntro(AppLocalizations? l10n) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.baseColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.history_rounded,
            size: 22,
            color: AppColors.textOnBase,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n?.translate('history') ?? 'History Tracking',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                l10n?.translate('Selectvehicletimeperiod') ??
                    'Select vehicle and time period',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSelectorCard(
    BuildContext context,
    HistoryTrackingController controller,
    app.MapController mapCtrl,
    AppLocalizations? l10n,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: _buildSelectorIntro(l10n),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: AppColors.dividerStrong.withOpacity(0.1),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(
                  Icons.directions_car_filled_rounded,
                  l10n?.translate('selectVehicle') ?? 'Vehicle',
                  AppColors.brandBlue,
                ),
                const SizedBox(height: 12),
                Obx(() =>
                    _buildVehicleDropdown(context, controller, mapCtrl, l10n)),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: AppColors.dividerStrong.withOpacity(0.1),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(
                  Icons.schedule_rounded,
                  l10n?.translate('selectDateTime') ?? 'Start Time',
                  AppColors.brandBlueDeep,
                ),
                const SizedBox(height: 12),
                _buildSimpleDateTimeField(context, controller, l10n),
                Obx(() {
                  if (controller.dateError.value.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _buildInlineMessage(
                      icon: Icons.error_outline,
                      color: AppColors.errorColor,
                      message: controller.dateError.value,
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String label, Color accent) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: accent, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: AppTextStyles.titleSmall.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildInlineMessage({
    required IconData icon,
    required Color color,
    required String message,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: color,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Surfaces backend failures (no data for the period, subscription, ...)
  /// which previously left the screen silent after a failed load.
  Widget _buildFetchError(HistoryTrackingController controller) {
    if (controller.error.value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _buildInlineMessage(
        icon: Icons.info_outline,
        color: AppColors.errorColor,
        message: controller.error.value,
      ),
    );
  }

  Widget _buildLoadButton(
    HistoryTrackingController controller,
    AppLocalizations? l10n,
  ) {
    return SizedBox(
      width: double.infinity,
      child: Obx(() {
        final isBusy = controller.isLoading.value;
        final canLoad = controller.selectedVehicle.value != null &&
            controller.dateError.value.isEmpty &&
            !isBusy;

        return ElevatedButton(
          onPressed: canLoad ? () => controller.fetchLocationHistory() : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.buttonBg,
            foregroundColor: AppColors.textOnBase,
            padding: const EdgeInsets.symmetric(vertical: 15),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            disabledBackgroundColor: AppColors.baseColor.withOpacity(0.25),
            disabledForegroundColor: AppColors.textOnBase.withOpacity(0.7),
          ),
          child: isBusy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: LoadingGif(width: 18, height: 18),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      controller.error.value.isEmpty
                          ? Icons.play_arrow_rounded
                          : Icons.refresh_rounded,
                      size: 20,
                      color: AppColors.textOnBase,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      controller.error.value.isEmpty
                          ? l10n?.translate('loadHistory') ?? 'Load History'
                          : l10n?.translate('retry') ?? 'Retry',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.textOnBase,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        );
      }),
    );
  }

  Widget _buildVehicleDropdown(
    BuildContext context,
    HistoryTrackingController controller,
    app.MapController mapCtrl,
    AppLocalizations? l10n,
  ) {
    if (mapCtrl.allVehicles.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.dividerStrong.withOpacity(0.15),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: AppColors.textTertiary,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n?.translate('noVehiclesAvailable') ??
                    'No vehicles available',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final selectedVehicle = controller.selectedVehicle.value;
    final hasMultipleCars = mapCtrl.allVehicles.length > 1;

    return InkWell(
      onTap: hasMultipleCars
          ? () => _showVehicleSelector(
                context,
                controller,
                mapCtrl,
                l10n,
                onSelected: controller.setSelectedVehicle,
              )
          : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selectedVehicle != null
                ? AppColors.brandBlue.withOpacity(0.25)
                : AppColors.dividerStrong.withOpacity(0.15),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.brandBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.directions_car_filled_rounded,
                color: AppColors.textOnBrand,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: selectedVehicle != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedVehicle['plate_number'] ?? 'Unknown',
                          textDirection: ui.TextDirection.ltr,
                          style: AppTextStyles.titleSmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (selectedVehicle['brand'] != null ||
                            selectedVehicle['model'] != null)
                          Text(
                            '${selectedVehicle['brand'] ?? ''} ${selectedVehicle['model'] ?? ''}'
                                .trim(),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    )
                  : Text(
                      l10n?.translate('selectVehicle') ?? 'Select a vehicle',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
            ),
            if (hasMultipleCars)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.brandBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.unfold_more_rounded,
                  color: AppColors.brandBlue,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleDateTimeField(
    BuildContext context,
    HistoryTrackingController controller,
    AppLocalizations? l10n,
  ) {
    return Obx(() {
      final selectedDate = controller.selectedStartDate.value;
      final endDate = selectedDate.add(const Duration(hours: 1));

      return InkWell(
        onTap: () => _selectStartDateTime(context, controller),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.brandBlueDeep.withOpacity(0.25),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.brandBlueDeep,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.event_rounded,
                  color: AppColors.textOnBrand,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatLocalizedDate(context, selectedDate),
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${DateFormat('HH:mm').format(selectedDate)} → '
                      '${DateFormat('HH:mm').format(endDate)}',
                      textDirection: ui.TextDirection.ltr,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.brandBlueDeep.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l10n?.translate('oneHour') ?? '1 h',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.brandBlueDeep,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.edit_calendar_rounded,
                color: AppColors.brandBlueDeep,
                size: 16,
              ),
            ],
          ),
        ),
      );
    });
  }

  /// Month names are localized manually so numbers stay Western in every locale.
  String _formatLocalizedDate(
    BuildContext context,
    DateTime date, {
    bool short = false,
  }) {
    final languageCode = Localizations.localeOf(context).languageCode;

    const arabicMonths = [
      'جانفي',
      'فيفري',
      'مارس',
      'أفريل',
      'ماي',
      'جوان',
      'جويلية',
      'أوت',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر'
    ];
    const frenchMonths = [
      'janv.',
      'févr.',
      'mars',
      'avr.',
      'mai',
      'juin',
      'juil.',
      'août',
      'sept.',
      'oct.',
      'nov.',
      'déc.'
    ];

    switch (languageCode) {
      case 'ar':
        final month = arabicMonths[date.month - 1];
        return short
            ? '$month ${date.day}'
            : '$month ${date.day}, ${date.year}';
      case 'fr':
        final month = frenchMonths[date.month - 1];
        return short
            ? '$month ${date.day}'
            : '$month ${date.day}, ${date.year}';
      default:
        return DateFormat(short ? 'MMM d' : 'MMM d, yyyy').format(date);
    }
  }

  Future<void> _selectStartDateTime(
      BuildContext context, HistoryTrackingController controller) async {
    final selected = await _pickStartDateTime(context, controller);
    if (selected == null || !context.mounted) return;

    _applySelectedDateTime(context, controller, selected);
  }

  /// Change the selected date from the map without losing the loaded session.
  Future<void> _changeDateTimeOnly(
      BuildContext context, HistoryTrackingController controller) async {
    final selected = await _pickStartDateTime(context, controller);
    if (selected == null || !context.mounted) return;

    final isValid = _applySelectedDateTime(context, controller, selected);
    if (!isValid) return;

    controller.clearRouteData();
    await controller.fetchLocationHistory();
  }

  Future<DateTime?> _pickStartDateTime(
      BuildContext context, HistoryTrackingController controller) async {
    final l10n = AppLocalizations.of(context);

    final date = await showAppDatePicker(
      context: context,
      initialDate: controller.startDate,
      firstDate: controller.minAllowedDate,
      lastDate: DateTime.now().subtract(const Duration(hours: 1)),
      builder: appDatePickerThemeBuilder,
    );

    if (date == null || !context.mounted) return null;

    final time = await ModernTimePicker.show(
      context,
      controller.startDate,
      l10n,
    );

    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  /// Validates the picked date and stores it. Returns whether it was accepted.
  bool _applySelectedDateTime(
    BuildContext context,
    HistoryTrackingController controller,
    DateTime selected,
  ) {
    final l10n = AppLocalizations.of(context);

    if (selected.add(const Duration(hours: 1)).isAfter(DateTime.now())) {
      controller.dateError.value =
          l10n.translate('Starttimemustallowatonehourwindow');
      return false;
    }

    if (selected.isBefore(controller.minAllowedDate)) {
      controller.dateError.value =
          l10n.translate('Historyonlyavailableforlast');
      return false;
    }

    controller.selectedStartDate.value = selected;
    controller.dateError.value = '';
    return true;
  }

  // ---------------------------------------------------------------------------
  // Map + playback screen
  // ---------------------------------------------------------------------------

  Widget _buildHistoryMap(
      BuildContext context,
      HistoryTrackingController controller,
      AppLocalizations? l10n,
      bool isSmallScreen) {
    // The app header overlays this tab: status bar, its vertical padding and
    // the profile avatar that drives its height.
    final headerBottom = MediaQuery.of(context).padding.top +
        (isSmallScreen ? 24 : 32) +
        (isSmallScreen ? 45 : 53);

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
                initialCenter: controller.currentPosition.value ??
                    const LatLng(36.8065, 10.1815),
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
                  keepBuffer: 4, // Balanced for smooth scrolling
                  panBuffer: 1, // Reduced for better performance
                  retinaMode: false, // Significantly improves performance
                  tileDisplay: const TileDisplay.fadeIn(
                    duration: Duration(milliseconds: 200),
                  ),
                  errorTileCallback: (tile, error, stackTrace) {},
                ),
                RepaintBoundary(
                  child: PolylineLayer(
                    polylines: controller.getColoredSegments(),
                  ),
                ),
                // Start and End point markers
                RepaintBoundary(
                  child: MarkerLayer(
                    markers: controller.getStartEndMarkers(),
                  ),
                ),
                // Car marker with tap handler
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
                              width: 80,
                              height: 80,
                              child: GestureDetector(
                                onTap: () => controller.toggleAddressBubble(),
                                child: RepaintBoundary(
                                  child: Transform.rotate(
                                    angle: controller.getCarRotationAngle(),
                                    child: Image.asset(
                                      controller.getCarMarkerPath(
                                          controller.selectedVehicle.value),
                                      width: 60,
                                      height: 60,
                                    ),
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

        // Session summary sits right under the app header
        Positioned(
          top: headerBottom + 8,
          left: 16,
          right: 16,
          child: Obx(() => controller.locationHistory.isEmpty
              ? const SizedBox.shrink()
              : _buildSessionSummary(context, controller, l10n)),
        ),

        Positioned(
          top: headerBottom + 62,
          left: 0,
          right: 0,
          child: Center(
            child: Obx(() => RideCompletedCue(
                  visible: controller.showRideCompletedCue.value,
                  eventVersion: controller.rideCompletedCueVersion.value,
                  fare: controller.completedRideFare.value,
                  rideLabel: l10n?.translate('ride').toLowerCase() ?? 'ride',
                  currencyLabel: l10n?.translate('currencySymbol') ?? 'DT',
                )),
          ),
        ),

        // Map controls + playback panel
        Positioned(
          bottom: 20,
          left: 16,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMapControls(context, controller, l10n),
              const SizedBox(height: 12),
              Obx(() => controller.locationHistory.isEmpty
                  ? const SizedBox.shrink()
                  : _PlaybackPanel(controller: controller, l10n: l10n)),
            ],
          ),
        ),

        // Loading overlay with smooth blur
        if (controller.isLoading.value)
          Positioned.fill(
            child: PlaybackLoadingOverlay(
              message:
                  l10n?.translate('loadingHistory') ?? 'Loading history...',
            ),
          ),
      ],
    );
  }

  /// Compact recap of what is being replayed: day, time window and distance.
  /// Tapping it re-opens the date picker.
  Widget _buildSessionSummary(BuildContext context,
      HistoryTrackingController controller, AppLocalizations? l10n) {
    final start = controller.historyStartTime ?? controller.startDate;
    final end = controller.historyEndTime ?? controller.endDate;

    return Center(
      child: Material(
        color: AppColors.white,
        elevation: 3,
        shadowColor: AppColors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(30),
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () => _changeDateTimeOnly(context, controller),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.event_rounded,
                  size: 15,
                  color: AppColors.brandBlue,
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    '${_formatLocalizedDate(context, start, short: true)} · '
                    '${DateFormat('HH:mm').format(start)}-${DateFormat('HH:mm').format(end)}',
                    textDirection: ui.TextDirection.ltr,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 14,
                  margin: const EdgeInsets.symmetric(horizontal: 9),
                  color: AppColors.dividerStrong.withOpacity(0.15),
                ),
                const Icon(
                  Icons.route_rounded,
                  size: 15,
                  color: AppColors.brandBlue,
                ),
                const SizedBox(width: 5),
                Obx(() => Text(
                      '${controller.totalDistanceKm.value.toStringAsFixed(1)} km',
                      textDirection: ui.TextDirection.ltr,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    )),
                const SizedBox(width: 4),
                const Icon(
                  Icons.expand_more_rounded,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMapControls(BuildContext context,
      HistoryTrackingController controller, AppLocalizations? l10n) {
    final mapCtrl = Get.find<app.MapController>();
    final hasMultipleCars = mapCtrl.allVehicles.length > 1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Back to the vehicle / period selection
        FloatingActionButton(
          heroTag: 'history_new_search',
          mini: true,
          tooltip: l10n?.translate('newSearch') ?? 'New search',
          onPressed: () => controller.resetState(),
          backgroundColor: AppColors.white,
          elevation: 4,
          child: const Icon(
            Icons.tune_rounded,
            size: 22,
            color: AppColors.brandBlue,
          ),
        ),
        if (hasMultipleCars) ...[
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'change_vehicle',
            mini: true,
            tooltip: l10n?.translate('changeVehicle') ?? 'Change vehicle',
            onPressed: () => _showVehicleSelector(
              context,
              controller,
              mapCtrl,
              l10n,
              onSelected: (car) async {
                controller.setSelectedVehicle(car);
                controller.clearRouteData();
                await controller.fetchLocationHistory();
              },
            ),
            backgroundColor: AppColors.white,
            elevation: 4,
            child: const Icon(
              Icons.directions_car,
              size: 22,
              color: AppColors.brandBlue,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Obx(() => FloatingActionButton(
              heroTag: 'center_history',
              mini: true,
              tooltip: l10n?.translate('followVehicle') ?? 'Follow vehicle',
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
            )),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Vehicle picker
  // ---------------------------------------------------------------------------

  void _showVehicleSelector(
    BuildContext context,
    HistoryTrackingController controller,
    app.MapController mapCtrl,
    AppLocalizations? l10n, {
    required void Function(Map<String, dynamic> vehicle) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(sheetContext).size.height * 0.8,
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
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.dividerStrong.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.brandBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.directions_car,
                      color: AppColors.brandBlue,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      l10n?.translate('selectVehicle') ?? 'Select Vehicle',
                      style: AppTextStyles.titleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    tooltip: l10n?.translate('close') ?? 'Close',
                    icon: const Icon(Icons.close_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surfaceColor,
                      foregroundColor: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              color: AppColors.dividerStrong.withOpacity(0.12),
            ),
            Flexible(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                shrinkWrap: true,
                itemCount: mapCtrl.allVehicles.length,
                itemBuilder: (context, index) {
                  final vehicle = mapCtrl.allVehicles[index];
                  final isSelected =
                      controller.selectedVehicle.value?['car_id'] ==
                          vehicle['car_id'];
                  final isOnline = vehicle['isOnline'] == true;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.brandBlue.withOpacity(0.06)
                          : AppColors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.brandBlue
                            : AppColors.dividerStrong.withOpacity(0.15),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          onSelected(vehicle);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.brandBlue
                                      : AppColors.surfaceColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.directions_car,
                                  color: isSelected
                                      ? AppColors.white
                                      : AppColors.brandBlue,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      vehicle['plate_number'] ?? 'Unknown',
                                      textDirection: ui.TextDirection.ltr,
                                      style: AppTextStyles.titleMedium.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (vehicle['brand'] != null ||
                                        vehicle['model'] != null)
                                      Text(
                                        '${vehicle['brand'] ?? ''} ${vehicle['model'] ?? ''}'
                                            .trim(),
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  color: AppColors.brandBlue,
                                  size: 22,
                                )
                              else
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isOnline
                                        ? AppColors.successColor
                                        : AppColors.textTertiary
                                            .withOpacity(0.4),
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

// -----------------------------------------------------------------------------
// Playback panel
// -----------------------------------------------------------------------------

/// Bottom sheet-like panel driving the route playback. It can be collapsed to
/// free up the map while keeping the timeline and the play button reachable.
class _PlaybackPanel extends StatelessWidget {
  final HistoryTrackingController controller;
  final AppLocalizations? l10n;

  const _PlaybackPanel({
    required this.controller,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() => PlaybackPanel(
          isExpanded: controller.isPanelExpanded.value,
          header: _buildHeader(),
          metrics: _buildMetrics(),
          timeline: _buildTimeline(),
          controls: _buildControls(),
        ));
  }

  Widget _buildHeader() {
    return Obx(() {
      final isOccupied = controller.getCurrentTaximeter();
      final status = isOccupied
          ? l10n?.translate('occupied') ?? 'Occupied'
          : l10n?.translate('free') ?? 'Free';

      return PlaybackPanelHeader(
        leading: PlaybackStatusIcon(
          icon: Icons.local_taxi,
          color: isOccupied ? AppColors.successColor : AppColors.errorColor,
        ),
        title: controller.selectedVehicle.value?['plate_number'] ?? '',
        subtitle:
            '${DateFormat('HH:mm:ss').format(controller.getPlaybackTime())} · $status',
        isPlaying: controller.isPlaying.value,
        onPlayPause: controller.togglePlayback,
        isExpanded: controller.isPanelExpanded.value,
        onToggleExpanded: controller.isPanelExpanded.toggle,
      );
    });
  }

  Widget _buildMetrics() {
    return Obx(() {
      final speed = controller.getCurrentSpeed();
      final fare = controller.getCurrentFare();
      final isDoorOpen = controller.getCurrentDoorStatus();

      return Row(
        children: [
          Expanded(
            child: PlaybackMetricChip(
              icon: Icons.speed_rounded,
              color: AppColors.brandBlue,
              label:
                  '${speed.toStringAsFixed(0)} ${l10n?.translate('speedUnit') ?? 'km/h'}',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: PlaybackMetricChip(
              icon: Icons.meeting_room_rounded,
              color:
                  isDoorOpen ? AppColors.tertiaryColor : AppColors.textTertiary,
              label: isDoorOpen
                  ? l10n?.translate('doorOpen') ?? 'Open'
                  : l10n?.translate('doorClosed') ?? 'Closed',
            ),
          ),
          if (fare > 0) ...[
            const SizedBox(width: 8),
            Expanded(
              child: PlaybackMetricChip(
                icon: Icons.payments_rounded,
                color: AppColors.successColor,
                label:
                    '${fare.toStringAsFixed(2)} ${l10n?.translate('currencySymbol') ?? 'DT'}',
              ),
            ),
          ],
        ],
      );
    });
  }

  /// Elapsed / total times come from the recorded timestamps, and the track is
  /// colored like the route so the driver sees when the taximeter was running.
  Widget _buildTimeline() {
    return Obx(() => PlaybackTimeline(
          progress: controller.playbackPosition.value,
          segments: controller.taximeterRuns
              .map((run) => PlaybackSegment(
                    start: run.start,
                    end: run.end,
                    color: run.occupied
                        ? AppColors.successColor
                        : AppColors.errorColor,
                  ))
              .toList(),
          onSeek: controller.updatePosition,
          leadingLabel:
              formatPlaybackDuration(controller.elapsedHistoryDuration),
          trailingLabel:
              formatPlaybackDuration(controller.totalHistoryDuration),
          center: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PlaybackLegendDot(
                color: AppColors.successColor,
                label: l10n?.translate('occupied') ?? 'Occupied',
              ),
              const SizedBox(width: 10),
              PlaybackLegendDot(
                color: AppColors.errorColor,
                label: l10n?.translate('free') ?? 'Free',
              ),
            ],
          ),
        ));
  }

  Widget _buildControls() {
    return PlaybackControlsRow(
      buttons: [
        PlaybackCircleButton(
          icon: Icons.restart_alt_rounded,
          tooltip: l10n?.translate('restart') ?? 'Restart',
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
