import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../shared_widgets/app_header.dart';
import '../../../shared_widgets/bottom_nav_bar.dart';
import '../../../state/locale_provider.dart';
import '../../../state/diagnostic_session_provider.dart';
import '../widgets/option_tile.dart';
import '../widgets/why_engine_drawer.dart';

class TestScreen extends ConsumerWidget {
  const TestScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(localeProvider);
    final isOdia = language == AppLanguage.odia;
    final sessionState = ref.watch(diagnosticSessionProvider);
    final question = sessionState.currentQuestion;

    if (sessionState.isLoading || question == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryPaddyGreen),
        ),
      );
    }

    final isAddedToRevision =
        sessionState.revisionQuestionIds.contains(question.id);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8EF),
      body: SafeArea(
        child: Column(
          children: [
            // Top AppHeader
            const AppHeader(showBackButton: true),

            // Question Progress Bar & Topic Status
            _buildStatusBar(question),

            // Main Scrollable Test Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question Card
                    _buildQuestionCard(question, isOdia),
                    const SizedBox(height: 16),

                    // Options List
                    ...question.options.map((option) {
                      final isSelected =
                          sessionState.selectedOptionId == option.id;
                      final isCorrect =
                          option.id == question.correctOptionId;
                      final isWrongSelection =
                          isSelected && !isCorrect;

                      return OptionTile(
                        option: option,
                        isSelected: isSelected,
                        isSubmitted: sessionState.isSubmitted,
                        isCorrect: isCorrect,
                        isWrongSelection: isWrongSelection,
                        isOdia: isOdia,
                        onTap: () {
                          if (!sessionState.isSubmitted) {
                            ref
                                .read(diagnosticSessionProvider.notifier)
                                .selectOption(option.id);
                          }
                        },
                      );
                    }).toList(),
                    const SizedBox(height: 12),

                    // Submit Answer button if not yet submitted
                    if (!sessionState.isSubmitted)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: ElevatedButton(
                          onPressed: sessionState.selectedOptionId != null
                              ? () {
                                  ref
                                      .read(diagnosticSessionProvider.notifier)
                                      .submitAnswer();
                                }
                              : null,
                          child: Text(
                            isOdia ? 'ଉତ୍ତର ଜମା କରନ୍ତୁ' : 'Submit Answer',
                          ),
                        ),
                      ),

                    // WHY Engine Slide-up Diagnosis Card
                    if (sessionState.isSubmitted &&
                        sessionState.whyResult != null) ...[
                      WhyEngineDrawer(
                        result: sessionState.whyResult!,
                        isOdia: isOdia,
                        isAddedToRevision: isAddedToRevision,
                        onToggleRevision: () {
                          ref
                              .read(diagnosticSessionProvider.notifier)
                              .toggleRevision(question.id);
                        },
                        onListenInOdia: () {
                          context.push('/repair');
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Persistent Bottom Nav
            const BottomNavBar(currentIndex: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar(dynamic question) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFFEAF5E7),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.bar_chart_rounded,
                      size: 16, color: AppColors.primaryPaddyGreen),
                  const SizedBox(width: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Question ${question.stepNumber} of ${question.totalSteps}',
                        style: AppTypography.titleSmall(),
                      ),
                      Text(
                        'Topic: ${question.topic}',
                        style: AppTypography.labelSmall(
                          color: AppColors.textMutedOlive,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cardBorderHairline),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.storage_rounded,
                        size: 12, color: AppColors.primaryPaddyGreen),
                    SizedBox(width: 4),
                    Text(
                      'SQLite Offline',
                      style: TextStyle(
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
          const SizedBox(height: 10),

          // 5-segment progress bar matching Screenshot 3
          Row(
            children: List.generate(question.totalSteps, (index) {
              final step = index + 1;
              Color color;
              if (step < question.stepNumber) {
                color = AppColors.primaryPaddyGreen; // Completed
              } else if (step == question.stepNumber) {
                color = const Color(0xFFC75D2C); // Active question (orange)
              } else {
                color = const Color(0xFFD6E8D2); // Upcoming
              }

              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    right: index == question.totalSteps - 1 ? 0 : 4,
                  ),
                  height: 4,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(dynamic question, bool isOdia) {
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2F0DE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isOdia ? question.typeBadgeOr : question.typeBadgeEn,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDarkGreen,
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.verified_outlined,
                      size: 12, color: AppColors.primaryPaddyGreen),
                  const SizedBox(width: 4),
                  Text(
                    question.standard,
                    style: AppTypography.labelSmallBold(
                      color: AppColors.primaryPaddyGreen,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            question.questionTextEn,
            style: AppTypography.headlineSmall(),
          ),
          const SizedBox(height: 8),
          Text(
            question.questionTextOr,
            style: AppTypography.bodyLargeOdia(),
          ),
        ],
      ),
    );
  }
}
