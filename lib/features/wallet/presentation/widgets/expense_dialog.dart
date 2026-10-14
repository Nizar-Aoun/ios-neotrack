import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taxi_driver_app/core/errors/error_messages.dart';
import 'package:taxi_driver_app/core/theme/app_colors.dart';
import 'package:taxi_driver_app/l10n/app_localizations.dart';
import 'package:taxi_driver_app/features/wallet/provider/wallet_controller.dart';
import 'package:taxi_driver_app/models/category.dart';
import 'package:taxi_driver_app/models/expense.dart';
import 'package:taxi_driver_app/core/shared/custom_filed.dart';
import 'package:taxi_driver_app/core/shared/custom_elevated_button.dart';
import 'package:taxi_driver_app/core/shared/snackbar.dart';
import 'package:taxi_driver_app/core/shared/timepicker.dart';
import 'package:taxi_driver_app/core/shared/app_date_picker.dart';
import 'package:taxi_driver_app/utils/date_formatter.dart';
import 'package:taxi_driver_app/features/wallet/presentation/widgets/category_icon.dart';

/// Dialog for adding/editing expenses
class ExpenseDialog extends StatefulWidget {
  final Expense? expense;

  const ExpenseDialog({
    super.key,
    this.expense,
  });

  @override
  State<ExpenseDialog> createState() => _ExpenseDialogState();
}

class _ExpenseDialogState extends State<ExpenseDialog> {
  final WalletController controller = Get.find<WalletController>();

  bool get isEdit => widget.expense != null;

  String _sortedLocale = '';
  List<Category> _sortedCategories = const [];

  @override
  void initState() {
    super.initState();
    // Load the edited expense once, not on every rebuild.
    if (isEdit) {
      controller.loadExpenseForEdit(widget.expense!);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context).languageCode;
    if (locale != _sortedLocale ||
        _sortedCategories.length != controller.categories.length) {
      _sortedLocale = locale;
      _sortedCategories = _sortCategories(controller.categories, locale);
    }
  }

  /// "Autres / Other / أخرى" always goes last, the rest is alphabetical.
  static List<Category> _sortCategories(
      List<Category> categories, String locale) {
    bool isOther(Category c) {
      final name = c.getLocalizedName(locale).toLowerCase();
      return name.contains('autres') ||
          name.contains('other') ||
          name.contains('أخرى');
    }

    final sorted = List<Category>.from(categories);
    sorted.sort((a, b) {
      final aIsOther = isOther(a);
      final bIsOther = isOther(b);
      if (aIsOther != bIsOther) return aIsOther ? 1 : -1;
      return a
          .getLocalizedName(locale)
          .toLowerCase()
          .compareTo(b.getLocalizedName(locale).toLowerCase());
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isSmallScreen = screenWidth < 360;
    final radius = isSmallScreen ? 16.0 : 20.0;

    final sectionLabelStyle = GoogleFonts.barlow(
      color: AppColors.textSecondary,
      fontSize: isSmallScreen ? 12 : 14,
      fontWeight: FontWeight.w600,
    );
    final errorStyle = GoogleFonts.barlow(
      color: AppColors.errorColor,
      fontSize: isSmallScreen ? 10 : 11,
    );

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 20,
        vertical: isSmallScreen ? 20 : 24,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
      backgroundColor: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: mediaQuery.size.height * 0.80,
          maxWidth: 600,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(l10n, isSmallScreen, radius),

            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                physics: const ClampingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.translate('category'), style: sectionLabelStyle),
                    SizedBox(height: isSmallScreen ? 6 : 8),
                    _buildCategoryGrid(isSmallScreen),
                    Obx(() {
                      final error = controller.categoryError.value;
                      if (error == null) return const SizedBox.shrink();
                      return Padding(
                        padding: EdgeInsets.only(top: isSmallScreen ? 4 : 6),
                        child: Text(error, style: errorStyle),
                      );
                    }),
                    SizedBox(height: isSmallScreen ? 16 : 20),

                    // Amount
                    Obx(() => CustomTextField(
                          controller: controller.expenseAmountController,
                          labelText: l10n.translate('amount'),
                          hintText: '0.000',
                          errorText: controller.amountError.value,
                          isNumber: true,
                          allowDecimals: true,
                          allowNegative: false,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          textInputAction: TextInputAction.next,
                          prefixText: '${l10n.translate('currencySymbol')} ',
                          onChanged: (value) => _validateAmount(value, l10n),
                        )),
                    SizedBox(height: isSmallScreen ? 24 : 30),

                    // Description
                    Obx(() => CustomTextFieldPresets.textArea(
                          controller: controller.expenseDescriptionController,
                          labelText:
                              '${l10n.translate('description')} (${l10n.translate('optional')})',
                          hintText: l10n.translate('descriptionHint'),
                          errorText: controller.descriptionError.value,
                          maxLines: 3,
                          onChanged: (_) =>
                              controller.descriptionError.value = null,
                        )),
                    SizedBox(height: isSmallScreen ? 16 : 20),

                    // Date and time
                    Text(
                      l10n.translate('dateAndTime'),
                      style: sectionLabelStyle,
                    ),
                    SizedBox(height: isSmallScreen ? 8 : 10),
                    _buildDateTimeField(isSmallScreen),
                    Obx(() {
                      final error = controller.timeError.value;
                      if (error == null) return const SizedBox.shrink();
                      return Padding(
                        padding: EdgeInsets.only(top: isSmallScreen ? 4 : 6),
                        child: Text(error, style: errorStyle),
                      );
                    }),
                  ],
                ),
              ),
            ),

            _buildActions(l10n, isSmallScreen, radius),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
      AppLocalizations l10n, bool isSmallScreen, double radius) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.baseColor, AppColors.blackLight],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(radius),
          topRight: Radius.circular(radius),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isEdit ? Icons.edit : Icons.receipt_long,
              color: Colors.white,
              size: isSmallScreen ? 18 : 20,
            ),
          ),
          SizedBox(width: isSmallScreen ? 10 : 12),
          Expanded(
            child: Text(
              isEdit
                  ? l10n.translate('editExpense')
                  : l10n.translate('addExpense'),
              style: GoogleFonts.barlow(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: isSmallScreen ? 16 : 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid(bool isSmallScreen) {
    final spacing = isSmallScreen ? 6.0 : 8.0;

    return RepaintBoundary(
      child: Obx(() {
        // Keep the cached sort in sync when categories arrive/change.
        if (_sortedCategories.length != controller.categories.length) {
          _sortedCategories =
              _sortCategories(controller.categories, _sortedLocale);
        }
        final categories = _sortedCategories;

        return LayoutBuilder(
          builder: (context, constraints) {
            final cellWidth = (constraints.maxWidth - spacing * 2) / 3;
            final iconSize = (cellWidth * 0.58).clamp(36.0, 60.0);
            final labelHeight = isSmallScreen ? 28.0 : 32.0;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                mainAxisExtent: iconSize + labelHeight + 12,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) => _CategoryTile(
                category: categories[index],
                iconSize: iconSize,
                isSmallScreen: isSmallScreen,
                controller: controller,
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildDateTimeField(bool isSmallScreen) {
    return Obx(() => InkWell(
          borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
          onTap: () {
            FocusScope.of(context).unfocus();
            _selectDateTime(context);
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 10 : 12,
              vertical: isSmallScreen ? 12 : 14,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
              border: Border.all(
                color: controller.timeError.value != null
                    ? AppColors.errorColor
                    : AppColors.borderColor,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.event,
                  size: isSmallScreen ? 16 : 18,
                  color: AppColors.brandBlue,
                ),
                SizedBox(width: isSmallScreen ? 8 : 10),
                Expanded(
                  child: Text(
                    DateFormatter.formatDateTime(
                      DateTime(
                        controller.expenseDate.value.year,
                        controller.expenseDate.value.month,
                        controller.expenseDate.value.day,
                        controller.expenseTime.value.hour,
                        controller.expenseTime.value.minute,
                      ),
                      context,
                    ),
                    style: GoogleFonts.barlow(
                      fontSize: isSmallScreen ? 12 : 14,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: isSmallScreen ? 12 : 14,
                  color: AppColors.textPrimary,
                ),
              ],
            ),
          ),
        ));
  }

  Widget _buildActions(
      AppLocalizations l10n, bool isSmallScreen, double radius) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(radius),
          bottomRight: Radius.circular(radius),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 48,
              child: TextButton(
                onPressed: () {
                  controller.resetExpenseForm();
                  Navigator.pop(context);
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 8 : 12),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(isSmallScreen ? 8 : 10),
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    l10n.translate('cancel'),
                    maxLines: 1,
                    style: GoogleFonts.barlow(
                      color: AppColors.textSecondary,
                      fontSize: isSmallScreen ? 13 : 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: isSmallScreen ? 8 : 12),
          Expanded(
            flex: 2,
            child: Obx(() {
              final isLoading = isEdit
                  ? controller.isUpdatingExpense.value
                  : controller.isAddingExpense.value;

              return CustomElevatedButton(
                onPressed: isLoading ? null : () => _handleSubmit(context),
                text: isEdit
                    ? l10n.translate('update')
                    : l10n.translate('add'),
                isLoading: isLoading,
                loadingText: isEdit
                    ? l10n.translate('updating')
                    : l10n.translate('adding'),
                backgroundColor: AppColors.buttonBg,
                elevation: 4.0,
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 10 : 16,
                  vertical: 12,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _validateAmount(String value, AppLocalizations l10n) {
    controller.amountError.value = null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      controller.amountError.value = l10n.translate('Amountisrequired');
      return;
    }
    final amount = double.tryParse(trimmed);
    if (amount == null || amount <= 0) {
      controller.amountError.value = l10n.translate('Pleaseenteravalidamount');
    }
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();

    final pickedDate = await showAppDatePicker(
      context: context,
      initialDate: controller.expenseDate.value,
      firstDate: DateTime(2020),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.brandBlue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && context.mounted) {
      final pickedTime = await ModernTimePicker.show(
        context,
        DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          controller.expenseTime.value.hour,
          controller.expenseTime.value.minute,
        ),
        l10n,
      );

      if (pickedTime != null) {
        controller.expenseDate.value = pickedDate;
        controller.expenseTime.value = pickedTime;
        controller.timeError.value = null;
      }
    }
  }

  Future<void> _handleSubmit(BuildContext context) async {
    final l10n = AppLocalizations.of(context);

    // Validate amount
    final amountText = controller.expenseAmountController.text.trim();
    if (amountText.isEmpty) {
      controller.amountError.value = l10n.translate('Amountisrequired');
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      controller.amountError.value = l10n.translate('Pleaseenteravalidamount');
      return;
    }

    // Validate category
    if (controller.selectedCategory.value == null) {
      controller.categoryError.value = l10n.translate('Categoryisrequired');
      return;
    }

    final category = controller.selectedCategory.value!;
    final date = DateTime(
      controller.expenseDate.value.year,
      controller.expenseDate.value.month,
      controller.expenseDate.value.day,
      controller.expenseTime.value.hour,
      controller.expenseTime.value.minute,
    );
    final description = controller.expenseDescriptionController.text.trim();

    // Store expense ID before closing dialog (for update operation)
    final expenseId = widget.expense?.id;

    // Close dialog immediately
    if (context.mounted) {
      Navigator.pop(context);
    }

    // Execute API call in background
    try {
      if (isEdit && expenseId != null) {
        await controller.updateExpense(
          expenseId: expenseId,
          amount: amount,
          categoryId: category.id,
          date: date,
          description: description.isEmpty ? null : description,
        );
      } else {
        await controller.addExpense(
          amount: amount,
          categoryId: category.id,
          date: date,
          description: description.isEmpty ? null : description,
        );
      }

      CustomSnackBar.close();
      if (Get.context != null) {
        CustomSnackBar.success(
          title: l10n.translate('Success'),
          message: isEdit
              ? l10n.translate('expenseUpdated')
              : l10n.translate('expenseAdded'),
        );
      }
    } catch (e) {
      _showErrorSnackBar(e, l10n);
    }
  }

  /// Kept synchronous so the snackbar resolves a live context instead of the
  /// dialog's, which is already gone by the time the request fails.
  void _showErrorSnackBar(Object error, AppLocalizations l10n) {
    CustomSnackBar.close();
    final rootContext = Get.context;
    if (rootContext == null) return;
    CustomSnackBar.error(
      title: l10n.translate('Error'),
      message: friendlyErrorMessage(
        rootContext,
        error,
        fallbackKey: isEdit ? 'expenseUpdateError' : 'expenseAddError',
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final Category category;
  final double iconSize;
  final bool isSmallScreen;
  final WalletController controller;

  const _CategoryTile({
    required this.category,
    required this.iconSize,
    required this.isSmallScreen,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final label = category.getLocalizedName(locale);

    return Obx(() {
      final isSelected = controller.selectedCategory.value?.id == category.id;

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusScope.of(context).unfocus();
          controller.selectedCategory.value = category;
          controller.categoryError.value = null;
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.fastOutSlowIn,
          decoration: BoxDecoration(
            color:
                isSelected ? const Color(0xFFEAF2FF) : AppColors.surfaceColor,
            borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
            border: Border.all(
              color: isSelected ? AppColors.brandBlue : Colors.transparent,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CategoryIcon(
                category: category,
                size: iconSize,
                fallbackColor:
                    isSelected ? AppColors.brandBlue : AppColors.textSecondary,
              ),
              SizedBox(height: isSmallScreen ? 2 : 4),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    label,
                    style: GoogleFonts.barlow(
                      fontSize: isSmallScreen ? 10 : 11,
                      height: 1.15,
                      color: isSelected
                          ? AppColors.brandBlue
                          : AppColors.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
