import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';

class DiagnosticAssessmentCard extends StatelessWidget {
  final bool isOdia;
  final VoidCallback onTap;

  const DiagnosticAssessmentCard({
    Key? key,
    required this.isOdia,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorderHairline),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkmark / Doc circle icon
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: Color(0xFFD4EED8),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.edit_document,
                  color: AppColors.primaryPaddyGreen,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isOdia ? 'ଆଜିର ମକ୍ ଟେଷ୍ଟ' : "Today's Diagnostic Test",
                        style: AppTypography.titleMedium(),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCEFD9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isOdia ? '୫ ପ୍ରଶ୍ନ' : 'Class 10',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryPaddyGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isOdia
                        ? 'କେବଳ ୪ ମିନିଟ୍ • BSE ମଡେଲ ଅନୁସାରେ ପ୍ରସ୍ତୁତ'
                        : '5 questions curated to pinpoint knowledge gaps.',
                    style: AppTypography.bodySmallMuted(),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined,
                          size: 14, color: AppColors.textMutedOlive),
                      const SizedBox(width: 4),
                      Text(
                        isOdia ? '୪ ମିନିଟ୍' : 'Estimated: 4 mins',
                        style: AppTypography.labelSmallBold(
                            color: AppColors.textHighContrast),
                      ),
                      const SizedBox(width: 6),
                      const Text('•',
                          style: TextStyle(
                              color: AppColors.textMutedOlive, fontSize: 10)),
                      const SizedBox(width: 6),
                      Text(
                        isOdia ? 'ତୁରନ୍ତ ଫଳାଫଳ' : 'BSE Pattern',
                        style: AppTypography.labelSmall(
                          color: AppColors.textMutedOlive,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
