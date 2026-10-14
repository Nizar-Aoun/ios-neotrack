class Expense {
  final String id;
  final String carId;
  final double amount;
  final DateTime date;
  final String categoryId;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;

  Expense({
    required this.id,
    required this.carId,
    required this.amount,
    required this.date,
    required this.categoryId,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    // Helper function to safely get a string ID from either format
    String getStringId(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      if (value is Map && value.containsKey('\$oid')) return value['\$oid'];
      return value.toString();
    }

    // Helper function to safely parse a date from either format
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is String) return DateTime.parse(value);
      if (value is Map && value.containsKey('\$date')) {
        final dateStr = value['\$date'];
        if (dateStr is String) return DateTime.parse(dateStr);
        if (dateStr is int) return DateTime.fromMillisecondsSinceEpoch(dateStr);
      }
      return DateTime.now();
    }

    // Helper function to safely get a double from a number
    double getDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return Expense(
      id: getStringId(json['_id']),
      carId: getStringId(json['id_car']),
      amount: getDouble(json['amount']),
      date: parseDate(json['date']),
      categoryId: (() {
        final cat = json['id_category'];
        if (cat == null) return '';
        if (cat is String) return cat;
        if (cat is Map) {
          // Handle both MongoDB format and regular object format
          if (cat['_id'] != null) {
            if (cat['_id'] is Map && cat['_id']['\$oid'] != null) {
              return cat['_id']['\$oid'];
            }
            return cat['_id'].toString();
          }
          // If it's a direct category object with id
          if (cat['id'] != null) return cat['id'].toString();
        }
        return '';
      })(),
      description: json['description']?.toString() ?? '',
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'id_car': carId,
      'amount': amount,
      'date': date.toIso8601String(),
      'id_category': categoryId,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
