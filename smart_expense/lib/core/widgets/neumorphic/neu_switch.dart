import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';

class NeuSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeColor;
  final double width;
  final double height;

  const NeuSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.width = 56.0,
    this.height = 30.0,
  });

  @override
  Widget build(BuildContext context) {
    final dark = AppTheme.isDark(context);
    final primary = activeColor ?? AppTheme.getPrimary(context);
    final inColor = AppTheme.getInset(context);
    final surfaceColor = AppTheme.getSurface(context);

    final trackColor = value
        ? (dark ? primary.withValues(alpha: 0.25) : primary.withValues(alpha: 0.18))
        : inColor;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onChanged(!value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        height: height,
        padding: const EdgeInsets.all(3.0),
        decoration: BoxDecoration(
          color: trackColor,
          borderRadius: BorderRadius.circular(height / 2),
          border: Border.all(
            color: value
                ? primary.withValues(alpha: 0.4)
                : (dark ? const Color(0xFF141720) : const Color(0xFFB0BDD0)),
            width: 1.0,
          ),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: height - 8,
            height: height - 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value ? primary : surfaceColor,
              boxShadow: [
                BoxShadow(
                  color: dark
                      ? Colors.black.withValues(alpha: 0.6)
                      : const Color(0xFFA3B1C6).withValues(alpha: 0.6),
                  offset: const Offset(1, 2),
                  blurRadius: 3,
                ),
                if (!dark)
                  const BoxShadow(
                    color: Colors.white,
                    offset: Offset(-1, -1),
                    blurRadius: 2,
                  ),
              ],
            ),
            child: value
                ? const Icon(
                    Icons.check,
                    size: 14,
                    color: Colors.white,
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
