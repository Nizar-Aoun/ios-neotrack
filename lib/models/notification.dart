import 'package:taxi_driver_app/l10n/app_localizations.dart';

class NotificationModel {
  final String id;
  final NotificationContent fr;
  final NotificationContent ar;
  final String? type;
  final String userId;
  final String carId;
  final bool seen;
  final List<double>? coordinates; // [longitude, latitude]
  final double? speed;
  final double? limit;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationModel({
    required this.id,
    required this.fr,
    required this.ar,
    this.type,
    required this.userId,
    required this.carId,
    required this.seen,
    this.coordinates,
    this.speed,
    this.limit,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    // Parse coordinates
    final coords = json['coordinates'] != null
        ? List<double>.from(
            json['coordinates'].map((e) => (e as num).toDouble()))
        : null;

    // Try to read speed/limit from structured data first
    double? speed = (json['data'] != null)
        ? (json['data']['speed'] as num?)?.toDouble()
        : (json['speed'] as num?)?.toDouble();
    double? limit = (json['data'] != null)
        ? (json['data']['limit'] as num?)?.toDouble()
        : (json['limit'] as num?)?.toDouble();

    // If structured fields are missing, try to extract numbers from the
    // localized content text (e.g. "Votre véhicule roule à 49 km/h... 40 km/h")
    if (speed == null || limit == null) {
      final frContent = (json['fr'] != null && json['fr']['content'] != null)
          ? json['fr']['content'].toString()
          : '';
      final arContent = (json['ar'] != null && json['ar']['content'] != null)
          ? json['ar']['content'].toString()
          : '';
      final contentToParse = frContent.isNotEmpty ? frContent : arContent;

      if (contentToParse.isNotEmpty) {
        final regex = RegExp(r"(\d+(?:[.,]\d+)?)\s*(?:km/h|kmh|كم/ساعة)",
            caseSensitive: false);
        final matches = regex
            .allMatches(contentToParse)
            .map((m) => m.group(1))
            .whereType<String>()
            .toList();

        if (matches.isNotEmpty) {
          // First numeric match is most likely the actual speed
          if (speed == null) {
            speed = double.tryParse(matches[0].replaceAll(',', '.'));
          }
          // Second numeric match is most likely the limit
          if (limit == null && matches.length > 1) {
            limit = double.tryParse(matches[1].replaceAll(',', '.'));
          }
        }

        // As a last resort, try to find "seuil" or "limit" followed by a number
        if (limit == null) {
          final limitRegex = RegExp(
              r"(?:seuil|limit|limite)\D*(\d+(?:[.,]\d+)?)",
              caseSensitive: false);
          final lm = limitRegex.firstMatch(contentToParse);
          if (lm != null && lm.groupCount >= 1) {
            limit = double.tryParse(lm.group(1)!.replaceAll(',', '.'));
          }
        }
      }
    }

    return NotificationModel(
      id: json['_id'] ?? json['id'],
      fr: NotificationContent.fromJson(json['fr']),
      ar: NotificationContent.fromJson(json['ar']),
      type: json['type'],
      userId: json['user_id'],
      carId: json['car_id'],
      seen: json['seen'] ?? false,
      coordinates: coords,
      speed: speed,
      limit: limit,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fr': fr.toJson(),
      'ar': ar.toJson(),
      'type': type,
      'user_id': userId,
      'car_id': carId,
      'seen': seen,
      'coordinates': coordinates,
      'data': {
        'speed': speed,
        'limit': limit,
      },
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String getTitle(String language) {
    return language == 'ar' ? ar.title : fr.title;
  }

  String getContent(String language) {
    return language == 'ar' ? ar.content : fr.content;
  }

  String getTimeAgo(AppLocalizations l10n) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return difference.inDays == 1
          ? 'Hier'
          : l10n.translate('Il y a ${difference.inDays} jours');
    } else if (difference.inHours > 0) {
      return l10n.translate('Il y a ${difference.inHours}h');
    } else if (difference.inMinutes > 0) {
      return l10n.translate('Il y a ${difference.inMinutes} min');
    } else {
      return l10n.translate('instantly');
    }
  }
}

class NotificationContent {
  final String title;
  final String content;

  NotificationContent({
    required this.title,
    required this.content,
  });

  factory NotificationContent.fromJson(Map<String, dynamic> json) {
    return NotificationContent(
      title: json['title'] ?? '',
      content: json['content'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
    };
  }
}
