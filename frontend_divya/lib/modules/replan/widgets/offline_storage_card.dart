import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../models/study_plan.dart';

class OfflineStorageCard extends StatelessWidget {
  final Step5Storage storage;

  const OfflineStorageCard({Key? key, required this.storage}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4EED8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  storage.stepLabel,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDarkGreen,
                  ),
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F6E6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.save_rounded,
                  color: AppColors.primaryPaddyGreen,
                  size: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            storage.title,
            style: AppTypography.headlineSmall(),
          ),
          const SizedBox(height: 12),

          // Inner Storage Details Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F6E6),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle,
                        size: 16, color: AppColors.primaryPaddyGreen),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        storage.details,
                        style: AppTypography.titleSmall(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryDarkGreen,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        storage.networkBadge,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      storage.commitId,
                      style: AppTypography.labelSmall(
                        color: AppColors.textMutedOlive,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      storage.storageUsed,
                      style: AppTypography.labelSmall(
                        color: AppColors.textHighContrast,
                      ),
                    ),
                    Text(
                      storage.readyPercent,
                      style: AppTypography.labelSmallBold(
                        color: AppColors.primaryPaddyGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: const LinearProgressIndicator(
                    value: 1.0,
                    backgroundColor: Color(0xFFCCE4C7),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primaryPaddyGreen,
                    ),
                    minHeight: 5,
                  ),
                ),
                const SizedBox(height: 14),

                // Checkpoints
                ...storage.checkpoints.map((cp) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.check,
                            size: 14, color: AppColors.primaryPaddyGreen),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            cp,
                            style: AppTypography.bodySmallMuted(
                              color: AppColors.textHighContrast,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
