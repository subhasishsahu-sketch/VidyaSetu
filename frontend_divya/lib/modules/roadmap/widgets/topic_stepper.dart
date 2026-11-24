import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../models/topic.dart';

class TopicStepper extends StatelessWidget {
  final List<Topic> topics;
  final bool isOdia;
  final Function(Topic) onTopicTap;

  const TopicStepper({
    Key? key,
    required this.topics,
    required this.isOdia,
    required this.onTopicTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(topics.length, (index) {
        final topic = topics[index];
        final isCompleted = topic.status == 'completed';
        final isActive = topic.status == 'active_focus';
        final isAssessment = topic.status == 'final_assessment';

        final title = isOdia ? topic.titleOr : topic.titleEn;

        return InkWell(
          onTap: () => onTopicTap(topic),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFFEFF8ED)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: isActive
                    ? Border.all(color: const Color(0xFFCBE7C6), width: 1)
                    : null,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLeadingIcon(isCompleted, isActive, isAssessment),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isActive
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isActive
                                ? AppColors.textHighContrast
                                : (isCompleted
                                    ? AppColors.textSecondary
                                    : AppColors.textMutedOlive),
                          ),
                        ),
                        if (isActive && isOdia) ...[
                          const SizedBox(height: 2),
                          Text(
                            topic.titleOr,
                            style: AppTypography.bodySmallMuted(
                              color: AppColors.accentTerracotta,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  _buildStatusPill(topic.statusLabel, isCompleted, isActive),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildLeadingIcon(
      bool isCompleted, bool isActive, bool isAssessment) {
    if (isCompleted) {
      return Container(
        width: 22,
        height: 22,
        decoration: const BoxDecoration(
          color: AppColors.primaryPaddyGreen,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, size: 14, color: Colors.white),
      );
    }
    if (isActive) {
      return Container(
        width: 22,
        height: 22,
        decoration: const BoxDecoration(
          color: Color(0xFFFBE4DC),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.bolt,
            size: 14, color: AppColors.accentTerracotta),
      );
    }
    if (isAssessment) {
      return Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.cardBorderHairline, width: 1.5),
        ),
        child: const Icon(Icons.description_outlined,
            size: 12, color: AppColors.textMutedOlive),
      );
    }
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.cardBorderHairline, width: 1.5),
      ),
      child: const Center(
        child: Icon(Icons.circle, size: 8, color: AppColors.textMutedOlive),
      ),
    );
  }

  Widget _buildStatusPill(
      String label, bool isCompleted, bool isActive) {
    if (isActive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.terracottaDark,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          'Current',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      );
    }
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.textMutedOlive,
      ),
    );
  }
}
