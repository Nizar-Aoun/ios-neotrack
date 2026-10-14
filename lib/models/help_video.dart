class HelpVideo {
  final String id;
  final String title;
  final String description;
  final String youtubeUrl;
  final String thumbnail;
  final String category;
  final String language;
  final int duration;
  final bool isActive;
  final int order;
  final List<String> tags;
  final int viewCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  HelpVideo({
    required this.id,
    required this.title,
    required this.description,
    required this.youtubeUrl,
    required this.thumbnail,
    required this.category,
    required this.language,
    required this.duration,
    required this.isActive,
    required this.order,
    required this.tags,
    required this.viewCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HelpVideo.fromJson(Map<String, dynamic> json) {
    // Handle different _id formats
    String parseId(dynamic id) {
      if (id is String) return id;
      if (id is Map && id['\$oid'] != null) return id['\$oid'];
      return '';
    }

    // Handle different date formats
    DateTime parseDate(dynamic date) {
      if (date is String) {
        try {
          return DateTime.parse(date);
        } catch (e) {
          return DateTime.now();
        }
      }
      if (date is Map && date['\$date'] != null) {
        try {
          return DateTime.parse(date['\$date']);
        } catch (e) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    return HelpVideo(
      id: parseId(json['_id']),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      youtubeUrl: json['youtubeUrl'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
      category: json['category'] ?? '',
      language: json['language'] ?? 'fr',
      duration: json['duration'] ?? 0,
      isActive: json['isActive'] ?? true,
      order: json['order'] ?? 0,
      tags: List<String>.from(json['tags'] ?? []),
      viewCount: json['viewCount'] ?? 0,
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': {'\$oid': id},
      'title': title,
      'description': description,
      'youtubeUrl': youtubeUrl,
      'thumbnail': thumbnail,
      'category': category,
      'language': language,
      'duration': duration,
      'isActive': isActive,
      'order': order,
      'tags': tags,
      'viewCount': viewCount,
      'createdAt': {'\$date': createdAt.toIso8601String()},
      'updatedAt': {'\$date': updatedAt.toIso8601String()},
    };
  }

  // Helper method to get formatted duration
  String get formattedDuration {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Helper method to get category display name
  String getCategoryDisplayName(String language) {
    final categoryMap = {
      'fr': {
        'general': 'Général',
        'getting_started': 'Démarrage',
        'gps_tracking': 'Suivi GPS',
        'wallet_management': 'Gestion du portefeuille',
        'settings': 'Paramètres',
        'dashcam': 'Dashcam',
        'alerts': 'Alertes',
        'navigation': 'Navigation',
        'maintenance': 'Maintenance',
        'safety': 'Sécurité',
      },
      'ar': {
        'general': 'عام',
        'getting_started': 'البداية',
        'gps_tracking': 'تتبع GPS',
        'wallet_management': 'إدارة المحفظة',
        'settings': 'الإعدادات',
        'dashcam': 'داشكام',
        'alerts': 'التنبيهات',
        'navigation': 'التنقل',
        'maintenance': 'الصيانة',
        'safety': 'الأمان',
      },
    };

    return categoryMap[language]?[category] ?? category;
  }

  // Helper method to get category color
  String getCategoryColor() {
    final colorMap = {
      'general': '#2196F3',
      'getting_started': '#4CAF50',
      'gps_tracking': '#FF9800',
      'wallet_management': '#9C27B0',
      'settings': '#607D8B',
      'dashcam': '#E91E63',
      'alerts': '#F44336',
      'navigation': '#3F51B5',
      'maintenance': '#795548',
      'safety': '#FF5722',
    };

    return colorMap[category] ?? '#2196F3';
  }

  @override
  String toString() {
    return 'HelpVideo(id: $id, title: $title, category: $category, language: $language)';
  }
} 