import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:taxi_driver_app/core/localization/app_localizations.dart';
import 'package:taxi_driver_app/features/shifts/application/shift_controller.dart';
import 'package:taxi_driver_app/models/ride.dart';
import 'package:taxi_driver_app/models/expense.dart';
import 'package:taxi_driver_app/models/category.dart';
import 'package:taxi_driver_app/features/wallet/domain/transaction_model.dart';
import 'package:taxi_driver_app/features/wallet/domain/filter_types.dart';
import 'package:taxi_driver_app/features/wallet/domain/wallet_summary.dart';
import 'package:taxi_driver_app/features/wallet/domain/i_wallet_repository.dart';
import 'package:taxi_driver_app/utils/image_cache_helper.dart';

import '../../shifts/domain/shift_model.dart';

extension AppLocalizationsTranslate on AppLocalizations {
  String translate(String key) => key;
}

class WalletController extends GetxController {
  final IWalletRepository _repository;

  WalletController(this._repository);

  // Observable state
  final selectedCar = Rx<Map<String, dynamic>?>(null);
  final startDate = Rx<DateTime?>(null);
  final endDate = Rx<DateTime?>(null);
  final rides = <Ride>[].obs;
  final expenses = <Expense>[].obs;
  final transactions = <TransactionModel>[].obs;
  final categories = <Category>[].obs;
  final isLoading = false.obs;
  final isAddingExpense = false.obs;
  final isUpdatingExpense = false.obs;
  final isDeletingExpense = false.obs;
  final error = Rx<String?>(null);
  final dateError = Rx<String?>(null);

  // Filter states
  final selectedFilter = TransactionFilter.all.obs;
  final selectedDateFilter = DateFilterType.lastDay.obs;

  // Expense form state
  final expenseAmountController = TextEditingController();
  final expenseDescriptionController = TextEditingController();
  final amountFocusNode = FocusNode();
  final selectedCategory = Rx<Category?>(null);
  final expenseDate = DateTime.now().obs;
  final expenseTime = TimeOfDay.now().obs;
  final amountError = Rx<String?>(null);
  final categoryError = Rx<String?>(null);
  final timeError = Rx<String?>(null);
  final descriptionError = Rx<String?>(null);

  // Deletion tracking
  final deletingExpenseStates = <String, bool>{}.obs;

  @override
  void onInit() {
    super.onInit();
    // Initialize dates based on default filter
    _updateDateRangeFromFilter();
  }

  @override
  void onClose() {
    expenseAmountController.dispose();
    expenseDescriptionController.dispose();
    amountFocusNode.dispose();
    super.onClose();
  }

  // Computed properties
  WalletSummary get summary {
    if (error.value != null) {
      return WalletSummary.empty();
    }

    // For personalized filters, check date errors more strictly
    if (selectedDateFilter.value == DateFilterType.personalized &&
        dateError.value != null) {
      return WalletSummary.empty();
    }

    final summaryTransactions = _summaryTransactions;

    final totalRevenue = summaryTransactions
        .where((t) => !t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalExpenses = summaryTransactions
        .where((t) => t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);
    final rideCount = summaryTransactions.where((t) => !t.isExpense).length;
    final expenseCount = summaryTransactions.where((t) => t.isExpense).length;

    return WalletSummary(
      totalRevenue: totalRevenue,
      totalExpenses: totalExpenses,
      netBalance: totalRevenue - totalExpenses,
      rideCount: rideCount,
      expenseCount: expenseCount,
      revenueBreakdown: _calculateRevenueBreakdown(),
    );
  }

  List<TransactionModel> get filteredTransactions {
    final visible = _summaryTransactions;

    switch (selectedFilter.value) {
      case TransactionFilter.revenue:
        return visible.where((t) => !t.isExpense).toList();
      case TransactionFilter.expenses:
        return visible.where((t) => t.isExpense).toList();
      case TransactionFilter.all:
        return visible.toList();
    }
  }

  List<TransactionModel> get visibleTransactions {
    return transactions
        .where((transaction) =>
            transaction.isExpense || transaction.asRide?.isDeleted != true)
        .toList();
  }

  List<TransactionModel> get _summaryTransactions {
    final currentShift = _selectedShift;
    return visibleTransactions.where((transaction) {
      if (currentShift == null) return true;
      return currentShift.containsTime(transaction.date);
    }).toList();
  }

  ShiftModel? get _selectedShift {
    if (!Get.isRegistered<ShiftController>()) return null;
    return Get.find<ShiftController>().selectedShift;
  }

  List<Ride> get visibleRides {
    return rides.where((ride) => ride.isDeleted != true).toList();
  }

  // Actions
  void setSelectedCar(Map<String, dynamic>? car) {
    selectedCar.value = car;
    if (car != null) {
      loadData();
    }
  }

  void setTransactionFilter(TransactionFilter filter) {
    selectedFilter.value = filter;
  }

  void setDateFilter(DateFilterType filter) {
    selectedDateFilter.value = filter;
    _updateDateRangeFromFilter();
    if (selectedCar.value != null) {
      loadData();
    }
  }

  void setCustomDateRange(DateTime? start, DateTime? end) {
    startDate.value = start;
    endDate.value = end;
    _validateDates();
    if (selectedCar.value != null && start != null && end != null) {
      loadData();
    }
  }

  Future<void> loadData() async {
    if (selectedCar.value == null ||
        startDate.value == null ||
        endDate.value == null) {
      return;
    }

    isLoading.value = true;
    error.value = null;
    rides.clear();
    expenses.clear();
    transactions.clear();

    try {
      final carId = selectedCar.value!['car_id'] ?? selectedCar.value!['id'];

      // Load data in parallel
      final results = await Future.wait([
        _repository.getRides(
          carId: carId,
          startDate: startDate.value,
          endDate: endDate.value,
        ),
        _repository.getExpenses(
          carId: carId,
          startDate: startDate.value,
          endDate: endDate.value,
        ),
        _repository.getCategories(),
      ]);

      final loadedRides = results[0] as List<Ride>;
      final loadedExpenses = results[1] as List<Expense>;
      final loadedCategories = results[2] as List<Category>;
      rides.assignAll(loadedRides);
      expenses.assignAll(loadedExpenses);
      categories.assignAll(loadedCategories);
      _precacheCategoryIcons(loadedCategories);

      // Combine and sort transactions
      final allTransactions = <TransactionModel>[];
      allTransactions
          .addAll(loadedRides.map((ride) => TransactionModel.fromRide(ride)));
      allTransactions.addAll(loadedExpenses
          .map((expense) => TransactionModel.fromExpense(expense)));

      // Sort by date (newest first)
      allTransactions.sort((a, b) => b.date.compareTo(a.date));
      transactions.assignAll(allTransactions);
    } catch (e) {
      error.value = e.toString();
      rides.clear();
      expenses.clear();
      transactions.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addExpense({
    required double amount,
    required String categoryId,
    required DateTime date,
    String? description,
  }) async {
    if (selectedCar.value == null) return;

    isAddingExpense.value = true;

    // Create new expense object for optimistic UI update
    final now = DateTime.now();
    final tempExpense = Expense(
      id: 'temp_${now.millisecondsSinceEpoch}', // Temporary ID
      carId: selectedCar.value!['car_id'] ?? selectedCar.value!['id'],
      amount: amount,
      categoryId: categoryId,
      date: date,
      description: description ?? '',
      createdAt: now,
      updatedAt: now,
    );

    // Add to UI immediately at the beginning of the list
    expenses.insert(0, tempExpense);

    transactions.insert(0, TransactionModel.fromExpense(tempExpense));

    try {
      final carId = selectedCar.value!['car_id'] ?? selectedCar.value!['id'];

      // API call in background
      final addedExpense = await _repository.addExpense(
        carId: carId,
        amount: amount,
        categoryId: categoryId,
        date: date,
        description: description,
      );

      // Replace temp expense with the real one from API
      final tempIndex = expenses.indexWhere((e) => e.id == tempExpense.id);
      if (tempIndex != -1) {
        expenses[tempIndex] = addedExpense;
      }

      final tempTxIndex =
          transactions.indexWhere((t) => t.id == tempExpense.id);
      if (tempTxIndex != -1) {
        transactions[tempTxIndex] = TransactionModel.fromExpense(addedExpense);
      }

      // Sort transactions after successful addition
      expenses.sort((a, b) => b.date.compareTo(a.date));
      transactions.sort((a, b) => b.date.compareTo(a.date));

      resetExpenseForm();
    } catch (e) {
      // Remove the optimistically added expense if API fails
      expenses.removeWhere((exp) => exp.id == tempExpense.id);
      transactions.removeWhere((t) => t.id == tempExpense.id);

      error.value = e.toString();
      rethrow;
    } finally {
      isAddingExpense.value = false;
    }
  }

  Future<void> updateExpense({
    required String expenseId,
    required double amount,
    required String categoryId,
    required DateTime date,
    String? description,
  }) async {
    if (selectedCar.value == null) return;

    // Check if trying to update a temporary expense
    if (expenseId.startsWith('temp_')) {
      // Remove the temp expense and add as new
      expenses.removeWhere((e) => e.id == expenseId);
      transactions.removeWhere((t) => t.id == expenseId);

      // Add as new expense
      await addExpense(
        amount: amount,
        categoryId: categoryId,
        date: date,
        description: description,
      );
      return;
    }

    isUpdatingExpense.value = true;

    // Find and update expense in UI immediately
    final expenseIndex = expenses.indexWhere((e) => e.id == expenseId);
    Expense? oldExpense;

    if (expenseIndex != -1) {
      oldExpense = expenses[expenseIndex];
      // Update in expenses list
      expenses[expenseIndex] = Expense(
        id: expenseId,
        carId: selectedCar.value!['car_id'] ?? selectedCar.value!['id'],
        amount: amount,
        categoryId: categoryId,
        date: date,
        description: description ?? '',
        createdAt: oldExpense.createdAt,
        updatedAt: DateTime.now(),
      );
      expenses.sort((a, b) => b.date.compareTo(a.date));

      // Update in transactions list
      final txIndex = transactions.indexWhere((t) => t.id == expenseId);
      if (txIndex != -1) {
        transactions[txIndex] =
            TransactionModel.fromExpense(expenses[expenseIndex]);
        transactions.sort((a, b) => b.date.compareTo(a.date));
      }
    } else {}

    try {
      final carId = selectedCar.value!['car_id'] ?? selectedCar.value!['id'];

      // API call in background
      await _repository.updateExpense(
        expenseId: expenseId,
        carId: carId,
        amount: amount,
        categoryId: categoryId,
        date: date,
        description: description,
      );

      // Clear form
      resetExpenseForm();
    } catch (e) {
      // Restore old expense if API fails
      if (oldExpense != null && expenseIndex != -1) {
        expenses[expenseIndex] = oldExpense;
        expenses.sort((a, b) => b.date.compareTo(a.date));

        final txIndex = transactions.indexWhere((t) => t.id == expenseId);
        if (txIndex != -1) {
          transactions[txIndex] = TransactionModel.fromExpense(oldExpense);
          transactions.sort((a, b) => b.date.compareTo(a.date));
        }
      }

      error.value = e.toString();
      rethrow;
    } finally {
      isUpdatingExpense.value = false;
    }
  }

  Future<void> deleteExpense(String expenseId) async {
    if (selectedCar.value == null) return;

    // Check if trying to delete a temporary expense
    if (expenseId.startsWith('temp_')) {
      // Just remove from local lists, no API call
      expenses.removeWhere((e) => e.id == expenseId);
      transactions.removeWhere((t) => t.id == expenseId);

      return;
    }

    // Optimistic deletion - remove from UI immediately
    final deletedExpense = expenses.firstWhereOrNull((e) => e.id == expenseId);
    if (deletedExpense != null) {
      expenses.remove(deletedExpense);

      // Also remove from transactions list
      transactions
          .removeWhere((t) => t.isExpense && t.asExpense?.id == expenseId);
    }

    // Mark as deleting for UI feedback
    deletingExpenseStates[expenseId] = true;
    deletingExpenseStates.refresh();

    try {
      final carId = selectedCar.value!['car_id'] ?? selectedCar.value!['id'];

      // Perform API call in background - no reload needed
      await _repository.deleteExpense(
        expenseId: expenseId,
        carId: carId,
      );
    } catch (e) {
      // If API fails, restore the expense and show error
      if (deletedExpense != null) {
        expenses.add(deletedExpense);
        expenses.sort((a, b) => b.date.compareTo(a.date));

        // Restore in transactions using the factory method
        transactions.add(TransactionModel.fromExpense(deletedExpense));
        transactions.sort((a, b) => b.date.compareTo(a.date));
      }

      error.value = e.toString();
      rethrow;
    } finally {
      deletingExpenseStates.remove(expenseId);
      deletingExpenseStates.refresh();
    }
  }

  Future<void> deleteRide(String rideId) async {
    if (selectedCar.value == null) return;

    // Optimistic deletion - remove from UI immediately
    final deletedRide = rides.firstWhereOrNull((r) => r.id == rideId);
    if (deletedRide != null) {
      rides.remove(deletedRide);

      // Also remove from transactions list
      transactions.removeWhere((t) => !t.isExpense && t.asRide?.id == rideId);
    }

    try {
      // Perform API call in background - no reload needed
      await _repository.deleteRide(rideId: rideId);
    } catch (e) {
      // If API fails, restore the ride and show error
      if (deletedRide != null) {
        rides.add(deletedRide);
        rides.sort((a, b) => (b.startDate ?? DateTime.now())
            .compareTo(a.startDate ?? DateTime.now()));

        // Restore in transactions using the factory method
        transactions.add(TransactionModel.fromRide(deletedRide));
        transactions.sort((a, b) => b.date.compareTo(a.date));
      }

      error.value = e.toString();
      rethrow;
    }
  }

  /// Decode the category icons ahead of time so the expense dialog does not
  /// pay for it on the frame it opens.
  void _precacheCategoryIcons(List<Category> loadedCategories) {
    if (loadedCategories.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = Get.context;
      if (context == null) return;
      ImageCacheHelper.precacheCategoryIcons(
        context,
        loadedCategories.map((category) => category.iconAssetPath),
      );
    });
  }

  void resetExpenseForm() {
    expenseAmountController.text = '0';
    expenseDescriptionController.clear();
    selectedCategory.value = null;
    expenseDate.value = DateTime.now();
    expenseTime.value = TimeOfDay.now();
    amountError.value = null;
    categoryError.value = null;
    timeError.value = null;
    descriptionError.value = null;
  }

  void loadExpenseForEdit(Expense expense) {
    expenseAmountController.text = expense.amount.toStringAsFixed(2);
    expenseDescriptionController.text = expense.description;
    selectedCategory.value =
        categories.firstWhereOrNull((cat) => cat.id == expense.categoryId);
    expenseDate.value = expense.date;
    expenseTime.value = TimeOfDay.fromDateTime(expense.date);
  }

  bool validateExpenseForm(AppLocalizations l10n) {
    bool isValid = true;

    // Validate amount
    final amountText = expenseAmountController.text.trim();
    if (amountText.isEmpty) {
      amountError.value = l10n.translate('Amountisrequired');
      isValid = false;
    } else {
      final amount = double.tryParse(amountText);
      if (amount == null || amount <= 0) {
        amountError.value = l10n.translate('Pleaseenteravalidamount');
        isValid = false;
      } else {
        amountError.value = null;
      }
    }

    // Validate category
    if (selectedCategory.value == null) {
      categoryError.value = l10n.translate('Categoryisrequired');
      isValid = false;
    } else {
      categoryError.value = null;
    }

    return isValid;
  }

  // Private helper methods
  void _updateDateRangeFromFilter() {
    final now = DateTime.now();

    switch (selectedDateFilter.value) {
      case DateFilterType.lastDay:
        // "Today" = current day only: 00:00 → 23:59:59
        startDate.value = DateTime(now.year, now.month, now.day, 0, 0, 0);
        endDate.value = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;

      case DateFilterType.lastWeek:
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        startDate.value =
            DateTime(weekStart.year, weekStart.month, weekStart.day, 0, 0, 0);
        endDate.value = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;

      case DateFilterType.lastMonth:
        startDate.value = DateTime(now.year, now.month, 1, 0, 0, 0);
        endDate.value = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;

      case DateFilterType.personalized:
        // Keep existing dates or set default
        if (startDate.value == null) {
          startDate.value = DateTime(now.year, now.month, now.day, 0, 0, 0);
        }
        if (endDate.value == null) {
          endDate.value = DateTime(now.year, now.month, now.day, 23, 59, 59);
        }
        break;
    }

    _validateDates();
  }

  void _validateDates() {
    if (startDate.value == null || endDate.value == null) {
      dateError.value = 'Please select both start and end dates';
      return;
    }

    final start = startDate.value!;
    final end = endDate.value!;
    final now = DateTime.now();

    // Get date-only versions for comparison (ignore time)
    final startDateOnly = DateTime(start.year, start.month, start.day);
    final endDateOnly = DateTime(end.year, end.month, end.day);
    final todayDateOnly = DateTime(now.year, now.month, now.day);

    // Check if end date is after start date
    if (end.isBefore(start)) {
      dateError.value = 'End date must be after start date';
      return;
    }

    // Check if dates are in the future (compare date only, not time)
    if (startDateOnly.isAfter(todayDateOnly)) {
      dateError.value = 'Start date cannot be in the future';
      return;
    }

    if (endDateOnly.isAfter(todayDateOnly)) {
      dateError.value = 'End date cannot be in the future';
      return;
    }

    // Check if the date range is too large (e.g., more than 1 year)
    final daysDifference = end.difference(start).inDays;
    if (daysDifference > 365) {
      dateError.value = 'Date range cannot exceed 1 year';
      return;
    }

    // All validations passed
    dateError.value = null;
  }

  Map<String, double> _calculateRevenueBreakdown() {
    if (startDate.value == null || endDate.value == null) {
      return {};
    }

    double totalRevenue = 0.0;
    double ownerShare = 0.0;
    double driverShare = 0.0;

    final relevantRides = _summaryTransactions
        .where((transaction) => !transaction.isExpense)
        .map((transaction) => transaction.data as Ride)
        .toList();

    for (final ride in relevantRides) {
      final rideAmount = ride.rideAmount ?? 0.0;
      totalRevenue += rideAmount;

      if (ride.startDate != null) {
        final split = _getRevenueSplit(ride.startDate!);
        ownerShare += rideAmount * split['owner']!;
        driverShare += rideAmount * split['driver']!;
      }
    }

    return {
      'totalRevenue': totalRevenue,
      'ownerShare': ownerShare,
      'driverShare': driverShare,
    };
  }

  Map<String, double> _getRevenueSplit(DateTime rideTime) {
    final hour = rideTime.hour;

    // Between 05:00 and 20:59: Owner 70%, Driver 30%
    if (hour >= 5 && hour <= 20) {
      return {'owner': 0.70, 'driver': 0.30};
    }
    // Between 21:00 and 04:59: Owner 47%, Driver 53%
    else {
      return {'owner': 0.47, 'driver': 0.53};
    }
  }
}
