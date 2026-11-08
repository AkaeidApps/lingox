import 'package:flutter/material.dart';

import '../../app/constants/app_colors.dart';
import '../../app/constants/app_dimensions.dart';
import '../../data/models/language_model.dart';

class LanguageSelector extends StatelessWidget {
  final LanguageModel selectedLanguage;
  final VoidCallback onTap;
  final bool isSource;

  const LanguageSelector({
    super.key,
    required this.selectedLanguage,
    required this.onTap,
    this.isSource = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingMD,
          vertical: AppDimensions.paddingSM,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedLanguage.flagEmoji,
              style: const TextStyle(fontSize: AppDimensions.fontXL),
            ),
            const SizedBox(width: AppDimensions.paddingSM),
            Text(
              selectedLanguage.name,
              style: TextStyle(
                fontSize: AppDimensions.fontMD,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: AppDimensions.paddingXS),
            Icon(
              Icons.keyboard_arrow_down,
              size: AppDimensions.iconMD,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
