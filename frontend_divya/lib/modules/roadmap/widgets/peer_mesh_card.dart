import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';

class PeerMeshCard extends StatelessWidget {
  final bool isOdia;

  const PeerMeshCard({Key? key, required this.isOdia}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE5F3E2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4EBD0)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.primaryPaddyGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.share_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOdia
                      ? 'ସାଙ୍ଗମାନଙ୍କ ସହ ଅଫଲାଇନ୍ ପଢ଼ନ୍ତୁ?'
                      : 'Study Offline with Friends?',
                  style: AppTypography.titleSmall(),
                ),
                const SizedBox(height: 2),
                Text(
                  isOdia
                      ? 'ଲୋକାଲ୍ ପିୟର ମେସ୍ ନେଟ୍‌ୱାର୍କ ଦ୍ୱାରା ଅଧ୍ୟାୟ ୨ ନୋଟ୍ ସେୟାର କରନ୍ତୁ'
                      : 'Share Chapter 2 lesson notes via local peer mesh.',
                  style: AppTypography.labelSmall(
                    color: AppColors.textMutedOlive,
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
