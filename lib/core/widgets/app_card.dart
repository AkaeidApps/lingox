import 'package:flutter/material.dart';

import '../../app/constants/app_colors.dart';
import '../../app/constants/app_dimensions.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final double? elevation;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? margin;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.color,
    this.elevation,
    this.borderRadius,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final card = Card(
      color: color ?? AppColors.surface,
      elevation: elevation ?? AppDimensions.elevationSM,
      shape: RoundedRectangleBorder(
        borderRadius:
            borderRadius ?? BorderRadius.circular(AppDimensions.radiusMD),
      ),
      margin:
          margin ??
          const EdgeInsets.symmetric(
            horizontal: AppDimensions.cardMargin,
            vertical: AppDimensions.paddingXS,
          ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AppDimensions.cardPadding),
        child: child,
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius:
            borderRadius ?? BorderRadius.circular(AppDimensions.radiusMD),
        child: card,
      );
    }

    return card;
  }
}
