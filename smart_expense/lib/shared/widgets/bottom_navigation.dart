import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/neumorphic/neu_card.dart';

class BottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      const _NavItem(
        icon: Icons.grid_view_rounded,
        label: 'Home',
      ),
      const _NavItem(
        icon: Icons.receipt_long_rounded,
        label: 'Expenses',
      ),
      const _NavItem(
        icon: Icons.pie_chart_outline_rounded,
        label: 'Reports',
      ),
      const _NavItem(
        icon: Icons.tune_rounded,
        label: 'Settings',
      ),
    ];

    final primary = AppTheme.getPrimary(context);
    final textMuted = AppTheme.getTextMuted(context);
    final dark = AppTheme.isDark(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12, top: 4),
        child: NeuCard(
          borderRadius: 26,
          depth: 4.5,
          blur: 10,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final isSelected = currentIndex == index;
              final item = items[index];

              return GestureDetector(
                onTap: () => onTap(index),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (dark
                            ? primary.withValues(alpha: 0.2)
                            : primary.withValues(alpha: 0.12))
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                    border: isSelected
                        ? Border.all(
                            color: primary.withValues(alpha: 0.3),
                            width: 1.0,
                          )
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        size: 20,
                        color: isSelected ? primary : textMuted,
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 6),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({required this.icon, required this.label});
}
