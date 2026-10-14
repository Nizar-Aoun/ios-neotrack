import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Utility class for formatting dates with locale support, especially Arabic
class DateFormatter {
  /// Arabic month names
  static const Map<int, String> arabicMonths = {
    1: 'جانفي',
  2: 'فيفري',
  3: 'مارس',
  4: 'أفريل',
  5: 'ماي',
  6: 'جوان',
  7: 'جويلية',
  8: 'أوت',
  9: 'سبتمبر',
  10: 'أكتوبر',
  11: 'نوفمبر',
  12: 'ديسمبر',
  };

  /// Arabic month names (short)
  static const Map<int, String> arabicMonthsShort = {
    1: 'جان',
  2: 'فيف',
  3: 'مار',
  4: 'أفر',
  5: 'ماي',
  6: 'جوا',
  7: 'جوي',
  8: 'أوت',
  9: 'سبت',
  10: 'أكت',
  11: 'نوف',
  12: 'ديس',
  };

  /// Formats [date] for API query params, e.g. `2026-06-25T00:00:00.000Z`.
  static String toApiDateTimeParam(DateTime date) {
    return DateTime.utc(
      date.year,
      date.month,
      date.day,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
    ).toIso8601String();
  }

  /// Formats [date] as a date-only API query param, e.g. `2026-06-25`.
  static String toApiDateParam(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// Format date with time in the format: "dd MMM yyyy, HH:mm"
  /// Example: "15 Nov 2024, 14:30" or "15 نوفمبر 2024, 14:30" (Arabic)
  static String formatDateTime(DateTime date, BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;

    if (locale == 'ar') {
      // Arabic format
      final day = date.day.toString().padLeft(2, '0');
      final month = arabicMonths[date.month] ?? '';
      final year = date.year.toString();
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');

      return '$day $month $year, $hour:$minute';
    } else {
      // Default format for other languages
      return DateFormat('dd MMM yyyy, HH:mm', locale).format(date);
    }
  }

  /// Format date without time in the format: "dd MMM yyyy"
  /// Example: "15 Nov 2024" or "15 نوفمبر 2024" (Arabic)
  static String formatDate(DateTime date, BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;

    if (locale == 'ar') {
      // Arabic format
      final day = date.day.toString().padLeft(2, '0');
      final month = arabicMonths[date.month] ?? '';
      final year = date.year.toString();

      return '$day $month $year';
    } else {
      // Default format for other languages
      return DateFormat('dd MMM yyyy', locale).format(date);
    }
  }

  /// Format date with short month name: "dd MMM yyyy"
  /// Example: "15 Nov 2024" or "15 نوف 2024" (Arabic)
  static String formatDateShort(DateTime date, BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;

    if (locale == 'ar') {
      // Arabic format with short month
      final day = date.day.toString().padLeft(2, '0');
      final month = arabicMonthsShort[date.month] ?? '';
      final year = date.year.toString();

      return '$day $month $year';
    } else {
      // Default format for other languages
      return DateFormat('dd MMM yyyy', locale).format(date);
    }
  }

  /// Format time only: "HH:mm"
  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  /// Get month name in current locale
  static String getMonthName(int month, BuildContext context,
      {bool short = false}) {
    final locale = Localizations.localeOf(context).languageCode;

    if (locale == 'ar') {
      return short
          ? (arabicMonthsShort[month] ?? '')
          : (arabicMonths[month] ?? '');
    } else {
      final date = DateTime(2024, month, 1);
      return DateFormat(short ? 'MMM' : 'MMMM', locale).format(date);
    }
  }
}
