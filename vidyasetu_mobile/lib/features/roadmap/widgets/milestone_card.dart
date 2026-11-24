import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../state/roadmap_provider.dart';

class MilestoneCard extends StatelessWidget {
  final MilestoneProgress milestone;
  final String subjectName;
  final bool isOdia;

  const MilestoneCard({
    Key? key,
    required this.milestone,
    required this.subjectName,
    required this.isOdia,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE5F3E2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD3E7CE)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOdia ? 'ସମୁଦାୟ ସଫଳତା (MILESTONES)' : 'OVERALL MILESTONES',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.textMutedOlive,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isOdia
                      ? '୪ ଟି ମଧ୍ୟରୁ ୧ ଟି ଇତିହାସ ଏକକ ସମାପ୍ତ'
                      : '${milestone.clearedUnits} of ${milestone.totalUnits} $subjectName Units Cleared',
                  style: AppTypography.titleMedium(),
                ),
                const SizedBox(height: 2),
                Text(
                  isOdia
                      ? 'ବାର୍ଷିକ ବୋର୍ଡ ପରୀକ୍ଷା ଲକ୍ଷ୍ୟ: ${milestone.examTargetPercent}%+'
                      : 'Annual Board Exam target: ${milestone.examTargetPercent}%+',
                  style: AppTypography.bodySmallMuted(),
                ),
              ],
            ),
          ),
          // Circular Progress
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: milestone.currentProgressPercent / 100.0,
                  strokeWidth: 6,
                  backgroundColor: const Color(0xFFCCE4C7),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primaryDarkGreen,
                  ),
                  strokeCap: StrokeCap.round,
                ),
                Text(
                  '${milestone.currentProgressPercent}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textHighContrast,
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
