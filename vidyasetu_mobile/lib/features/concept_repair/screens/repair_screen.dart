import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../shared_widgets/app_header.dart';
import '../../../shared_widgets/bottom_nav_bar.dart';
import '../../../state/locale_provider.dart';
import '../../../state/explanation_mode_provider.dart';
import '../../../data/mock/mock_data.dart';
import '../../../models/explanation.dart';
import '../../../services/audio_service.dart';
import '../widgets/trilingual_selector.dart';
import '../widgets/comparison_cards.dart';
import '../widgets/citation_card.dart';
import '../widgets/rourkela_reference_card.dart';
import '../widgets/audio_player_widget.dart';

final audioServiceProvider = audioPlayerServiceProvider;

class RepairScreen extends ConsumerStatefulWidget {
  const RepairScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RepairScreen> createState() => _RepairScreenState();
}

class _RepairScreenState extends ConsumerState<RepairScreen> {
  Explanation? _explanation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExplanation();
  }

  Future<void> _loadExplanation() async {
    final exp = await MockDataStore.getExplanation('HIST_CH2_Q03');
    if (mounted) {
      setState(() {
        _explanation = exp;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(localeProvider);
    final isOdia = language == AppLanguage.odia;
    final currentMode = ref.watch(explanationModeProvider);
    final audioService = ref.watch(audioServiceProvider);

    if (_isLoading || _explanation == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryPaddyGreen),
        ),
      );
    }

    final exp = _explanation!;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8EF),
      body: SafeArea(
        child: Column(
          children: [
            // Top AppHeader
            const AppHeader(showBackButton: true),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Concept Diagnosis Sub-Header
                    _buildSubHeader(exp),
                    const SizedBox(height: 12),

                    // 3-Way Tri-Lingual Segmented Selector
                    TrilingualSelector(
                      selectedMode: currentMode,
                      onModeChanged: (mode) {
                        ref
                            .read(explanationModeProvider.notifier)
                            .setMode(mode);
                      },
                    ),
                    const SizedBox(height: 14),

                    // Smart Diagnostic Breakdown Card
                    _buildBreakdownCard(exp, currentMode),
                    const SizedBox(height: 14),

                    // Grounded Source Citation Card
                    CitationCard(citation: exp.groundedCitation),
                    const SizedBox(height: 14),

                    // Historical Case Study Card
                    RourkelaReferenceCard(reference: exp.historicalReference),
                    const SizedBox(height: 14),

                    // Offline Audio TTS Player
                    AudioPlayerWidget(
                      service: audioService,
                      isOdia: isOdia,
                      textToSpeak: isOdia ? exp.pureOdia : exp.pureEnglish,
                    ),
                    const SizedBox(height: 14),

                    // Insight Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4EED8),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.lightbulb_outline_rounded,
                              size: 18, color: AppColors.primaryPaddyGreen),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              exp.insight,
                              style: AppTypography.bodySmallMuted(
                                color: AppColors.textHighContrast,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Next: Update Study Plan CTA Button
                    ElevatedButton(
                      onPressed: () {
                        context.push('/replan');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryDarkGreen,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isOdia
                                ? 'ପରବର୍ତ୍ତୀ: ଅଧ୍ୟୟନ ଯୋଜନା ନବୀକରଣ ➔'
                                : 'Next: Update Study Plan (ଅଧ୍ୟୟନ ଯୋଜନା ନବୀକରଣ) ➔',
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
            ),

            // Persistent Bottom Nav
            const BottomNavBar(currentIndex: 3),
          ],
        ),
      ),
    );
  }

  Widget _buildSubHeader(Explanation exp) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology_alt_outlined,
                    size: 14, color: AppColors.accentTerracotta),
                const SizedBox(width: 4),
                Text(
                  exp.subHeader,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMutedOlive,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFDEDEC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Active Review',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentTerracotta,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                exp.title,
                style: AppTypography.headlineMedium(),
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFFD4EED8),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.volume_up_rounded,
                color: AppColors.primaryPaddyGreen,
                size: 20,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 14, color: AppColors.textMutedOlive),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                exp.mistakeTag,
                style: AppTypography.labelSmall(
                  color: AppColors.textMutedOlive,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBreakdownCard(Explanation exp, ExplanationMode mode) {
    final text = exp.getTextForMode(mode);

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
              Row(
                children: [
                  const Icon(Icons.auto_fix_high_rounded,
                      size: 16, color: AppColors.primaryPaddyGreen),
                  const SizedBox(width: 6),
                  Text(
                    'Smart Diagnostic Breakdown',
                    style: AppTypography.titleSmall(),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5F3E2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  exp.subjectTag,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDarkGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Diagnostic explanation text dynamically updated from mode
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              text,
              key: ValueKey<ExplanationMode>(mode),
              style: mode == ExplanationMode.pureOdia
                  ? AppTypography.bodyLargeOdia()
                  : AppTypography.bodyLarge(),
            ),
          ),
          const SizedBox(height: 6),

          // Comparison Cards
          ComparisonCards(cards: exp.comparisonCards),
        ],
      ),
    );
  }
}
