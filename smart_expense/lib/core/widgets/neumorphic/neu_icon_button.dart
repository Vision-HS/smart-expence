import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';

class NeuIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final Color? color;
  final Color? iconColor;
  final bool hasBadge;
  final Color badgeColor;
  final bool isCircle;
  final double borderRadius;

  const NeuIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 42.0,
    this.iconSize = 20.0,
    this.color,
    this.iconColor,
    this.hasBadge = false,
    this.badgeColor = const Color(0xFFEF4444),
    this.isCircle = true,
    this.borderRadius = 12.0,
  });

  @override
  State<NeuIconButton> createState() => _NeuIconButtonState();
}

class _NeuIconButtonState extends State<NeuIconButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.color ?? AppTheme.getSurface(context);
    final iColor = widget.iconColor ?? AppTheme.getTextPrimary(context);
    final shadows = _isPressed
        ? <BoxShadow>[]
        : AppTheme.neuElevation(context, depth: 3.5, blur: 7.0);

    return GestureDetector(
      onTapDown: widget.onTap != null
          ? (_) {
              setState(() => _isPressed = true);
              HapticFeedback.lightImpact();
            }
          : null,
      onTapUp: widget.onTap != null
          ? (_) {
              setState(() => _isPressed = false);
              widget.onTap?.call();
            }
          : null,
      onTapCancel: () {
        if (_isPressed) setState(() => _isPressed = false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: bgColor,
          shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius:
              widget.isCircle ? null : BorderRadius.circular(widget.borderRadius),
          boxShadow: shadows,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              widget.icon,
              size: widget.iconSize,
              color: iColor,
            ),
            if (widget.hasBadge)
              Positioned(
                top: widget.size * 0.2,
                right: widget.size * 0.22,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: widget.badgeColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: bgColor,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
