import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/colors.dart';
import '../state/locale_provider.dart';

class BottomNavBar extends ConsumerWidget {
  final int currentIndex;

  const BottomNavBar({
    Key? key,
    required this.currentIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(localeProvider);
    final isOdia = language == AppLanguage.odia;

    final items = [
      _NavItem(
        icon: Icons.home_rounded,
        labelEn: 'Home',
        labelOr: 'Home (ମୁଖ୍ୟ)',
        route: '/home',
      ),
      _NavItem(
        icon: Icons.alt_route_rounded,
        labelEn: 'Roadmap',
        labelOr: 'Roadmap (ପାଠ୍ୟ)',
        route: '/roadmap',
      ),
      _NavItem(
        icon: Icons.edit_note_rounded,
        labelEn: 'Practice',
        labelOr: 'Practice (ଅଭ୍ୟାସ)',
        route: '/test',
      ),
      _NavItem(
        icon: Icons.psychology_rounded,
        labelEn: 'WHY Engine',
        labelOr: 'WHY (ବିଶ୍ଳେଷଣ)',
        route: '/repair',
      ),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFEEF5EB),
        border: Border(
          top: BorderSide(color: AppColors.cardBorderHairline, width: 1),
        ),
      ),
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (index) {
            final item = items[index];
            final isSelected = currentIndex == index;
            final label = isOdia ? item.labelOr : item.labelEn;

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (!isSelected) {
                  context.go(item.route);
                }
              },
              child: Container(
                constraints: const BoxConstraints(minWidth: 70, minHeight: 48),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      size: 24,
                      color: isSelected
                          ? AppColors.primaryPaddyGreen
                          : AppColors.textMutedOlive,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? AppColors.primaryPaddyGreen
                            : AppColors.textMutedOlive,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String labelEn;
  final String labelOr;
  final String route;

  const _NavItem({
    required this.icon,
    required this.labelEn,
    required this.labelOr,
    required this.route,
  });
}
