/// Enum for transaction filtering options
enum TransactionFilter { all, revenue, expenses }

/// Enum for date filter types
enum DateFilterType { lastDay, lastWeek, lastMonth, personalized }

/// Extension to convert filter types to readable strings
extension TransactionFilterExtension on TransactionFilter {
  String get name {
    switch (this) {
      case TransactionFilter.all:
        return 'all';
      case TransactionFilter.revenue:
        return 'revenue';
      case TransactionFilter.expenses:
        return 'expenses';
    }
  }
}

extension DateFilterTypeExtension on DateFilterType {
  String get name {
    switch (this) {
      case DateFilterType.lastDay:
        return 'lastDay';
      case DateFilterType.lastWeek:
        return 'lastWeek';
      case DateFilterType.lastMonth:
        return 'lastMonth';
      case DateFilterType.personalized:
        return 'personalized';
    }
  }
}

