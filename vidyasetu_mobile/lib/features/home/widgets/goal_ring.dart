import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';

class GoalRing extends StatelessWidget {
  final int percentage;
  final int completedMinutes;
  final int remainingMinutes;
  final int totalMinutes;
  final bool isOdia;

  const GoalRing({
    Key? key,
    required this.percentage,
    required this.completedMinutes,
    required this.remainingMinutes,
    required this.totalMinutes,
    required this.isOdia,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F3E6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Circular Progress Indicator
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: percentage / 100.0,
                    strokeWidth: 9,
                    backgroundColor: const Color(0xFFCCE2C9),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primaryDarkGreen,
                    ),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$percentage%',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textHighContrast,
                      ),
                    ),
                    Text(
                      isOdia ? 'ଲକ୍ଷ୍ୟ' : 'DONE',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMutedOlive,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Goal Information
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOdia
                      ? 'ଆଜିର ଲକ୍ଷ୍ୟ: $totalMinutes ମିନିଟ୍ ଅଫଲାଇନ୍ ପାଠ'
                      : 'Daily Goal: $totalMinutes mins offline study',
                  style: AppTypography.titleSmall(),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: AppTypography.bodySmallMuted(),
                    children: [
                      TextSpan(
                        text: isOdia
                            ? '$completedMinutes ମିନିଟ୍ ପଢ଼ା ସରିଛି • '
                            : '$completedMinutes mins completed • ',
                      ),
                      TextSpan(
                        text: isOdia
                            ? 'ଆଉ $remainingMinutes ମିନିଟ୍ ବାକି'
                            : '$remainingMinutes mins remaining',
                        style: const TextStyle(
                          color: AppColors.accentTerracotta,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
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
                    const SizedBox(width: 6),
                    Text(
                      isOdia
                          ? 'ଅନ୍ୟ ସାଙ୍ଗମାନଙ୍କ ସହ ସିଙ୍କ୍ ହୋଇଛି'
                          : 'Synced with peer mesh network',
                      style: AppTypography.labelSmall(
                        color: AppColors.textMutedOlive,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
