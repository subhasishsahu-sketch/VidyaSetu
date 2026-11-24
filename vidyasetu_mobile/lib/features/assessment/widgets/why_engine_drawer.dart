import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../data/models/diagnostic_model.dart';
import '../../../data/models/question_model.dart';
import '../../../models/diagnostic_result.dart';

class WhyEngineDrawer extends StatelessWidget {
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
  final bool isSubmittingProbe;
  final bool isSubmittingRecovery;

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
    this.isSubmittingProbe = false,
    this.isSubmittingRecovery = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                      'Diagnosis: ${result.diagnosisTitle}',
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
                        '${result.certaintyPercent}% Certainty',
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
                Text(
                  result.sourceEngine,
                  style: AppTypography.labelSmall(
                    color: AppColors.textMutedOlive,
                  ),
                ),
                const SizedBox(height: 12),

                // Causal Card
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
                          Text(
                            result.causalWhyTitle,
                            style: AppTypography.titleSmall(
                              color: AppColors.accentTerracotta,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        isOdia ? result.causalWhyOr : result.causalWhyEn,
                        style: isOdia
                            ? AppTypography.bodyMedium()
                            : AppTypography.bodyMedium(),
                      ),
                      const SizedBox(height: 12),
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
                                result.citation,
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
                    ],
                  ),
                ),

                // Step 2: Adaptive Diagnostic Probe Section (if available)
                if (activeProbe != null && onSelectProbeOption != null) ...[
                  const SizedBox(height: 12),
                  _buildProbeCard(),
                ],

                // Step 3: Immediate Recovery Question Section (if available)
                if (recoveryQuestion != null && onSelectRecoveryOption != null) ...[
                  const SizedBox(height: 12),
                  _buildRecoveryCard(),
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
                        isOdia
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

                // Secondary Action Buttons Row
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onListenInOdia,
                        icon: const Icon(Icons.volume_up_outlined,
                            size: 16, color: AppColors.textHighContrast),
                        label: Text(
                          isOdia ? 'ଓଡ଼ିଆରେ ଶୁଣନ୍ତୁ' : 'Listen in Odia',
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
                        onPressed: onToggleRevision,
                        icon: Icon(
                          isAddedToRevision
                              ? Icons.bookmark_added
                              : Icons.bookmark_add_outlined,
                          size: 16,
                          color: isAddedToRevision
                              ? AppColors.primaryPaddyGreen
                              : AppColors.textHighContrast,
                        ),
                        label: Text(
                          isAddedToRevision ? 'Saved' : 'Add to Revision',
                          style: AppTypography.titleSmall(
                            color: isAddedToRevision
                                ? AppColors.primaryPaddyGreen
                                : AppColors.textHighContrast,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: isAddedToRevision
                              ? const Color(0xFFE8F6E6)
                              : Colors.white,
                          side: BorderSide(
                            color: isAddedToRevision
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
                    result.dbStorageBadge,
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

  Widget _buildProbeCard() {
    final probePrompt = activeProbe!['prompt_odia']?.toString() ??
        activeProbe!['prompt_en']?.toString() ??
        'Adaptive Diagnostic Probe: Confirming root hypothesis';
    final options = (activeProbe!['options'] as List?)?.cast<Map<String, dynamic>>() ?? [];

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
              if (isSubmittingProbe) ...[
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
              final isChosen = selectedProbeOption == key;

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: InkWell(
                  onTap: () => onSelectProbeOption!(key),
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
                final isChosen = selectedProbeOption == k;
                return ChoiceChip(
                  label: Text('Option $k'),
                  selected: isChosen,
                  onSelected: (_) => onSelectProbeOption!(k),
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
              if (isSubmittingRecovery) ...[
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
          Text(recoveryQuestion!.questionText, style: AppTypography.bodySmall()),
          const SizedBox(height: 8),
          ...recoveryQuestion!.options.map((opt) {
            final isChosen = selectedRecoveryOption == opt.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: InkWell(
                onTap: () => onSelectRecoveryOption!(opt.key),
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
}
