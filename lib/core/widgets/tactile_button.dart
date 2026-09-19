import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';

enum TactileButtonType {
  primary, // Vert Duolingo (#58CC02)
  secondary, // Bleu Duolingo (#1CB0F6)
  gold, // Or / Étoiles (#FFC800)
  danger, // Rouge (#FF4B4B)
  neutral, // Blanc / Gris clair
  outline, // Contour tactile
}

class TactileButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final TactileButtonType type;
  final Color? customColor;
  final Color? customDarkColor;
  final Color? customTextColor;
  final Widget? icon;
  final double height;
  final double? width;
  final double borderRadius;
  final double elevation;
  final bool isLoading;
  final TextStyle? textStyle;

  const TactileButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.type = TactileButtonType.primary,
    this.customColor,
    this.customDarkColor,
    this.customTextColor,
    this.icon,
    this.height = 52.0,
    this.width = double.infinity,
    this.borderRadius = 16.0,
    this.elevation = 4.0,
    this.isLoading = false,
    this.textStyle,
  });

  @override
  State<TactileButton> createState() => _TactileButtonState();
}

class _TactileButtonState extends State<TactileButton> {
  bool _isPressed = false;

  (Color bg, Color dark, Color text) _resolveColors(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.onPressed == null) {
      return isDark
          ? (
              const Color(0xFF1E293B),
              const Color(0xFF0F172A),
              const Color(0xFF64748B),
            )
          : (
              AppColors.duoGreyLight,
              AppColors.duoGrey,
              AppColors.duoTextMuted,
            );
    }

    if (widget.customColor != null) {
      return (
        widget.customColor!,
        widget.customDarkColor ?? widget.customColor!.withValues(alpha: 0.8),
        widget.customTextColor ?? Colors.white,
      );
    }

    switch (widget.type) {
      case TactileButtonType.primary:
        return (AppColors.duoGreen, AppColors.duoGreenDark, Colors.white);
      case TactileButtonType.secondary:
        return (AppColors.duoBlue, AppColors.duoBlueDark, Colors.white);
      case TactileButtonType.gold:
        return (AppColors.duoGold, AppColors.duoGoldDark, Colors.white);
      case TactileButtonType.danger:
        return (AppColors.duoRed, AppColors.duoRedDark, Colors.white);
      case TactileButtonType.neutral:
        return isDark
            ? (const Color(0xFF334155), const Color(0xFF1E293B), Colors.white)
            : (Colors.white, AppColors.duoGrey, AppColors.duoTextDark);
      case TactileButtonType.outline:
        return isDark
            ? (const Color(0xFF1E293B), const Color(0xFF334155), AppColors.primaryLight)
            : (Colors.white, const Color(0xFFD1D5DB), AppColors.primary);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (bgColor, darkColor, textColor) = _resolveColors(context);
    final isEnabled = widget.onPressed != null && !widget.isLoading;
    final currentElevation = _isPressed || !isEnabled ? 0.0 : widget.elevation;
    final topPadding = _isPressed || !isEnabled ? widget.elevation : 0.0;

    return GestureDetector(
      onTapDown: isEnabled
          ? (_) {
              setState(() => _isPressed = true);
              HapticFeedback.lightImpact();
            }
          : null,
      onTapUp: isEnabled
          ? (_) {
              setState(() => _isPressed = false);
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        width: widget.width,
        height: widget.height,
        margin: EdgeInsets.only(top: topPadding),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: widget.type == TactileButtonType.neutral || widget.type == TactileButtonType.outline
              ? Border.all(color: darkColor, width: 2)
              : null,
          boxShadow: currentElevation > 0
              ? [
                  BoxShadow(
                    color: darkColor,
                    offset: Offset(0, currentElevation),
                    blurRadius: 0,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: widget.isLoading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(textColor),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      widget.icon!,
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.text,
                      style: widget.textStyle ??
                          TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
