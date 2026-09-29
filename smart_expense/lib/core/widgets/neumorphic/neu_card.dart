import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class NeuCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double depth;
  final double blur;
  final VoidCallback? onTap;
  final Color? color;
  final Gradient? gradient;
  final Border? border;
  final bool isCircle;

  const NeuCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 16.0,
    this.depth = 4.0,
    this.blur = 8.0,
    this.onTap,
    this.color,
    this.gradient,
    this.border,
    this.isCircle = false,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? AppTheme.getSurface(context);
    final shadows = AppTheme.neuElevation(context, depth: depth, blur: blur);

    Widget content = Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: cardColor,
        gradient: gradient,
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : BorderRadius.circular(borderRadius),
        boxShadow: shadows,
        border: border,
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }

    return content;
  }
}
