import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';

class NeuButton extends StatefulWidget {
  final Widget? child;
  final String? text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final double height;
  final double? width;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Color? textColor;

  const NeuButton({
    super.key,
    this.child,
    this.text,
    this.icon,
    required this.onPressed,
    this.isPrimary = false,
    this.height = 48.0,
    this.width,
    this.borderRadius = 14.0,
    this.padding,
    this.color,
    this.textColor,
  });

  @override
  State<NeuButton> createState() => _NeuButtonState();
}

class _NeuButtonState extends State<NeuButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final dark = AppTheme.isDark(context);
    final primaryColor = AppTheme.getPrimary(context);

    Color buttonColor;
    if (widget.isPrimary) {
      buttonColor = primaryColor;
    } else {
      buttonColor = widget.color ?? AppTheme.getSurface(context);
    }

    final double depth = _isPressed ? 1.5 : 4.0;
    final double blur = _isPressed ? 3.0 : 8.0;

    List<BoxShadow> shadows;
    if (widget.isPrimary) {
      shadows = _isPressed
          ? []
          : [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.4),
                offset: const Offset(0, 4),
                blurRadius: 10,
              ),
            ];
    } else {
      shadows = _isPressed
          ? []
          : AppTheme.neuElevation(context, depth: depth, blur: blur);
    }

    Color effectiveTextColor;
    if (widget.textColor != null) {
      effectiveTextColor = widget.textColor!;
    } else if (widget.isPrimary) {
      effectiveTextColor = Colors.white;
    } else {
      effectiveTextColor = AppTheme.getTextPrimary(context);
    }

    Widget content = widget.child ??
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, size: 18, color: effectiveTextColor),
              const SizedBox(width: 8),
            ],
            if (widget.text != null)
              Text(
                widget.text!,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: effectiveTextColor,
                ),
              ),
          ],
        );

    return GestureDetector(
      onTapDown: widget.onPressed != null
          ? (_) {
              setState(() => _isPressed = true);
              HapticFeedback.selectionClick();
            }
          : null,
      onTapUp: widget.onPressed != null
          ? (_) {
              setState(() => _isPressed = false);
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: () {
        if (_isPressed) setState(() => _isPressed = false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        height: widget.height,
        width: widget.width,
        padding: widget.padding ??
            const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: shadows,
          border: !widget.isPrimary && _isPressed
              ? Border.all(
                  color: dark
                      ? const Color(0xFF10121A)
                      : const Color(0xFFB0BDD0),
                  width: 1,
                )
              : null,
        ),
        alignment: Alignment.center,
        child: content,
      ),
    );
  }
}
