import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:taxi_driver_app/features/help/data/help_repository.dart';
import 'package:taxi_driver_app/features/help/domain/help_video_model.dart';
import 'package:taxi_driver_app/core/controllers/language_controller.dart';

/// Help Controller - Manages help videos state with GetX
class HelpController extends GetxController {
  final HelpRepository _repository;

  HelpController(this._repository);

  // Observables
  final RxList<HelpVideoModel> videos = <HelpVideoModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxnString errorMessage = RxnString();

  // Get language from LanguageController
  String get currentLanguage {
    try {
      final langController = Get.find<LanguageController>();
      return langController.currentLocale.value.languageCode;
    } catch (e) {
      return 'fr'; // Default to French
    }
  }

  @override
  void onInit() {
    super.onInit();
    loadVideos();
  }

  /// Load help videos
  Future<void> loadVideos() async {
    try {
      isLoading.value = true;
      errorMessage.value = null;

      final fetchedVideos = await _repository.getHelpVideos(
        language: currentLanguage,
        limit: 50,
      );

      // Filter active videos and sort by order
      final activeVideos = fetchedVideos
          .where((video) => video.isActive)
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));

      videos.value = activeVideos;
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh videos
  Future<void> refreshVideos() async {
    await loadVideos();
  }

  /// Get videos by category
  List<HelpVideoModel> getVideosByCategory(String category) {
    return videos.where((video) => video.category == category).toList();
  }

  /// Increment view count for a video
  Future<void> incrementViewCount(String videoId) async {
    try {
      await _repository.incrementViewCount(videoId);

      // Update local view count
      final index = videos.indexWhere((v) => v.id == videoId);
      if (index != -1) {
        final video = videos[index];
        videos[index] = HelpVideoModel(
          id: video.id,
          title: video.title,
          description: video.description,
          youtubeUrl: video.youtubeUrl,
          thumbnail: video.thumbnail,
          category: video.category,
          language: video.language,
          duration: video.duration,
          isActive: video.isActive,
          order: video.order,
          tags: video.tags,
          viewCount: video.viewCount + 1,
          createdAt: video.createdAt,
          updatedAt: video.updatedAt,
        );
      }
    } catch (e) {
      // Don't show error to user - non-critical operation
    }
  }

  /// Clear error
  void clearError() {
    errorMessage.value = null;
  }
}

