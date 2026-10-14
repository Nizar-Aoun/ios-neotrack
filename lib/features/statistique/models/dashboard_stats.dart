/// Modèle de données pour les statistiques du tableau de bord
/// Basé sur le nouveau format API /statistics/car/{carId}
class DashboardStats {
  final String carId;
  final String method;
  final DateTime? startDate;
  final DateTime? endDate;
  final double distanceRidesKm; // Distance avec passagers (TC)
  final double distanceVideKm; // Distance à vide (TV)
  final double totalRideAmount; // Chiffre d'affaires total
  final int rideCount; // Nombre de courses
  final double workDurationHours; // Durée de travail
  final double workDistanceKm; // Distance de travail

  const DashboardStats({
    required this.carId,
    required this.method,
    this.startDate,
    this.endDate,
    required this.distanceRidesKm,
    required this.distanceVideKm,
    required this.totalRideAmount,
    required this.rideCount,
    required this.workDurationHours,
    required this.workDistanceKm,
  });

  // Shift is valid only if rideCount >= 2
  bool get isShiftActive => rideCount >= 2;

  // Computed properties for compatibility (respect shift rules)
  double get totalKm => isShiftActive ? distanceRidesKm + distanceVideKm : 0.0;
  double get loadedKm => isShiftActive ? distanceRidesKm : 0.0;
  double get emptyKm => isShiftActive ? distanceVideKm : 0.0;
  double get totalRevenue => isShiftActive ? totalRideAmount : 0.0;
  double get workHours => isShiftActive ? workDurationHours : 0.0;
  int get numberOfTrips => isShiftActive ? rideCount : 0;
  double get avgRevenuePerTrip =>
      isShiftActive && numberOfTrips > 0 ? totalRevenue / numberOfTrips : 0.0;
  double get hourlyRevenue =>
      isShiftActive && workHours > 0 ? totalRevenue / workHours : 0.0;
  double get kmRevenue =>
      isShiftActive && totalKm > 0 ? totalRevenue / totalKm : 0.0;

  // Calcul du taux de charge (load rate)
  double get loadRate =>
      isShiftActive && totalKm > 0 ? (loadedKm / totalKm) * 100 : 0.0;

  // Calcul de l'indice de performance global (IR)
  // Basé sur: taux de charge (40%), revenu horaire (40%), revenu/km (20%)
  double get performanceIndex {
    if (!isShiftActive) return 0.0;
    final load = (loadRate / 70) * 40;
    final hourly = (hourlyRevenue / 20) * 40;
    final km = (kmRevenue / 0.8) * 20;
    return (load + hourly + km).clamp(0, 100);
  }

  // Performance badge based on performance index
  String getPerformanceBadge() {
    if (!isShiftActive) return 'offline';
    if (performanceIndex >= 85) return 'excellent';
    if (performanceIndex >= 70) return 'good';
    if (performanceIndex >= 50) return 'acceptable';
    return 'low';
  }

  // Check if needs alert
  bool needsAlert() {
    if (!isShiftActive) return false;
    return loadRate < 60 ||
        loadRate >= 80 ||
        hourlyRevenue < 10 ||
        hourlyRevenue >= 20 ||
        kmRevenue < 0.6 ||
        kmRevenue >= 1.0;
  }

  // Get alert message key
  String? getAlertMessage() {
    if (!isShiftActive) return null;
    if (loadRate < 60) return 'loadRateLow';
    if (loadRate >= 80) return 'loadRateExcellent';
    if (hourlyRevenue < 10) return 'hourlyRevenueLow';
    if (hourlyRevenue >= 20) return 'hourlyRevenueExcellent';
    if (kmRevenue < 0.6) return 'kmRevenueLow';
    if (kmRevenue >= 1.0) return 'kmRevenueExcellent';
    return null;
  }

  // Check if alert is success
  bool isSuccessAlert() {
    if (!isShiftActive) return false;
    return loadRate >= 80 || hourlyRevenue >= 20 || kmRevenue >= 1.0;
  }

  // Factory pour créer depuis JSON (nouvelle API)
  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value, [double defaultValue = 0.0]) {
      if (value == null) return defaultValue;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    int parseInt(dynamic value, [int defaultValue = 0]) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    // Parse date range
    DateTime? startDate;
    DateTime? endDate;
    if (json['dateRange'] != null) {
      final dateRange = json['dateRange'] as Map<String, dynamic>;
      if (dateRange['startDate'] != null) {
        startDate = DateTime.tryParse(dateRange['startDate'].toString());
      }
      if (dateRange['endDate'] != null) {
        endDate = DateTime.tryParse(dateRange['endDate'].toString());
      }
    }

    return DashboardStats(
      carId: json['car_id']?.toString() ?? '',
      method: json['method']?.toString() ?? 'with_odo',
      startDate: startDate,
      endDate: endDate,
      distanceRidesKm: parseDouble(json['distanceRides_km']),
      distanceVideKm: parseDouble(json['distanceVide_km']),
      totalRideAmount: parseDouble(json['totalRideAmount']),
      rideCount: parseInt(json['rideCount']),
      workDurationHours: parseDouble(json['workDuration_hours'], 1.0),
      workDistanceKm: parseDouble(json['workDistance_km']),
    );
  }

  // Données statiques pour démonstration
  factory DashboardStats.mock() {
    return DashboardStats(
      carId: 'mock_car_id',
      method: 'with_odo',
      startDate: DateTime.now().subtract(const Duration(hours: 12)),
      endDate: DateTime.now(),
      distanceRidesKm: 7.96,
      distanceVideKm: 5.0,
      totalRideAmount: 64.74,
      rideCount: 13,
      workDurationHours: 8.95,
      workDistanceKm: 6.44,
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'car_id': carId,
      'method': method,
      'dateRange': {
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
      },
      'distanceRides_km': distanceRidesKm,
      'distanceVide_km': distanceVideKm,
      'totalRideAmount': totalRideAmount,
      'rideCount': rideCount,
      'workDuration_hours': workDurationHours,
      'workDistance_km': workDistanceKm,
      'hourlyRevenue': hourlyRevenue,
      'revenuePerKm': kmRevenue,
      'revenueMoyenne': avgRevenuePerTrip,
    };
  }
}

/// Statistiques quotidiennes pour les graphiques
class DailyStatistic {
  final String date;
  final double distanceRidesKm;
  final double distanceVideKm;
  final double totalRideAmount;
  final int rideCount;
  final double workDurationHours;
  final double workDistanceKm;

  const DailyStatistic({
    required this.date,
    required this.distanceRidesKm,
    required this.distanceVideKm,
    required this.totalRideAmount,
    required this.rideCount,
    required this.workDurationHours,
    required this.workDistanceKm,
  });

  // Computed properties
  bool get isShiftActive => rideCount >= 2;
  double get totalKm => isShiftActive ? distanceRidesKm + distanceVideKm : 0.0;
  double get loadRate =>
      isShiftActive && totalKm > 0 ? (distanceRidesKm / totalKm) * 100 : 0.0;
  double get workHours => isShiftActive ? workDurationHours : 0.0;
  int get numberOfTrips => isShiftActive ? rideCount : 0;
  // For daily charts we want to show reported revenue even when a day has
  // a single trip. Return the actual reported ride amount here.
  double get totalRevenue => totalRideAmount;
  double get hourlyRevenue =>
      isShiftActive && workHours > 0 ? totalRevenue / workHours : 0.0;
  double get revenuePerKm =>
      isShiftActive && totalKm > 0 ? totalRevenue / totalKm : 0.0;
  double get revenueMoyenne =>
      isShiftActive && numberOfTrips > 0 ? totalRevenue / numberOfTrips : 0.0;

  // Formatted date for display (e.g., "23/01")
  String get formattedDate {
    final parts = date.split('-');
    if (parts.length == 3) return '${parts[2]}/${parts[1]}';
    return date;
  }

  // Day name for display
  String get dayName {
    try {
      final dateTime = DateTime.parse(date);
      const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
      return days[dateTime.weekday - 1];
    } catch (e) {
      return date;
    }
  }

  factory DailyStatistic.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value, [double defaultValue = 0.0]) {
      if (value == null) return defaultValue;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    int parseInt(dynamic value, [int defaultValue = 0]) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    return DailyStatistic(
      date: json['date']?.toString() ?? '',
      distanceRidesKm: parseDouble(json['distanceRides_km']),
      distanceVideKm: parseDouble(json['distanceVide_km']),
      totalRideAmount: parseDouble(json['totalRideAmount']),
      rideCount: parseInt(json['rideCount']),
      workDurationHours: parseDouble(json['workDuration_hours']),
      workDistanceKm: parseDouble(json['workDistance_km']),
    );
  }
}

/// Statistiques hebdomadaires (endpoint /7days)
/// Retourne les données de lundi au jour courant
class WeeklyStats {
  final String carId;
  final String method;
  final DateTime? startDate;
  final DateTime? endDate;
  final DashboardStats totals;
  final List<DailyStatistic> dailyStatistics;

  const WeeklyStats({
    required this.carId,
    required this.method,
    this.startDate,
    this.endDate,
    required this.totals,
    required this.dailyStatistics,
  });

  // Get daily revenue values for chart (only actual days worked)
  List<double> get dailyRevenueValues {
    final values = dailyStatistics.map((day) => day.totalRevenue).toList();
    return _completeWeekWithZeros(values);
  }

  // Get daily load rate values for chart (only actual days worked)
  List<double> get dailyLoadRateValues {
    final values = dailyStatistics.map((day) => day.loadRate).toList();
    return _completeWeekWithZeros(values);
  }

  // Complete week data with zeros for future days (not yet worked)
  List<double> _completeWeekWithZeros(List<double> values) {
    if (values.isEmpty) return List.filled(7, 0.0);

    // If we already have 7 days, return as is
    if (values.length >= 7) return values.take(7).toList();

    // Reconstruct full week starting from Monday
    // Calculate which day of the week the data starts
    if (dailyStatistics.isEmpty) return values;

    // Get the first date from daily statistics
    try {
      final firstDate = DateTime.parse(dailyStatistics.first.date);
      // weekday: 1=Monday, 7=Sunday
      final startDayOffset = firstDate.weekday - 1; // 0=Monday, 6=Sunday

      final weekData = List<double>.filled(7, 0.0);

      // Place data values at the correct positions
      for (int i = 0; i < values.length && startDayOffset + i < 7; i++) {
        weekData[startDayOffset + i] = values[i];
      }

      return weekData;
    } catch (e) {
      // Fallback to simple padding if date parsing fails
      final completed = List<double>.from(values);
      while (completed.length < 7) {
        completed.add(0.0);
      }
      return completed;
    }
  }

  // Get daily hourly revenue values for chart
  List<double> get dailyHourlyRevenueValues {
    return dailyStatistics.map((day) => day.hourlyRevenue).toList();
  }

  // Get daily work hours for chart
  List<double> get dailyWorkHoursValues {
    return dailyStatistics.map((day) => day.workHours).toList();
  }

  // Get daily ride count for chart
  List<int> get dailyRideCountValues {
    return dailyStatistics.map((day) => day.numberOfTrips).toList();
  }

  // Get formatted date labels for chart
  List<String> get dateLabels {
    return dailyStatistics.map((day) => day.formattedDate).toList();
  }

  // Get day name labels for chart (complete week)
  List<String> get dayLabels {
    const allDays = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

    // If we already have 7 days, return as is
    if (dailyStatistics.length >= 7) {
      return dailyStatistics.take(7).map((day) => day.dayName).toList();
    }

    // Calculate which day of the week the data starts
    if (dailyStatistics.isEmpty) {
      return allDays; // Default to full week if no data
    }

    try {
      final firstDate = DateTime.parse(dailyStatistics.first.date);
      // weekday: 1=Monday, 7=Sunday
      final startDayIndex = firstDate.weekday - 1; // 0=Monday, 6=Sunday

      final weekLabels = List<String>.from(allDays);
      // Shift labels to align with the first date
      // If data starts on Wednesday (index 2), we want [Mer, Jeu, Ven, Sam, Dim, Lun, Mar]
      if (startDayIndex > 0) {
        final rotated =
            allDays.sublist(startDayIndex) + allDays.sublist(0, startDayIndex);
        return rotated;
      }

      return allDays;
    } catch (e) {
      // Fallback to default week if date parsing fails
      return allDays;
    }
  }

  factory WeeklyStats.fromJson(Map<String, dynamic> json) {
    // Parse date range
    DateTime? startDate;
    DateTime? endDate;
    if (json['dateRange'] != null) {
      final dateRange = json['dateRange'] as Map<String, dynamic>;
      if (dateRange['startDate'] != null) {
        startDate = DateTime.tryParse(dateRange['startDate'].toString());
      }
      if (dateRange['endDate'] != null) {
        endDate = DateTime.tryParse(dateRange['endDate'].toString());
      }
    }

    // Parse totals
    DashboardStats totals;
    if (json['totals'] != null) {
      final totalsData = json['totals'] as Map<String, dynamic>;
      totalsData['car_id'] = json['car_id'];
      totalsData['method'] = json['method'];
      totalsData['dateRange'] = json['dateRange'];
      totals = DashboardStats.fromJson(totalsData);
    } else {
      totals = DashboardStats.mock();
    }

    // Parse daily statistics
    List<DailyStatistic> dailyStats = [];
    if (json['dailyStatistics'] != null && json['dailyStatistics'] is List) {
      dailyStats = (json['dailyStatistics'] as List)
          .map((day) => DailyStatistic.fromJson(day as Map<String, dynamic>))
          .toList();
    }

    return WeeklyStats(
      carId: json['car_id']?.toString() ?? '',
      method: json['method']?.toString() ?? 'with_odo',
      startDate: startDate,
      endDate: endDate,
      totals: totals,
      dailyStatistics: dailyStats,
    );
  }
}
