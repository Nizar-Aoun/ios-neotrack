class Location {
  final String id;
  final List<double> coordinates;
  final DateTime timestamp;

  Location({
    required this.id,
    required this.coordinates,
    required this.timestamp,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    String parseId(dynamic id) {
      if (id is String) return id;
      if (id is Map && id.containsKey('_id')) return id['_id'];
      return id.toString();
    }

    DateTime parseDate(dynamic date) {
      if (date is String) {
        try {
          return DateTime.parse(date);
        } catch (e) {
          // Handle different date formats
          if (date.contains('T')) {
            return DateTime.parse(date);
          } else {
            // Try parsing as ISO format without timezone
            return DateTime.parse('${date}Z');
          }
        }
      }
      if (date is Map && date.containsKey('\$date')) {
        return DateTime.parse(date['\$date']);
      }
      return DateTime.parse(date.toString());
    }

    List<double> parseCoordinates(dynamic raw) {
      if (raw is! List) return const <double>[];
      return raw
          .map((value) {
            if (value is num) return value.toDouble();
            if (value is String) return double.tryParse(value);
            return null;
          })
          .whereType<double>()
          .toList();
    }

    return Location(
      id: parseId(json['_id']),
      coordinates: parseCoordinates(json['coordinates']),
      timestamp: parseDate(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'coordinates': coordinates,
      'timestamp': timestamp.toIso8601String(),
    };
  }
} 