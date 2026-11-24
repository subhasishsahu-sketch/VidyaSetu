import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../data/models/diagnostic_model.dart';
import '../../../data/models/question_model.dart';
import '../../../models/diagnostic_result.dart';
import '../../../services/audio_service.dart';

class WhyEngineDrawer extends ConsumerStatefulWidget {
  final DiagnosticResult result;
  final bool isOdia;
  final bool isAddedToRevision;
  final VoidCallback onToggleRevision;
  final VoidCallback onListenInOdia;

  // Step 2 & 3 extensions:
  final Map<String, dynamic>? activeProbe;
  final String? selectedProbeOption;
  final ValueChanged<String>? onSelectProbeOption;
  final RecoveryPracticeQuestionModel? recoveryQuestion;
  final String? selectedRecoveryOption;
  final ValueChanged<String>? onSelectRecoveryOption;
  final RecoverySubmitResponse? recoveryResult;
  final VoidCallback? onNextQuestion;
  final bool isSubmittingProbe;
  final bool isSubmittingRecovery;
  final String? error;
  final ProbeResponseResult? probeResult;

  const WhyEngineDrawer({
    Key? key,
    required this.result,
    required this.isOdia,
    required this.isAddedToRevision,
    required this.onToggleRevision,
    required this.onListenInOdia,
    this.activeProbe,
    this.selectedProbeOption,
    this.onSelectProbeOption,
    this.recoveryQuestion,
    this.selectedRecoveryOption,
    this.onSelectRecoveryOption,
    this.recoveryResult,
    this.onNextQuestion,
    this.isSubmittingProbe = false,
    this.isSubmittingRecovery = false,
    this.error,
    this.probeResult,
  }) : super(key: key);

  @override
  ConsumerState<WhyEngineDrawer> createState() => _WhyEngineDrawerState();
}

class _WhyEngineDrawerState extends ConsumerState<WhyEngineDrawer> {
  int _selectedTab = 0; // 0: Bilingual (Bridge), 1: Odia, 2: English

  @override
  Widget build(BuildContext context) {
    final audioPlayback = ref.watch(audioPlayerServiceProvider);
    final audioState = audioPlayback.state;

    final intervention = widget.probeResult?.intervention;
    final bilingualText = intervention?.bilingualExplanation ?? widget.result.causalWhyOr;
    final odiaText = intervention?.pureOdiaExplanation ?? widget.result.causalWhyOr;
    final englishText = intervention?.pureEnglishExplanation ?? widget.result.causalWhyEn;
    final citation = intervention?.textbookCitation ?? widget.result.citation;
    final glossary = intervention?.groundedGlossary ?? [];

    String currentExplanationText;
    if (_selectedTab == 1) {
      currentExplanationText = odiaText;
    } else if (_selectedTab == 2) {
      currentExplanationText = englishText;
    } else {
      currentExplanationText = bilingualText;
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEBF6EA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD4EBD1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Diagnosis Title Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.accentTerracotta,
              borderRadius: BorderRadius.vertical(top: Radius.circular(19)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.psychology_outlined,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Diagnosis: ${widget.result.diagnosisTitle}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bolt, color: Colors.white, size: 12),
                      const SizedBox(width: 2),
                      Text(
                        '${widget.result.certaintyPercent}% Certainty',
                        style: const TextStyle(
                          fontSize: 10,
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

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Error Alert Banner (if any)
                if (widget.error != null) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDE8E8),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.error!,
                            style: const TextStyle(fontSize: 11, color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                Text(
                  widget.result.sourceEngine,
                  style: AppTypography.labelSmall(
                    color: AppColors.textMutedOlive,
                  ),
                ),
                const SizedBox(height: 12),

                // 3-Way Tri-Lingual Bridge Tab Selector
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCEAD9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Row(
                    children: [
                      _buildTabButton(0, 'Bilingual Bridge (ଓଡ଼ିଆ-ଇଂରାଜୀ)'),
                      _buildTabButton(1, 'ଶୁଦ୍ଧ ଓଡ଼ିଆ'),
                      _buildTabButton(2, 'English'),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Causal Explanation Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.cardBorderHairline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3EC),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.lightbulb_outline_rounded,
                              size: 16,
                              color: AppColors.accentTerracotta,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.result.causalWhyTitle,
                              style: AppTypography.titleSmall(
                                color: AppColors.accentTerracotta,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        currentExplanationText,
                        style: AppTypography.bodyMedium(),
                      ),
                      const SizedBox(height: 12),

                      // Grounded Citation Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F7F2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.menu_book,
                                size: 14, color: AppColors.primaryPaddyGreen),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                citation,
                                style: AppTypography.labelSmallBold(
                                  color: AppColors.textHighContrast,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Grounded Glossary Chips (if any)
                      if (glossary.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: glossary.map((term) {
                            return Chip(
                              label: Text(
                                term,
                                style: const TextStyle(fontSize: 10, color: AppColors.primaryDarkGreen),
                              ),
                              backgroundColor: const Color(0xFFE2F0DE),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),

                // Step 2: Adaptive Diagnostic Probe Section
                if (widget.activeProbe != null && widget.onSelectProbeOption != null) ...[
                  const SizedBox(height: 12),
                  _buildProbeCard(),
                ],

                // Step 3: Immediate Recovery Question Section
                if (widget.recoveryQuestion != null && widget.onSelectRecoveryOption != null) ...[
                  const SizedBox(height: 12),
                  _buildRecoveryCard(),
                ],

                // Step 3 Result: Recovery Banner
                if (widget.recoveryResult != null) ...[
                  const SizedBox(height: 12),
                  _buildRecoveryResultCard(),
                ],

                const SizedBox(height: 14),

                // Primary View Concept Repair Button
                ElevatedButton(
                  onPressed: () {
                    context.push('/repair');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentTerracotta,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.auto_fix_high,
                          size: 16, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        widget.isOdia
                            ? 'ଧାରଣା ସଂଶୋଧନ ଓ ପୁନଃଦେଖଣା (ପ୍ରମାଣ ଓ ବୁଝାମଣା) ➔'
                            : 'View Concept Repair & Replay (ପ୍ରମାଣ ଓ ବୁଝାମଣା) ➔',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Secondary Action Buttons Row (Listen with Sarvam TTS & Add to Revision)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          final textToSpeak = currentExplanationText;
                          final langCode = _selectedTab == 2 ? 'en-IN' : 'od-IN';
                          ref.read(audioPlayerServiceProvider).playSynthesizedText(
                                text: textToSpeak,
                                languageCode: langCode,
                              );
                        },
                        icon: Icon(
                          audioState.state == AudioState.playing
                              ? Icons.pause_circle_outline
                              : (audioState.state == AudioState.loading
                                  ? Icons.hourglass_top
                                  : Icons.volume_up_outlined),
                          size: 16,
                          color: AppColors.textHighContrast,
                        ),
                        label: Text(
                          audioState.state == AudioState.playing
                              ? (widget.isOdia ? 'ବାଜୁଛି...' : 'Playing...')
                              : (audioState.state == AudioState.loading
                                  ? 'Loading...'
                                  : (widget.isOdia ? 'ଓଡ଼ିଆରେ ଶୁଣନ୍ତୁ' : 'Listen')),
                          style: AppTypography.titleSmall(),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(
                              color: AppColors.cardBorderHairline),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          minimumSize: const Size(0, 44),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: widget.onToggleRevision,
                        icon: Icon(
                          widget.isAddedToRevision
                              ? Icons.bookmark_added
                              : Icons.bookmark_add_outlined,
                          size: 16,
                          color: widget.isAddedToRevision
                              ? AppColors.primaryPaddyGreen
                              : AppColors.textHighContrast,
                        ),
                        label: Text(
                          widget.isAddedToRevision ? 'Saved' : 'Add to Revision',
                          style: AppTypography.titleSmall(
                            color: widget.isAddedToRevision
                                ? AppColors.primaryPaddyGreen
                                : AppColors.textHighContrast,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: widget.isAddedToRevision
                              ? const Color(0xFFE8F6E6)
                              : Colors.white,
                          side: BorderSide(
                            color: widget.isAddedToRevision
                                ? AppColors.primaryPaddyGreen
                                : AppColors.cardBorderHairline,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          minimumSize: const Size(0, 44),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Bottom SQLite indexing notice
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFDFEEDC),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(19)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_box_outlined,
                    size: 14, color: AppColors.primaryPaddyGreen),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.result.dbStorageBadge,
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
    );
  }

  Widget _buildTabButton(int index, String label) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primaryDarkGreen : AppColors.textMutedOlive,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProbeCard() {
    final promptOdia = widget.activeProbe?['prompt_odia']?.toString();
    final promptEn = (widget.activeProbe?['prompt_english'] ??
            widget.activeProbe?['question_text'] ??
            widget.activeProbe?['prompt'] ??
            widget.activeProbe?['scenario'])
        ?.toString();

    final probePrompt = widget.isOdia
        ? (promptOdia ?? promptEn ?? 'Adaptive Diagnostic Probe')
        : (promptEn ?? promptOdia ?? 'Adaptive Diagnostic Probe');

    final rawOptions = widget.activeProbe?['options'];
    List<Map<String, dynamic>> options = [];
    if (rawOptions is List) {
      options = rawOptions.map((opt) {
        if (opt is Map) return Map<String, dynamic>.from(opt);
        return {'key': opt.toString(), 'text': opt.toString()};
      }).toList();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD8C2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.help_center_outlined,
                  size: 16, color: AppColors.accentTerracotta),
              const SizedBox(width: 6),
              Text(
                'Adaptive Diagnostic Probe (ତନଖି ପ୍ରଶ୍ନ)',
                style: AppTypography.labelSmallBold(color: AppColors.accentTerracotta),
              ),
              if (widget.isSubmittingProbe) ...[
                const Spacer(),
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentTerracotta),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(probePrompt, style: AppTypography.bodySmall()),
          const SizedBox(height: 8),
          if (options.isNotEmpty)
            ...options.map((opt) {
              final key = opt['key']?.toString() ?? '';
              final text = opt['text']?.toString() ?? '';
              final isChosen = widget.selectedProbeOption == key;

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: InkWell(
                  onTap: () => widget.onSelectProbeOption!(key),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isChosen ? const Color(0xFFFFE8DC) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isChosen ? AppColors.accentTerracotta : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text('$key. ', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
                      ],
                    ),
                  ),
                ),
              );
            }).toList()
          else
            Wrap(
              spacing: 8,
              children: ['A', 'B', 'C', 'D'].map((k) {
                final isChosen = widget.selectedProbeOption == k;
                return ChoiceChip(
                  label: Text('Option $k'),
                  selected: isChosen,
                  onSelected: (_) => widget.onSelectProbeOption!(k),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildRecoveryCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified, size: 16, color: AppColors.successGreen),
              const SizedBox(width: 6),
              Text(
                'Recovery Practice Question (ପୁନରୁଦ୍ଧାର ଅଭ୍ୟାସ)',
                style: AppTypography.labelSmallBold(color: AppColors.successGreen),
              ),
              if (widget.isSubmittingRecovery) ...[
                const Spacer(),
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.successGreen),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(widget.recoveryQuestion!.questionText, style: AppTypography.bodySmall()),
          const SizedBox(height: 8),
          ...widget.recoveryQuestion!.options.map((opt) {
            final isChosen = widget.selectedRecoveryOption == opt.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: InkWell(
                onTap: () => widget.onSelectRecoveryOption!(opt.key),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isChosen ? const Color(0xFFDCFCE7) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isChosen ? AppColors.successGreen : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text('${opt.key}. ', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(child: Text(opt.text, style: const TextStyle(fontSize: 12))),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildRecoveryResultCard() {
    final res = widget.recoveryResult!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFD4EED8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryPaddyGreen),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.primaryPaddyGreen, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  res.isCorrect
                      ? (widget.isOdia
                          ? 'ପୁନରୁଦ୍ଧାର ଅଭ୍ୟାସ ସଫଳ! ଦକ୍ଷତା ବୃଦ୍ଧି (+${res.masteryImpact.toStringAsFixed(0)}%)'
                          : 'Recovery Practice Cleared! (+${res.masteryImpact.toStringAsFixed(0)}% Mastery)')
                      : (widget.isOdia ? 'ସମୀକ୍ଷା ସମ୍ପୂର୍ଣ୍ଣ' : 'Recovery Review Completed'),
                  style: AppTypography.titleSmall(color: AppColors.primaryDarkGreen),
                ),
              ),
            ],
          ),
          if (res.explanation != null) ...[
            const SizedBox(height: 6),
            Text(res.explanation!, style: AppTypography.bodySmall()),
          ],
          const SizedBox(height: 10),
          if (widget.onNextQuestion != null)
            ElevatedButton(
              onPressed: widget.onNextQuestion,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPaddyGreen,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.isOdia ? 'ପରବର୍ତ୍ତୀ ପ୍ରଶ୍ନ ➔' : 'Next Question ➔',
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
}
