import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../models/diagnostic_result.dart';

class WhyEngineDrawer extends StatelessWidget {
  final DiagnosticResult result;
  final bool isOdia;
  final bool isAddedToRevision;
  final VoidCallback onToggleRevision;
  final VoidCallback onListenInOdia;

  const WhyEngineDrawer({
    Key? key,
    required this.result,
    required this.isOdia,
    required this.isAddedToRevision,
    required this.onToggleRevision,
    required this.onListenInOdia,
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
}
