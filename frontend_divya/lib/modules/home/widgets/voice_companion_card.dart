import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';

class VoiceCompanionCard extends StatelessWidget {
  final bool isOdia;
  final VoidCallback onTap;

  const VoiceCompanionCard({
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
            // Mic circle icon
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: Color(0xFFFDE8E1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.mic,
                  color: AppColors.accentTerracotta,
                  size: 26,
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
                        isOdia ? 'ଭଏସ୍ ସାହାଯ୍ୟ' : 'Ask via Voice',
                        style: AppTypography.titleMedium(),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBE4DC),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isOdia ? 'ମାଇକ ଦବାନ୍ତୁ' : 'No Internet',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accentTerracotta,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isOdia
                        ? 'ଓଡ଼ିଆ କିମ୍ବା ଇଂରାଜୀରେ ପଚାରନ୍ତୁ • ଅଫ୍‌ଲାଇନ୍ AI ସହାୟକ'
                        : 'Tap & speak naturally in Odia or English.',
                    style: AppTypography.bodySmallMuted(),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.volume_up_outlined,
                          size: 14, color: AppColors.accentTerracotta),
                      const SizedBox(width: 4),
                      Text(
                        isOdia ? 'ଶୁଣନ୍ତୁ କୁହନ୍ତୁ' : 'Zero network latency',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accentTerracotta,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text('•',
                          style: TextStyle(
                              color: AppColors.textMutedOlive, fontSize: 10)),
                      const SizedBox(width: 6),
                      Text(
                        isOdia
                            ? 'ସ୍ଥାନୀୟ ମଡେଲ'
                            : '(Local Whisper Engine)',
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
