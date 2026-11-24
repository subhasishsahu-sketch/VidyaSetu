import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../shared_widgets/app_header.dart';
import '../../../shared_widgets/bottom_nav_bar.dart';
import '../../../state/locale_provider.dart';
import '../../../state/diagnostic_session_provider.dart';
import '../../../models/question.dart';
import '../widgets/option_tile.dart';
import '../widgets/why_engine_drawer.dart';

class TestScreen extends ConsumerStatefulWidget {
  final String? chapterId;
  const TestScreen({Key? key, this.chapterId}) : super(key: key);

  @override
  ConsumerState<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends ConsumerState<TestScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(diagnosticSessionProvider.notifier)
          .loadSession(chapterId: widget.chapterId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(localeProvider);
    final isOdia = language == AppLanguage.odia;
    final sessionState = ref.watch(diagnosticSessionProvider);
    final question = sessionState.currentQuestion;

    if (sessionState.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryPaddyGreen),
        ),
      );
    }

    // Session Completed View (Celebratory Summary)
    if (sessionState.isSessionCompleted || question == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF1F8EF),
        body: SafeArea(
          child: Column(
            children: [
              const AppHeader(showBackButton: true),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.cardBorderHairline),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: const BoxDecoration(
                              color: Color(0xFFD4EED8),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.emoji_events_rounded,
                              size: 40,
                              color: AppColors.primaryPaddyGreen,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isOdia
                                ? 'ଅଧ୍ୟାୟ ତନଖି ସମ୍ପୂର୍ଣ୍ଣ!'
                                : 'Chapter Diagnostic Completed!',
                            style: AppTypography.headlineSmall(),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isOdia
                                ? 'ଆପଣ ${sessionState.questions.length} ରୁ ${sessionState.correctAnswersCount} ଟି ପ୍ରଶ୍ନର ସଠିକ୍ ଉତ୍ତର ଦେଇଛନ୍ତି।'
                                : 'You answered ${sessionState.correctAnswersCount} of ${sessionState.questions.length} questions correctly.',
                            style: AppTypography.bodyMedium(
                              color: AppColors.textMutedOlive,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),

                          // Return to Roadmap Button
                          ElevatedButton(
                            onPressed: () {
                              context.push('/roadmap');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryPaddyGreen,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 14),
                              minimumSize: const Size(double.infinity, 48),
                            ),
                            child: Text(
                              isOdia
                                  ? 'ପାଠ୍ୟକ୍ରମ ରୋଡମ୍ୟାପ୍କୁ ଫେରନ୍ତୁ ➔'
                                  : 'Back to Roadmap ➔',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Retake Chapter Button
                          OutlinedButton(
                            onPressed: () {
                              ref
                                  .read(diagnosticSessionProvider.notifier)
                                  .restartSession();
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: AppColors.primaryPaddyGreen),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 14),
                              minimumSize: const Size(double.infinity, 48),
                            ),
                            child: Text(
                              isOdia ? 'ପୁଣି ଅଭ୍ୟାସ କରନ୍ତୁ' : 'Retake Chapter',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryPaddyGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const BottomNavBar(currentIndex: 2),
            ],
          ),
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
            _buildStatusBar(question, sessionState),

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
                      final isCorrect = option.id == question.correctOptionId;
                      final isWrongSelection = isSelected && !isCorrect;

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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryPaddyGreen,
                            minimumSize: const Size(double.infinity, 48),
                          ),
                          child: Text(
                            isOdia ? 'ଉତ୍ତର ଜମା କରନ୍ତୁ' : 'Submit Answer',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                    // Correct Answer Feedback Banner
                    if (sessionState.isSubmitted &&
                        sessionState.isCorrect == true)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4EED8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppColors.primaryPaddyGreen, width: 1.5),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.check_circle,
                                    color: AppColors.primaryPaddyGreen,
                                    size: 24),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    isOdia
                                        ? 'ସଠିକ୍ ଉତ୍ତର! (Correct Answer!)'
                                        : 'Correct Answer! (ସଠିକ୍ ଉତ୍ତର!)',
                                    style: AppTypography.titleMedium(
                                      color: AppColors.primaryDarkGreen,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () {
                                ref
                                    .read(diagnosticSessionProvider.notifier)
                                    .nextQuestion();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryPaddyGreen,
                                minimumSize: const Size(double.infinity, 44),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    (sessionState.currentQuestionIndex ==
                                            sessionState.questions.length - 1)
                                        ? (isOdia
                                            ? 'ଅଧ୍ୟାୟ ସମ୍ପୂର୍ଣ୍ଣ କରନ୍ତୁ ➔'
                                            : 'Finish Chapter ➔')
                                        : (isOdia
                                            ? 'ପରବର୍ତ୍ତୀ ପ୍ରଶ୍ନ ➔'
                                            : 'Next Question ➔'),
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
                      ),

                    // WHY Engine Slide-up Diagnosis Card (Triggered on Wrong Answer)
                    if (sessionState.isSubmitted &&
                        sessionState.isCorrect == false &&
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
                        activeProbe: sessionState.activeProbe,
                        selectedProbeOption: sessionState.selectedProbeOption,
                        onSelectProbeOption: (probeOpt) {
                          ref
                              .read(diagnosticSessionProvider.notifier)
                              .submitProbeAnswer(probeOpt);
                        },
                        recoveryQuestion: sessionState.recoveryQuestion,
                        selectedRecoveryOption:
                            sessionState.selectedRecoveryOption,
                        onSelectRecoveryOption: (recOpt) {
                          ref
                              .read(diagnosticSessionProvider.notifier)
                              .submitRecoveryAnswer(recOpt);
                        },
                        recoveryResult: sessionState.recoveryResult,
                        onNextQuestion: () {
                          ref
                              .read(diagnosticSessionProvider.notifier)
                              .nextQuestion();
                        },
                        isSubmittingProbe: sessionState.isSubmittingProbe,
                        isSubmittingRecovery:
                            sessionState.isSubmittingRecovery,
                        error: sessionState.error,
                        probeResult: sessionState.probeResult,
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

  Widget _buildStatusBar(Question question, DiagnosticSessionState state) {
    final stepNum = state.currentQuestionIndex + 1;
    final totalSteps = state.questions.length;

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
                        'Question $stepNum of $totalSteps',
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

          // Multi-segment progress bar
          Row(
            children: List.generate(totalSteps, (index) {
              final step = index + 1;
              Color color;
              if (step < stepNum) {
                color = AppColors.primaryPaddyGreen; // Completed
              } else if (step == stepNum) {
                color = const Color(0xFFC75D2C); // Active question (orange)
              } else {
                color = const Color(0xFFD6E8D2); // Upcoming
              }

              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    right: index == totalSteps - 1 ? 0 : 4,
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

  Widget _buildQuestionCard(Question question, bool isOdia) {
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
