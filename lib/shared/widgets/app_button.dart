import 'package:flutter/material.dart';

import 'package:voxora/core/theme/app_colors.dart';
import 'package:voxora/core/theme/app_text_styles.dart';

enum AppButtonVariant { primary, outline, text }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final double? width;
  final double height;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry? padding;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.isFullWidth = true,
    this.leadingIcon,
    this.trailingIcon,
    this.width,
    this.height = 52,
    this.borderRadius = 12,
    this.backgroundColor,
    this.foregroundColor,
    this.textStyle,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case AppButtonVariant.primary:
        return _buildElevated(context);
      case AppButtonVariant.outline:
        return _buildOutlined(context);
      case AppButtonVariant.text:
        return _buildText(context);
    }
  }

  Widget _buildElevated(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: isFullWidth ? double.infinity : (width ?? 0),
        minHeight: height,
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.primary,
          foregroundColor: foregroundColor ?? AppColors.white,
          disabledBackgroundColor: AppColors.textDisabledLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: padding ??
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          elevation: 0,
        ),
        child: _buildChild(foregroundColor ?? AppColors.white),
      ),
    );
  }

  Widget _buildOutlined(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: isFullWidth ? double.infinity : (width ?? 0),
        minHeight: height,
      ),
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: foregroundColor ?? AppColors.primary,
          side: BorderSide(
            color: foregroundColor ?? AppColors.primary,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: padding ??
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        child: _buildChild(foregroundColor ?? AppColors.primary),
      ),
    );
  }

  Widget _buildText(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: isFullWidth ? double.infinity : (width ?? 0),
        minHeight: height,
      ),
      child: TextButton(
        onPressed: isLoading ? null : onPressed,
        style: TextButton.styleFrom(
          foregroundColor: foregroundColor ?? AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: padding ??
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
        child: _buildChild(foregroundColor ?? AppColors.primary),
      ),
    );
  }

  Widget _buildChild(Color color) {
    if (isLoading) {
      return SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      );
    }

    final labelWidget = Text(
      label,
      style: (textStyle ?? AppTextStyles.button).copyWith(color: color),
    );

    if (leadingIcon == null && trailingIcon == null) return labelWidget;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leadingIcon != null) ...[
          Icon(leadingIcon, size: 20, color: color),
          const SizedBox(width: 8),
        ],
        labelWidget,
        if (trailingIcon != null) ...[
          const SizedBox(width: 8),
          Icon(trailingIcon, size: 20, color: color),
        ],
      ],
    );
  }
}
