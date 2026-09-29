import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class NeuInset extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? color;
  final bool isCircle;
  final double? width;
  final double? height;

  const NeuInset({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 12.0,
    this.color,
    this.isCircle = false,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final dark = AppTheme.isDark(context);
    final inColor = color ?? AppTheme.getInset(context);

    final borderColor = dark
        ? Colors.black.withValues(alpha: 0.45)
        : const Color(0xFFB0BDD0).withValues(alpha: 0.5);

    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding ?? const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: inColor,
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor,
          width: 1.0,
        ),
      ),
      child: child,
    );
  }
}
