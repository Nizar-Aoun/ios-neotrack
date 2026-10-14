/// Represents the summary of wallet financial data
class WalletSummary {
  final double totalRevenue;
  final double totalExpenses;
  final double netBalance;
  final int rideCount;
  final int expenseCount;
  final Map<String, double>? revenueBreakdown;

  WalletSummary({
    required this.totalRevenue,
    required this.totalExpenses,
    required this.netBalance,
    required this.rideCount,
    required this.expenseCount,
    this.revenueBreakdown,
  });

  factory WalletSummary.empty() {
    return WalletSummary(
      totalRevenue: 0.0,
      totalExpenses: 0.0,
      netBalance: 0.0,
      rideCount: 0,
      expenseCount: 0,
    );
  }

  WalletSummary copyWith({
    double? totalRevenue,
    double? totalExpenses,
    double? netBalance,
    int? rideCount,
    int? expenseCount,
    Map<String, double>? revenueBreakdown,
  }) {
    return WalletSummary(
      totalRevenue: totalRevenue ?? this.totalRevenue,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      netBalance: netBalance ?? this.netBalance,
      rideCount: rideCount ?? this.rideCount,
      expenseCount: expenseCount ?? this.expenseCount,
      revenueBreakdown: revenueBreakdown ?? this.revenueBreakdown,
    );
  }
}

