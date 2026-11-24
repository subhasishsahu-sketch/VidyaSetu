import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../models/chapter.dart';
import 'topic_stepper.dart';

class ChapterCard extends StatelessWidget {
  final Chapter chapter;
  final bool isCurrentlyStudying;
  final bool isCompleted;
  final bool isLocked;
  final bool isExpanded;
  final VoidCallback? onToggleExpand;
  final VoidCallback? onActionTap;
  final bool isOdia;

  const ChapterCard({
    Key? key,
    required this.chapter,
    this.isCurrentlyStudying = false,
    this.isCompleted = false,
    this.isLocked = false,
    this.isExpanded = false,
    this.onToggleExpand,
    this.onActionTap,
    required this.isOdia,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isCurrentlyStudying) {
      return _buildCurrentlyStudyingCard(context);
    }
    if (isCompleted) {
      return _buildCompletedCard();
    }
    return _buildLockedCard();
  }

  Widget _buildCompletedCard() {
    return InkWell(
      onTap: onActionTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorderHairline),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryPaddyGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ch ${chapter.chapterNo}: ${chapter.titleEn}',
                        style: AppTypography.titleSmall(),
                      ),
                      if (isOdia)
                        Text(
                          '(${chapter.titleOr})',
                          style: AppTypography.labelSmall(),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4EED8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Mastery: ${chapter.masteryPercent}%',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryPaddyGreen,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${chapter.eventsMapped ?? "12/12 Key events mapped"} • Diagnostic cleared on ${chapter.clearedDate ?? "14 Oct"}',
                  style: AppTypography.labelSmall(
                    color: AppColors.textMutedOlive,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.textMutedOlive,
                  ),
                  onPressed: onToggleExpand,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentlyStudyingCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primaryPaddyGreen, width: 2),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4EED8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '⚡ In Progress • Active Focus',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDarkGreen,
                  ),
                ),
              ),
              Text(
                'Estimated: ${chapter.estimatedMinsLeft ?? 35} mins left',
                style: AppTypography.labelSmall(
                  color: AppColors.textMutedOlive,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Ch ${chapter.chapterNo}: ${chapter.titleEn}',
            style: AppTypography.titleMedium(),
          ),
          const SizedBox(height: 3),
          Text(
            chapter.titleOr,
            style: AppTypography.bodySmallMuted(),
          ),
          const SizedBox(height: 12),

          // Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress: ${chapter.clearedTopicsCount ?? 3} of ${chapter.totalTopicsCount ?? 5} topics cleared',
                style: AppTypography.labelSmallBold(
                  color: AppColors.primaryPaddyGreen,
                ),
              ),
              Text(
                '${chapter.progressPercent ?? 60}%',
                style: AppTypography.labelSmallBold(
                  color: AppColors.primaryPaddyGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (chapter.progressPercent ?? 60) / 100.0,
              backgroundColor: const Color(0xFFCCE4C7),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primaryPaddyGreen,
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 14),

          // 5-Topic Stepper
          TopicStepper(
            topics: chapter.topics,
            isOdia: isOdia,
            onTopicTap: (topic) {
              if (onActionTap != null) onActionTap!();
            },
          ),
          const SizedBox(height: 12),

          // Audio Explainer Ready Card
          if (chapter.audioExplainer != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF5E8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4E6D2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.history_edu_rounded,
                      color: AppColors.primaryPaddyGreen,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chapter.audioExplainer!.title,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: AppColors.accentTerracotta,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          chapter.audioExplainer!.heading,
                          style: AppTypography.titleSmall(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          chapter.audioExplainer!.description,
                          style: AppTypography.labelSmall(
                            color: AppColors.textMutedOlive,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),

          // Primary Continue Button
          ElevatedButton(
            onPressed: onActionTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPaddyGreen,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isOdia
                      ? 'ପରବର୍ତ୍ତୀ ପଦକ୍ଷେପ: ସବୁଜ ବିପ୍ଳବ (Green Revolution) ➔'
                      : 'Continue Step : Green Revolution (ସବୁଜ ବିପ୍ଳବ) ➔',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedCard() {
    return InkWell(
      onTap: onActionTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFEFF3EE),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorderHairline),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                color: AppColors.textMutedOlive,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          chapter.titleEn,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMutedOlive,
                          ),
                        ),
                      ),
                      if (chapter.totalTopicsCount != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${chapter.totalTopicsCount} Topics',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textMutedOlive,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (isOdia) ...[
                    const SizedBox(height: 2),
                    Text(
                      chapter.titleOr,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMutedOlive,
                      ),
                    ),
                  ],
                  if (chapter.lockReason != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.lock_clock_outlined,
                            size: 12, color: AppColors.textMutedOlive),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            chapter.lockReason!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMutedOlive,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
