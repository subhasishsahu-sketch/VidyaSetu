import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../data/models/student_model.dart';
import '../../../shared_widgets/app_header.dart';
import '../../../shared_widgets/bottom_nav_bar.dart';
import '../../../state/locale_provider.dart';
import '../../../state/student_profile_provider.dart';
import '../../../state/roadmap_provider.dart';
import '../widgets/goal_ring.dart';
import '../widgets/voice_companion_card.dart';
import '../widgets/diagnostic_assessment_card.dart';
import '../widgets/subject_pills.dart';
import '../widgets/cached_textbooks_card.dart';
import '../widgets/concept_vs_language_growth_graph.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(localeProvider);
    final isOdia = language == AppLanguage.odia;
    final profileState = ref.watch(studentProfileProvider);
    final roadmapState = ref.watch(roadmapProvider);
    final student = profileState.student;

    return Scaffold(
      backgroundColor: const Color(0xFFEBF6EA),
      body: SafeArea(
        child: Column(
          children: [
            // App Header
            AppHeader(
              title: student != null
                  ? '${student.name} | Class ${student.classGrade}'
                  : 'Sunita | Class 10',
            ),

            // Main Scrollable Dashboard
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primaryPaddyGreen,
                onRefresh: () async {
                  await ref.read(studentProfileProvider.notifier).loadProfile();
                  await ref.read(roadmapProvider.notifier).loadRoadmap();
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Offline AI Pill Banner
                      _buildOfflineAiBanner(isOdia),
                      const SizedBox(height: 12),

                      // Sunita's Greeting & Daily Progress Card
                      _buildGreetingCard(
                        context,
                        isOdia,
                        student,
                        profileState.goalPercentage > 0
                            ? profileState.goalPercentage
                            : (student?.goalPercentage ?? 0),
                      ),
                      const SizedBox(height: 16),

                      // Subject Selection Pills
                      SubjectPills(
                        subjects: roadmapState.subjects,
                        selectedSubjectId: roadmapState.selectedSubjectId,
                        onSelect: (id) {
                          ref.read(roadmapProvider.notifier).selectSubject(id);
                        },
                        isOdia: isOdia,
                      ),
                      const SizedBox(height: 16),

                      // Voice Companion Card
                      VoiceCompanionCard(
                        isOdia: isOdia,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.primaryPaddyGreen,
                              content: Text(
                                isOdia
                                    ? 'ଭଏସ୍ ସହାୟକ ପ୍ରସ୍ତୁତ: ମାଇକରେ କୁହନ୍ତୁ...'
                                    : 'Voice Assistant Listening (Offline Whisper SLM)...',
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),

                      // Diagnostic Assessment Card
                      DiagnosticAssessmentCard(
                        isOdia: isOdia,
                        onTap: () {
                          final activeChapterId = roadmapState
                                  .currentRoadmap?.currentChapter.chapterId ??
                              'HIST_CH2';
                          context.push('/test?chapterId=$activeChapterId');
                        },
                      ),
                      const SizedBox(height: 16),

                      // Growth Analytics Chart
                      ConceptVsLanguageGrowthGraph(isOdia: isOdia),
                      const SizedBox(height: 16),

                      // Cached Textbooks Status Card
                      CachedTextbooksCard(isOdia: isOdia),
                    ],
                  ),
                ),
              ),
            ),

            // Persistent Bottom Navigation Bar
            const BottomNavBar(currentIndex: 0),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineAiBanner(bool isOdia) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFDCEFD9),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primaryPaddyGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isOdia
                    ? 'ଅଫଲାଇନ୍ ଏଲ୍ AI (୧୦୦% ଇଣ୍ଟରନେଟ୍ ବିନା)'
                    : 'Offline Edge AI Active',
                style: AppTypography.labelSmallBold(
                  color: AppColors.primaryDarkGreen,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFC7E5C3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isOdia ? 'BSE 2025' : 'BSE Class 10 Local Cache',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDarkGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreetingCard(
      BuildContext context, bool isOdia, StudentModel? student, int goalPercentage) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorderHairline),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOdia
                          ? 'ଶୁଭ ଅପରାହ୍ନ • CLASS 10'
                          : 'Good Afternoon, Sunita',
                      style: AppTypography.labelSmallBold(
                        color: AppColors.accentTerracotta,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isOdia
                          ? 'ନମସ୍କାର, ସୁନିତା'
                          : "Ready for today's BSE Odisha preparation?",
                      style: AppTypography.headlineMedium(),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isOdia
                          ? 'ଆଜିର ମାଟ୍ରିକ ପରୀକ୍ଷା ପ୍ରସ୍ତୁତି ଆରମ୍ଭ କରନ୍ତୁ'
                          : 'Daily target tracking and offline mark recovery.',
                      style: AppTypography.bodySmallMuted(),
                    ),
                  ],
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFE4F3E2),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: AppColors.primaryPaddyGreen,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Daily Progress Circular Indicator
          GoalRing(
            percentage: goalPercentage,
            completedMinutes: student?.completedMinutes ?? 0,
            remainingMinutes: student?.remainingMinutes ?? 15,
            totalMinutes: student?.dailyGoalMinutes ?? 15,
            isOdia: isOdia,
          ),
          const SizedBox(height: 14),

          // Resume Learning Card
          InkWell(
            onTap: () {
              context.push('/roadmap');
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.primaryPaddyGreen,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.menu_book_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isOdia ? 'ପାଠ ଜାରି ରଖନ୍ତୁ' : 'Resume: History',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isOdia
                              ? 'ଇତିହାସ: ସ୍ୱାଧୀନତା ପରବର୍ତ୍ତୀ ଭାରତ'
                              : 'Chapter 1, Sec 2 • Ready Offline',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        if (isOdia)
                          Text(
                            'ଅଧ୍ୟାୟ ୧, ଭାଗ ୨',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
