import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../models/study_plan.dart';

class MicroLessonCard extends StatelessWidget {
  final Step4Replan replan;

  const MicroLessonCard({Key? key, required this.replan}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final lesson = replan.microLesson;

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
                  color: const Color(0xFFD4EED8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  replan.stepLabel,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDarkGreen,
                  ),
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F6E6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.alt_route_rounded,
                  color: AppColors.primaryPaddyGreen,
                  size: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            replan.title,
            style: AppTypography.headlineSmall(),
          ),
          const SizedBox(height: 4),
          Text(
            replan.description,
            style: AppTypography.bodySmallMuted(),
          ),
          const SizedBox(height: 14),

          // Inner Scheduled Lesson Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F6E6),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.menu_book,
                        size: 14, color: AppColors.primaryPaddyGreen),
                    const SizedBox(width: 6),
                    Text(
                      lesson.tag,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: AppColors.primaryDarkGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  lesson.title,
                  style: AppTypography.titleMedium(),
                ),
                const SizedBox(height: 2),
                Text(
                  lesson.focus,
                  style: AppTypography.bodySmallMuted(),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.alarm,
                        size: 13, color: AppColors.textMutedOlive),
                    const SizedBox(width: 4),
                    Text(
                      lesson.slot,
                      style: AppTypography.labelSmallBold(
                        color: AppColors.textHighContrast,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4EED8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    lesson.projectedGain,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryPaddyGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Pacing Note
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 14, color: AppColors.textMutedOlive),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  lesson.pacingNote,
                  style: const TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textMutedOlive,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
