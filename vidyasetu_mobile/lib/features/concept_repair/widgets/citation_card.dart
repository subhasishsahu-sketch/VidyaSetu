import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../models/grounded_citation.dart';

class CitationCard extends StatelessWidget {
  final GroundedCitation citation;

  const CitationCard({Key? key, required this.citation}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE4F0E2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD2E6D0)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book,
                  size: 16, color: AppColors.accentTerracotta),
              const SizedBox(width: 6),
              Text(
                'Grounded Source Citation (ପ୍ରମାଣିକ ପୁସ୍ତକ ଆଧାର):',
                style: AppTypography.titleSmall(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorderHairline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${citation.bookTitle}, Chapter ${citation.chapterNo}, Page ${citation.pageNo}, Paragraph ${citation.paragraphNo}.',
                  style: AppTypography.titleSmall(),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle,
                            size: 14, color: AppColors.primaryPaddyGreen),
                        const SizedBox(width: 4),
                        Text(
                          citation.status,
                          style: AppTypography.labelSmallBold(
                            color: AppColors.primaryPaddyGreen,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EFE9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        citation.code,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMutedOlive,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.wifi_off_rounded,
                  size: 12, color: AppColors.textMutedOlive),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  citation.subtext,
                  style: AppTypography.labelSmall(
                    color: AppColors.textMutedOlive,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
