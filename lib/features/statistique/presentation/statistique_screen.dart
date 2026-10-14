import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../l10n/app_localizations.dart';
import '../models/dashboard_stats.dart';
import '../services/dashboard_service.dart';
import '../widgets/kpi_card.dart';
import '../widgets/performance_metric.dart';
import '../widgets/performance_indicator.dart';
import '../widgets/weekly_performance_chart.dart';
import '../widgets/car_selection_dialog.dart';
import '../widgets/dashboard_skeleton.dart';
import '../../wallet/presentation/widgets/dialogs/wallet_date_filter_dialog.dart';
import '../../wallet/domain/filter_types.dart';
import '../../home/controller/home_controller.dart';
import '../../../services/car_service.dart';

/// Page de présentation du tableau de bord des statistiques
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final DashboardService _service;
  DashboardStats? _stats;
  WeeklyStats? _weeklyStats;
  bool _isLoading = true;
  String? _error;
  String? _plateNumber;
  Map<String, dynamic>? _selectedCar;
  DateFilterType _currentFilter = DateFilterType.lastDay;
  DateTime? _startDate;
  DateTime? _endDate;

  /// Convert decimal hours to "Xh Ymin" format
  String _formatWorkDuration(double hours) {
    final h = hours.floor();
    final minutes = ((hours - h) * 60).round();
    return '${h}h ${minutes}min';
  }

  @override
  void initState() {
    super.initState();
    _service = DashboardService();
    // Initialize with today's date (00:00 to 23:59:59.999)
    final now = DateTime.now();
    _startDate = DateTime.utc(now.year, now.month, now.day, 0, 0, 0);
    _endDate = DateTime.utc(now.year, now.month, now.day, 23, 59, 59, 999);
    _initializeCarsAndLoadStats();
  }

  Future<void> _initializeCarsAndLoadStats() async {
    try {
      // Try to get HomeController if it exists
      if (Get.isRegistered<HomeController>()) {
        final homeController = Get.find<HomeController>();

        // Wait for cars to load if still loading
        int retries = 0;
        while (homeController.isLoadingCars.value && retries < 10) {
          await Future.delayed(const Duration(milliseconds: 200));
          retries++;
        }

        // Select first car if available
        if (homeController.cars.isNotEmpty) {
          _selectedCar = homeController.cars.first;
          _plateNumber = _selectedCar?['plate_number'] as String?;
        }
      } else {
        // HomeController not registered, fetch cars directly
        await _fetchCarsDirect();
      }
    } catch (e) {
      try {
        await _fetchCarsDirect();
        // ignore: empty_catches
      } catch (e2) {}
    }

    // Load stats even if car selection fails (will show error)
    _loadStats();
  }

  Future<void> _fetchCarsDirect() async {
    try {
      final carService = Get.find<CarService>();
      final response = await carService.getUserCars();
      final cars =
          (response['cars'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      if (cars.isNotEmpty) {
        _selectedCar = cars.first;
        _plateNumber = _selectedCar?['plate_number'] as String?;
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _loadStats() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Ensure we have a car selected
      if (_selectedCar == null) {
        final homeController = Get.find<HomeController>();
        if (homeController.cars.isNotEmpty) {
          _selectedCar = homeController.cars.first;
          _plateNumber = _selectedCar?['plate_number'] as String?;
        }
      }

      // Get car ID from selected car
      final carId = _selectedCar?['car_id'] as String?;

      if (carId == null) {
        throw Exception('No car available. Please add a car first.');
      }

      // Load both stats in parallel
      final results = await Future.wait([
        // Load main stats (current day or filtered period)
        _service.getStats(
          carId: carId,
          startDate: _startDate,
          endDate: _endDate,
        ),
        // Load weekly stats for charts (not affected by date filter)
        _service.getWeeklyStats(carId: carId),
      ]);

      if (!mounted) return;

      setState(() {
        _stats = results[0] as DashboardStats;
        _weeklyStats = results[1] as WeeklyStats;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        // Stored as a translation key so the UI never shows raw exception text.
        _error = 'statsError';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const Scaffold(
        body: DashboardSkeleton(),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.backgroundColor,
                AppColors.surfaceColor,
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                    border: Border.all(
                      color: AppColors.dividerColor.withOpacity(0.25),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.errorColor.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Image.asset(
                            'assets/images/icons8-wi-fi-off-94.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        l10n.translate('errorPrefix').trim(),
                        style: AppTextStyles.titleLarge.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l10n.translate('noInternetConnectionMessage'),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.dividerColor.withOpacity(0.35),
                          ),
                        ),
                        child: Text(
                          l10n.translate(_error!),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.45,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _loadStats,
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text(l10n.translate('retry')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.buttonBg,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (_stats != null) {
      final size = MediaQuery.of(context).size;
      final isSmallScreen = size.width < 360;

      return Scaffold(
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Date Filter Button
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(isSmallScreen ? 24 : 28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondaryColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: FloatingActionButton(
                heroTag: 'date_filter_button',
                onPressed: () => _showDateFilterDialog(context, isSmallScreen),
                backgroundColor: AppColors.secondaryColor,
                mini: isSmallScreen,
                elevation: 0,
                child: const Icon(Icons.calendar_today,
                    color: Colors.white, size: 20),
              ),
            ),
            SizedBox(height: isSmallScreen ? 10 : 12),
            // Car Selection Button
            if (_selectedCar != null &&
                Get.find<HomeController>()
                        .cars
                        .where((c) =>
                            (c['car_type']?.toString().toLowerCase() ?? '') ==
                            'taxi')
                        .length >
                    1)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(isSmallScreen ? 24 : 28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.baseColor.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: FloatingActionButton(
                  heroTag: 'car_selection_button',
                  onPressed: () =>
                      _showCarSelectionDialog(context, isSmallScreen),
                  backgroundColor: AppColors.primaryColor,
                  mini: isSmallScreen,
                  elevation: 0,
                  child: const Icon(Icons.directions_car,
                      color: Colors.white, size: 22),
                ),
              ),
          ],
        ),
        body: _buildContent(context, l10n, _stats!),
      );
    }

    return Scaffold(
      body: Center(
        child: Text(l10n.translate('noDataAvailable')),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppLocalizations l10n,
    DashboardStats stats,
  ) {
    final size = MediaQuery.of(context).size;
    final topPadding = MediaQuery.of(context).padding.top;
    final textScale =
        MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.6).toDouble();
    final isSmallScreen = size.width < 360;
    final baseKpiAspectRatio = size.height < 600
        ? 1.15
        : size.height < 700
            ? 1.25
            : size.height < 800
                ? 1.3
                : 1.4;
    final kpiChildAspectRatio =
        (baseKpiAspectRatio / textScale).clamp(0.78, 1.4);

    return Container(
      color: AppColors.backgroundColor,
      child: Column(
        children: [
          // Performance Index Header - pinned
          Container(
            margin: EdgeInsets.only(
              left: 16,
              right: 16,
              top: topPadding + 100, // Account for AppHeader
              bottom: 12,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.brandBlue,
                  AppColors.brandBlueDeep,
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brandBlue.withOpacity(0.22),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.speed,
                                color: Colors.white,
                                size: isSmallScreen ? 16 : 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                l10n.translate('performanceIndex'),
                                style: AppTextStyles.titleSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: isSmallScreen ? 13 : 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 8 : 10,
                            vertical: isSmallScreen ? 4 : 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            l10n.translate(stats.getPerformanceBadge()),
                            style: AppTextStyles.labelSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: isSmallScreen ? 10 : 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 8 : 10),
                        if (_plateNumber != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.directions_car,
                                  color: Colors.white,
                                  size: isSmallScreen ? 14 : 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _plateNumber!,
                                  textDirection: TextDirection.ltr,
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 13 : 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                      ],
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 10 : 12),
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: PerformanceIndicator(
                      value: stats.performanceIndex,
                      badge: l10n.translate(stats.getPerformanceBadge()),
                    ),
                  ),
                ],
              ),
            ),
          ), // Everything below scrolls
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              physics: const BouncingScrollPhysics(),
              children: [
                if (!stats.isShiftActive)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.warningColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.warningColor.withOpacity(0.35),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.warningColor.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.power_settings_new,
                              color: AppColors.warningColor,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.translate('taxiOffRest'),
                                  style: AppTextStyles.titleSmall.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  l10n.translate('taxiOffRestDesc'),
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (!stats.isShiftActive) const SizedBox(height: 16),
                // KPI Cards Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.translate('overview'),
                        style: AppTextStyles.titleLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: kpiChildAspectRatio,
                        children: [
                          KpiCard(
                            icon: Icons.route,
                            label: l10n.translate('totalDistance'),
                            value: stats.totalKm.toStringAsFixed(3),
                            unit: 'km',
                            color: AppColors.brandBlue,
                          ),
                          KpiCard(
                            icon: Icons.remove_road,
                            label: l10n.translate('emptyDistance'),
                            value: stats.emptyKm.toStringAsFixed(3),
                            unit: 'km',
                            color: AppColors.errorColor,
                          ),
                          KpiCard(
                            icon: Icons.add_road,
                            label: l10n.translate('loadedDistance'),
                            value: stats.loadedKm.toStringAsFixed(3),
                            unit: 'km',
                            color: AppColors.secondaryColor,
                          ),
                          KpiCard(
                            icon: Icons.local_taxi,
                            label: l10n.translate('numberOfTrips'),
                            value: stats.numberOfTrips.toString(),
                            unit: l10n.translate('trips'),
                            color: AppColors.secondaryColor,
                          ),
                          KpiCard(
                            icon: Icons.payments,
                            label: l10n.translate('totalRevenue'),
                            value: stats.totalRevenue.toStringAsFixed(3),
                            unit: l10n.translate('currencySymbol'),
                            color: AppColors.secondaryColor,
                          ),
                          KpiCard(
                            icon: Icons.schedule,
                            label: l10n.translate('workDuration'),
                            value: _formatWorkDuration(stats.workHours),
                            unit: '',
                            color: AppColors.tertiaryColor,
                            isTimeFormat: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Performance Metrics Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.translate('performanceMetrics'),
                        style: AppTextStyles.titleLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            PerformanceMetric(
                              label: l10n.translate('loadRate'),
                              value: stats.loadRate.toStringAsFixed(1),
                              unit: '%',
                              progress: (stats.loadRate / 100).clamp(0.0, 1.0),
                              color: stats.loadRate >= 70
                                  ? AppColors.secondaryColor
                                  : stats.loadRate >= 50
                                      ? AppColors.warningColor
                                      : AppColors.errorColor,
                            ),
                            const SizedBox(height: 16),
                            PerformanceMetric(
                              label: l10n.translate('hourlyRevenue'),
                              value: stats.hourlyRevenue.toStringAsFixed(1),
                              unit: l10n.translate('TND/h'),
                              progress:
                                  (stats.hourlyRevenue / 30).clamp(0.0, 1.0),
                              color: stats.hourlyRevenue >= 20
                                  ? AppColors.secondaryColor
                                  : stats.hourlyRevenue >= 15
                                      ? AppColors.warningColor
                                      : AppColors.errorColor,
                            ),
                            const SizedBox(height: 16),
                            PerformanceMetric(
                              label: l10n.translate('kmRevenue'),
                              value: stats.kmRevenue.toStringAsFixed(2),
                              unit: l10n.translate('TND/km'),
                              progress: (stats.kmRevenue / 1.5).clamp(0.0, 1.0),
                              color: stats.kmRevenue >= 0.8
                                  ? AppColors.secondaryColor
                                  : stats.kmRevenue >= 0.6
                                      ? AppColors.warningColor
                                      : AppColors.errorColor,
                            ),
                            const SizedBox(height: 16),
                            PerformanceMetric(
                              label: l10n.translate('avgRevenuePerTrip'),
                              value: stats.avgRevenuePerTrip.toStringAsFixed(1),
                              unit: l10n.translate('TND'),
                              progress: (stats.avgRevenuePerTrip / 50)
                                  .clamp(0.0, 1.0),
                              color: AppColors.brandBlue,
                            ),
                            const SizedBox(height: 20),
                            // Color Legend
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.backgroundColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color:
                                      AppColors.dividerColor.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        size: 16,
                                        color: AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        l10n.translate('colorLegend'),
                                        style:
                                            AppTextStyles.labelMedium.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  _LegendRow(
                                    color: AppColors.secondaryColor,
                                    text: l10n.translate('colorLegendGood'),
                                  ),
                                  const SizedBox(height: 8),
                                  _LegendRow(
                                    color: AppColors.warningColor,
                                    text: l10n.translate('colorLegendWarning'),
                                  ),
                                  const SizedBox(height: 8),
                                  _LegendRow(
                                    color: AppColors.brandBlue,
                                    text: l10n.translate('colorLegendMedium'),
                                  ),
                                  const SizedBox(height: 8),
                                  _LegendRow(
                                    color: AppColors.errorColor,
                                    text: l10n.translate('colorLegendLow'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Alerts

                // Weekly Performance Chart (Revenue Evolution)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.translate('dailyRevenueEvolution'),
                        style: AppTextStyles.titleLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: WeeklyPerformanceChart(
                          weeklyData: _weeklyStats?.dailyRevenueValues ?? [],
                          labels: _weeklyStats?.dayLabels ?? [],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Load Rate Evolution Chart
                if (_weeklyStats != null &&
                    _weeklyStats!.dailyStatistics.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.translate('loadRateEvolution'),
                          style: AppTextStyles.titleLarge.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: WeeklyPerformanceChart(
                            weeklyData: _weeklyStats!.dailyLoadRateValues,
                            labels: _weeklyStats!.dayLabels,
                            isPercentage: true,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCarSelectionDialog(BuildContext context, bool isSmallScreen) {
    showDialog(
      context: context,
      builder: (dialogContext) => CarSelectionDialog(
        isSmallScreen: isSmallScreen,
        selectedCar: _selectedCar,
        onCarSelected: (car) {
          if (!mounted) return;

          setState(() {
            _selectedCar = car;
            _plateNumber = car['plate_number'] as String?;
          });
          _loadStats();
        },
      ),
    );
  }

  void _showDateFilterDialog(BuildContext context, bool isSmallScreen) {
    final size = MediaQuery.of(context).size;
    final isVerySmallScreen = size.width < 340;

    showDialog(
      context: context,
      builder: (dialogContext) => WalletDateFilterDialog(
        isVerySmallScreen: isVerySmallScreen,
        isSmallScreen: isSmallScreen,
        initialFilter: _currentFilter,
        initialStartDate: _startDate,
        initialEndDate: _endDate,
        onApply: (filterType, startDate, endDate) {
          if (!mounted) return;

          setState(() {
            _currentFilter = filterType;

            // Calculate dates based on filter type
            final now = DateTime.now();
            switch (filterType) {
              case DateFilterType.lastDay:
                _startDate =
                    DateTime.utc(now.year, now.month, now.day, 0, 0, 0);
                _endDate =
                    DateTime.utc(now.year, now.month, now.day, 23, 59, 59, 999);
                break;
              case DateFilterType.lastWeek:
                final startOfWeek =
                    now.subtract(Duration(days: now.weekday - 1));
                _startDate = DateTime.utc(startOfWeek.year, startOfWeek.month,
                    startOfWeek.day, 0, 0, 0);
                _endDate =
                    DateTime.utc(now.year, now.month, now.day, 23, 59, 59, 999);
                break;
              case DateFilterType.lastMonth:
                _startDate = DateTime.utc(now.year, now.month, 1, 0, 0, 0);
                _endDate =
                    DateTime.utc(now.year, now.month, now.day, 23, 59, 59, 999);
                break;
              case DateFilterType.personalized:
                _startDate = startDate;
                _endDate = endDate;
                break;
            }
          });
          _loadStats();
        },
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String text;

  const _LegendRow({
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
