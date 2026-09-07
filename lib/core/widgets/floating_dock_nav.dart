import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/toyverse_theme.dart';

class FloatingDockNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const FloatingDockNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = const [
      _DockItemData(icon: Icons.grid_view_rounded, activeIcon: Icons.grid_view_rounded, label: 'Home'),
      _DockItemData(icon: Icons.category_outlined, activeIcon: Icons.category_rounded, label: 'Explore'),
      _DockItemData(icon: Icons.stars_outlined, activeIcon: Icons.stars_rounded, label: 'Rewards'),
      _DockItemData(icon: Icons.local_shipping_outlined, activeIcon: Icons.local_shipping_rounded, label: 'Orders'),
      _DockItemData(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(ToyVerseTheme.radiusNavigation),
        border: Border.all(
          color: Colors.grey.shade200.withValues(alpha: 0.8),
          width: 0.8,
        ),
        boxShadow: ToyVerseTheme.subtleShadow(opacity: 0.06, blur: 24, offset: const Offset(0, 8)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ToyVerseTheme.radiusNavigation),
        child: AnimatedBuilder(
          animation: AlwaysStoppedAnimation(currentIndex),
          builder: (context, child) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: child,
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(items.length, (index) {
                final isSelected = index == currentIndex;
                final item = items[index];

                return GestureDetector(
                  onTap: () => onTap(index),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    padding: EdgeInsets.symmetric(
                      horizontal: isSelected ? 14 : 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? ToyVerseTheme.primaryNavy : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedOpacity(
                          opacity: isSelected ? 1.0 : 0.72,
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.easeOutCubic,
                          child: Icon(
                            isSelected ? item.activeIcon : item.icon,
                            color: isSelected ? Colors.white : ToyVerseTheme.textMuted,
                            size: isSelected ? 20 : 19,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 6),
                          Text(
                            item.label,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
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
      ),
    );
  }
}

class _DockItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _DockItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
