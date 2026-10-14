import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taxi_driver_app/core/theme/app_colors.dart';
import 'package:taxi_driver_app/core/theme/text_styles.dart';
import 'package:taxi_driver_app/features/profile/application/profile_controller.dart';
import 'package:taxi_driver_app/features/profile/application/profile_screen_controller.dart';
import 'package:taxi_driver_app/features/profile/presentation/widgets/profile_header.dart';
import 'package:taxi_driver_app/features/profile/presentation/widgets/profile_widgets.dart';
import 'package:taxi_driver_app/features/profile/presentation/widgets/profile_dialogs.dart';
import 'package:taxi_driver_app/features/profile/presentation/widgets/expandable_car_card.dart';
import 'package:taxi_driver_app/l10n/app_localizations.dart';
import 'package:taxi_driver_app/models/user.dart';
import 'package:taxi_driver_app/core/shared/snackbar.dart';
import 'package:taxi_driver_app/core/shared/custom_elevated_button.dart';
import 'package:taxi_driver_app/core/shared/loading_gif.dart';

class ProfileScreenNew extends GetView<ProfileController> {
  const ProfileScreenNew({super.key});

  @override
  Widget build(BuildContext context) {
    final ui = ProfileScreenController();
    final l10n = AppLocalizations.of(context);
    // Responsive helpers are used inside composed widgets; screen width check not needed here.

    // Initialize once on first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.initialize();
    });

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: AppColors.cardColor,
        elevation: 0,
        title: Text(
          l10n.translate('profile'),
          style: GoogleFonts.barlow(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        child: Obx(() {
          final state = controller.state.value;
          final user = state.user;
          final cars = state.cars;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with update name button
              ProfileHeader(
                user: user,
                onEditNameTap: user != null
                    ? () async {
                        await showDialog(
                          context: context,
                          builder: (_) => UpdateProfileDialog(
                            initialFname: user.fname,
                            initialLname: user.lname,
                            onSave: (fname, lname) async {
                              await ui.updateProfileInfo(fname, lname, context);
                              CustomSnackBar.success(
                                title: l10n.translate('success'),
                                message: l10n.translate('nameUpdated'),
                              );
                            },
                          ),
                        );
                      }
                    : null,
              ),
              Padding(
                padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Personal info
                    Text(
                      l10n.translate('personalInformation'),
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 12 : 16),
                    if (user != null)
                      PersonalInfoSection(
                          items: _buildPersonalInfoMap(context, user)),
                    SizedBox(height: isSmallScreen ? 20 : 24),
                    // Vehicles with preferences
                    if (state.isLoadingCars)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: LoadingGif(
                            width: 60,
                            height: 60,
                          ),
                        ),
                      )
                    else if (cars.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(l10n.translate('noVehiclesAvailable'),
                              style: AppTextStyles.bodyMedium.copyWith(
                                  fontSize: 16,
                                  color: AppColors.textSecondary)),
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.translate('vehicles'),
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontSize: isSmallScreen ? 16 : 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 12 : 16),
                          ...cars.asMap().entries.map((entry) {
                            final index = entry.key;
                            final car = entry.value;
                            final carId = car['car_id']?.toString() ?? '';
                            final carPrefs = state.carPreferences[carId];
                            final prefs = carPrefs?.toUserPreferences();

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: ExpandableCarCard(
                                key: ValueKey(carId),
                                car: car,
                                preferences: prefs,
                                showExpandable: cars.length > 1,
                                initiallyExpanded:
                                    cars.length > 1 && index == 0,
                                isSmallScreen: isSmallScreen,
                                translate: (key) => l10n.translate(key),
                                onSpeedTap: () async {
                                  await showSpeedAlertDialog(
                                    context,
                                    initial: prefs?.speedAlert,
                                    onSave: (speed) async {
                                      await ui.updateCarPreferences(carId,
                                          {'speed_alert': speed}, context);
                                      _showSnack(context,
                                          l10n.translate('preferencesUpdated'));
                                    },
                                  );
                                },
                                onSpeedChanged: (enabled) async {
                                  if (enabled) {
                                    await showSpeedAlertDialog(
                                      context,
                                      initial: prefs?.speedAlert,
                                      onSave: (speed) async {
                                        await ui.updateCarPreferences(carId,
                                            {'speed_alert': speed}, context);
                                        _showSnack(
                                            context,
                                            l10n.translate(
                                                'preferencesUpdated'));
                                      },
                                    );
                                  } else {
                                    await ui.updateCarPreferences(
                                        carId, {'speed_alert': null}, context);
                                    _showSnack(context,
                                        l10n.translate('preferencesUpdated'));
                                  }
                                },
                                onFreeStatusTap: () async {
                                  await showDialog(
                                    context: context,
                                    builder: (_) => FreeStatusAlertDialog(
                                      initialDistance:
                                          prefs?.freeStatusAlert?.distance,
                                      initialDuration:
                                          prefs?.freeStatusAlert?.duration,
                                      onSave: (distance, duration) async {
                                        await ui.updateCarPreferences(
                                            carId,
                                            {
                                              'free_status_alert': {
                                                if (distance != null)
                                                  'distance': distance,
                                                if (duration != null)
                                                  'duration': duration,
                                              }
                                            },
                                            context);
                                        _showSnack(
                                            context,
                                            l10n.translate(
                                                'preferencesUpdated'));
                                      },
                                    ),
                                  );
                                },
                                onFreeStatusChanged: (enabled) async {
                                  if (enabled) {
                                    await showDialog(
                                      context: context,
                                      builder: (_) => FreeStatusAlertDialog(
                                        initialDistance:
                                            prefs?.freeStatusAlert?.distance,
                                        initialDuration:
                                            prefs?.freeStatusAlert?.duration,
                                        onSave: (distance, duration) async {
                                          await ui.updateCarPreferences(
                                              carId,
                                              {
                                                'free_status_alert': {
                                                  if (distance != null)
                                                    'distance': distance,
                                                  if (duration != null)
                                                    'duration': duration,
                                                }
                                              },
                                              context);
                                          _showSnack(
                                              context,
                                              l10n.translate(
                                                  'preferencesUpdated'));
                                        },
                                      ),
                                    );
                                  } else {
                                    await ui.updateCarPreferences(
                                        carId,
                                        {
                                          'free_status_alert': {
                                            'distance': null,
                                            'duration': null,
                                          }
                                        },
                                        context);
                                    _showSnack(context,
                                        l10n.translate('preferencesUpdated'));
                                  }
                                },
                                onStopTap: () async {
                                  await showDialog(
                                    context: context,
                                    builder: (_) => StopAlertDialog(
                                      initialMinutes: prefs?.stopAlert,
                                      onSave: (m) async {
                                        await ui.updateCarPreferences(
                                            carId, {'stop_alert': m}, context);
                                        _showSnack(
                                            context,
                                            l10n.translate(
                                                'preferencesUpdated'));
                                      },
                                    ),
                                  );
                                },
                                onStopChanged: (enabled) async {
                                  if (enabled) {
                                    await showDialog(
                                      context: context,
                                      builder: (_) => StopAlertDialog(
                                        initialMinutes: prefs?.stopAlert,
                                        onSave: (m) async {
                                          await ui.updateCarPreferences(carId,
                                              {'stop_alert': m}, context);
                                          _showSnack(
                                              context,
                                              l10n.translate(
                                                  'preferencesUpdated'));
                                        },
                                      ),
                                    );
                                  } else {
                                    await ui.updateCarPreferences(
                                        carId, {'stop_alert': null}, context);
                                    _showSnack(context,
                                        l10n.translate('preferencesUpdated'));
                                  }
                                },
                                onGeoTap: () async {
                                  final current =
                                      prefs?.isGeoForcingEnabled ?? false;
                                  await ui.updateCarPreferences(carId,
                                      {'geo_forcing_alert': !current}, context);
                                  _showSnack(context,
                                      l10n.translate('preferencesUpdated'));
                                },
                                onGeoChanged: (enabled) async {
                                  await ui.updateCarPreferences(carId,
                                      {'geo_forcing_alert': enabled}, context);
                                  _showSnack(context,
                                      l10n.translate('preferencesUpdated'));
                                },
                                onOpenDoorChanged: (v) async {
                                  await ui.updateCarPreferences(
                                      carId, {'open_door': v}, context);
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    if (user != null) ...[
                      ProfileActionsCard(
                        onEditNameTap: () async {
                          await showDialog(
                            context: context,
                            builder: (_) => UpdateProfileDialog(
                              initialFname: user.fname,
                              initialLname: user.lname,
                              onSave: (fname, lname) async {
                                await ui.updateProfileInfo(
                                    fname, lname, context);
                                _showSnack(
                                  context,
                                  l10n.translate('nameUpdated'),
                                );
                              },
                            ),
                          );
                        },
                        onChangeContactTap: () async {
                          await showDialog(
                            context: context,
                            builder: (_) => ChangeContactDialog(
                              onRequestOtp: (phone, email) async {
                                await ui.requestProfileChangeOtp(
                                  phone,
                                  email,
                                  context,
                                );
                              },
                              onVerifyOtp: (phone, email, otp) async {
                                await ui.verifyProfileChangeOtp(
                                  phone,
                                  email,
                                  otp,
                                  context,
                                );
                                CustomSnackBar.success(
                                  title: l10n.translate('success'),
                                  message: l10n.translate('contactUpdated'),
                                );
                              },
                            ),
                          );
                        },
                      ),
                      SizedBox(height: isSmallScreen ? 16 : 20),
                    ],

                    // Security: Update password
                    PasswordSectionCard(
                      onTap: () async {
                        await showDialog(
                          context: context,
                          builder: (_) => UpdatePasswordDialog(
                            onSave: (oldPwd, newPwd) async {
                              await ui.updatePassword(oldPwd, newPwd, context);
                              _showSnack(
                                  context, l10n.translate('passwordUpdated'));
                            },
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Remote actions - Stop card
                    RemoteStopCard(cars: cars, controller: ui),

                    const SizedBox(height: 24),

                    // Remote actions - Start card
                    RemoteStartCard(cars: cars, controller: ui),

                    const SizedBox(height: 24),

                    // Language
                    const LanguageSection(),

                    const SizedBox(height: 24),

                    // Logout button

                    SizedBox(
                      width: double.infinity,
                      child: CustomElevatedButtonPresets.danger(
                        text: l10n.translate('logout'),
                        icon: Icons.logout,
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (_) => const LogoutConfirmDialog(
                              onConfirm: null,
                            ),
                          );
                          if (confirmed == true) {
                            await ui.handleLogout();
                            // Use GetX navigation to ensure bindings are executed
                            Get.offAllNamed('/login');
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Map<String, String> _buildPersonalInfoMap(BuildContext context, User user) {
    final l10n = AppLocalizations.of(context);
    // The backend returns the phone with the country code (e.g. +216...).
    // For display we strip the country code if present and any common
    // separators so the UI shows the local number only.
    String stripCountryCode(String? phone) {
      if (phone == null || phone.trim().isEmpty) return '-';
      // Remove common separators and whitespace
      var normalized = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
      // Remove leading plus if present
      if (normalized.startsWith('+')) normalized = normalized.substring(1);
      // If it starts with the Tunisian country code (216), strip it
      if (normalized.startsWith('216')) {
        normalized = normalized.substring(3);
      }
      // Trim any remaining leading zeros introduced by formatting
      while (normalized.startsWith('0')) {
        normalized = normalized.substring(1);
      }
      return normalized.isEmpty ? '-' : normalized;
    }

    return {
      l10n.translate('fullName'): user.fullName,
      if (user.email != null && user.email!.trim().isNotEmpty)
        l10n.translate('email'): user.email!,
      l10n.translate('phoneNumber'): stripCountryCode(user.fullPhone),
      l10n.translate('cin'): user.cin ?? '-',
    };
  }

  void _showSnack(BuildContext context, String message) {
    CustomSnackBar.info(
      title: 'Info',
      message: message,
    );
  }
}

/// Ensures required provider overrides exist when navigating directly
class ProfileScreenShell extends StatelessWidget {
  const ProfileScreenShell({super.key});

  @override
  Widget build(BuildContext context) {
    // With GetX, bindings should be registered at route level.
    // This shell now just returns the screen.
    return const ProfileScreenNew();
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: AppTextStyles.bodyMedium
            .copyWith(fontSize: 18, fontWeight: FontWeight.bold));
  }
}

class RemoteStopCard extends StatelessWidget {
  final List<Map<String, dynamic>> cars;
  final ProfileScreenController controller;

  const RemoteStopCard({
    super.key,
    required this.cars,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    // Filter cars that can be stopped
    final stoppableCars = cars.where((car) {
      final action = car['action']?.toString().toLowerCase();
      return action == null || action == 'go';
    }).toList();

    final isEnabled = stoppableCars.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Opacity(
                  opacity: isEnabled ? 1.0 : 0.45,
                  child: Image.asset(
                    'assets/images/icons8-start-94.png',
                    width: isSmallScreen ? 28 : 32,
                    height: isSmallScreen ? 28 : 32,
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 8 : 12),
                Expanded(
                  child: Text(
                    l10n.translate('remoteStop'),
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      color: isEnabled
                          ? AppColors.textPrimary
                          : AppColors.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 8 : 12),
            Text(
              l10n.translate('remoteStopDescription'),
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: isSmallScreen ? 13 : 14,
                color: isEnabled
                    ? AppColors.textSecondary
                    : AppColors.textTertiary,
              ),
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            Opacity(
              opacity: isEnabled ? 1.0 : 0.5,
              child: SizedBox(
                width: double.infinity,
                child: CustomElevatedButtonPresets.danger(
                  text: l10n.translate('activateRemoteStop'),
                  onPressed: () {
                    if (!isEnabled) return;
                    showDialog(
                      context: context,
                      builder: (_) => RemoteActionDialog(
                        cars: stoppableCars,
                        title: l10n.translate('remoteStop'),
                        warningText: l10n.translate('remoteStopWarning'),
                        color: AppColors.errorColor,
                        buttonLabel: l10n.translate('deactivate'),
                        onConfirm: (carId) async {
                          await controller.remoteStop(carId);
                          CustomSnackBar.success(
                            title: l10n.translate('success'),
                            message: l10n.translate('remoteStopActivated'),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RemoteStartCard extends StatelessWidget {
  final List<Map<String, dynamic>> cars;
  final ProfileScreenController controller;

  const RemoteStartCard({
    super.key,
    required this.cars,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    // Filter cars that can be started
    final startableCars = cars.where((car) {
      final action = car['action']?.toString().toLowerCase();
      return action == 'stop';
    }).toList();

    final isEnabled = startableCars.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Opacity(
                  opacity: isEnabled ? 1.0 : 0.45,
                  child: Image.asset(
                    'assets/images/icons8-start-94 (1).png',
                    width: isSmallScreen ? 28 : 32,
                    height: isSmallScreen ? 28 : 32,
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 8 : 12),
                Expanded(
                  child: Text(
                    l10n.translate('remoteStart'),
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      color: isEnabled
                          ? AppColors.textPrimary
                          : AppColors.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 8 : 12),
            Text(
              l10n.translate('remoteStartDescription'),
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: isSmallScreen ? 13 : 14,
                color: isEnabled
                    ? AppColors.textSecondary
                    : AppColors.textTertiary,
              ),
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            Opacity(
              opacity: isEnabled ? 1.0 : 0.5,
              child: SizedBox(
                width: double.infinity,
                child: CustomElevatedButtonPresets.success(
                  text: l10n.translate('activateRemoteStart'),
                  onPressed: () {
                    if (!isEnabled) return;
                    showDialog(
                      context: context,
                      builder: (_) => RemoteActionDialog(
                        cars: startableCars,
                        title: l10n.translate('remoteStart'),
                        warningText: l10n.translate('remoteStartWarning'),
                        color: AppColors.secondaryVariant,
                        buttonLabel: l10n.translate('activate'),
                        onConfirm: (carId) async {
                          await controller.remoteStart(carId);
                          CustomSnackBar.success(
                            title: l10n.translate('success'),
                            message: l10n.translate('remoteStartActivated'),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
