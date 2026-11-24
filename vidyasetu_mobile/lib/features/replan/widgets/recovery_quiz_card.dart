import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../models/study_plan.dart';

class RecoveryQuizCard extends StatelessWidget {
  final Step6Quiz quiz;
  final VoidCallback onStartQuiz;
  final VoidCallback onBackToHome;

  const RecoveryQuizCard({
    Key? key,
    required this.quiz,
    required this.onStartQuiz,
    required this.onBackToHome,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorderHairline),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBE4DC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  quiz.stepLabel,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accentTerracotta,
                  ),
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFFFDE8E1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.assignment_turned_in_rounded,
                  color: AppColors.accentTerracotta,
                  size: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            quiz.title,
            style: AppTypography.headlineSmall(),
          ),
          const SizedBox(height: 4),
          Text(
            quiz.description,
            style: AppTypography.bodySmallMuted(),
          ),
          const SizedBox(height: 14),

          // Time and XP container
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F6E6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.timer_outlined,
                        size: 16, color: AppColors.textHighContrast),
                    const SizedBox(width: 6),
                    Text(
                      quiz.estimatedTime,
                      style: AppTypography.titleSmall(),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.cardBorderHairline),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.stars_rounded,
                          size: 14, color: AppColors.accentTerracotta),
                      const SizedBox(width: 4),
                      Text(
                        quiz.rewardXp,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accentTerracotta,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Primary Recovery Action Button
          ElevatedButton(
            onPressed: onStartQuiz,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDarkGreen,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  quiz.buttonLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Secondary Back to Home Button
          OutlinedButton(
            onPressed: onBackToHome,
            style: OutlinedButton.styleFrom(
              backgroundColor: const Color(0xFFE8F6E6),
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              minimumSize: const Size(double.infinity, 44),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.home_outlined,
                    size: 16, color: AppColors.textHighContrast),
                const SizedBox(width: 6),
                Text(
                  quiz.secondaryLabel,
                  style: AppTypography.titleSmall(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
