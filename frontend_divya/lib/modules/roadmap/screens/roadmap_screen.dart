import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../shared_widgets/app_header.dart';
import '../../../shared_widgets/bottom_nav_bar.dart';
import '../../../state/locale_provider.dart';
import '../../../state/roadmap_provider.dart';
import '../widgets/milestone_card.dart';
import '../widgets/chapter_card.dart';
import '../widgets/peer_mesh_card.dart';

class RoadmapScreen extends ConsumerWidget {
  const RoadmapScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(localeProvider);
    final isOdia = language == AppLanguage.odia;
    final roadmapState = ref.watch(roadmapProvider);
    final currentRoadmap = roadmapState.currentRoadmap;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F8F0),
      body: SafeArea(
        child: Column(
          children: [
            // Top AppHeader
            const AppHeader(showBackButton: true),

            // Main Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subtitle & Academic Year Banner
                    _buildSubHeader(isOdia),
                    const SizedBox(height: 12),

                    // Subject Pills
                    _buildSubjectSelector(ref, roadmapState, isOdia),
                    const SizedBox(height: 16),

                    if (currentRoadmap != null) ...[
                      // Overall Milestones
                      MilestoneCard(
                        milestone: currentRoadmap.overallMilestone,
                        subjectName: currentRoadmap.subjectNameEn,
                        isOdia: isOdia,
                      ),
                      const SizedBox(height: 16),

                      // Section 1: Completed Chapters
                      _buildSectionHeader(
                        isOdia
                            ? 'ସମାପ୍ତ ଅଧ୍ୟାୟ (COMPLETED CHAPTERS)'
                            : 'COMPLETED CHAPTERS (ସମାପ୍ତ ଅଧ୍ୟାୟ)',
                        '1 Done',
                        Icons.check_circle_outline,
                      ),
                      const SizedBox(height: 8),
                      ...currentRoadmap.completedChapters.map((ch) {
                        final isExpanded = roadmapState.expandedChapterIds
                            .contains(ch.chapterId);
                        return ChapterCard(
                          chapter: ch,
                          isCompleted: true,
                          isExpanded: isExpanded,
                          onToggleExpand: () {
                            ref
                                .read(roadmapProvider.notifier)
                                .toggleChapterExpanded(ch.chapterId);
                          },
                          isOdia: isOdia,
                        );
                      }).toList(),
                      const SizedBox(height: 16),

                      // Section 2: Currently Studying
                      _buildSectionHeader(
                        isOdia
                            ? 'ବର୍ତ୍ତମାନ ପଢୁଛନ୍ତି (CURRENTLY STUDYING)'
                            : 'CURRENTLY STUDYING (ବର୍ତ୍ତମାନ ପଢୁଛନ୍ତି)',
                        'Active Unit',
                        Icons.radio_button_checked,
                        badgeColor: AppColors.primaryPaddyGreen,
                        textColor: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      ChapterCard(
                        chapter: currentRoadmap.currentChapter,
                        isCurrentlyStudying: true,
                        isOdia: isOdia,
                        onActionTap: () {
                          // Navigates to active test session or concept repair
                          context.push('/test');
                        },
                      ),
                      const SizedBox(height: 16),

                      // Section 3: Next Goals
                      _buildSectionHeader(
                        isOdia
                            ? 'ଆଗାମୀ ଲକ୍ଷ୍ୟ (NEXT GOALS)'
                            : 'NEXT GOALS (ଆଗାମୀ ଲକ୍ଷ୍ୟ)',
                        'Locked Pathway',
                        Icons.lock_outline,
                      ),
                      const SizedBox(height: 8),
                      ...currentRoadmap.nextGoals.map((ch) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ChapterCard(
                            chapter: ch,
                            isLocked: true,
                            isOdia: isOdia,
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 16),

                      // Study Offline with Friends Card
                      PeerMeshCard(isOdia: isOdia),
                    ],
                  ],
                ),
              ),
            ),

            // Persistent Bottom Nav
            const BottomNavBar(currentIndex: 1),
          ],
        ),
      ),
    );
  }

  Widget _buildSubHeader(bool isOdia) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFD7EED6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                '⚡ ସିଲାବସ୍ ସମନ୍ୱୟ (Offline Ready)',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDarkGreen,
                ),
              ),
            ),
            const Text(
              'BSE Odisha Board',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textMutedOlive,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          isOdia
              ? 'ମୋର ପାଠ୍ୟକ୍ରମ / My Learning Pathway'
              : 'My Learning Pathway / ମୋର ପାଠ୍ୟକ୍ରମ',
          style: AppTypography.headlineMedium(),
        ),
        Text(
          'BSE Odisha Class 10 • Academic Year 2024–25',
          style: AppTypography.bodySmallMuted(),
        ),
      ],
    );
  }

  Widget _buildSubjectSelector(
      WidgetRef ref, RoadmapState state, bool isOdia) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: state.subjects.map((sub) {
          final isSelected = sub.id == state.selectedSubjectId;
          final label = isOdia
              ? '${sub.nameOr} (${sub.nameEn})'
              : '${sub.nameEn} (${sub.nameOr})';

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                ref.read(roadmapProvider.notifier).selectSubject(sub.id);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryDarkGreen
                      : const Color(0xFFE2EDE0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    String badge,
    IconData icon, {
    Color? badgeColor,
    Color? textColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primaryPaddyGreen),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textHighContrast,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: badgeColor ?? const Color(0xFFE0EFE0),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            badge,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: textColor ?? AppColors.primaryDarkGreen,
            ),
          ),
        ),
      ],
    );
  }
}
