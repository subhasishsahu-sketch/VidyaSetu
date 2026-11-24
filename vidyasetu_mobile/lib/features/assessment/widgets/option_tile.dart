import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../models/answer_option.dart';

class OptionTile extends StatelessWidget {
  final AnswerOption option;
  final bool isSelected;
  final bool isSubmitted;
  final bool isCorrect;
  final bool isWrongSelection;
  final bool isOdia;
  final VoidCallback onTap;

  const OptionTile({
    Key? key,
    required this.option,
    required this.isSelected,
    required this.isSubmitted,
    required this.isCorrect,
    required this.isWrongSelection,
    required this.isOdia,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color bgColor = AppColors.surfaceWhite;
    Color borderColor = AppColors.cardBorderHairline;
    Widget leadingIcon;
    Widget? trailingBadge;

    if (isSubmitted) {
      if (isCorrect) {
        bgColor = const Color(0xFFE8F8F5);
        borderColor = AppColors.successGreen;
        leadingIcon = Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: AppColors.successGreen,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, color: Colors.white, size: 16),
        );
        trailingBadge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.successGreen,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'ସଠିକ୍ ଉତ୍ତର (Correct)',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        );
      } else if (isWrongSelection) {
        bgColor = const Color(0xFFFDEDEC);
        borderColor = const Color(0xFFE74C3C);
        leadingIcon = Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: Color(0xFFE74C3C),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.close, color: Colors.white, size: 16),
        );
        trailingBadge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFC75D2C),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'ତୁମର ଉତ୍ତର (Your Pick)',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        );
      } else {
        leadingIcon = _buildLetterCircle(option.id, false);
      }
    } else {
      if (isSelected) {
        bgColor = const Color(0xFFEFF7EE);
        borderColor = AppColors.primaryPaddyGreen;
        leadingIcon = Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: AppColors.primaryPaddyGreen,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              option.id,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        );
      } else {
        leadingIcon = _buildLetterCircle(option.id, false);
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: isSubmitted ? 1.5 : 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              leadingIcon,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.textEn,
                      style: AppTypography.titleSmall(),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      option.textOr,
                      style: AppTypography.bodySmallMuted(),
                    ),
                  ],
                ),
              ),
              if (trailingBadge != null) trailingBadge,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLetterCircle(String letter, bool active) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: active ? AppColors.primaryPaddyGreen : const Color(0xFFF0F4EF),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : AppColors.textMutedOlive,
          ),
        ),
      ),
    );
  }
}
