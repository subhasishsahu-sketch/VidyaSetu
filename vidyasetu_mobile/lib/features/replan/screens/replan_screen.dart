import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../shared_widgets/app_header.dart';
import '../../../shared_widgets/bottom_nav_bar.dart';
import '../../../state/locale_provider.dart';
import '../../../data/mock/mock_data.dart';
import '../../../models/study_plan.dart';
import '../widgets/micro_lesson_card.dart';
import '../widgets/offline_storage_card.dart';
import '../widgets/recovery_quiz_card.dart';

class ReplanScreen extends ConsumerStatefulWidget {
  const ReplanScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ReplanScreen> createState() => _ReplanScreenState();
}

class _ReplanScreenState extends ConsumerState<ReplanScreen> {
  StudyPlan? _plan;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    final p = await MockDataStore.getStudyPlan();
    if (mounted) {
      setState(() {
        _plan = p;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(localeProvider);
    final isOdia = language == AppLanguage.odia;

    if (_isLoading || _plan == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryPaddyGreen),
        ),
      );
    }

    final plan = _plan!;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8EF),
      body: SafeArea(
        child: Column(
          children: [
            // Top AppHeader
            const AppHeader(showBackButton: true),

            // Scrollable Replan Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Autonomous Audit Header
                    _buildHeader(plan, isOdia),
                    const SizedBox(height: 12),

                    // Resolved Gap Callout
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3EC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF6D8C8)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.tips_and_updates_outlined,
                              size: 16, color: AppColors.accentTerracotta),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              plan.resolvedGap,
                              style: AppTypography.bodySmallMuted(
                                color: AppColors.terracottaDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Step 4: Autonomous Replan Card
                    MicroLessonCard(replan: plan.step4Replan),
                    const SizedBox(height: 14),

                    // Step 5: Storage Verified Card
                    OfflineStorageCard(storage: plan.step5Storage),
                    const SizedBox(height: 14),

                    // Step 6: Action Ready Recovery Quiz Card
                    RecoveryQuizCard(
                      quiz: plan.step6Quiz,
                      onStartQuiz: () {
                        context.go('/test');
                      },
                      onBackToHome: () {
                        context.go('/home');
                      },
                    ),
                    const SizedBox(height: 14),

                    // Footer SchoolMesh Auto-Sync indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE4F0E2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.sensors,
                              size: 16, color: AppColors.primaryPaddyGreen),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              plan.footerSync,
                              style: AppTypography.labelSmall(
                                color: AppColors.textMutedOlive,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Persistent Bottom Navigation
            const BottomNavBar(currentIndex: 3),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(StudyPlan plan, bool isOdia) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle_outline,
                    size: 14, color: AppColors.primaryPaddyGreen),
                const SizedBox(width: 4),
                Text(
                  plan.auditStatus,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: AppColors.primaryDarkGreen,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.cardBorderHairline),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt,
                    size: 12, color: AppColors.primaryPaddyGreen),
                  const SizedBox(width: 4),
                  Text(
                    plan.engineStatus,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDarkGreen,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          plan.title,
          style: AppTypography.headlineMedium(),
        ),
        const SizedBox(height: 2),
        Text(
          plan.subtitle,
          style: AppTypography.bodySmallMuted(),
        ),
      ],
    );
  }
}
