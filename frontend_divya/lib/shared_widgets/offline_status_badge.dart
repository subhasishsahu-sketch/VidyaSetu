import 'package:flutter/material.dart';
import '../core/theme/colors.dart';
import '../core/theme/typography.dart';

class OfflineStatusBadge extends StatelessWidget {
  final String text;
  final String? rightText;

  const OfflineStatusBadge({
    Key? key,
    this.text = '● 100% Offline SLM',
    this.rightText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE5F4E7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFCCE8CF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.primaryPaddyGreen,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppTypography.labelSmallBold(color: AppColors.primaryPaddyGreen),
          ),
          if (rightText != null) ...[
            const SizedBox(width: 6),
            Text(
              rightText!,
              style: AppTypography.labelSmall(color: AppColors.textMutedOlive),
            ),
          ]
        ],
      ),
    );
  }
}
