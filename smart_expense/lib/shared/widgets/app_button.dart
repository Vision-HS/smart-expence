import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

enum AppButtonVariant { primary, secondary, outline }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final AppButtonVariant variant;
  final bool fullWidth;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget button;

    switch (variant) {
      case AppButtonVariant.primary:
        button = ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            minimumSize: fullWidth ? const Size.fromHeight(48) : const Size(0, 48),
          ),
          child: Text(text),
        );
        break;
      case AppButtonVariant.secondary:
        button = ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryContainer,
            foregroundColor: AppTheme.primary,
            minimumSize: fullWidth ? const Size.fromHeight(48) : const Size(0, 48),
            elevation: 0,
          ),
          child: Text(text),
        );
        break;
      case AppButtonVariant.outline:
        button = OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.textPrimary,
            side: const BorderSide(color: AppTheme.border, width: 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            minimumSize: fullWidth ? const Size.fromHeight(48) : const Size(0, 48),
          ),
          child: Text(text),
        );
        break;
    }

    return button;
  }
}
