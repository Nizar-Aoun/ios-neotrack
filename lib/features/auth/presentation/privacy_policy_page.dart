import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taxi_driver_app/core/theme/app_colors.dart';
import 'package:taxi_driver_app/l10n/app_localizations.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.cardColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          AppLocalizations.of(context).translate('privacyPolicy'),
          style: GoogleFonts.barlow(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceColor,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.privacy_tip_outlined,
                    size: 48,
                    color: AppColors.brandBlue,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context).translate('privacyPolicy'),
                    style: GoogleFonts.barlow(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context).translate('lastUpdated'),
                    style: GoogleFonts.barlow(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Introduction
            _buildSection(
              context,
              "",
              AppLocalizations.of(context).translate('privacyIntro'),
            ),

            // Definitions
            _buildSection(
              context,
              AppLocalizations.of(context)
                  .translate('interpretationDefinitions'),
              AppLocalizations.of(context)
                  .translate('interpretationDefinitionsContent'),
            ),

            // Personal Data Collection
            _buildSection(
              context,
              AppLocalizations.of(context).translate('informationWeCollect'),
              AppLocalizations.of(context)
                  .translate('informationWeCollectContent'),
            ),

            _buildSection(
              context,
              AppLocalizations.of(context).translate('useOfPersonalData'),
              AppLocalizations.of(context)
                  .translate('useOfPersonalDataContent'),
            ),

            _buildSection(
              context,
              AppLocalizations.of(context).translate('informationSharing'),
              AppLocalizations.of(context)
                  .translate('informationSharingContent'),
            ),

            _buildSection(
              context,
              AppLocalizations.of(context).translate('dataRetention'),
              AppLocalizations.of(context).translate('dataRetentionContent'),
            ),

            _buildSection(
              context,
              AppLocalizations.of(context).translate('dataSecurity'),
              AppLocalizations.of(context).translate('dataSecurityContent'),
            ),

            _buildSection(
              context,
              AppLocalizations.of(context).translate('yourRights'),
              AppLocalizations.of(context).translate('yourRightsContent'),
            ),

            _buildSection(
              context,
              AppLocalizations.of(context).translate('dataDisclosure'),
              AppLocalizations.of(context).translate('dataDisclosureContent'),
            ),

            _buildSection(
              context,
              AppLocalizations.of(context).translate('childrensPrivacy'),
              AppLocalizations.of(context).translate('childrensPrivacyContent'),
            ),

            _buildSection(
              context,
              AppLocalizations.of(context).translate('linksToOtherWebsites'),
              AppLocalizations.of(context)
                  .translate('linksToOtherWebsitesContent'),
            ),

            _buildSection(
              context,
              AppLocalizations.of(context).translate('changesToPrivacyPolicy'),
              AppLocalizations.of(context)
                  .translate('changesToPrivacyPolicyContent'),
            ),

            _buildSection(
              context,
              AppLocalizations.of(context).translate('contactUs'),
              AppLocalizations.of(context).translate('contactUsContent'),
            ),

            const SizedBox(height: 30),

            // Footer
            Container(
              height: 100,
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.brandBlue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Image.asset(
                'assets/images/FDS Logo.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Text(
              title,
              style: GoogleFonts.barlow(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
          ],
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.greybg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.borderColor,
                width: 1,
              ),
            ),
            child: Text(
              content,
              style: GoogleFonts.barlow(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
