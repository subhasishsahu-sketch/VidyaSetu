import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/colors.dart';
import '../core/theme/typography.dart';
import 'language_toggle_pill.dart';

class AppHeader extends ConsumerWidget {
  final String? title;
  final bool showBackButton;
  final bool showOfflineBadge;
  final bool showLanguageToggle;
  final Widget? trailing;

  const AppHeader({
    Key? key,
    this.title,
    this.showBackButton = false,
    this.showOfflineBadge = true,
    this.showLanguageToggle = true,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      color: AppColors.backgroundRiceCream,
      child: Row(
        children: [
          if (showBackButton) ...[
            IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textHighContrast),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/home');
                }
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
            const SizedBox(width: 4),
          ],
          // Logo & Name
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.cardBorderHairline),
            ),
            child: const Center(
              child: Icon(Icons.school, size: 18, color: AppColors.primaryPaddyGreen),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title ?? 'Sunita | Class 10',
                  style: AppTypography.titleSmall(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (showOfflineBadge)
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryPaddyGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '100% Offline SLM',
                        style: AppTypography.labelSmall(
                          color: AppColors.primaryPaddyGreen,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          if (showLanguageToggle) ...[
            const LanguageTogglePill(),
            const SizedBox(width: 10),
          ],
          if (trailing != null)
            trailing!
          else
            // User Avatar matching screenshots
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.cardBorderHairline, width: 1.5),
                color: const Color(0xFFD4E6D2),
              ),
              child: const ClipOval(
                child: Icon(Icons.person, color: AppColors.primaryPaddyGreen, size: 22),
              ),
            ),
        ],
      ),
    );
  }
}
