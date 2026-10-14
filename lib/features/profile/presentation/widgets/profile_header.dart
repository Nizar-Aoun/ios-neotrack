import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:taxi_driver_app/core/errors/error_messages.dart';
import 'package:taxi_driver_app/core/theme/app_colors.dart';
import 'package:taxi_driver_app/core/theme/text_styles.dart';
import 'package:taxi_driver_app/features/profile/application/profile_controller.dart';
import 'package:taxi_driver_app/models/user.dart';
import 'package:taxi_driver_app/core/shared/snackbar.dart';
import 'package:taxi_driver_app/core/shared/loading_gif.dart';

import '../../../../l10n/app_localizations.dart';

/// Profile header with avatar and user info
class ProfileHeader extends StatelessWidget {
  final User? user;
  final VoidCallback? onEditNameTap;

  const ProfileHeader({
    super.key,
    required this.user,
    this.onEditNameTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 24 : 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildAvatar(context, isSmallScreen),
          const SizedBox(height: 12),
          Text(
            user?.fullName ?? ' ',
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: isSmallScreen ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          if (onEditNameTap != null)
            Padding(
              padding: EdgeInsets.only(top: isSmallScreen ? 6 : 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onEditNameTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 8 : 12,
                      vertical: isSmallScreen ? 4 : 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: isSmallScreen ? 14 : 16,
                          color: AppColors.brandBlue,
                        ),
                        SizedBox(width: isSmallScreen ? 4 : 6),
                        Text(
                          l10n.translate('updateName'),
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontSize: isSmallScreen ? 12 : 13,
                            color: AppColors.brandBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar(
    BuildContext context,
    bool isSmallScreen,
  ) {
    final profileController = Get.find<ProfileController>();
    final state = profileController.state.value;

    return Stack(
      children: [
        if (state.isUploadingPhoto || state.isRemovingPhoto)
          Container(
            width: isSmallScreen ? 100 : 120,
            height: isSmallScreen ? 100 : 120,
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: LoadingGif(
                width: 60,
                height: 60,
              ),
            ),
          )
        else
          GestureDetector(
            onTap: () => _pickAndUploadImage(context),
            child: Container(
              width: isSmallScreen ? 100 : 120,
              height: isSmallScreen ? 100 : 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceMuted,
              ),
              child: user?.fullProfilePhotoUrl != null
                  ? ClipOval(
                      child: Image.network(
                        user!.fullProfilePhotoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildDefaultProfileIcon(isSmallScreen),
                      ),
                    )
                  : _buildDefaultProfileIcon(isSmallScreen),
            ),
          ),
        if (user?.profilePhoto != null &&
            !state.isUploadingPhoto &&
            !state.isRemovingPhoto)
          Positioned(
            left: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: () => _removeProfilePhoto(context),
              child: Container(
                padding: EdgeInsets.all(isSmallScreen ? 3 : 4),
                decoration: BoxDecoration(
                  color: AppColors.errorColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(
                  Icons.delete_outline,
                  size: isSmallScreen ? 16 : 20,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        if (!state.isUploadingPhoto && !state.isRemovingPhoto)
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: () => _pickAndUploadImage(context),
              child: Container(
                padding: EdgeInsets.all(isSmallScreen ? 3 : 4),
                decoration: BoxDecoration(
                  color: AppColors.brandBlue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(
                  Icons.camera_alt,
                  size: isSmallScreen ? 16 : 20,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDefaultProfileIcon(bool isSmallScreen) {
    final size = isSmallScreen ? 64.0 : 76.0;
    return Center(
      child: Image.asset(
        'assets/images/icons8-add-user-male-94.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }

  Future<void> _pickAndUploadImage(BuildContext context) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      final bytes = await pickedFile.readAsBytes();
      final filename = pickedFile.name.isNotEmpty
          ? pickedFile.name
          : 'profile_photo.jpg';

      final controller = Get.find<ProfileController>();
      await controller.uploadProfilePhoto(bytes, filename);

      if (context.mounted) {
        CustomSnackBar.success(
          title: AppLocalizations.of(context).translate('Success'),
          message:
              AppLocalizations.of(context).translate('profilePhotoUpdated'),
        );
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.error(
          title: AppLocalizations.of(context).translate('Error'),
          message: friendlyErrorMessage(
            context,
            e,
            fallbackKey: 'profilePhotoUploadFailed',
          ),
        );
      }
    }
  }

  Future<void> _removeProfilePhoto(BuildContext context) async {
    try {
      final controller = Get.find<ProfileController>();
      await controller.removeProfilePhoto();

      if (context.mounted) {
        CustomSnackBar.success(
          title: AppLocalizations.of(context).translate('Success'),
          message:
              AppLocalizations.of(context).translate('profilePhotoRemoved'),
        );
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.error(
          title: AppLocalizations.of(context).translate('Error'),
          message: friendlyErrorMessage(
            context,
            e,
            fallbackKey: 'profilePhotoRemoveFailed',
          ),
        );
      }
    }
  }
}
