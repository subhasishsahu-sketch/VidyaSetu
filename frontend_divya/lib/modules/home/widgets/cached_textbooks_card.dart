import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';

class CachedTextbooksCard extends StatelessWidget {
  final bool isOdia;

  const CachedTextbooksCard({
    Key? key,
    required this.isOdia,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE4F0E2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD2E6D0)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.cloud_done_rounded,
                color: AppColors.primaryPaddyGreen,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOdia
                      ? 'ସ୍କୁଲ୍ ମେସ୍ ନେଟ୍‌ୱାର୍କ: ୨୨ ଜଣ ସାଥୀଙ୍କ ସହ ଅପଡେଟ୍ ହୋଇଛି'
                      : 'All BSE Textbooks Cached',
                  style: AppTypography.titleSmall(),
                ),
                const SizedBox(height: 2),
                Text(
                  isOdia
                      ? '୧୦୦% ଇଣ୍ଟରନେଟ୍ ବିନା ସମ୍ପୂର୍ଣ୍ଣ ସୁରକ୍ଷିତ'
                      : 'Study anytime, uninterrupted even during power cuts.',
                  style: AppTypography.labelSmall(
                    color: AppColors.textMutedOlive,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFD3E8D0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Text(
                  isOdia ? 'ସୁରକ୍ଷିତ' : 'Ready',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryPaddyGreen,
                  ),
                ),
                const SizedBox(width: 3),
                const Icon(
                  Icons.check,
                  size: 12,
                  color: AppColors.primaryPaddyGreen,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
