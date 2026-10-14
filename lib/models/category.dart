class Category {
  final String id;
  final String name;
  final String icon;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String frName;
  final String arName;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.createdAt,
    required this.updatedAt,
    required this.frName,
    required this.arName,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
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

    return Category(
      id: getStringId(json['_id']),
      name: json['name']?.toString() ?? '',
      icon: json['icon']?.toString() ?? 'other',
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
      frName: json['fr_name']?.toString() ?? json['name']?.toString() ?? '',
      arName: json['ar_name']?.toString() ?? json['name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'icon': icon,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'fr_name': frName,
      'ar_name': arName,
    };
  }

  // Helper method to get the asset path for the category icon
  String get iconAssetPath => 'assets/images/${icon}.png';

  // Helper method to get the localized name based on the current locale
  String getLocalizedName(String locale) {
    switch (locale) {
      case 'fr':
        return frName;
      case 'ar':
        return arName;
      default:
        return name;
    }
  }
} 