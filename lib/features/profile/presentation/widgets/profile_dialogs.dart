import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:slide_to_act/slide_to_act.dart';
import 'package:taxi_driver_app/core/shared/snackbar.dart';
import 'package:taxi_driver_app/core/theme/app_colors.dart';
import 'package:taxi_driver_app/core/theme/text_styles.dart';
import 'package:taxi_driver_app/features/profile/presentation/widgets/speed_alert_dialog.dart';
import 'package:taxi_driver_app/l10n/app_localizations.dart';
import 'package:taxi_driver_app/models/user.dart';
import 'package:taxi_driver_app/features/profile/presentation/widgets/profile_text_helper.dart';
import 'package:taxi_driver_app/core/shared/custom_filed.dart';
import 'package:taxi_driver_app/core/shared/custom_elevated_button.dart';

/// Simple confirm dialog for logout
class LogoutConfirmDialog extends StatelessWidget {
  final VoidCallback? onConfirm;
  const LogoutConfirmDialog({super.key, this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isSmall = MediaQuery.of(context).size.width < 360;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: Container(
        constraints: BoxConstraints(maxWidth: isSmall ? 280 : 320),
        padding: EdgeInsets.all(isSmall ? 16 : 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.translate('logout'),
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: isSmall ? 16 : 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: isSmall ? 10 : 16),
            Text(
              localizations.translate('logoutConfirmation'),
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: isSmall ? 13 : 16,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: isSmall ? 14 : 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Flexible(
                  child: DialogCancelButton(
                    onPressed: () => Navigator.pop(context, false),
                    label: localizations.translate('cancel'),
                    isSmallScreen: true,
                  ),
                ),
                Flexible(
                  child: DialogSaveButton(
                    onPressed: () {
                      Navigator.pop(context, true);
                    },
                    label: localizations.translate('logout'),
                    backgroundColor: AppColors.errorColor,
                    isSmallScreen: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Free Status Alert dialog
class FreeStatusAlertDialog extends StatefulWidget {
  final double? initialDistance;
  final int? initialDuration;
  final void Function(double? distance, int? duration) onSave;

  const FreeStatusAlertDialog({
    super.key,
    this.initialDistance,
    this.initialDuration,
    required this.onSave,
  });

  @override
  State<FreeStatusAlertDialog> createState() => _FreeStatusAlertDialogState();
}

class _FreeStatusAlertDialogState extends State<FreeStatusAlertDialog> {
  late final TextEditingController distanceController;
  late final TextEditingController durationController;
  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    distanceController =
        TextEditingController(text: widget.initialDistance?.toString() ?? '');
    durationController =
        TextEditingController(text: widget.initialDuration?.toString() ?? '');
  }

  @override
  void dispose() {
    distanceController.dispose();
    durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isSmall = MediaQuery.of(context).size.width < 360;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: Container(
        constraints: BoxConstraints(maxWidth: isSmall ? 280 : 320),
        padding: EdgeInsets.all(isSmall ? 16 : 24),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.translate('freeStatusAlert'),
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: isSmall ? 18 : 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.translate('enterFreeStatusLimits'),
                style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: isSmall ? 12 : 14,
                    color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: distanceController,
                labelText: l10n.translate('distanceLimit'),
                hintText: '0.0',
                suffixText: l10n.translate('kmDriven'),
                isNumber: true,
                allowDecimals: true,
                allowNegative: false,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if ((value == null || value.isEmpty) &&
                      durationController.text.isEmpty) {
                    return l10n.translate('atLeastOneRequired');
                  }
                  if (value != null && value.isNotEmpty) {
                    final d = double.tryParse(value);
                    if (d == null || d <= 0) {
                      return l10n.translate('mustBeGreaterThanZero');
                    }
                  }
                  return null;
                },
                borderRadius: 12,
                filled: true,
                fillColor: AppColors.surfaceColor,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: durationController,
                labelText: l10n.translate('durationLimit'),
                hintText: '0',
                suffixText: l10n.translate('min'),
                isNumber: true,
                allowDecimals: false,
                allowNegative: false,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if ((value == null || value.isEmpty) &&
                      distanceController.text.isEmpty) {
                    return l10n.translate('atLeastOneRequired');
                  }
                  if (value != null && value.isNotEmpty) {
                    final t = int.tryParse(value);
                    if (t == null || t <= 0) {
                      return l10n.translate('mustBeGreaterThanZero');
                    }
                  }
                  return null;
                },
                borderRadius: 12,
                filled: true,
                fillColor: AppColors.surfaceColor,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  DialogCancelButton(
                    onPressed: () => Navigator.pop(context),
                    label: l10n.translate('cancel'),
                    isSmallScreen: isSmall,
                  ),
                  SizedBox(width: isSmall ? 8 : 12),
                  DialogSaveButton(
                    onPressed: () {
                      if (formKey.currentState?.validate() ?? false) {
                        final distance = distanceController.text.isNotEmpty
                            ? double.parse(distanceController.text)
                            : null;
                        final duration = durationController.text.isNotEmpty
                            ? int.parse(durationController.text)
                            : null;
                        widget.onSave(distance, duration);
                        Navigator.pop(context);
                      }
                    },
                    label: l10n.translate('save'),
                    isSmallScreen: isSmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Stop Alert dialog
class StopAlertDialog extends StatefulWidget {
  final int? initialMinutes;
  final void Function(int minutes) onSave;
  const StopAlertDialog({super.key, this.initialMinutes, required this.onSave});

  @override
  State<StopAlertDialog> createState() => _StopAlertDialogState();
}

class _StopAlertDialogState extends State<StopAlertDialog> {
  late final TextEditingController controller;
  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    controller =
        TextEditingController(text: widget.initialMinutes?.toString() ?? '');
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isSmall = MediaQuery.of(context).size.width < 360;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: Container(
        constraints: BoxConstraints(maxWidth: isSmall ? 280 : 320),
        padding: EdgeInsets.all(isSmall ? 16 : 24),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.translate('stopAlert'),
                  style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: isSmall ? 18 : 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              CustomTextField(
                controller: controller,
                labelText: l10n.translate('stopTime'),
                hintText: '0',
                suffixText: l10n.translate('min'),
                isNumber: true,
                allowDecimals: false,
                allowNegative: false,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.translate('requiredField');
                  }
                  final t = int.tryParse(value);
                  if (t == null || t <= 0) {
                    return l10n.translate('mustBeGreaterThanZero');
                  }
                  return null;
                },
                borderRadius: 12,
                filled: true,
                fillColor: AppColors.surfaceColor,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  DialogCancelButton(
                    onPressed: () => Navigator.pop(context),
                    label: l10n.translate('cancel'),
                    isSmallScreen: isSmall,
                  ),
                  SizedBox(width: isSmall ? 8 : 12),
                  DialogSaveButton(
                    onPressed: () {
                      if (formKey.currentState?.validate() ?? false) {
                        widget.onSave(int.parse(controller.text));
                        Navigator.pop(context);
                      }
                    },
                    label: l10n.translate('save'),
                    isSmallScreen: isSmall,
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

/// GeoForcing configuration dialog with map and radius slider
class GeoForcingDialog extends StatefulWidget {
  final GeoForcingAlert? initial;
  final void Function(double lat, double lng, double radiusMeters) onSave;
  const GeoForcingDialog({super.key, this.initial, required this.onSave});

  @override
  State<GeoForcingDialog> createState() => _GeoForcingDialogState();
}

class _GeoForcingDialogState extends State<GeoForcingDialog> {
  late double selectedLatitude;
  late double selectedLongitude;
  late double selectedRadius;
  double currentZoom = 13.0;

  @override
  void initState() {
    super.initState();
    selectedLatitude = widget.initial?.latitude ?? 36.8065; // Tunis default
    selectedLongitude = widget.initial?.longitude ?? 10.1815;
    selectedRadius = widget.initial?.radius ?? 1000.0; // 1km
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isSmall = MediaQuery.of(context).size.width < 360;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: Container(
        constraints: BoxConstraints(
            maxWidth: isSmall ? 320 : 400,
            maxHeight: MediaQuery.of(context).size.height * 0.8),
        padding: EdgeInsets.all(isSmall ? 16 : 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.location_on,
                    color: AppColors.brandBlue, size: isSmall ? 24 : 28),
                SizedBox(width: isSmall ? 8 : 12),
                Expanded(
                    child: Text(l10n.translate('geoForcing'),
                        style: AppTextStyles.bodyMedium.copyWith(
                            fontSize: isSmall ? 18 : 20,
                            fontWeight: FontWeight.bold))),
              ]),
              const SizedBox(height: 12),
              Text(l10n.translate('geoForcingDescription'),
                  style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: isSmall ? 12 : 14,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              Container(
                height: 300,
                decoration: BoxDecoration(
                  color: AppColors.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderColor),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(children: [
                    FlutterMap(
                      options: MapOptions(
                        initialCenter:
                            LatLng(selectedLatitude, selectedLongitude),
                        initialZoom: 13.0,
                        onTap: (tapPosition, point) {
                          setState(() {
                            selectedLatitude = point.latitude;
                            selectedLongitude = point.longitude;
                          });
                        },
                        onMapEvent: (event) {
                          setState(() => currentZoom = event.camera.zoom);
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.fds.neotrack',
                        ),
                        MarkerLayer(markers: [
                          Marker(
                            point: LatLng(selectedLatitude, selectedLongitude),
                            width: ProfileTextHelper.calculateCircleSize(
                                selectedRadius, currentZoom),
                            height: ProfileTextHelper.calculateCircleSize(
                                selectedRadius, currentZoom),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.brandBlue.withOpacity(0.2),
                                border: Border.all(
                                    color: AppColors.brandBlue.withOpacity(0.6),
                                    width: 2),
                              ),
                            ),
                          ),
                          Marker(
                            point: LatLng(selectedLatitude, selectedLongitude),
                            width: 30,
                            height: 30,
                            child: const Icon(Icons.location_on,
                                color: AppColors.brandBlue, size: 30),
                          ),
                        ]),
                      ],
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(8)),
                        child: Text(l10n.translate('tapToSetLocation'),
                            style: AppTextStyles.bodyMedium.copyWith(
                                color: Colors.white,
                                fontSize: isSmall ? 11 : 12,
                                fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center),
                      ),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 16),
              Text(l10n.translate('setRadius'),
                  style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: isSmall ? 14 : 16,
                      fontWeight: FontWeight.w600)),
              Slider(
                value: (selectedRadius / 1000).clamp(1.0, 400.0),
                min: 1.0,
                max: 400.0,
                divisions: 399,
                label: '${(selectedRadius / 1000).toStringAsFixed(1)} km',
                onChanged: (v) => setState(() => selectedRadius = v * 1000),
                activeColor: AppColors.brandBlue,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.brandBlue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: AppColors.brandBlue.withOpacity(0.3)),
                  ),
                  child: Text(
                      '${(selectedRadius / 1000).toStringAsFixed(1)} km',
                      style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.brandBlue)),
                ),
              ),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                DialogCancelButton(
                  onPressed: () => Navigator.pop(context),
                  label: l10n.translate('cancel'),
                  isSmallScreen: isSmall,
                ),
                SizedBox(width: isSmall ? 8 : 12),
                DialogSaveButton(
                  onPressed: () {
                    widget.onSave(
                        selectedLatitude, selectedLongitude, selectedRadius);
                    Navigator.pop(context);
                  },
                  label: l10n.translate('save'),
                  isSmallScreen: isSmall,
                ),
              ])
            ],
          ),
        ),
      ),
    );
  }
}

enum _ContactUpdateType { phone, email }

class UpdateProfileDialog extends StatefulWidget {
  final String? initialFname;
  final String? initialLname;
  final Future<void> Function(String? fname, String? lname) onSave;

  const UpdateProfileDialog({
    super.key,
    this.initialFname,
    this.initialLname,
    required this.onSave,
  });

  @override
  State<UpdateProfileDialog> createState() => _UpdateProfileDialogState();
}

class _UpdateProfileDialogState extends State<UpdateProfileDialog> {
  late final TextEditingController fnameController;
  late final TextEditingController lnameController;
  final formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    fnameController = TextEditingController(text: widget.initialFname ?? '');
    lnameController = TextEditingController(text: widget.initialLname ?? '');
  }

  @override
  void dispose() {
    fnameController.dispose();
    lnameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isSmall = MediaQuery.of(context).size.width < 360;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: Container(
        constraints: BoxConstraints(maxWidth: isSmall ? 320 : 380),
        padding: EdgeInsets.all(isSmall ? 16 : 24),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.translate('updateName'),
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: isSmall ? 18 : 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: fnameController,
                  labelText: l10n.translate('firstName'),
                  hintText: l10n.translate('firstName'),
                  prefixIcon: const Icon(Icons.person_outline),
                  validator: (value) {
                    final first = value?.trim() ?? '';
                    final last = lnameController.text.trim();
                    if (first.isEmpty && last.isEmpty) {
                      return l10n.translate('atLeastOneRequired');
                    }
                    return null;
                  },
                  borderRadius: 12,
                  filled: true,
                  fillColor: AppColors.surfaceColor,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: lnameController,
                  labelText: l10n.translate('lastName'),
                  hintText: l10n.translate('lastName'),
                  prefixIcon: const Icon(Icons.person_outline),
                  validator: (value) {
                    final first = fnameController.text.trim();
                    final last = value?.trim() ?? '';
                    if (first.isEmpty && last.isEmpty) {
                      return l10n.translate('atLeastOneRequired');
                    }
                    return null;
                  },
                  borderRadius: 12,
                  filled: true,
                  fillColor: AppColors.surfaceColor,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    DialogCancelButton(
                      onPressed:
                          _isSubmitting ? null : () => Navigator.pop(context),
                      label: l10n.translate('cancel'),
                      isSmallScreen: isSmall,
                    ),
                    SizedBox(width: isSmall ? 8 : 12),
                    DialogSaveButton(
                      onPressed: _isSubmitting
                          ? null
                          : () async {
                              if (formKey.currentState?.validate() ?? false) {
                                setState(() => _isSubmitting = true);
                                try {
                                  final fname = fnameController.text.trim();
                                  final lname = lnameController.text.trim();
                                  await widget.onSave(
                                    fname.isEmpty ? null : fname,
                                    lname.isEmpty ? null : lname,
                                  );
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                  }
                                } finally {
                                  if (mounted) {
                                    setState(() => _isSubmitting = false);
                                  }
                                }
                              }
                            },
                      label: l10n.translate('save'),
                      isSmallScreen: isSmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ChangeContactDialog extends StatefulWidget {
  final Future<void> Function(String? phone, String? email) onRequestOtp;
  final Future<void> Function(String? phone, String? email, String otp)
      onVerifyOtp;

  const ChangeContactDialog({
    super.key,
    required this.onRequestOtp,
    required this.onVerifyOtp,
  });

  @override
  State<ChangeContactDialog> createState() => _ChangeContactDialogState();
}

class _ChangeContactDialogState extends State<ChangeContactDialog> {
  final formKey = GlobalKey<FormState>();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final otpController = TextEditingController();
  _ContactUpdateType _type = _ContactUpdateType.phone;
  bool _otpRequested = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    phoneController.dispose();
    emailController.dispose();
    otpController.dispose();
    super.dispose();
  }

  String? _selectedPhone() {
    final value = phoneController.text.trim();
    return _type == _ContactUpdateType.phone && value.isNotEmpty ? value : null;
  }

  String? _selectedEmail() {
    final value = emailController.text.trim();
    return _type == _ContactUpdateType.email && value.isNotEmpty ? value : null;
  }

  Future<void> _submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    final l10n = AppLocalizations.of(context);
    setState(() => _isSubmitting = true);
    try {
      final phone = _selectedPhone();
      final email = _selectedEmail();
      if (!_otpRequested) {
        await widget.onRequestOtp(phone, email);
        if (!mounted) return;
        CustomSnackBar.success(
          title: l10n.translate('success'),
          message: l10n.translate('otpSent'),
        );
        setState(() => _otpRequested = true);
      } else {
        await widget.onVerifyOtp(phone, email, otpController.text.trim());
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (_) {
      if (mounted) {
        CustomSnackBar.error(
          title: l10n.translate('error'),
          message: l10n.translate(
            _otpRequested ? 'otpVerifyFailed' : 'otpRequestFailed',
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isSmall = MediaQuery.of(context).size.width < 360;
    final selectedColor = AppColors.brandBlue;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: Container(
        constraints: BoxConstraints(maxWidth: isSmall ? 340 : 400),
        padding: EdgeInsets.all(isSmall ? 16 : 24),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.translate('changeContactInfo'),
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: isSmall ? 18 : 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.translate('phoneOrEmailChangeRequiresOtp'),
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: isSmall ? 12 : 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const borderWidth = 1.0;
                      const buttonCount = 2;
                      // ToggleButtons draws borders on both sides + between buttons.
                      final buttonWidth = (constraints.maxWidth -
                              borderWidth * (buttonCount + 1)) /
                          buttonCount;

                      return ToggleButtons(
                      isSelected: [
                        _type == _ContactUpdateType.phone,
                        _type == _ContactUpdateType.email,
                      ],
                      onPressed: _isSubmitting
                          ? null
                          : (index) {
                              setState(() {
                                _type = index == 0
                                    ? _ContactUpdateType.phone
                                    : _ContactUpdateType.email;
                                _otpRequested = false;
                                otpController.clear();
                              });
                            },
                      borderRadius: BorderRadius.circular(12),
                      selectedColor: Colors.white,
                      fillColor: selectedColor,
                      color: AppColors.textSecondary,
                      constraints: BoxConstraints(
                        minHeight: isSmall ? 40 : 46,
                        minWidth: buttonWidth,
                        maxWidth: buttonWidth,
                      ),
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmall ? 4 : 8,
                          ),
                          child: Text(
                            l10n.translate('phoneNumber'),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: isSmall ? 12 : 14),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmall ? 4 : 8,
                          ),
                          child: Text(
                            l10n.translate('email'),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: isSmall ? 12 : 14),
                          ),
                        ),
                      ],
                    );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                if (_type == _ContactUpdateType.phone)
                  CustomTextField(
                    controller: phoneController,
                    labelText: l10n.translate('newPhoneNumber'),
                    hintText: '98765432',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                    ],
                    validator: (value) {
                      final phone = value?.trim() ?? '';
                      if (phone.isEmpty) {
                        return l10n.translate('requiredField');
                      }
                      if (phone.length != 8) {
                        return l10n.translate('invalidPhone');
                      }
                      return null;
                    },
                    borderRadius: 12,
                    filled: true,
                    fillColor: AppColors.surfaceColor,
                  )
                else
                  CustomTextField(
                    controller: emailController,
                    labelText: l10n.translate('newEmailAddress'),
                    hintText: 'name@example.com',
                    prefixIcon: const Icon(Icons.email_outlined),
                    isEmail: true,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      if (email.isEmpty) {
                        return l10n.translate('requiredField');
                      }
                      final emailRegex = RegExp(
                        r'^[\w-.]+@([\w-]+\.)+[\w-]{2,}$',
                      );
                      if (!emailRegex.hasMatch(email)) {
                        return l10n.translate('invalidEmail');
                      }
                      return null;
                    },
                    borderRadius: 12,
                    filled: true,
                    fillColor: AppColors.surfaceColor,
                  ),
                if (_otpRequested) ...[
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: otpController,
                    labelText: l10n.translate('otpCode'),
                    hintText: '123456',
                    prefixIcon: const Icon(Icons.lock_outline),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    validator: (value) {
                      final otp = value?.trim() ?? '';
                      if (otp.isEmpty) {
                        return l10n.translate('requiredField');
                      }
                      if (otp.length != 6) {
                        return l10n.translate('invalidOtp');
                      }
                      return null;
                    },
                    borderRadius: 12,
                    filled: true,
                    fillColor: AppColors.surfaceColor,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.translate('otpSent'),
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: isSmall ? 12 : 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: isSmall ? 8 : 12,
                  runSpacing: 8,
                  children: [
                    DialogCancelButton(
                      onPressed:
                          _isSubmitting ? null : () => Navigator.pop(context),
                      label: l10n.translate('cancel'),
                      isSmallScreen: isSmall,
                    ),
                    DialogSaveButton(
                      onPressed: _isSubmitting ? null : _submit,
                      label: _otpRequested
                          ? l10n.translate('verifyAndSave')
                          : l10n.translate('requestOtp'),
                      isSmallScreen: isSmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Update password dialog
class UpdatePasswordDialog extends StatefulWidget {
  final Future<void> Function(String oldPwd, String newPwd) onSave;
  const UpdatePasswordDialog({super.key, required this.onSave});

  @override
  State<UpdatePasswordDialog> createState() => _UpdatePasswordDialogState();
}

class _UpdatePasswordDialogState extends State<UpdatePasswordDialog> {
  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isSmall = MediaQuery.of(context).size.width < 360;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: Container(
        constraints: BoxConstraints(
            maxWidth: isSmall ? 280 : 320,
            maxHeight: MediaQuery.of(context).size.height * 0.8),
        padding: EdgeInsets.all(isSmall ? 16 : 24),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.translate('updatePassword'),
                    style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: isSmall ? 18 : 20,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: oldPasswordController,
                  labelText: l10n.translate('oldPassword'),
                  hintText: '••••••••',
                  isPassword: true,
                  showPasswordToggle: true,
                  prefixIcon: const Icon(Icons.lock_outline),
                  validator: (v) => (v == null || v.isEmpty)
                      ? l10n.translate('requiredField')
                      : null,
                  borderRadius: 12,
                  filled: true,
                  fillColor: AppColors.surfaceColor,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: newPasswordController,
                  labelText: l10n.translate('newPassword'),
                  hintText: '••••••••',
                  isPassword: true,
                  showPasswordToggle: true,
                  prefixIcon: const Icon(Icons.lock_outline),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return l10n.translate('requiredField');
                    }
                    if (v.length < 8) return l10n.translate('passwordTooShort');
                    if (!RegExp(r'[0-9]').hasMatch(v)) {
                      return l10n.translate('passwordMustContainNumber');
                    }
                    return null;
                  },
                  borderRadius: 12,
                  filled: true,
                  fillColor: AppColors.surfaceColor,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: confirmPasswordController,
                  labelText: l10n.translate('confirmPassword'),
                  hintText: '••••••••',
                  isPassword: true,
                  showPasswordToggle: true,
                  prefixIcon: const Icon(Icons.lock_outline),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return l10n.translate('requiredField');
                    }
                    if (v != newPasswordController.text) {
                      return l10n.translate('passwordsDoNotMatch');
                    }
                    return null;
                  },
                  borderRadius: 12,
                  filled: true,
                  fillColor: AppColors.surfaceColor,
                ),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  DialogCancelButton(
                    onPressed: () => Navigator.pop(context),
                    label: l10n.translate('cancel'),
                    isSmallScreen: isSmall,
                  ),
                  SizedBox(width: isSmall ? 8 : 12),
                  DialogSaveButton(
                    onPressed: () async {
                      if (formKey.currentState?.validate() ?? false) {
                        await widget.onSave(oldPasswordController.text,
                            newPasswordController.text);
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
                    label: l10n.translate('save'),
                    isSmallScreen: isSmall,
                  ),
                ])
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Remote Stop/Start dialogs share similar UI; parameterize by theme and action
class RemoteActionDialog extends StatefulWidget {
  final List<Map<String, dynamic>> cars;
  final String title;
  final String warningText;
  final Color color;
  final Future<void> Function(String carId) onConfirm;
  final String buttonLabel;

  const RemoteActionDialog({
    super.key,
    required this.cars,
    required this.title,
    required this.warningText,
    required this.color,
    required this.onConfirm,
    required this.buttonLabel,
  });

  @override
  State<RemoteActionDialog> createState() => _RemoteActionDialogState();
}

class _RemoteActionDialogState extends State<RemoteActionDialog> {
  String? selectedCarId;
  bool isSliderConfirmed = false;
  bool _isSubmitting = false;
  final sliderKey = GlobalKey<SlideActionState>();

  Future<void> _handleConfirm() async {
    if (selectedCarId == null || !isSliderConfirmed || _isSubmitting) return;

    final carId = selectedCarId!;
    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();
    await Future<void>.delayed(Duration.zero);
    if (!mounted) {
      widget.onConfirm(carId);
      return;
    }
    Navigator.pop(context);
    widget.onConfirm(carId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isSmall = MediaQuery.of(context).size.width < 360;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: Container(
        constraints: BoxConstraints(
            maxWidth: isSmall ? 320 : 400,
            maxHeight: MediaQuery.of(context).size.height * 0.8),
        padding: EdgeInsets.all(isSmall ? 16 : 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                  children: isArabic
                      ? [
                          Expanded(
                              child: Text(widget.title,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                      fontSize: isSmall ? 18 : 20,
                                      fontWeight: FontWeight.bold,
                                      color: widget.color))),
                          SizedBox(width: isSmall ? 8 : 12),
                          Icon(Icons.directions_car,
                              color: widget.color, size: isSmall ? 24 : 28),
                        ]
                      : [
                          Icon(Icons.directions_car,
                              color: widget.color, size: isSmall ? 24 : 28),
                          SizedBox(width: isSmall ? 8 : 12),
                          Expanded(
                              child: Text(widget.title,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                      fontSize: isSmall ? 18 : 20,
                                      fontWeight: FontWeight.bold,
                                      color: widget.color))),
                        ]),
              const SizedBox(height: 12),
              Text(widget.warningText,
                  style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: isSmall ? 12 : 14, color: widget.color)),
              const SizedBox(height: 20),
              Text(l10n.translate('selectVehicle'),
                  style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: isSmall ? 14 : 16,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              if (widget.cars.isEmpty)
                Container(
                  padding: EdgeInsets.all(isSmall ? 12 : 16),
                  decoration: BoxDecoration(
                      color: AppColors.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderColor)),
                  child: Row(
                      children: isArabic
                          ? [
                              Expanded(
                                  child: Text(
                                      l10n.translate('noVehiclesAvailable'),
                                      style: AppTextStyles.bodyMedium.copyWith(
                                          fontSize: isSmall ? 12 : 14,
                                          color: AppColors.textSecondary))),
                              const SizedBox(width: 8),
                              Icon(Icons.info_outline,
                                  color: AppColors.textSecondary,
                                  size: isSmall ? 16 : 20),
                            ]
                          : [
                              Icon(Icons.info_outline,
                                  color: AppColors.textSecondary,
                                  size: isSmall ? 16 : 20),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: Text(
                                      l10n.translate('noVehiclesAvailable'),
                                      style: AppTextStyles.bodyMedium.copyWith(
                                          fontSize: isSmall ? 12 : 14,
                                          color: AppColors.textSecondary))),
                            ]),
                )
              else
                ...widget.cars.asMap().entries.map((entry) {
                  final index = entry.key;
                  final car = entry.value;
                  final carId = (car['car_id']?.toString() ?? index.toString());
                  final selected = selectedCarId == carId;
                  return Padding(
                    padding: EdgeInsets.only(bottom: isSmall ? 8 : 12),
                    child: InkWell(
                      onTap: () => setState(() => selectedCarId = carId),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: EdgeInsets.all(isSmall ? 12 : 16),
                        decoration: BoxDecoration(
                          color: selected
                              ? widget.color.withOpacity(0.08)
                              : AppColors.surfaceColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: selected
                                  ? widget.color.withOpacity(0.3)
                                  : AppColors.borderColor,
                              width: selected ? 2 : 1),
                        ),
                        child: Row(
                            children: isArabic
                                ? [
                                    Radio<String>(
                                        value: carId,
                                        groupValue: selectedCarId,
                                        onChanged: (v) =>
                                            setState(() => selectedCarId = v),
                                        activeColor: widget.color),
                                    SizedBox(width: isSmall ? 12 : 16),
                                    Expanded(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                                '${car['brand']} ${car['model']}',
                                                style: AppTextStyles.bodyMedium
                                                    .copyWith(
                                                        fontSize:
                                                            isSmall ? 12 : 14,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: selected
                                                            ? widget.color
                                                            : AppColors
                                                                .textPrimary)),
                                            const SizedBox(height: 2),
                                            Text(car['plate_number'] ?? '',
                                                textDirection:
                                                    TextDirection.ltr,
                                                style: AppTextStyles.bodyMedium
                                                    .copyWith(
                                                        fontSize:
                                                            isSmall ? 12 : 14,
                                                        color: selected
                                                            ? widget.color
                                                            : AppColors
                                                                .textSecondary)),
                                          ]),
                                    ),
                                    SizedBox(width: isSmall ? 12 : 16),
                                    Icon(Icons.directions_car,
                                        color: selected
                                            ? widget.color
                                            : AppColors.textSecondary,
                                        size: isSmall ? 20 : 24),
                                  ]
                                : [
                                    Icon(Icons.directions_car,
                                        color: selected
                                            ? widget.color
                                            : AppColors.textSecondary,
                                        size: isSmall ? 20 : 24),
                                    SizedBox(width: isSmall ? 12 : 16),
                                    Expanded(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                                '${car['brand']} ${car['model']}',
                                                style: AppTextStyles.bodyMedium
                                                    .copyWith(
                                                        fontSize:
                                                            isSmall ? 14 : 16,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: selected
                                                            ? widget.color
                                                            : AppColors
                                                                .textPrimary)),
                                            const SizedBox(height: 2),
                                            Text(car['plate_number'] ?? '',
                                                textDirection:
                                                    TextDirection.ltr,
                                                style: AppTextStyles.bodyMedium
                                                    .copyWith(
                                                        fontSize:
                                                            isSmall ? 12 : 14,
                                                        color: selected
                                                            ? widget.color
                                                            : AppColors
                                                                .textSecondary)),
                                          ]),
                                    ),
                                    Radio<String>(
                                        value: carId,
                                        groupValue: selectedCarId,
                                        onChanged: (v) =>
                                            setState(() => selectedCarId = v),
                                        activeColor: widget.color),
                                  ]),
                      ),
                    ),
                  );
                }),
              if (selectedCarId != null) ...[
                const SizedBox(height: 12),
                Text(l10n.translate('confirmAction'),
                    style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: isSmall ? 14 : 16,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                if (!isSliderConfirmed)
                  Column(children: [
                    SlideAction(
                      key: sliderKey,
                      text: '',
                      outerColor: widget.color.withOpacity(0.08),
                      innerColor: widget.color,
                      elevation: 0,
                      height: isSmall ? 50 : 60,
                      sliderButtonIcon: Icon(
                          isArabic ? Icons.arrow_back : Icons.arrow_forward,
                          color: Colors.white),
                      onSubmit: () {
                        setState(() => isSliderConfirmed = true);
                        return null;
                      },
                      alignment: Alignment.centerLeft,
                      borderRadius: 12,
                      submittedIcon:
                          const Icon(Icons.check, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                  ])
                else
                  Center(
                      child: Icon(Icons.check_circle,
                          color: widget.color, size: isSmall ? 40 : 48)),
              ],
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                DialogCancelButton(
                  onPressed:
                      _isSubmitting ? null : () => Navigator.pop(context),
                  label: l10n.translate('cancel'),
                  isSmallScreen: isSmall,
                ),
                SizedBox(width: isSmall ? 8 : 12),
                DialogSaveButton(
                  onPressed: (selectedCarId != null &&
                          isSliderConfirmed &&
                          !_isSubmitting)
                      ? _handleConfirm
                      : null,
                  label: widget.buttonLabel,
                  backgroundColor: widget.color,
                  isSmallScreen: isSmall,
                  isLoading: _isSubmitting,
                ),
              ])
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper to show SpeedAlertDialog via a simple function
Future<void> showSpeedAlertDialog(BuildContext context,
    {double? initial, required void Function(double) onSave}) async {
  await showDialog(
      context: context,
      builder: (_) => SpeedAlertDialog(initialValue: initial, onSave: onSave));
}

/// Consistent Save button for all dialogs
class DialogSaveButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final Color? backgroundColor;
  final bool isSmallScreen;
  final bool isLoading;

  const DialogSaveButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.backgroundColor,
    this.isSmallScreen = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomElevatedButton(
      onPressed: isLoading ? null : onPressed,
      text: label,
      isLoading: isLoading,
      backgroundColor: backgroundColor ?? AppColors.buttonBg,
      foregroundColor: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 12 : 20,
        vertical: isSmallScreen ? 8 : 12,
      ),
      borderRadius: 8.0,
      elevation: 0,
    );
  }
}

/// Consistent Cancel button for all dialogs
class DialogCancelButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final bool isSmallScreen;

  const DialogCancelButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.isSmallScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomElevatedButton(
      onPressed: onPressed,
      text: label,
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.textSecondary,
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 12 : 20,
        vertical: isSmallScreen ? 8 : 12,
      ),
      borderRadius: 8.0,
      elevation: 0,
      borderSide: const BorderSide(color: Colors.transparent),
    );
  }
}
